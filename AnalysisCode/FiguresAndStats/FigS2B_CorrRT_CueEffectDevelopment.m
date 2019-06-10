%% function residuals = FigS2B_CorrRT_CueEffectDevelopment(T, figSize, fontSize, paths, nBoots)
% Make Figure S2B for the supplement to White, Boynton & Yeatman (2019)
% Individual cueing effects on mean correct RTs as a function of age in each condition, with a
% piecewise linear model of development.
% Saves 1 figure and prints statistics to one text file.
%
% Inputs :
% - T: table with information about each subejct and their thresholds in
%   each condition
% - figSize: a 2x1 vector of figure size in cm
% - fontSize: size of the font in the fiture
% - paths: a structure with full directory names for the figure folder
%   (paths.figs) and stats folder (paths.stats)
% - nBoots: number of bootstrapping repetitions to do
%
% Outputs:
% - residuals: a Nx1 matrix of residuals from the fitted function, for each
%   of N subjects
% 
% % By Alex L. White, University of Washington, 2019

function residuals = FigS2B_CorrRT_CueEffectDevelopment(T, figSize, fontSize, paths, nBoots)

ageMin = floor(min(T.age));
ageMax = ceil(max(T.age));

xlims = [ageMin-2 ageMax+2];

%colors
effectColr = hsv2rgb([0.5 0.8 0.6]);
fitColr = effectColr*0.8;

typFillColr = effectColr;
bothColrs = cat(3,ones(size(effectColr)), typFillColr);
neitherFillColr = mean(bothColrs,3);
dysFillColr = ones(size(effectColr));  

datMarkSz = 4;

%% Pull out data
ds = 1000*[T.corrRT_Uncued T.corrRT_Cued];
cueLabels = {'Uncued','Cued'};
effects = ds(:,1) - ds(:,2);

ages = T.age;

readGroups = T.readingGroup;

ylab = 'diff of RTs';

plotTitle = sprintf('%s - %s', cueLabels{1}, cueLabels{2});

eRng = [min(effects) max(effects)];
ylims = eRng + [-1 1]*0.07*diff(eRng);
if ylims(1)>-400 && ylims(2) < 400
    ylims = [-400 400]; 
end

%filter any missing data
goodpts = find(~isnan(effects));
x = ages(goodpts);
y = effects(goodpts);
readGroups = readGroups(goodpts);

%% First do a linear regression for comparison
design = [x ones(size(x))];
[betas, rSqr] = linearRegressionWithStats(design, y);

linearFitParams = betas';
linearRSqr = rSqr;

%cross-validated r-squared
xValResids = NaN(size(x));
sNums = 1:length(x);

for sOut = sNums
    sIs = setdiff(sNums, sOut);
    newBetas = linearRegressionWithStats(design(sIs,:), y(sIs));
    yHat = newBetas(1)*x(sOut) + newBetas(2);
    xValResids(sOut) = y(sOut) - yHat;
end

meanB = nanmean(y);
SSres = sum(xValResids.^2);
SStot = sum((y - meanB).^2);
linearXValRSqr = 1-SSres/SStot;

%% fit the piecewise linear model
fitFun = @twoLinesJoined; % @lineThenFlat;
startParams=[0 0.01 20 0.01]; %slope y-intercept infleciton

fitParams = lsqcurvefit(fitFun,startParams,x,y);
yhat = fitFun(fitParams,ageMin:ageMax);

predy = fitFun(fitParams, x);
resids = y - predy;

residuals = NaN(size(ds,1),1);
residuals(goodpts) = resids;

%regular RSqr
meanB = nanmean(y);
SStot = nansum((y - meanB).^2);
SSres = nansum(residuals.^2);

model2RSqr = 1-SSres/SStot;

%cross-validated R2
xValResids = NaN(size(x));

for sOut = sNums
    sIs = setdiff(sNums, sOut);
    newBetas = lsqcurvefit(fitFun,startParams,x(sIs),y(sIs));
    yHat = fitFun(newBetas, x(sOut));
    xValResids(sOut) = y(sOut) - yHat;
end

SSres = sum(xValResids.^2);
model2XValRSqr = 1-SSres/SStot;
%% plot

figure; hold on;

plot(xlims,[0 0],'k-');

%plot fit
plot(ageMin:ageMax,yhat,'-','Color',fitColr,'LineWidth',1.5);

%plot raw data
for si=1:length(x)
    switch readGroups{si}
        case 'Dyslexic'
            fcolr = dysFillColr;
            marker = 'o';
            lineWidth = 1;
        case 'Typical'
            fcolr = typFillColr;
            marker = 'o';
            lineWidth = 1;
        case 'Neither'
            fcolr = neitherFillColr;
            marker = 'o';
            lineWidth = 0.5;
    end
    
    plot(x(si),y(si),marker,'MarkerSize',datMarkSz,'MarkerEdgeColor',effectColr, 'MarkerFaceColor',fcolr,'LineWidth',lineWidth);
end

ylim(ylims);
xlim(xlims);

set(gca,'XTick',10:10:70);
set(gca,'LabelFontSizeMultiplier',1.0);

xlabel('Age');
ylabel(ylab);
title(plotTitle);
set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);

set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);
figTitle = sprintf('FigS2B_RT_CueEffectDevelopment.eps');

exportfig(gcf,fullfile(paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',fontSize);

%% permutation test and bootstrapping
    
    %% bootstrapping straight linear model and  piecewise linear model
    
    bootLinearFitParams = NaN(nBoots,2);
    
    bootParams = NaN(nBoots, length(fitParams));
    nSubj = length(x);
    for bi=1:nBoots
        ss = randsample(nSubj, nSubj, 'true');
        bootParams(bi,:) = lsqcurvefit(fitFun,startParams,x(ss),y(ss));
        
        %linear model
        [betas] = linearRegressionWithStats([x(ss) ones(size(ss))], y(ss));
        bootLinearFitParams(bi,:) = betas';
    end    
    
    
    %% print stats
    statsF = fopen(fullfile(paths.stats,'StatsS2B_CorrRTs_CueEffectDevelopment.txt'),'w');
    
    fprintf(statsF,'Fitting the ''two-lines joined'' model to the cueing effect: %s - %s\n',cueLabels{1},cueLabels{2});    
   
    %print basic linear model parameters
    fprintf(statsF,'\n==========================================\n');
    fprintf(statsF,'Basic linear regression parameters:\n');
    
    range95 = [2.5 97.5];
    
    bootLinear95CIs = prctile(bootLinearFitParams,range95)';    
    linearParamNames = {'slope','intercept'};
    for pi=1:2
        fprintf(statsF,'\n\n%s\n', linearParamNames{pi});
        fprintf(statsF,'\nBestFit\t booted95%%CI\t\n');
        fprintf(statsF,'%.4f\t [%.4f %.4f]\t [%.4f %.4f]\t', linearFitParams(pi), bootLinear95CIs(pi,1), bootLinear95CIs(pi,2));
        fprintf(statsF,'\n');
    end
    
    fprintf(statsF,'\n==========================================\n');
    fprintf(statsF,'More complex piecewise linear model parameters:\n');
    fitParamNames = {'slope1','intercept1','inflection','slope2'};
    
    fprintf(statsF,'\n');
    for yi=1:size(fitParams,2)
        fprintf(statsF,'\n%s:',fitParamNames{yi});
        fprintf(statsF,'\n\ttrue fit:\t%.4f',fitParams(yi));
        bootCI = prctile(bootParams(:,yi),[2.5 97.5]);
        fprintf(statsF,'\n\tBootstrapped 95%% CI: [%.3f %.3f]\n', bootCI(1), bootCI(2));
    end
    
    fprintf(statsF,'\n\n==========================================\n');
    fprintf(statsF,'\nMODEL FIT QUALITY AND COMPARISON TO SIMPLE LINEAR REGRESSION:\n');
    fprintf(statsF,'\nSimpleLinearRSqr \tModel2RegularRSqr \tSimpleLinearXValRSqr \tModel2XValRSqr\n');
    fprintf(statsF,'%.4f\t%.4f\t', linearRSqr, model2RSqr, linearXValRSqr, model2XValRSqr);
end
