%% function FigZ_LapseRateVsReadingROCs(T, figHandle, subplotPositions, opt)
% Analyze lapse rate in White, Boynton & Yeatman (2019)
% This is the basis for results reported verbally in the Supplement. 
% It plots residuals of lapse rates from the developmental model, and then
% ROC anlaysis of those residuals comparing the DYS and CON groups. 
% This plots 2 panels of a figure that was started in another function
% (linked to figHanle), and prints a stats file. 
%
% Inputs : 
% - T: table with information about each subject and their lapse rates.
% - figHandle: handle to the figure into which these 2 panels should be
% plotted. 
% - subplotPositions: matrix of coordinates of the subplots, by row and
%   column. 
% - opt: structure with fields: 
%    - figSize: [width height] of the figure to be saved, in cm
%    - fontSize: size of the figure's font
%    - paths: a structure with full directory names for the figure folder
%      (opt.paths.figs) and stats folder (opt.paths.stats) 
% 
% 
% By Alex L. White, University of Washington, 2019

function FigZ_LapseRateVsReadingROCs(T, figHandle, subplotPositions, figSize, opt)


%% extract data
lapseRates = T.lapseDevResiduals;


%determine which reading score we're using 
if all(T.readScores == T.twre_pde_ss)
    opt.readMeasureLabel = 'TOWRE PDE';
elseif all(T.readScores == T.twre_swe_ss)
    opt.readMeasureLabel = 'TOWRE SWE';
end

%% plot choices
datColr = hsv2rgb([0.6 0.5 0.5]);

%fill colors for individual subject points on scatterplot:
dysFillColrs = ones(size(datColr));
typFillColrs = datColr;
bothColrs = cat(3,dysFillColrs, typFillColrs);
neitherFillColrs = mean(bothColrs,3);


ylims = [-0.15 0.15];
markSz = 5;

%% A. plot of lapses as a function of reading score for all subjects


goodS = ~isnan(T.readScores) & ~isnan(lapseRates);

readScoresToCorr = T.readScores(goodS);
lapseRatesToCorr = lapseRates(goodS);
readGroupsToCorr = T.readingGroup(goodS);

figure(figHandle);
rowI = 1; colI = 2;
panelB = subplot('position',squeeze(subplotPositions(rowI,colI,:)));
hold on;

xlims = [min(readScoresToCorr) max(readScoresToCorr)] + [-5 5];
plot(xlims,[0 0],'k-');


ecolr = datColr*0.85;
%plot each reading group separately
for subji=1:length(readScoresToCorr)
    switch  readGroupsToCorr{subji}
        case 'Dyslexic'
            fcolr = dysFillColrs(1,:);
            
        case 'Typical'
            fcolr = typFillColrs(1,:);
            
        case 'Neither'
            fcolr = neitherFillColrs(1,:);
    end
    plot(readScoresToCorr(subji), lapseRatesToCorr(subji), 'o','MarkerSize',markSz,'MarkerEdgeColor',ecolr, 'MarkerFaceColor',fcolr);
    
end

xlim(xlims); ylim(ylims);
set(gca,'XTick',60:20:xlims(2),'YTick',ylims(1):0.05:ylims(2));

xlabel(opt.readMeasureLabel);
ylabel('Lambda residual');


[corrRho, corrP] = corr(readScoresToCorr, lapseRatesToCorr);

textx = xlims(1)+0.52*diff(xlims);
texty = ylims(1)+0.08*diff(ylims);
text(textx, texty, sprintf('r=%.2f,p=%.2f',corrRho, corrP));

set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);

%% B. histogram of residuals for DYS vs CON groups

dysRes = lapseRates(strcmp(T.readingGroup,'Dyslexic'));
typRes = lapseRates(strcmp(T.readingGroup,'Typical'));

%ROC analysis
bothGrouplapseRates = lapseRates(~strcmp(T.readingGroup,'Neither'));
groupLabs = T.readingGroup(~strcmp(T.readingGroup,'Neither'));
groupIs = NaN(size(bothGrouplapseRates));
groupIs(strcmp(groupLabs,'Dyslexic')) = 1;
groupIs(strcmp(groupLabs,'Typical')) = 0;
[Ag] = ROC(bothGrouplapseRates, groupIs);

ROCpermute = true; nPermute = 5000;
if ROCpermute
    nullAgs = NaN(nPermute,1);
    for pi = 1:nPermute
        nullAgs(pi) = ROC(bothGrouplapseRates, groupIs(randperm(length(groupIs))));
    end
    nullAgCI = prctile(nullAgs,[2.5 97.5]);
    nullAgP = mean(nullAgs>Ag);
    nullAgSig = all(Ag>nullAgCI) || all(Ag<nullAgCI);
    
end

figure(figHandle);
rowI = 1; colI = 3;
panelC = subplot('position',squeeze(subplotPositions(rowI,colI,:)));
hold on;

bothRes = {dysRes, typRes};


plotOpt.midlineX = 0;
plotOpt.labelXVals = false;
plotOpt.doXLabel   = false;
plotOpt.doLegend   = false;
plotOpt.legendLabs = {'DYS','CON'};
plotOpt.legendLoc  = 'NorthEast';
plotOpt.fillColors = [1 1 1; datColr];
plotOpt.edgeColors = datColr([1; 1],:)*0.9;
plotOpt.meanColors = flipud(plotOpt.fillColors);
plotOpt.fillLineWidth  = 1.5;
plotOpt.meanLineWidth = 2;
plotOpt.plotMean = true;

%how to set kerney density
plotOpt.fixKernelWidth = false;
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
statsF = fopen(fullfile(opt.paths.stats,'StatsZ_LapseRateVsReadAbility.txt'),'w');
fprintf(statsF,'STATS ON LAPSE RATES\n');

fprintf(statsF,'\n\n--------------------------------------------------------------\n');
fprintf(statsF,'RELATIONSHIP BETWEEN READING ABILITY AND LAPSE RATES RESIDUALS FROM THE DEVELOPMENTAL FIT\n');
fprintf(statsF,'--------------------------------------------------------------\n');
fprintf(statsF,'Correlation between lapse residuals and %s: rho = %.3f, p=%.3f\n', opt.readMeasureLabel, corrRho, corrP);

fprintf(statsF,'\nThen, dividing into Dyslexic vs Typical readers, comparing the lapse residuals:\n');
fprintf(statsF,'\nDyslexics: mean lapse = %.4f, median = %.4f, SEM = %.3f', nanmean(dysRes), nanmedian(dysRes), standardError(dysRes'));
fprintf(statsF,'\nTypicals: mean lapse = %.4f, median = %.4f, SEM = %.3f', nanmean(typRes), nanmedian(typRes), standardError(typRes'));
fprintf(statsF,'\nLME to compare lapses between %i dyslexics and %i typical readers:\n', length(dysRes), length(typRes));

rT = table;
rT.lapseRates = lapseRates;
rT.ageNormed = T.age - nanmean(T.age);
rT.readingGroup = T.readingGroup;

rT.readingScore = T.readScores;

rT.wasiMatrix = T.wasiMatrixReasoningTScore;
rT.wasiMatrixNormed = rT.wasiMatrix - nanmean(rT.wasiMatrix);

rT.adhd = categorical(T.adhdDiagnosis);
rT.subject = (1:length(lapseRates))';
subst = ~strcmp(rT.readingGroup,'Neither');

eqtn = 'lapseRates ~ readingGroup + ageNormed + adhd + wasiMatrixNormed';

lm = fitlm(rT(subst,:),eqtn,'DummyVarCoding','effects');

fprintf(statsF,'\n%s\n\n', eqtn);
for cfi = 1:numel(lm.CoefficientNames)
    fprintf(statsF,'Fixed effect of %s = %.4f;\t', lm.CoefficientNames{cfi},  lm.Coefficients.Estimate(cfi));
    fprintf(statsF,'t(%i) = %.4f, p=%.4f\n', lm.DFE, lm.Coefficients.tStat(cfi), lm.Coefficients.pValue(cfi));
end

fprintf(statsF,'\nROC analysis: Area Under Curve = %.3f, permutation 95%%CI = [%.3f %.3f], p=%.4f\n', Ag, nullAgCI(1), nullAgCI(2), nullAgP);
fprintf(statsF,'\tSmoothing kernel width: %.3f',kernelWidth);

fprintf(statsF,'\nThen a similar analysis with reading score (%s) as a continuous measure on all subjects:\n', opt.readMeasureLabel);

eqtn2 = 'lapseRates ~ readingScore + ageNormed + adhd + wasiMatrixNormed';

lm2 = fitlm(rT,eqtn2);

fprintf(statsF,'\n%s\n\n', eqtn2);
for cfi = 1:numel(lm.CoefficientNames)
    fprintf(statsF,'Fixed effect of %s = %.4f;\t', lm2.CoefficientNames{cfi},  lm2.Coefficients.Estimate(cfi));
    fprintf(statsF,'t(%i) = %.4f, p=%.4f\n', lm2.DFE, lm2.Coefficients.tStat(cfi), lm2.Coefficients.pValue(cfi));
end

%plot prediction
subplot(panelB); hold on;

readScoreI  = find(strcmp(lm2.CoefficientNames,'readingScore'));
readScoreSlope = lm2.Coefficients.Estimate(readScoreI);
intercept  = lm2.Coefficients.Estimate(1);

readScorePred = rT.readingScore*readScoreSlope + intercept;
plot(rT.readingScore, readScorePred,'-','Color',datColr*0.75);

set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);
figTitle = 'FigZ_LapseDevResiduals.eps';
exportfig(gcf,fullfile(opt.paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',opt.fontSize);

