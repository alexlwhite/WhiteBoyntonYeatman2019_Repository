%% function figh = Fig4A_CueEffectReadGroupBars(T, subplotPositions, paths, nBoots)
% Make Figure 4A in White, Boynton & Yeatman (2019)
% Bar plots for cueing effects on threshold in 2 age groups (younger and older than 20) and
% 2 reading groups (DYS and CON)
%
% Creates just panel of Figure 4, which is finished in another function.
%
% Also prints out statistics from LMEs to accompany the bar plots.
%
% Inputs :
% - T: table with information about each subejct and their thresholds in
%   each condition
% - subplotPositions:  a RxCx4 matrix of subplot coordinates for R rows and
%   C columns in this figure.
% - paths: a structure with full directory names for the figure folder
%   (paths.figs) and stats folder (paths.stats)
% - nBoots: number of bootstrapping repetitions to do
%
% Outputs:
% - figh: figure handle
% 
% by Alex L. White, University of Washington, 2019
function figh = Fig4A_CueEffectReadGroupBars(T, subplotPositions, paths, nBoots)

log10Dat = true;

readMeasure = 'twre_pde_ss';
eval(sprintf('readScores = T.%s;', readMeasure));
readMeasureLabel = 'TOWRE PDE';


%% Pull out data
ds = [T.thresh_Uncued T.thresh_Cued];

if log10Dat
    ds = log10(ds);
end

cueLabels = {'Uncued','Cued'};

effects = ds(:,1) - ds(:,2);
compLabel = sprintf('%s-%s',cueLabels{1}, cueLabels{2});
diffLabel = sprintf('%sVs%s',cueLabels{1}, cueLabels{2});


ages = T.age;
nSubj = length(ages);

readLabs = unique(T.readingGroup);
nReadGroups = length(readLabs);

%sort into two age groups, pre-and post-maturation
[T, ageLabs] = assignTwoAgeGroups(T);
nAgeGroups = numel(ageLabs);


CIRange = 68.27;
bootstrapBCACorrection = true; %whether to do fancy bias correction of bootstrapped confidence intervals

%compute statistics in each group
ms = NaN(nAgeGroups, nReadGroups);
cis = NaN(nAgeGroups, nReadGroups, 2);
Ns = NaN(nAgeGroups, nReadGroups);


effectTable = table;
effectTable.ageGroup = ageLabs(T.ageGroup)';
effectTable.age = ages;
effectTable.readScore = readScores;
readScoresNormed = readScores - nanmean(readScores);

thisAgeGroupReadScoresNormed  = NaN(size(readScores));
thisAgeGroupAgeNormed = NaN(size(ages)); %just with the mean subtracted out
thisAgeGroupWasiMRNormed = NaN(size(ages));

effectTable.readScoresNormed = readScoresNormed;
effectTable.readGroup = T.readingGroup;
effectTable.subject = (1:nSubj)';
effectTable.wasiMatrix = T.wasiMatrixReasoningTScore;
effectTable.wasiMatrixNormed = T.wasiMatrixReasoningTScore - nanmean(T.wasiMatrixReasoningTScore);

allADHDLabs = cell(nSubj,1);
allADHDLabs(T.adhdDiagnosis==1) = {'Yes'};
allADHDLabs(T.adhdDiagnosis==0) = {'No'};
allADHDLabs(isnan(T.adhdDiagnosis)) = {'No'}; %only 1 subject has no entry
effectTable.adhd = allADHDLabs;

eval(sprintf('effectTable.%s = effects;', diffLabel));

for ai = 1:nAgeGroups
    ageS = T.ageGroup==ai;
    thisAgeGroupReadScoresNormed(ageS) = readScores(ageS) - nanmean(readScores(ageS));
    thisAgeGroupAgeNormed(ageS) = ages(ageS) - mean(ages(ageS)); %normalize by subtracting the mean
    thisAgeGroupWasiMRNormed(ageS) = T.wasiMatrixReasoningTScore(ageS) - nanmean(T.wasiMatrixReasoningTScore(ageS));
    
    for ri=1:nReadGroups
        readS = strcmp(T.readingGroup,readLabs{ri});
        ss = ageS & readS;
        Ns(ai,ri) = sum(ss);
        
        %compute mean effects in this suject group
        if sum(ss)>1
            ms(ai,ri) = mean(effects(ss));
            cis(ai,ri,:) =  boyntonBootstrap(@mean, effects(ss), nBoots, CIRange, bootstrapBCACorrection);
        end
        
    end
    
end

effectTable.thisAgeGroupAgeNormed = thisAgeGroupAgeNormed;
effectTable.thisAgeGroupReadScoreNormed = thisAgeGroupReadScoresNormed;
effectTable.thisAgeGroupWasiMRNormed = thisAgeGroupWasiMRNormed;


%% bar plot with read group x age group

ageGroupsToPlot = 1:nAgeGroups;
readGroupsToPlot = find(~strcmp(readLabs,'Neither')); %

nAges = length(ageGroupsToPlot);

clear opt;

opt.barWidth = 0.11;
opt.edgeLineWidth = 2;
opt.errorBarWidth = 1;
opt.level1Sep = 0.3;
opt.level2Sep = 0.2;
opt.xLab = 'Age';

% opt.ylims = [min(ecis(:))-0.05 max(ecis(:))+0.2];
% if opt.ylims(1)>0
%     opt.ylims(1) = 0;
% end
opt.ylims = [0 0.6];
opt.legendLabs = readLabs(readGroupsToPlot);
opt.legendLabs(strcmp(opt.legendLabs,'Dyslexic')) = {'DYS'};
opt.legendLabs(strcmp(opt.legendLabs,'Typical')) = {'CON'};

opt.doLegend = true;

if log10Dat
    opt.yLab = 'mean diff of log thresholds';
else
    opt.yLab = 'mean diff of thresholds';
end

effectHSV = [0.5 0.8 0.6];

effectColr = hsv2rgb(effectHSV);

ageSats = [0.8 0.8];
ageVals = [0.6 0.6];


figh = figure;
rowI = 1; colI = 1;
subplot('position',squeeze(subplotPositions(rowI,colI,:)));
hold on;

effsToPlot = squeeze(ms(ageGroupsToPlot,readGroupsToPlot));
cisToPlot = squeeze(cis(ageGroupsToPlot,readGroupsToPlot,:));

opt.xTickLabs = ageLabs(ageGroupsToPlot);

hues = ones(1,nAges)*effectHSV(1);
ageColors = hsv2rgb([hues' ageSats' ageVals']);

opt.fillColors = ones(nAges, length(readGroupsToPlot), 3);
opt.fillColors(:,2,:) = reshape(ageColors,size(ageColors,1), 1, 3);

opt.edgeColors = 0.8*opt.fillColors;
opt.edgeColors(:,1,:) = opt.edgeColors(:,2,:);
opt.errorBarColors = opt.edgeColors*0.5;


opt.yticks = 0:0.2:opt.ylims(2);

barPlot_AW(effsToPlot,cisToPlot,opt);

title(compLabel);

set(gca,'LabelFontSizeMultiplier',1.0);
set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);



%% open file
statsFile = fullfile(paths.stats,'Stats4A_CueEffectAgeGroupByReadGroup.txt');
diary(statsFile);
statsF = fopen(statsFile,'w');

if log10Dat
    fprintf(1,'\nStatistics on log10 thresholds\n');
else
    fprintf(1,'\nStatistics on raw thresholds not logged\n');
end
fprintf(1,'Reading score: %s\n', readMeasure);


fprintf(1,'\n');

fprintf(1,'Counts of subjects in each age and reading group:\n');
for ai=1:nAgeGroups
    fprintf(1,'\t%s', ageLabs{ai})
end
for ri=[1 3 2]
    fprintf('\n%s', readLabs{ri});
    for ai=1:nAgeGroups
        fprintf('\t%i',Ns(ai,ri));
    end
end

fprintf(1,'\n\n');

effectReadSubst = ~strcmp(effectTable.readGroup,'Neither');

for ai = 1:nAgeGroups
    
    %% LME for effect of reading group on cueing effect
    
    effectAgeSubst = strcmp(effectTable.ageGroup, ageLabs{ai});
    
    effectSubst = effectAgeSubst & effectReadSubst;
    
    
    fprintf(1,'\n-----------------------------------------------------------------\n');
    fprintf(1,'ANALYSIS OF EFFECT %s (within ages %s)',compLabel,ageLabs{ai});
    fprintf(1,'\n-----------------------------------------------------------------\n');
    
    fprintf(1,'Linear Model FOR EFFECT OF READING GROUP and AGE (normalized w/in this age group) ON EFFECT %s (ages %s)', compLabel,ageLabs{ai});
    
    eqtn = sprintf('%s ~ readGroup + thisAgeGroupAgeNormed + adhd + thisAgeGroupWasiMRNormed', diffLabel);
    lm = fitlm(effectTable(effectSubst,:), eqtn);
    display(lm);
    
    
    %make a little table of effect size for each reading group,
    %with or without adhd
    adhdLabs = {'No','Yes'};
    meanEffects = NaN(nReadGroups, 2);
    nSubjs = NaN(nReadGroups, 2);
    for rzi = 1:nReadGroups
        for azi = 1:2
            thisSubjSet = strcmp(effectTable.readGroup,readLabs{rzi}) & strcmp(effectTable.adhd, adhdLabs{azi}) & effectAgeSubst;
            nSubjs(rzi,azi) = sum(thisSubjSet);
            eval(sprintf('meanEffects(rzi,azi) = mean(effectTable.%s(thisSubjSet));', diffLabel));
        end
    end
    
    fprintf(1,'\n\nFOR AGES %s, MEAN EFFECT %s IN EACH READING AND ADHD GROUP:\n', ageLabs{ai}, compLabel);
    fprintf(1,'\tNoAdhd\tAdhd\n');
    for rzi = 1:nReadGroups
        fprintf(1,'%s\t',readLabs{rzi});
        
        for azi = 1:2
            fprintf(1,'%.3f\t', meanEffects(rzi,azi));
        end
        fprintf(1,'\n');
    end
    
    fprintf(1,'\n\nNUMBER OF SUBJECTS IN EACH READING AND ADHD GROUP:\n');
    fprintf(1,'\tNoAdhd\tAdhd\n');
    for rzi = 1:nReadGroups
        fprintf(1,'%s\t',readLabs{rzi});
        
        for azi = 1:2
            fprintf(1,'%i\t', nSubjs(rzi, azi));
        end
        fprintf(1,'\n');
    end
end


%Age bin x reading group on cueing effect

readGroupSubst = ~strcmp(effectTable.readGroup,'Neither');
exclSub3 = unique(effectTable.subject(~readGroupSubst));
fprintf(1,'\nEXCLUDING %i PARTICIPANTS WHO ARENT CATEGORIZED AS DYSLEXIC OR TYPICAL\n', length(exclSub3));

fprintf(1,'\n-----------------------------------------------------------------\n');
fprintf(1,'LME FOR AGE GROUP x READING GROUP ON EFFECT %s', compLabel);

eqtn = sprintf('%s ~ ageGroup*readGroup + adhd*ageGroup + wasiMatrixNormed + thisAgeGroupAgeNormed', diffLabel);

lm = fitlm(effectTable(readGroupSubst,:), eqtn,  'DummyVarCoding','effects');

display(lm);

fprintf(1,'\n---Corresponding ANOVA---\n');
display(lm.anova);


fprintf(1,'\n-----------------------------------------------------------------\n');
fprintf(1,'LME FOR AGE GROUP x Z-transformed READING SCORE (continuous) ON EFFECT %s', compLabel);

eqtn = sprintf('%s ~ ageGroup*thisAgeGroupReadScoreNormed + adhd*ageGroup + thisAgeGroupAgeNormed + wasiMatrixNormed', diffLabel);

lm = fitlm(effectTable, eqtn, 'DummyVarCoding','effects');

display(lm);

fprintf(1,'\n---Corresponding ANOVA---\n');
display(lm.anova);



diary off;


