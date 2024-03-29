%% function Fig3BC_ThresholdDevelopmentResiduals(T, condLabels, figH, figSize, subplotPositions, opt)
% Makes Figure 3B and 3C in White, Boynton & Yeatman (2019)
% This function plots residuals of thresholds from the developmental model, and then
% ROC anlaysis of those residuals comparing the DYS and CON groups. 
% This plots 2 panels of a figure that was started in another function
% (linked to figH), and prints a stats file. 
%
% Inputs : 
% - T: table with information about each subject and their thresholds.
% - condLabels: cell array of labels of each condition for which we have
%   residuals. 
% - figH: handle to the figure into which these 2 panels should be
%    plotted. 
% - figSize: [width height] of the figure to be saved, in cm
% - subplotPositions: matrix of coordinates of the subplots, by row and
%   column. 
% - opt: structure with fields: 
%    - fontSize: size of the figure's font
%    - paths: a structure with full directory names for the figure folder
%   (opt.paths.figs) and stats folder (opt.paths.stats) 
% 
% 
% By Alex L. White, University of Washington, 2019

function Fig3BC_ThresholdDevelopmentResiduals(T, condLabels, figH, figSize, subplotPositions, opt)


%exclude small cue condition
condLabels = condLabels(~strcmp(condLabels,'SmallCue'));
nConds = numel(condLabels);

%% plot settings (colors, sizes, axis limits)
cueHues = [0.6 0.4 0.12];
cueSats = [0.5 0.6 0.7];
cueVals = [0.5 0.6 1];

cueColrs = hsv2rgb([cueHues' cueSats' cueVals']);

%fill colors for individual subject points on scatterplot:
dysFillColrs = ones(size(cueColrs));
typFillColrs = cueColrs;
bothColrs = cat(3,dysFillColrs, typFillColrs);
neitherFillColrs = mean(bothColrs,3);

markSz = 5;

xlims = [min(T.readScores) max(T.readScores)] + [-5 5];

%set common y-axis limit
residuals = NaN(length(T.age), nConds);
for cueI = 1:nConds
    residName = sprintf('%sThresholdDevResids', condLabels{cueI});
    eval(sprintf('residuals(:,cueI) = T.%s;', residName));
end

yrng = [min(residuals(:)) max(residuals(:))];
ylims = yrng + [-1 1]*0.09*diff(yrng);

residYTicks = -1:0.5:1.5;

statsF = fopen(fullfile(opt.paths.stats,'Stats3BC_ThresholdDevelopmentResidualStats.txt'),'w');
fprintf(statsF,'STATS ON HOW READING ABILITY RELATES TO THRESHOLD RESIDUALS FROM THE DEVELOPMENTAL MODEL\n');

%% Plot relation between reading score and residuals, separately for each condition

figure(figH);
for cueI = 1:nConds
    %% A. plot of residuals as a function of reading score for all subjects
    resids = residuals(:,cueI);
    goodS = ~isnan(T.readScores) & ~isnan(resids);
    
    readScoresToCorr = T.readScores(goodS);
    residsToCorr = resids(goodS);
    readGroupsToCorr = T.readingGroup(goodS);
    
    rowI = cueI; colI = 2;
    corrSubplot = subplot('position',squeeze(subplotPositions(rowI,colI,:)));    
    hold on;
    
    plot(xlims,[0 0],'k-');
    
    ecolr = cueColrs(cueI,:)*0.85;
    %plot each reading group separately
    for subji=1:length(readScoresToCorr)
        switch  readGroupsToCorr{subji}
            case 'Dyslexic'
                fcolr = dysFillColrs(cueI,:);
                
            case 'Typical'
                fcolr = typFillColrs(cueI,:);
                
            case 'Neither'
                fcolr = neitherFillColrs(cueI,:);
        end
        plot(readScoresToCorr(subji), residsToCorr(subji), 'o','MarkerSize',markSz,'MarkerEdgeColor',ecolr, 'MarkerFaceColor',fcolr);
        
    end
    xlim(xlims); ylim(ylims);
    
    set(gca,'XTick',xlims(1):25:xlims(2),'YTick',residYTicks);
    
    if cueI==nConds
        xlabel(opt.readMeasureLabel);
    else
        set(gca,'XTickLabel',{});
    end
    ylabel('\Delta log threshold');
  
    %compute correlation and insert stats into the figure
    [corrRho, corrP] = corr(readScoresToCorr, residsToCorr);
    
    textx = xlims(1)+0.4*diff(xlims);
    texty = ylims(1)+0.08*diff(ylims);
    text(textx, texty, sprintf('r=%.2f,p=%.2f',corrRho, corrP));
    
    title(condLabels{cueI});
    set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);
  
    %% B. histogram of residuals for DYS vs CON groups, with ROC analysis
    
    dysRes = resids(strcmp(T.readingGroup,'Dyslexic') & ~isnan(resids));
    typRes = resids(strcmp(T.readingGroup,'Typical') & ~isnan(resids));
    
    %ROC analysis
    bothGroupResids = resids(~strcmp(T.readingGroup,'Neither') & ~isnan(resids));
    groupLabs = T.readingGroup(~strcmp(T.readingGroup,'Neither') & ~isnan(resids));
    groupIs = NaN(size(bothGroupResids));
    groupIs(strcmp(groupLabs,'Dyslexic')) = 1;
    groupIs(strcmp(groupLabs,'Typical')) = 0;
    
   
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
    
    rowI = cueI; colI = 3;
    subplot('position',squeeze(subplotPositions(rowI,colI,:)));    
    hold on;
    
    %data for the density plot
    bothRes = {dysRes, typRes};
    
    plotOpt.midlineX = 0; %x-position of the "midline", the vertical line between the two distributions
    plotOpt.labelXVals = false;
    plotOpt.doXLabel   = cueI==nConds;
    plotOpt.doLegend   = false; %cueI==1;
    plotOpt.legendLabs = {'DYS','CON'};
    plotOpt.legendLoc  = 'NorthEast';
    plotOpt.fillColors = [1 1 1; cueColrs(cueI,:)];
    plotOpt.edgeColors = cueColrs([cueI; cueI],:)*0.9;
    plotOpt.meanColors = flipud(plotOpt.fillColors);
    plotOpt.fillLineWidth  = 1.5;
    plotOpt.meanLineWidth = 2;
    plotOpt.plotMean = true;
    
    %how to set kerney density
    plotOpt.fixKernelWidth = true;
    plotOpt.fixedKernelWidth = 0.06;
    %if not fixed, set the proportion by which to multiply the average of what ksdensity is the optimal kernel widths
    plotOpt.kernelWidthFactor = 0.6;
    
    kernelWidth = pairedSampleDensityPlot(bothRes, plotOpt);
    
    ylim(ylims);
    set(gca,'YTickLabel',{});
    
    xlims2 = get(gca,'xlim');
    
    textx = xlims2(1)+0.6*diff(xlims2);
    texty = ylims(1)+0.08*diff(ylims);
    if nullAgSig
        text(textx, texty, sprintf('AUC=%.2f*', Ag));
    else
        text(textx, texty, sprintf('AUC=%.2f', Ag));
    end
    
    
    
    %% print stats
    
    
    fprintf(statsF,'\n\n--------------------------------------------------------------\n');
    fprintf(statsF,'RELATIONSHIP BETWEEN READING ABILITY AND RESIDUALS OF THE PIECEWISE LINEAR AGE MODEL FOR THRESHOLDS IN %s CONDITION\n', condLabels{cueI});
    fprintf(statsF,'--------------------------------------------------------------\n');
    fprintf(statsF,'Correlation between residuals and %s: rho = %.3f, p=%.4f\n', opt.readMeasureLabel, corrRho, corrP);
    
    fprintf(statsF,'\nThen, dividing into Dyslexic vs Typical readers, comparing the residuals:\n');
    fprintf(statsF,'\nDyslexics: mean residual = %.4f, median = %.4f, SEM = %.3f', nanmean(dysRes), nanmedian(dysRes), standardError(dysRes'));
    fprintf(statsF,'\nTypicals: mean residual = %.4f, median = %.4f, SEM = %.3f', nanmean(typRes), nanmedian(typRes), standardError(typRes'));
    fprintf(statsF,'\nLinear Model to compare residuals between %i dyslexics and %i typical readers:\n', length(dysRes), length(typRes));
    
    rT = table;
    rT.resids = resids;
    rT.readingGroup = T.readingGroup;
    
    rT.readingScore = T.readScores;
    
    rT.wasiMatrix = T.wasiMatrixReasoningTScore;
    rT.wasiMatrixNormed = rT.wasiMatrix - nanmean(rT.wasiMatrix); %de-mean the IQ scores
    
    
    rT.adhd = categorical(T.adhdDiagnosis);
    rT.subject = (1:length(resids))';
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
    
    fprintf(statsF,'\nThen a similar analysis with reading score (%s) as a continuous measure on all subjects:\n', opt.readMeasureLabel);
    
    eqtn2 = 'resids ~ readingScore + adhd + wasiMatrixNormed';
    
    lm2 = fitlm(rT,eqtn2);
    
    fprintf(statsF,'\n%s\n\n', eqtn2);
    for cfi = 1:numel(lm.CoefficientNames)
        fprintf(statsF,'Fixed effect of %s = %.4f;\t', lm2.CoefficientNames{cfi},  lm2.Coefficients.Estimate(cfi));
        fprintf(statsF,'t(%i) = %.4f, p=%.4f\n', lm2.DFE, lm2.Coefficients.tStat(cfi), lm2.Coefficients.pValue(cfi));
    end
    
    %plot *predicted*  residuals based on model's slope estimate for
    %reading score
    subplot(corrSubplot); hold on;
    
    readScoreI  = find(strcmp(lm2.CoefficientNames,'readingScore'));
    readScoreSlope = lm2.Coefficients.Estimate(readScoreI);
    intercept  = lm2.Coefficients.Estimate(1);
    
    readScorePred = rT.readingScore*readScoreSlope + intercept;
    plot(rT.readingScore, readScorePred,'-','Color',cueColrs(cueI,:)*0.75,'LineWidth',1.5);
    
end

set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);

figTitle = 'Fig3_ReadingAbilityOnThresholdsAndResids.eps';
exportfig(gcf,fullfile(opt.paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',opt.fontSize);

