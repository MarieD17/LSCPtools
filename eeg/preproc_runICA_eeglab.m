function D=preproc_runICA_eeglab(param)
% Original from Leonardo Barbosa

if ~isfield(param.ica, 'interactive'), param.ica.interactive = false; end
if ~isfield(param.ica, 'useadjust'), param.ica.useadjust = false; end



% select the correct file
spm_datapath = param.data_path;
file_name = param.file_name;
fprintf('\n\nProcessing %s...\n',file_name);

% load spm data
D = spm_eeg_load([spm_datapath filesep file_name]);

% % % reject aberrant channels
% % maxVal=squeeze(max(abs(D(match_str(D.chantype,'EEG'),:,:)),[],2));
% % wrongValues=maxVal>300;
% % pprtionBad=mean(wrongValues,2);
% % badChannels=find(pprtionBad>1/3);
% % fprintf('... ... %g channels with >30%% of max values above 300uV\n',length(badChannels))

% restart eeglab
ALLEEG = eeglab;

% Run the ICA (or load if dataset already exists)
ica_file_name = [file_name(1:end-4) '_ica.set'];

% convert SPM data to EEGLAB
EEG = pop_fileio([spm_datapath filesep file_name]);
EEG = pop_select( EEG,'nochannel',setdiff(1:D.nchannels,match_str(D.chantype,'EEG')));



netfile = [param.name_sensfile]; % for wanderlust .xyz
% if strcmp(param.type_sensfile,'.xyz')
%     EEG = pop_chanedit(EEG,'load',{netfile, 'filetype', param.type_sensfile});
% else
EEG = pop_chanedit(EEG,'load',{netfile, 'filetype', 'autodetect'});
% end
% EEG = pop_select( EEG,'nochannel',badChannels);

EEG = eeg_checkset( EEG );
eeglab redraw
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, 1);

% Reject bad channels
fprintf('Computing kurtosis for channels...\n');
[ measure indelec ] = rejkurt( reshape(EEG.data, size(EEG.data,1), size(EEG.data,2)*size(EEG.data,3)), 5, [], 2);
fprintf('... found %g bad channels with method: kurtosis\n',sum(indelec))
badChannels=find(indelec);

% Run the ICA
chanica = setdiff(1:EEG.nbchan,badChannels);
if strcmp(param.ica.icatype, 'pca')
    EEG = pop_runica(EEG, 'icatype', 'runica', 'pca', param.ica.pcanumcomp, 'chanind', chanica);
elseif strcmp(param.ica.icatype, 'runicanoext')
    EEG = pop_runica(EEG, 'icatype', 'runica', 'chanind', chanica);
elseif strcmp(param.ica.icatype, 'runica') % recommended
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'chanind', chanica);
else
    EEG = pop_runica(EEG, 'icatype', param.ica.icatype, 'extended', 1, 'chanind', chanica);
end
EEG = eeg_checkset(EEG);

EEG.setname = ica_file_name;
[ALLEEG,EEG] = eeg_store(ALLEEG,EEG,1);
EEG = pop_saveset(EEG, ica_file_name, spm_datapath);
[ALLEEG,EEG] = eeg_store(ALLEEG, EEG, 1);

% Visually inspect the data, and select components for removal and trials to reject
if param.ica.interactive
    
    fprintf('\n Selecting bad components for subject : %s \n\n', fname );
    
    eeglab redraw
    
    % load sensors positions
    netfile = [param.name_sensfile]; % for wanderlust .xyz
    if strcmp(param.type_sensfile,'.xyz')
        EEG = pop_chanedit(EEG,'load',{netfile, 'filetype', param.type_sensfile});
    else
        EEG = pop_chanedit(EEG,'load',{netfile, 'filetype', 'autodetect'});
    end
    
    % load the projection of the components in time
    tmpdata = eeg_getdatact(EEG, 'component', 1:size(EEG.icaweights,1));
    ncomp = size(EEG.icawinv,2);
    nchan = size(EEG.icawinv,1);
    
    EEG.spacing = 25;
    EEG.dispchans = 40;
    EEG.winlength = 20;
    myeegplot(EEG, tmpdata, 0);
    
    
    % Now select the Bad components (Eye movements, muscle, etc)
    %             hc = ceil(length(EEG.icachansind)/2);
    hc = size(EEG.icaweights,1);
    %             hc = 255;
    
    EEG.reject.gcompreject = zeros(1, ncomp);
    
    % Retrieve previously selected components
    badcompfile = [spm_datapath filesep 'rejica_' file_name '.mat'];
    if exist(badcompfile,'file')
        load(badcompfile);
        EEG.reject.gcompreject(compbad) = 1;
    end
    
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, 1);
    
    % Use Adjust to preselect components?
    if param.ica.useadjust
        [art, horiz, vert, blink, disc, ...
            soglia_DV, diff_var, soglia_K, med2_K, meanK, soglia_SED, med2_SED, SED, soglia_SAD, med2_SAD, SAD, ...
            soglia_GDSF, med2_GDSF, GDSF, soglia_V, med2_V, maxvar, soglia_D, maxdin] = ADJUST (EEG,['adjust_report_' fname '.txt']);
        
        % TODO The best would be to do it afterwards and contrast
        % automatic and manually select components, but
        % pop_selectcomps_ADJ is not returning the automatic ones
        % in the EEG object (the highlited in red), so I put all of
        % them as selected so we can unselect them if needed
        EEG.reject.gcompreject(art) = 1;
        
        EEG = pop_selectcomps_ADJ( EEG, 1:size(EEG.icaweights,1), art, horiz, vert, blink, disc,...
            soglia_DV, diff_var, soglia_K, med2_K, meanK, soglia_SED, med2_SED, SED, soglia_SAD, med2_SAD, SAD, ...
            soglia_GDSF, med2_GDSF, GDSF, soglia_V, med2_V, maxvar, soglia_D, maxdin );
        
    else
        EEG = pop_selectcomps(EEG, 1:hc);
    end
    
    f = warndlg('Click here when finished COMPONENT selection.', fname);
    waitfor(f);
    
    % Remove "Bad Trials" added for visualisation
    EEG.reject.icarejthresh = [];
    EEG.reject.icarejthreshE = [];
    
    % concatenate all rejections
    EEG = eeg_rejsuperpose( EEG, 0, 1, 1, 1, 1, 1, 1, 1);
    
    % do the rejection of components
    compbad = find(EEG.reject.gcompreject);
    saveICA = false;
    if isempty(compbad)
        question = sprintf('No bad components to remove! Do you want to generate a copy file ICA%s ?', allNames(subj).name);
        ok = questdlg(question, 'Dummy ICA', 'Yes', 'No', 'Yes');
        
        if strcmp(ok , 'Yes')
            save([eeglab_datapath filesep 'rejica_' fname ],'compbad')
            saveICA = true;
        end
        
    else
        
        if param.ica.finalinspection
            fprintf('Inspection of data after components removal...\n')
            
            % First for joint probability rejection
            if isfield(param.ica,'rejtrialsprob') && param.ica.rejtrialsprob && param.ica.rejtrials
                % calculate bad trials by joint probability distribution
                EEG = pop_jointprob(EEG, 1, 1:EEG.nbchan, 6, 4, 1, 0); % is the epoch probable given the data?
            end
            
            % update reject trials from ICA inspection
            EEG.reject.rejmanual = EEG.reject.icarejmanual;
            
            [ALLEEG EEG] = eeg_store(ALLEEG, EEG, 1);
            
            % look at the data, reject by visual inspection, + validate or invalidate proposed artifacts
            myeegplot(EEG, EEG.data, 1, compbad);
            
            %                     % plot bad trials with ICA removed data as overlay
            %                     eegplot( EEG.data, 'srate', EEG.srate, 'title', 'Channels Temporal Activities', ...
            %                         'limits', [EEG.xmin EEG.xmax]*1000 , 'data2', compproj, 'command', command, eegplotoptions{:});
            
            f = warndlg('Click here when finished RESULTS inpection.', fname);
            waitfor(f);
            
            EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
        end
        
        if param.ica.rejtrials
            question = 'Do you want to confirm Components subtraction and Trials rejection?';
        else
            question = 'Do you want to confirm Components subtraction?';
        end
        ok = questdlg(question, 'Final', 'Yes', 'No', 'Yes');
        
        if strcmp(ok , 'Yes')
            
            saveICA = true;
            % save subtraction in EEG object
            EEG = pop_subcomp(EEG, compbad);
            save([spm_datapath filesep 'rejica_' file_name ],'compbad')
            
        else
            fprintf('\n\nOperation Canceled!\n\n');
        end
        
    end
    
    if saveICA
        % copy the SPM file to the new ICA* file
        S = [];
        S.D = D;
        fprintf(['\nSaving results in the ' 'ICArej' fnamedat(S.D) ' spm files']);
        new_smp_fname = fullfile(spm_datapath,[ 'ICArej' fnamedat(S.D)]);
        S.newname = new_smp_fname;
        D = spm_eeg_copy(S);
        
        % updating meeg-object with new data (finally...)
        D(D.meegchannels,:,find(~D.reject)) = EEG.data; %#ok<FNDSB>
        
        D.save;
    end
    fprintf('\n\nVisual inspecion for %s done.\n', fname );
end

