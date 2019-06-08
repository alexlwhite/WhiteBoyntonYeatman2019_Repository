function Fig5_ThresholdResidsVsReading_SlidingWindow(T, condLabels, figSize, fontSize, paths)

close all;

%% choices
corrType = 'Pearson'; 

markSz = 14;

condLabels = condLabels(~strcmp(condLabels,'SmallCue') & ~strcmp(condLabels,'SingleStim'));

condLabels = cat(2,{'CueEffect'},condLabels);
nConds = length(condLabels);

ylimsR = [-0.8 0.8];
yticksR = ylimsR(1):0.4:ylimsR(2);

ylimsS = [-0.02 0.02];
yticksS = ylimsS(1):0.01:ylimsS(2);

ylimsA = [0.25 1];
yticksA = ylimsA(1):0.25:ylimsA(2);

ROCpermute = true; nPermute = 1000;

%% pull out data 
allAges = T.age;

minAge = min(allAges);
maxAge = max(allAges);

readMeasure = 'twre_pde_ss';
eval(sprintf('readScores = T.%s;', readMeasure));
readMeasureLabel = 'TOWRE PDE';


%% colors 

%condLabels = {'Uncued','Big Cue','Small cue','Single stim'};
uncuedColr = hsv2rgb([0.6 0.4 0.36]);
cuedColr = hsv2rgb([0.4 0.9 0.6]); 
singleColr = hsv2rgb([0.12 0.7 1]); 
smallColr = hsv2rgb([0.3 0.5 0.8]); 

effectColr = hsv2rgb([0.5 0.8 0.7]);

cueColors = NaN(nConds,3);
cueColors(strcmp(condLabels,'Uncued'),:) = uncuedColr;
cueColors(strcmp(condLabels,'Cued'),:) = cuedColr;
cueColors(strcmp(condLabels,'CueEffect'),:) = effectColr;
if any(strcmp(condLabels,'SingleStim'))
    cueColors(strcmp(condLabels,'SingleStim'),:) = singleColr;
end



%% setup subplot
nRows = 3;
nCols = 1;

leftMargin = 0.17;
rightMargin = 0.07;
topMargin = 0.05;
bottomMargin = 0.095;

verticalSpace = 0.105;
horizontalSpace = [0.1];

relativeHeights = [1 1 1];
relativeWidths = [1];

margins = [topMargin bottomMargin leftMargin rightMargin];
subplotPositions = makeVariableSubplots(nRows, nCols, margins, verticalSpace, horizontalSpace, relativeHeights, relativeWidths);

%window size is adjusted for constant N
%always includes ~1/3 of sample 
nInWindow = floor(size(T,1)/3); 

figure(1); 
hs = NaN(1,nConds);
hs2 = NaN(1,nConds);
for condI = 1:nConds
    if strcmp(condLabels{condI}, 'CueEffect')
        resids = T.bigCueEffectDevResiduals;
    else
        eval(sprintf('resids = T.%sThresholdDevResids;', condLabels{condI}));
    end
    
    goodS = ~isnan(resids);
    resids = resids(goodS);
    theseAges = T.age(goodS);
    theseReadScores = readScores(goodS);
    
    theseADHD = T.adhdDiagnosis(goodS);
    theseWASI = T.wasiMatrixReasoningTScore(goodS);
    
    theseReadGroups = T.readingGroup(goodS);

    sortedAges = sort(theseAges);
    
    minAge = min(sortedAges);
    maxAge = max(sortedAges);
    
    windowMedianAges = [];
    windowWidths = [];
    Ns = [];
    rhos = [];
    corrPs = [];
    readScoreSlopes = [];
    readScorePs = [];
    readScoreTs = [];
    AUCs = [];
    rocPs = [];
    rocSigs = [];
    
    isDone = false;
    windowMinI = 0;
    
    
    while ~isDone
        windowMinI = windowMinI+1;
        minA = sortedAges(windowMinI);
        if (windowMinI + nInWindow - 1) > length(sortedAges)
            maxA = maxAge;
        else
            maxA = sortedAges(windowMinI + nInWindow);
        end
        
        ageS =  theseAges>=minA & theseAges<=maxA & ~isnan(theseReadScores) & ~isnan(resids);
        
        x = theseReadScores(ageS);
        y = resids(ageS);
        
        Ns = [Ns length(x)];
        
        windowMedianAges = [windowMedianAges median(theseAges(ageS))];
        windowWidths = [windowWidths (maxA-minA)];
        
        [rho, pval] = corr(x,y,'type',corrType);
        rhos = [rhos rho];
        corrPs = [corrPs pval];
        
        %LME for effect of reading ability, while controlling for ADHD and
        %non-verbal IQ (age already controlled for)
        D = table;
        D.threshResid = y;
        D.readScore = x;
        D.wasiMatrix = theseWASI(ageS);
        D.adhd = theseADHD(ageS);
        
        eqtn = 'threshResid ~ readScore + wasiMatrix + adhd';
        lm = fitlm(D, eqtn);
        
        coI = strcmp(lm.CoefficientNames, 'readScore');
        readScoreSlopes = [readScoreSlopes lm.Coefficients.Estimate(coI)];
        readScorePs = [readScorePs lm.Coefficients.pValue(coI)];
        readScoreTs = [readScoreTs lm.Coefficients.tStat(coI)];
        
        %ROC
        ageReadGroups = theseReadGroups(ageS);
        dysCon = ~strcmp(ageReadGroups,'Neither');
        
        bothGroupResids = y(dysCon);
        groupLabs = ageReadGroups(dysCon);
        groupIs = NaN(size(bothGroupResids));
        groupIs(strcmp(groupLabs,'Dyslexic')) = 1;
        groupIs(strcmp(groupLabs,'Typical')) = 0;
        
        if strcmp(condLabels{condI}, 'CueEffect')
            groupIs = 1-groupIs; %for cue effect, prediction is higher in DYS group
        end
        
        
        [Ag] = ROC(bothGroupResids, groupIs);
        AUCs = [AUCs Ag];
        if ROCpermute
            nullAgs = NaN(nPermute,1);
            for pi = 1:nPermute
                nullAgs(pi) = ROC(bothGroupResids, groupIs(randperm(length(groupIs))));
            end
            nullAgCI = prctile(nullAgs,[2.5 97.5]);
            
            %get a p-value that could be FDR corrected 
            rocPs = [rocPs mean(nullAgs>Ag)];
            rocSigs = [rocSigs all(Ag>nullAgCI) || all(Ag<nullAgCI)];
            
        end
        
        isDone = maxA >=maxAge;
    end
    
    %check that p-val computation worked
    if ~all(rocSigs==rocPs<0.05)
        keyboard
    end
    
    xvals = windowMedianAges;
    xlab = 'Median age in window';
    
    xlims = [min(xvals)-3 max(xvals)+3];

    %% plot LME parameters
    fdrSigs=fdr_bh(readScorePs,0.05,'pdep');
    unCorrSigs = readScorePs<0.05;
        
    if condI==1
        subh1 = subplot('position',squeeze(subplotPositions(1,1,:)));
    else
        subplot(subh1);
    end
    
    hold on;
        
    plot(xlims,[0 0],'k-');
    hs(condI) = plot(xvals, readScoreSlopes, '-','Color',cueColors(condI,:),'LineWidth',1.5);
    if sum(fdrSigs)>0
        plot(xvals(fdrSigs), readScoreSlopes(fdrSigs), '.', 'MarkerSize', markSz,'Color',cueColors(condI,:));
    end

    %% plot correlation coefficient: 
    fdrCorrSigs=fdr_bh(corrPs,0.05,'pdep');
    
    if condI==1
        subh2 = subplot('position',squeeze(subplotPositions(2,1,:)));
    else 
        subplot(subh2);
    end
    hold on;
    
    plot(xlims, [0 0],'k-');
    
    hs2(condI) = plot(xvals, rhos, '-','LineWidth',1.5,'Color',cueColors(condI,:));
    if sum(fdrCorrSigs)>0
        plot(xvals(fdrCorrSigs), rhos(fdrCorrSigs), '.','MarkerSize',markSz,'Color',cueColors(condI,:));
    end
    
    %% plot ROCs
    fdrROCSigs=fdr_bh(rocPs,0.05,'pdep');
    
    if condI==1
        subh3 = subplot('position',squeeze(subplotPositions(3,1,:)));
    else 
        subplot(subh3);
    end
    hold on;
    
    plot(xlims, [0.5 0.5],'k-');
    
    hs3(condI) = plot(xvals, AUCs, '-','LineWidth',1.5,'Color',cueColors(condI,:));
    if sum(fdrROCSigs)>0
        plot(xvals(fdrROCSigs), AUCs(fdrROCSigs), '.','MarkerSize',markSz,'Color',cueColors(condI,:));
    end
   
end
figure(1);

subplot(subh1); hold on;
legend(hs, condLabels,'Location','SouthEast');
ylabel('slope');
xlim(xlims); ylim(ylimsS);
set(gca,'YTick',yticksS);
title('Linear model slope')
set(gca,'TitleFontSizeMultiplier',1,'TitleFontWeight', 'normal');

subplot(subh2); hold on;
ylabel('r');
xlim(xlims); ylim(ylimsR);
set(gca,'YTick',yticksR);

title('Correlation coefficient');
set(gca,'TitleFontSizeMultiplier',1,'TitleFontWeight', 'normal');

subplot(subh3); hold on;
xlabel(xlab);
ylabel('AUC');
xlim(xlims); xlabel(xlab);
ylim(ylimsA); set(gca,'YTick',yticksA);
title('Area under the ROC curve');
set(gca,'TitleFontSizeMultiplier',1,'TitleFontWeight', 'normal');

set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);

figTitle = 'Fig5_SlidingWindowResidsVsReading.eps';
exportfig(gcf,fullfile(paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',fontSize);


