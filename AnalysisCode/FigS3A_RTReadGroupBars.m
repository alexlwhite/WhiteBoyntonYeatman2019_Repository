%% figh = FigS3A_RTReadGroupBars(T, subplotPositions, paths, nBoots)
% Make Figure S3A in White, Boynton & Yeatman (2019)
% Bar plots for meanCorrRTs in 2 age groups (younger and older than 20) and
% 2 reading groups (DYS and CON)
%
% Creates just 1 column of Figure 3, which is finished in another function.
%
% Also prints out statistics from LMEs to accompany the bar plots.
%
% Inputs :
% - T: table with informaiton about each subejct and their meanCorrRTs in
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

function figh = FigS3A_RTReadGroupBars(T, subplotPositions, paths, nBoots)



%% Pull out data
ds = 1000*[T.corrRT_uncued T.corrRT_cuedAW T.corrRT_singleStim];
condLabels = {'Uncued','Cued','Single stim'};

nConds = size(ds,2);

ages = T.age;
nSubj = length(ages);

readLabs = unique(T.readingGroup);
nReadGroups = length(readLabs);

%sort into two age groups, pre-and post-maturation
[T, ageLabs] = assignTwoAgeGroups(T);
nAgeGroups = numel(ageLabs);

readMeasure = 'twre_pde_ss';
eval(sprintf('readScores = T.%s;', readMeasure));

%% Compute statistics in each age and reading ability group, and build up a table for LME analysis

CIRange = 68.27;
bootstrapBCACorrection = true; %whether to do fancy bias correction of bootstrapped confidence intervals

%compute statistics in each group
ms = NaN(nAgeGroups, nReadGroups, nConds);
cis = NaN(nAgeGroups, nReadGroups, nConds, 2);

Ns = NaN(nAgeGroups, nReadGroups);

readScoresNormed = readScores - nanmean(readScores);

thisAgeGroupAgeNormed = NaN(size(ages)); %just with the mean subtracted out
thisAgeGroupWasiNormed = NaN(size(ages));

allADHDLabs = cell(nSubj,1);
allADHDLabs(T.adhdDiagnosis==1) = {'Yes'};
allADHDLabs(T.adhdDiagnosis==0) = {'No'};
allADHDLabs(isnan(T.adhdDiagnosis)) = {'No'}; %only 1 subject has no entry

for ai = 1:nAgeGroups
    ageS = T.ageGroup==ai;
    thisAgeGroupAgeNormed(ageS) = ages(ageS) - mean(ages(ageS)); %normalize by subtracting the mean
    thisAgeGroupWasiNormed(ageS) = T.wasiMatrixReasoningTScore(ageS) - nanmean(T.wasiMatrixReasoningTScore(ageS));
    
    for ri=1:nReadGroups
        readS = strcmp(T.readingGroup,readLabs{ri});
        
        Ns(ai,ri) = sum(ageS & readS);
        
        %compute mean  meanCorrRTs and CIs in each condition for this subject group
        for ci = 1:nConds
            ss = ageS & readS & ~isnan(ds(:,ci));
            if sum(ss)>1
                ms(ai,ri,ci) = mean(ds(ss, ci));
                cis(ai,ri,ci,:) = boyntonBootstrap(@mean, ds(ss, ci), nBoots, CIRange, bootstrapBCACorrection);
            end
        end
    end
end



%% plot meanCorrRTs as a function of age group and reading group
ageGroupsToPlot = 1:nAgeGroups;
readGroupsToPlot = find(~strcmp(readLabs,'Neither'));
condsToPlot = 1:nConds;
opt.barWidth = 0.1;
opt.edgeLineWidth = 1;
opt.errorBarWidth = 1;
opt.level1Sep = 0.25;
opt.level2Sep = 0.15;
opt.xAxisMargin = 0.15;
opt.xTickLabs = ageLabs(ageGroupsToPlot);

opt.ylims = [0 1000];

opt.yLab = 'mean correct RT (ms)';
opt.legendLabs = readLabs(readGroupsToPlot);
opt.legendLabs(strcmp(opt.legendLabs,'Dyslexic')) = {'DYS'};
opt.legendLabs(strcmp(opt.legendLabs,'Typical')) = {'CON'};

opt.legendLoc = 'NorthEast';
opt.lev1ForLegend = 1;

%colors for each condition:
cueHues = [0.6 0.4 0.12];
cueReadHues = repmat(cueHues,length(readGroupsToPlot), 1);

cueSats = [0.4 0.9 0.7];
cueReadSats = repmat(cueSats, length(readGroupsToPlot), 1);

cueVals = [0.36 0.6 1];
cueReadVals = repmat(cueVals, length(readGroupsToPlot), 1);

edgeColors = hsv2rgb(cueReadHues, cueReadSats, cueReadVals);
fillColors = edgeColors;
fillColors(1,:,:) = ones([1 size(fillColors,2) size(fillColors,3)]); %white
edgeColors = edgeColors*0.8;
errorBarColors = 0.5*edgeColors;

%Put these in a figure combined with the analysis of developmental
%residuals, which is filled in through another function.

figh = figure;

for ii = 1:length(condsToPlot)
    cueI = condsToPlot(ii);
    
    opt.doLegend = ii==1;
    
    %subI = (ii-1)*nCols+1;
    %subplot(nRows,nCols,subI);
    
    rowI = ii; colI = 1;
    subplot('position',squeeze(subplotPositions(rowI,colI,:)));
    
    
    datsToPlot = squeeze(ms(ageGroupsToPlot,readGroupsToPlot,cueI));
    cisToPlot = squeeze(cis(ageGroupsToPlot,readGroupsToPlot,cueI,:));
    
    
    opt.fillColors = zeros(length(ageGroupsToPlot), length(readGroupsToPlot), 3);
    opt.edgeColors = zeros(length(ageGroupsToPlot), length(readGroupsToPlot), 3);
    opt.errorBarColors = zeros(length(ageGroupsToPlot), length(readGroupsToPlot), 3);
    
    for agi=1:length(ageGroupsToPlot)
        opt.fillColors(agi,:,:) = squeeze(fillColors(:,cueI,:));
        opt.edgeColors(agi,:,:) = squeeze(edgeColors(:,cueI,:));
        opt.errorBarColors(agi,:,:) = squeeze(errorBarColors(:,cueI,:));
    end
    
    barPlot_AW(datsToPlot, cisToPlot, opt);
    
   
    if ii==length(condsToPlot)
        xlabel('Age');
    end
    
    set(gca,'LabelFontSizeMultiplier',1.0);
    set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);
end

%% run LME and print stats


statsFile = fullfile(paths.stats,'StatsS3A_RTsByAgeGroup_ReadGroup_AndCond.txt');
diary(statsFile);
statsF = fopen(statsFile,'w');

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

%% Make a table:

nRows = nSubj*nConds;

meanCorrRTs = NaN(nRows,1);
subject = NaN(nRows,1);
age = NaN(nRows,1);
readScore = NaN(nRows,1);
readScoreNormed = NaN(nRows,1);

%make condition, age group and reading group categorical
ageGroup  = cell(nRows,1);
readGroup= cell(nRows,1);
agesNormedByAgeGroup = NaN(nRows,1);
conditions = cell(nRows,1);
adhd = cell(nRows,1);

wasiMatrix = NaN(nRows,1);
wasiMatrixNormedByAgeGroup = NaN(nRows,1);

for si=1:nSubj
    sRows = (si-1)*nConds+(1:nConds);
    meanCorrRTs(sRows) = ds(si,:)';
    conditions(sRows) = condLabels';
    ageGroup(sRows) = ageLabs(T.ageGroup(si));
    subject(sRows) = si;
    age(sRows) = ages(si);
    readScore(sRows) = readScores(si);
    readScoreNormed(sRows) = readScoresNormed(si);
    readGroup(sRows) = T.readingGroup(si);
    
    agesNormedByAgeGroup(sRows) = thisAgeGroupAgeNormed(si);
    if T.adhdDiagnosis(si)==0
        adhd(sRows) = {'No'};
    elseif T.adhdDiagnosis(si) == 1
        adhd(sRows) = {'Yes'};
    elseif isnan(T.adhdDiagnosis(si))
        fprintf(1,'\nFor subject %s, no entry for ADHD diangosis but setting it to ''No''\n', T.IDs{si});
        adhd(sRows) = {'No'};
    end
    
    wasiMatrix(sRows) = T.wasiMatrixReasoningTScore(si);
    wasiMatrixNormedByAgeGroup(sRows) = thisAgeGroupWasiNormed(si);
end

lmeT = table;
lmeT.meanCorrRT = meanCorrRTs;
lmeT.ageGroup = ageGroup;
lmeT.age = age;
lmeT.ageNormed = age-mean(age);
lmeT.ageNormedByAgeGroup = agesNormedByAgeGroup;
lmeT.condition = conditions;
lmeT.subject = subject;
lmeT.readScore = readScore;
lmeT.readScoreNormed = readScoreNormed;
lmeT.readGroup = readGroup;
lmeT.adhd = adhd;
lmeT.wasiMatrix = wasiMatrix;
lmeT.wasiMatrixNormedByAgeGroup = wasiMatrixNormedByAgeGroup;


%ONLY INCLUDE DYSLEXICS AND TYPICALS
readSubst = ~strcmp(lmeT.readGroup,'Neither');
exclSub = unique(lmeT.subject(~readSubst));

fprintf(1,'\nEXCLUDING %i PARTICIPANTS WHO ARENT CATEGORIZED AS DYSLEXIC OR TYPICAL\n', length(exclSub));

%% For each age group, do an analysis of condition x read group (or condition
%x read score)
for aii = 1:length(ageGroupsToPlot)
    ai = ageGroupsToPlot(aii);
    fprintf(1,'\n-----------------------------------------------------------------');
    fprintf(1,'\n-----------------------------------------------------------------\n');
    fprintf(1,'ANALYSIS OF AGE GROUP %i: %s years', ai, ageLabs{ai});
    fprintf(1,'\n-----------------------------------------------------------------');
    fprintf(1,'\n-----------------------------------------------------------------\n');
    
    
    ageSubst = strcmp(lmeT.ageGroup, ageLabs{ai});
    
    ageReadSubst = ageSubst & readSubst; %this age group and select reading groups (excluding 'neithers')
    
    fprintf(1,'LME FOR EFFECT AND INTERACTION OF AGE (normalized w/in this age group), READING SCORE GROUP AND CONDITION (all conds, ages %s)',ageLabs{ai});
    
    eqtn = 'meanCorrRT ~ ageNormedByAgeGroup*condition + readGroup*condition + adhd*condition + wasiMatrixNormedByAgeGroup*condition + (1 | subject)';
    
    lme = fitlme(lmeT(ageReadSubst,:), eqtn, 'DummyVarCoding','effects');
    display(lme);
    
    fprintf(1,'\n---Corresponding ANOVA---\n');
    display(lme.anova);
    
    fprintf(1,'\n-----------------------------------------------------------------\n');
    fprintf(1,'LME FOR EFFECT AND INTERACTION OF AGE (normed w/in this age group), READING SCORE GROUP AND 2 CONDITIONs: Uncued and Big Cue (%s)', ageLabs{ai});
    
    subst = ageReadSubst & (strcmp(lmeT.condition,'Uncued') | strcmp(lmeT.condition,'Cued'));
    
    eqtn = 'meanCorrRT ~ ageNormedByAgeGroup*condition + readGroup*condition + adhd*condition + wasiMatrixNormedByAgeGroup*condition + (1 | subject)';
    lme = fitlme(lmeT(subst,:), eqtn, 'DummyVarCoding','effects');
    display(lme);
    
    fprintf(1,'\n---Corresponding ANOVA---\n');
    display(lme.anova);
    
end

%% For each condition, do an analysis of age x read group
for cueI = 1:length(condLabels)
    condSubst = strcmp(lmeT.condition,condLabels{cueI});
    fprintf(1,'\n-----------------------------------------------------------------');
    fprintf(1,'\n-----------------------------------------------------------------\n');
    fprintf(1,'ANALYSIS OF RTs IN %s CONDITION:', condLabels{cueI});
    fprintf(1,'\n-----------------------------------------------------------------');
    fprintf(1,'\n-----------------------------------------------------------------\n');
    
   
    
    fprintf(1,'%s: LME OF AGE GROUP AND READING GROUP, factors adhd and wasiMatrix also interacting with age group, and control ageNormedByAgeGroup',condLabels{cueI});
    
    eqtn = 'meanCorrRT ~ ageGroup*readGroup + adhd*ageGroup + wasiMatrixNormedByAgeGroup*ageGroup + ageNormedByAgeGroup + (1 | subject)';
    
    lme = fitlme(lmeT(condSubst & readSubst,:), eqtn, 'DummyVarCoding','effects');
    display(lme);
    
    fprintf(1,'\n---Corresponding ANOVA---\n');
    display(lme.anova);
    
    
    
    fprintf(1,'%s: LME OF AGE GROUP AND READING SCORE (normalized within all subjects), factors adhd and wasiMatrix also interacting with age group, and control ageNormedByAgeGroup',condLabels{cueI});
    
    eqtn = 'meanCorrRT ~ ageGroup*readScoreNormed + adhd*ageGroup + wasiMatrixNormedByAgeGroup*ageGroup + ageNormedByAgeGroup + (1 | subject)';
    
    lme = fitlme(lmeT(condSubst,:), eqtn, 'DummyVarCoding','effects');
    display(lme);
    
    fprintf(1,'\n---Corresponding ANOVA---\n');
    display(lme.anova);
     
end


diary off;


