%% function figH = FigS1A_SmallCueThresholds(T, subplotPositions, paths)
% Make Figure S1A for the supplement to White, Boynton & Yeatman (2019)
% Individual thresholds in the Small Cue conditon as a function of reading score.  
% Saves 1 figure and prints statistics to one text file. 
%
% Inputs : 
% - T: table with information about each subject and their thresholds
% - subplot positions: a RxCx4 matrix of subplot coordinates for this
%   figure
% - paths: a structure with full directory names for the figure folder
%   (paths.figs) and stats folder (paths.stats) 
% 
% Outputs: 
% - figH: handle to this figure, which is completed by another function
% 
% by Alex L. White, University of Washington, 2019
% 
function figH = FigS1A_SmallCueThresholds(T, subplotPositions, paths)


%% extract data
thresholds = T.thresh_SmallCue;
log10Threshs = true;
if log10Threshs
    thresholds = log10(thresholds);
end

readMeasure =  'twre_pde_ss';
readMeasureLabel = 'TOWRE PDE';
eval(sprintf('readScores = T.%s;', readMeasure));

%only take subjects over 14
ageMin = 14;

ageS = T.age>=ageMin;

ages = T.age(ageS);
thresholds = thresholds(ageS); 
readScores = readScores(ageS); 
readGroups = T.readingGroup(ageS);


%% plot choices

yrng = [min(thresholds(:)) max(thresholds(:))];
ylims = yrng + [-1 1]*0.13*diff(yrng);
markSz = 5;

cueHues = [0.3];
cueSats = [0.7];
cueVals = [0.8];

cueColrs = hsv2rgb([cueHues' cueSats' cueVals']);

%fill colors for individual subject points on scatterplot:
dysFillColrs = ones(size(cueColrs));
typFillColrs = cueColrs;
bothColrs = cat(3,dysFillColrs, typFillColrs);
neitherFillColrs = mean(bothColrs,3);

%% print stats
statsF = fopen(fullfile(paths.stats,'Stats_S1A_SmallCueThresholdVsReadAbility.txt'),'w');
fprintf(statsF,'STATS ON DEVELOPMENTAL EFFECTS ON ORIENTATION DISCRIMINATION THRESHOLDS IN SMALL CUE CONDITION\n');

if log10Threshs
    fprintf(statsF,'\nRan analysis on log10 thresholds\n');
else
    fprintf(statsF,'\nRan analysis on thresholds not log-transformed\n');
end

fprintf(statsF,'\n\nOnly including subjects over age 14, because only 1 person less than that did this condition, and that was in error.\n');




%% A. plot of thresholds as a function of reading score for all subjects

figH = figure;

goodS = ~isnan(readScores) & ~isnan(thresholds);

readScoresToCorr = readScores(goodS);
threshsToCorr = thresholds(goodS);
readGroupsToCorr = readGroups(goodS);

rowI = 1; colI = 1;
panelA = subplot('position',squeeze(subplotPositions(rowI,colI,:)));

hold on;

xlims = [min(readScoresToCorr) max(readScoresToCorr)] + [-5 5];
plot(xlims,[0 0],'k-');


ecolr = cueColrs(1,:)*0.85;
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
    plot(readScoresToCorr(subji), threshsToCorr(subji), 'o','MarkerSize',markSz,'MarkerEdgeColor',ecolr, 'MarkerFaceColor',fcolr);
    
end

xlim(xlims); ylim(ylims);
set(gca,'XTick',60:20:xlims(2),'YTick',-0.25:0.25:ylims(2));


set(gca,'XTickLabel',{});
ylabel('Log threshold');

title('Small Cue');
set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);

[corrRho, corrP] = corr(readScoresToCorr, threshsToCorr);

textx = xlims(1)+0.62*diff(xlims);
texty = ylims(1)+0.08*diff(ylims);
text(textx, texty, sprintf('r=%.2f,p=%.2f',corrRho, corrP));


%% B. histogram of residuals for DYS vs CON groups

dysRes = thresholds(strcmp(readGroups,'Dyslexic'));
typRes = thresholds(strcmp(readGroups,'Typical'));

%ROC analysis
bothGroupThreshs = thresholds(~strcmp(readGroups,'Neither'));
groupLabs = readGroups(~strcmp(readGroups,'Neither'));
groupIs = NaN(size(bothGroupThreshs));
groupIs(strcmp(groupLabs,'Dyslexic')) = 1;
groupIs(strcmp(groupLabs,'Typical')) = 0;
[Ag] = ROC(bothGroupThreshs, groupIs);

ROCpermute = true; nPermute = 5000;
if ROCpermute
    nullAgs = NaN(nPermute,1);
    for pi = 1:nPermute
        nullAgs(pi) = ROC(bothGroupThreshs, groupIs(randperm(length(groupIs))));
    end
    nullAgCI = prctile(nullAgs,[2.5 97.5]);
    nullAgP = mean(nullAgs>Ag);
    nullAgSig = all(Ag>nullAgCI) || all(Ag<nullAgCI);
    
end

rowI = 1; colI = 2;
subplot('position',squeeze(subplotPositions(rowI,colI,:)));
hold on;


bothRes = {dysRes, typRes};

cueI = 1;

opt.midlineX = 0;
opt.labelXVals = false;
opt.doXLabel   = false;
opt.doLegend   = false;
opt.legendLabs = {'DYS','CON'};
opt.legendLoc  = 'NorthEast';
opt.fillColors = [1 1 1; cueColrs(cueI,:)];
opt.edgeColors = cueColrs([cueI; cueI],:)*0.9;
opt.meanColors = flipud(opt.fillColors);
opt.fillLineWidth  = 1.5;
opt.meanLineWidth = 2;
opt.plotMean = true;

%how to set kerney density
opt.fixKernelWidth = true;
opt.fixedKernelWidth = 0.06;
%if not fixed, set the proportion by which to multiply the average of what ksdensity is the optimal kernel widths
opt.kernelWidthFactor = 0.6;

kernelWidth = pairedSampleDensityPlot(bothRes, opt);

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
fprintf(statsF,'RELATIONSHIP BETWEEN READING ABILITY AND THRESHOLDS IN %s CONDITION\n', 'Small cue');
fprintf(statsF,'--------------------------------------------------------------\n');
fprintf(statsF,'Correlation between thresholds and %s: rho = %.3f, p=%.3f\n', readMeasure, corrRho, corrP);

fprintf(statsF,'\nThen, dividing into Dyslexic vs Typical readers, comparing the thresholds:\n');
fprintf(statsF,'\nDyslexics: mean threshold = %.4f, median = %.4f, SEM = %.3f', nanmean(dysRes), nanmedian(dysRes), standardError(dysRes'));
fprintf(statsF,'\nTypicals: mean threshold = %.4f, median = %.4f, SEM = %.3f', nanmean(typRes), nanmedian(typRes), standardError(typRes'));
fprintf(statsF,'\nLME to compare thresholds between %i dyslexics and %i typical readers:\n', length(dysRes), length(typRes));

rT = table;
rT.thresholds = thresholds;
rT.age = ages;
rT.ageNormed = ages - nanmean(ages);

rT.readingGroup = readGroups;

rT.readingScore = readScores;
rT.readingScoreZ = NaN(size(readScores));
rT.readingScoreZ(~isnan(readScores)) = zscore(readScores(~isnan(readScores)));

rT.wasiMatrix = T.wasiMatrixReasoningTScore(ageS);
rT.wasiMatrixNormed = rT.wasiMatrix - nanmean(rT.wasiMatrix); %de-meaned

rT.adhd = categorical(T.adhdDiagnosis(ageS));
rT.subject = (1:length(thresholds))';
subst = ~strcmp(rT.readingGroup,'Neither');

eqtn = 'thresholds ~ readingGroup + ageNormed + adhd + wasiMatrixNormed';

lm = fitlm(rT(subst,:),eqtn,'DummyVarCoding','effects');

fprintf(statsF,'\n%s\n\n', eqtn);
for cfi = 1:numel(lm.CoefficientNames)
    fprintf(statsF,'Fixed effect of %s = %.4f;\t', lm.CoefficientNames{cfi},  lm.Coefficients.Estimate(cfi));
    fprintf(statsF,'t(%i) = %.4f, p=%.4f\n', lm.DFE, lm.Coefficients.tStat(cfi), lm.Coefficients.pValue(cfi));
end

fprintf(statsF,'\nROC analysis: Area Under Curve = %.3f, permutation 95%%CI = [%.3f %.3f], p=%.4f\n', Ag, nullAgCI(1), nullAgCI(2), nullAgP);
fprintf(statsF,'\tSmoothing kernel width: %.3f',kernelWidth);

fprintf(statsF,'\nThen a similar analysis with reading score (%s) as a continuous measure on all subjects:\n', readMeasure);

eqtn2 = 'thresholds ~ readingScore + ageNormed + adhd + wasiMatrixNormed';

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
plot(rT.readingScore, readScorePred,'-','Color',cueColrs(1,:)*0.75);

