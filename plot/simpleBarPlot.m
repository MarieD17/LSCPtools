function [hbar pV]=simpleBarPlot(Pos,data,colorBar,widthBar,colorError,sigFlag,widthLine)
% hbar=simpleBarPlot(Pos,data,colorBar,widthBar,colorError,sigFlag)
pV=[];
if nargin<6 || isempty(sigFlag)
    sigFlag={0};
end
if nargin<7
    widthLine=3;
end
if size(colorBar,1)==1
    if colorBar(1)=='w'
        colorBar(2,:)='k';
    else
    colorBar(2,:)=colorBar(1,:);
    end
end
hold on;
if sigFlag{1}==1
    hbar=bar(Pos,nanmean(data),'BarWidth',widthBar,'FaceColor',colorBar(1,:),'EdgeColor',colorBar(2,:),'LineWidth',widthLine);
    line([1 1]*Pos,[-1 1]*nanstd(data)/sqrt(sum(~isnan(data))-1)+nanmean(data),'LineWidth',widthLine-1,'Color',colorError)
     if length(data)==length(sigFlag{2}) || length(sigFlag{2})==1
         [h, pV, ~, stats]=ttest(data,sigFlag{2});
         fprintf('... paired t-test p=%1.5f (t(%g)=%2.3f)\n',pV,stats.df,stats.tstat);
    else
         [h, pV, ~, stats]=ttest2(data,sigFlag{2});
         fprintf('... non-paired t-test p=%1.5f (t(%g)=%2.3f)\n',pV,stats.df,stats.tstat);
     end
    if pV<sigFlag{3}
        if nanmean(data)>0
            plot(Pos,1.3*nanstd(data)/sqrt(sum(~isnan(data))-1)+nanmean(data),'*k')
        else
            plot(Pos,-1.3*nanstd(data)/sqrt(sum(~isnan(data))-1)+nanmean(data),'*k')
        end
    end
elseif sigFlag{1}==2
    hbar=bar(Pos,nanmean(data),'BarWidth',widthBar,'FaceColor',colorBar(1,:),'EdgeColor',colorBar(2,:),'LineWidth',widthLine);
    line([1 1]*Pos,[-1 1]*nanstd(data)/sqrt(sum(~isnan(data))-1)+nanmean(data),'LineWidth',widthLine-1,'Color',colorError)
    if length(data)==length(sigFlag{2}) || length(sigFlag{2})==1
        [pV h]=signrank(data,sigFlag{2});
        fprintf('... paired u-test p=%1.5f\n',pV);
    else
        [pV h]=ranksum(data,sigFlag{2});
        fprintf('... non-paired u-test p=%1.5f\n',pV);
    end
    if pV<sigFlag{3}
        if nanmean(data)>0
            plot(Pos,1.3*nanstd(data)/sqrt(sum(~isnan(data))-1)+nanmean(data),'*k')
        else
            plot(Pos,-1.3*nanstd(data)/sqrt(sum(~isnan(data))-1)+nanmean(data),'*k')
        end
    end
elseif sigFlag{1}==0 && length(sigFlag)==3
    if length(data)==length(sigFlag{2}) || length(sigFlag{2})==1
         [h, pV, ~, stats]=ttest(data,sigFlag{2});
         fprintf('... paired t-test p=%1.5f (t(%g)=%2.3f)\n',pV,stats.df,stats.tstat);
    else
         [h, pV, ~, stats]=ttest2(data,sigFlag{2});
         fprintf('... non-paired t-test p=%1.5f (t(%g)=%2.3f)\n',pV,stats.df,stats.tstat);
    end
     hbar=bar(Pos,nanmean(data),'BarWidth',widthBar,'FaceColor',colorBar(1,:),'EdgeColor',colorBar(2,:),'LineWidth',widthLine);
    line([1 1]*Pos,[-1 1]*nanstd(data)/sqrt(sum(~isnan(data))-1)+nanmean(data),'LineWidth',widthLine-1,'Color',colorError)
    
else
    hbar=bar(Pos,nanmean(data),'BarWidth',widthBar,'FaceColor',colorBar(1,:),'EdgeColor',colorBar(2,:),'LineWidth',widthLine);
    line([1 1]*Pos,[-1 1]*nanstd(data)/sqrt(sum(~isnan(data))-1)+nanmean(data),'LineWidth',widthLine-1,'Color',colorError)
    
end