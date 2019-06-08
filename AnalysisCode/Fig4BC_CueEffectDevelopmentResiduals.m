%% function Fig4BC_CueEffectDevelopmentResiduals(T, figSize, figHandle, subplotPositions, fontSize, paths)

function Fig4BC_CueEffectDevelopmentResiduals(T, figSize, figHandle, subplotPositions, fontSize, paths)

readMeasure = 'twre_pde_ss';
readMeasureLabel = 'TOWRE PDE';
eval(sprintf('readScores = T.%s;', readMeasure));

%% plot parameters (axis limits, colors)

ylims = [-1 1];
residYTicks = -1:0.5:1;

markSz = 5;


effectColr = hsv2rgb([0.5 0.8 0.6]);

%fill colors for individual subject points on scatterplot:
dysFillColr = ones(size(effectColr));
typFillColr = effectColr;
bothColrs = cat(3,dysFillColr, typFillColr);
neitherFillColr = mean(bothColrs,3);


%% A. plot of residuals as a function of reading score for all subject
figure(figHandle);
rowI = 1; colI = 2;
panelB = subplot('position',squeeze(subplotPositions(rowI,colI,:)));
hold on;

residuals = T.bigCueEffectDevResiduals;
goodS = ~isnan(readScores) & ~isnan(residuals);

readScoresToCorr = readScores(goodS);
residsToCorr = residuals(goodS);
readGroupsToCorr = T.readingGroup(goodS);

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
    plot(readScoresToCorr(subji), residsToCorr(subji), 'o','MarkerSize',markSz,'MarkerEdgeColor',effectColr, 'MarkerFaceColor',fcolr);
end
xlim(xlims); ylim(ylims);
set(gca,'XTick',xlims(1):25:xlims(2),'YTick',residYTicks);


xlabel(readMeasureLabel);
ylabel('Cue effect residual');

[corrRho, corrP] = corr(readScoresToCorr, residsToCorr);

textx = xlims(1)+0.4*diff(xlims);
texty = ylims(1)+0.08*diff(ylims);
text(textx, texty, sprintf('r=%.2f,p=%.2f',corrRho, corrP));

set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);

%% B. histogram of residuals for DYS vs CON groups
dysRes = residuals(strcmp(T.readingGroup,'Dyslexic'));
typRes = residuals(strcmp(T.readingGroup,'Typical'));

%ROC analysis
bothGroupResids = residuals(~strcmp(T.readingGroup,'Neither'));
groupLabs = T.readingGroup(~strcmp(T.readingGroup,'Neither'));
groupIs = NaN(size(bothGroupResids));
groupIs(strcmp(groupLabs,'Dyslexic')) = 0;
groupIs(strcmp(groupLabs,'Typical')) = 1;
[Ag] = ROC(bothGroupResids, groupIs);

ROCpermute = true; nPermute = 5000;
if ROCpermute
    nullAgs = NaN(nPermute,1);
    for pi = 1:nPermute
        nullAgs(pi) = ROC(bothGroupResids, groupIs(randperm(length(groupIs))));
    end
    nullAgCI = prctile(nullAgs,[2.5 97.5]);
    nullAgP = mean(nullAgs>Ag);
    nullAgSig = all(Ag>nullAgCI) || all(Ag<nullAgCI);
    
end

figure(figHandle)
rowI = 1; colI = 3;
subplot('position',squeeze(subplotPositions(rowI,colI,:)));
hold on;

bothRes = {dysRes, typRes};

opt.midlineX = 0;
opt.labelXVals    = false;
opt.doXLabel      = true;
opt.doLegend      = false;
opt.legendLabs    = {'DYS','CON'};
opt.legendLoc     = 'NorthEast';
opt.fillColors    = [1 1 1; effectColr];
opt.edgeColors    = [effectColr; effectColr];
opt.meanColors    = [effectColr; 1 1 1];
opt.fillLineWidth = 1.5;
opt.meanLineWidth = 2;
opt.plotMean      = true;
%how to set kerney density
opt.fixKernelWidth = true;
opt.fixedKernelWidth = 0.07;
%if not fixed, set the proportion by which to multiply the average of what ksdensity is the optimal kernel widths
opt.kernelWidthFactor = 0.6;


kernelWidth = pairedSampleDensityPlot(bothRes, opt);

ylim(ylims);
set(gca,'YTickLabel',{});

xlims2 = get(gca,'xlim');

textx = xlims2(1)+0.66*diff(xlims2);
texty = ylims(1)+0.08*diff(ylims);
if nullAgSig
    text(textx, texty, sprintf('AUC=%.2f*', Ag));
else
    text(textx, texty, sprintf('AUC=%.2f', Ag));
end

%% stats

statsF = fopen(fullfile(paths.stats,'Stats4B_CueEffectDevelopmentResiduals.txt'),'w');
fprintf(statsF,'STATS ON DEVELOPMENTAL EFFECT ON Cueing Effect on Thresholds\n');

fprintf(statsF,'\n\n--------------------------------------------------------------\n');
fprintf(statsF,'RELATIONSHIP BETWEEN READING ABILITY AND RESIDUALS OF THE PIECEWISE LINEAR AGE MODEL FOR THE BIG CUE - UNCUED EFFECT\n');
fprintf(statsF,'--------------------------------------------------------------\n');
fprintf(statsF,'Correlation between residuals and %s: rho = %.3f, p=%.3f\n', readMeasure, corrRho, corrP);

fprintf(statsF,'\nThen, dividing into Dyslexic vs Typical readers, comparing the residuals:\n');
fprintf(statsF,'\nDyslexics: mean residual = %.4f, median = %.4f, SEM = %.3f', nanmean(dysRes), nanmedian(dysRes), standardError(dysRes'));
fprintf(statsF,'\nTypicals: mean residual = %.4f, median = %.4f, SEM = %.3f', nanmean(typRes), nanmedian(typRes), standardError(typRes'));
fprintf(statsF,'\n\nLM to compare residuals between %i dyslexics and %i typical readers:\n', length(dysRes), length(typRes));

rT = table;
rT.resids = residuals;
rT.readingGroup = T.readingGroup;

rT.readingScore = readScores;

rT.wasiMatrixNormed = T.wasiMatrixReasoningTScore - nanmean(T.wasiMatrixReasoningTScore);

rT.adhd = categorical(T.adhdDiagnosis);
rT.subject = (1:length(residuals))';
subst = ~strcmp(rT.readingGroup,'Neither');

eqtn = 'resids ~ readingGroup + adhd + wasiMatrixNormed';

lm = fitlm(rT(subst,:),eqtn);

fprintf(statsF,'\n%s\n\n', eqtn);
for cfi = 1:numel(lm.CoefficientNames)
    fprintf(statsF,'Fixed effect of %s = %.4f;\t', lm.CoefficientNames{cfi},  lm.Coefficients.Estimate(cfi));
    fprintf(statsF,'t(%i) = %.4f, p=%.4f\n', lm.DFE, lm.Coefficients.tStat(cfi), lm.Coefficients.pValue(cfi));
end

fprintf(statsF,'\nROC analysis: Area Under Curve = %.3f, permutation 95%%CI = [%.3f %.3f], p=%.4f\n', Ag, nullAgCI(1), nullAgCI(2), nullAgP);
fprintf(statsF,'\tSmoothing kernel width: %.3f',kernelWidth);

fprintf(statsF,'\nThen a similar analysis with reading score (%s) as a continuous measure on all subjects:\n', readMeasure);

eqtn2 = 'resids ~ readingScore + adhd + wasiMatrixNormed';

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
plot(rT.readingScore, readScorePred,'-','Color', effectColr*0.75,'LineWidth',1.5);

set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);
figTitle = 'Fig4_CueEffects.eps';
exportfig(gcf,fullfile(paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',fontSize);


