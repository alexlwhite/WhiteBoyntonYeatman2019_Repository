%% function FigS1B_SmallCueEffects(T, figH, subplotPositions, figSize, opt)
% % Makes Figure S1B for the supplement to White, Boynton & Yeatman (2019)
% This function plots cueing effects as a function of reading ability, and then
% ROC anlaysis comparing the DYS and CON groups. 
% This plots the second panel of a figure that was started in another function
% (linked to figH), and prints a stats file. 
%
% Inputs : 
% - T: table with information about each subject and their thresholds.
% - figH: handle to the figure into which these 2 panels should be
%    plotted.
% - subplotPositions: matrix of coordinates of the subplots, by row and
%   column. 
% - figSize: [width height] of the figure to be saved, in cm
% - opt: structure with fields: 
%   - fontSize: size of the figure's font
%   - opt.paths: a structure with full directory names for the figure folder
%    (opt.paths.figs) and stats folder (opt.paths.stats) 
% 
% 
% By Alex L. White, University of Washington, 2019
function FigS1B_SmallCueEffects(T, figH, subplotPositions, figSize, opt)

threshs = [T.thresh_SmallCue T.thresh_Uncued];
threshs = log10(threshs);


%For this analysis, exclude any subjects who failed to perform above chance
%in either the Uncued or Cued conditions, and therefore have NaNs for those
%thresholds
goodSubj = ~any(isnan(threshs),2);
threshs = threshs(goodSubj,:);

T = T(goodSubj,:);

allEffects = diff(threshs,1,2);


%only take subjects over 14 (because only 1 below 14 did the version of the
%experiment that included the small cue condition) 

ageMin = 14;

ageS = T.age>=ageMin;
ages = T.age(ageS);
readScores = T.readScores(ageS);
readGroups = T.readingGroup(ageS);

effects = allEffects(ageS);

%% plot choices

yrng = [min(allEffects(:)) max(allEffects(:))];
ylims = yrng + [-1 1]*0.13*diff(yrng);

markSz = 5;


effectColr = hsv2rgb([0.8 0.5 0.6]);

%fill colors for individual subject points on scatterplot:
dysFillColr = ones(size(effectColr));
typFillColr = effectColr;
bothColrs = cat(3,dysFillColr, typFillColr);
neitherFillColr = mean(bothColrs,3);

%% print stats
statsF = fopen(fullfile(opt.paths.stats,'StatsS1B_SmallCueEffectVsReadingAbility.txt'),'w');
fprintf(statsF,'STATS ON DEVELOPMENTAL EFFECT ON Uncued-SmallCue Effect on Threshold IN CUEDL1\n');


fprintf(statsF,'\nRan analysis on log10 thresholds\n');


%% Effect of reading ability on cue effects

figure(figH);

%% A. plot of thresholds as a function of reading score for all subjects

goodS = ~isnan(readScores) & ~isnan(effects);

readScoresToCorr = readScores(goodS);
effectsToCorr = effects(goodS);
readGroupsToCorr = readGroups(goodS);

rowI = 2; colI = 1;
panelA = subplot('position',squeeze(subplotPositions(rowI,colI,:)));

hold on;


xlims = [min(readScoresToCorr) max(readScoresToCorr)] + [-5 5];
plot(xlims,[0 0],'k-');

%plot each reading group separately
for subji=1:length(readScoresToCorr)
    switch  readGroupsToCorr{subji}
        case 'Dyslexic'
            fcolr = dysFillColr;
            
        case 'Typical'
            fcolr = typFillColr;
            
        case 'Neither'
            fcolr = neitherFillColr;
    end
    plot(readScoresToCorr(subji), effectsToCorr(subji), 'o','MarkerSize',markSz,'MarkerEdgeColor',effectColr, 'MarkerFaceColor',fcolr);
end
xlim(xlims); ylim(ylims);
set(gca,'XTick',60:20:xlims(2),'YTick',-0.25:0.25:1);

xlabel(opt.readMeasureLabel);
ylabel('\Delta Log threshold');

[corrRho, corrP] = corr(readScoresToCorr, effectsToCorr);

textx = xlims(1)+0.62*diff(xlims);
texty = ylims(1)+0.08*diff(ylims);
text(textx, texty, sprintf('r=%.2f,p=%.2f',corrRho, corrP));
title('Uncued - Small Cue');
set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);


%% B. histogram of residuals for DYS vs CON groups

%and histogram of effects for good & poor readers
dysRes = effects(strcmp(readGroups,'Dyslexic'));
typRes = effects(strcmp(readGroups,'Typical'));

%ROC analysis
bothGroupEffects = effects(~strcmp(readGroups,'Neither'));
groupLabs = readGroups(~strcmp(readGroups,'Neither'));
groupIs = NaN(size(bothGroupEffects));
groupIs(strcmp(groupLabs,'Dyslexic')) = 0;
groupIs(strcmp(groupLabs,'Typical')) = 1;
[Ag] = ROC(bothGroupEffects, groupIs);

ROCpermute = true; nPermute = 5000;
if ROCpermute
    nullAgs = NaN(nPermute,1);
    for pi = 1:nPermute
        nullAgs(pi) = ROC(bothGroupEffects, groupIs(randperm(length(groupIs))));
    end
    nullAgCI = prctile(nullAgs,[2.5 97.5]);
    nullAgP = mean(nullAgs>Ag);
    nullAgSig = all(Ag>nullAgCI) || all(Ag<nullAgCI);
end

rowI = 2; colI = 2;
subplot('position',squeeze(subplotPositions(rowI,colI,:)));

hold on;


bothRes = {dysRes, typRes};

plotOpt.midlineX = 0;
plotOpt.labelXVals    = false;
plotOpt.doXLabel      = true;
plotOpt.doLegend      = false;
plotOpt.legendLabs    = {'DYS','CON'};
plotOpt.legendLoc     = 'NorthEast';
plotOpt.fillColors    = [1 1 1; effectColr];
plotOpt.edgeColors    = [effectColr; effectColr];
plotOpt.meanColors    = [effectColr; 1 1 1];
plotOpt.fillLineWidth = 1.5;
plotOpt.meanLineWidth = 2;
plotOpt.plotMean      = true;

%how to set kerney density
plotOpt.fixKernelWidth = true;
plotOpt.fixedKernelWidth = 0.06;
%if not fixed, set the proportion by which to multiply the average of what ksdensity is the optimal kernel widths
plotOpt.kernelWidthFactor = 0.6;

kernelWidth = pairedSampleDensityPlot(bothRes, plotOpt);

ylim(ylims);
set(gca,'YTickLabel',{});

xlims2 = get(gca,'xlim');

textx = xlims2(1)+0.58*diff(xlims2);
texty = ylims(1)+0.08*diff(ylims);
if nullAgSig
    text(textx, texty, sprintf('AUC=%.2f*', Ag));
else
    text(textx, texty, sprintf('AUC=%.2f', Ag));
end


%% stats
fprintf(statsF,'\n\n--------------------------------------------------------------\n');
fprintf(statsF,'RELATIONSHIP BETWEEN READING ABILITY AND THE *SMALL* CUE - UNCUED EFFECT\n');
fprintf(statsF,'--------------------------------------------------------------\n');
fprintf(statsF,'Correlation between effects and %s: rho = %.3f, p=%.3f\n', opt.readMeasureLabel, corrRho, corrP);

fprintf(statsF,'\nThen, dividing into Dyslexic vs Typical readers, comparing the effets:\n');
fprintf(statsF,'\nDyslexics: mean effect = %.4f, median = %.4f, SEM = %.3f', nanmean(dysRes), nanmedian(dysRes), standardError(dysRes'));
fprintf(statsF,'\nTypicals: mean effect = %.4f, median = %.4f, SEM = %.3f', nanmean(typRes), nanmedian(typRes), standardError(typRes'));
fprintf(statsF,'\n\nLM to compare effects between %i dyslexics and %i typical readers:\n', length(dysRes), length(typRes));

rT = table;
rT.effect = effects;
rT.age = ages;
rT.ageNormed = ages - nanmean(ages); %de-mean the ages

rT.readingGroup = readGroups;

rT.readingScore = readScores;


rT.wasiMatrix = T.wasiMatrixReasoningTScore(ageS);
rT.wasiMatrixNormed = rT.wasiMatrix - nanmean(rT.wasiMatrix); %de-mean
rT.adhd = categorical(T.adhdDiagnosis(ageS));
rT.subject = (1:length(effects))';
subst = ~strcmp(rT.readingGroup,'Neither');

eqtn = 'effect ~ readingGroup + ageNormed + adhd + wasiMatrixNormed';

lm = fitlm(rT(subst,:),eqtn); %,'DummyVarCoding','effects');

fprintf(statsF,'\n%s\n\n', eqtn);
for cfi = 1:numel(lm.CoefficientNames)
    fprintf(statsF,'Fixed effect of %s = %.4f;\t', lm.CoefficientNames{cfi},  lm.Coefficients.Estimate(cfi));
    fprintf(statsF,'t(%i) = %.4f, p=%.4f\n', lm.DFE, lm.Coefficients.tStat(cfi), lm.Coefficients.pValue(cfi));
end

fprintf(statsF,'\nROC analysis: Area Under Curve = %.3f, permutation 95%%CI = [%.3f %.3f], p=%.4f\n', Ag, nullAgCI(1), nullAgCI(2), nullAgP);
fprintf(statsF,'\tSmoothing kernel width: %.3f',kernelWidth);

fprintf(statsF,'\nThen a similar analysis with reading score (%s) as a continuous measure on all subjects:\n', opt.readMeasureLabel);

eqtn2 = 'effect ~ readingScore + ageNormed + adhd + wasiMatrixNormed';

lm2 = fitlm(rT,eqtn2);

fprintf(statsF,'\n%s\n\n', eqtn2);
for cfi = 1:numel(lm.CoefficientNames)
    fprintf(statsF,'Fixed effect of %s = %.4f;\t', lm2.CoefficientNames{cfi},  lm2.Coefficients.Estimate(cfi));
    fprintf(statsF,'t(%i) = %.4f, p=%.4f\n', lm2.DFE, lm2.Coefficients.tStat(cfi), lm2.Coefficients.pValue(cfi));
end

%plot prediction
subplot(panelA); hold on;
readScoreI  = find(strcmp(lm2.CoefficientNames,'readingScore'));
readScoreSlope = lm2.Coefficients.Estimate(readScoreI);
intercept  = lm2.Coefficients.Estimate(1);

readScorePred = rT.readingScore*readScoreSlope + intercept;
plot(rT.readingScore, readScorePred,'-','Color', effectColr*0.75);

%how to save?
set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);
figTitle = 'FigS1_SmallCueThresholds.eps';

exportfig(gcf,fullfile(opt.paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',opt.fontSize);


