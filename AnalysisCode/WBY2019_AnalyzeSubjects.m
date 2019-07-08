%% All subject analysis script for:
% White, Boynton & Yeatman (2019): The link between visual spatial attention and reading ability across development
%
% This script analyzes each subject and creates a big table with all their
% results. It also sorts them into groups by reading ability.
%
% It calls analyzeSubject to fit psychometric functions for each
% participant. That requires the Palamedes toolbox (http://www.palamedestoolbox.org/)
%
% % By Alex L. White, University of Washington, 2019

clear; close all;


%% which reading ability measure to use
%the TOWRE phonemic decoding efficiency scaled score:
readMeasure = 'twre_pde_ss';


%% load table with subject info (demographics, test scores, etc)

%set paths
paths.repo = fileparts(fileparts(which('WBY2019_AnalyzeSubjects.m')));
addpath(genpath(paths.repo));
paths.code = fullfile(paths.repo,'AnalysisCode');
paths.data = fullfile(paths.repo,'Data');
paths.stats = fullfile(paths.repo,'Stats');
paths.figs = fullfile(paths.repo,'Figures');

if strcmp(readMeasure, 'twre_swe_ss')
    paths.stats = fullfile(paths.stats,'SWE');
    paths.figs = fullfile(paths.figs,'SWE');
end

if ~isdir(paths.stats), mkdir(paths.stats); end
if ~isdir(paths.figs), mkdir(paths.figs); end

tableFile = fullfile(paths.data,'SubjectInfoTable.mat');

load(tableFile);
nSubj = size(T,1);


%% analyze each subject's data

T.lambda  = NaN(nSubj,1);
T.aboveChance_Overall = NaN(nSubj,1);

for si=1:size(T,1)
    %load in the text file with information about each trial
    subj = T.IDs{si};
    subjFile = fullfile(paths.data, 'indiv', sprintf('%sAllDat.txt', subj));
    d = readtable(subjFile);
    %note: this prints a warning about variable names being modified,
    %because one column in the AllDat text file is call "catch", which
    %is also a Matlab term. it gets changed to xCatch. Not a problem.
    
    %analyze the data
    r = analyzeSubject(d);
    
    %add results to the big table T, starting with thresholds and RTs in each condition:
    for ci=1:length(r.condLabels)
        thisCond = r.condLabels{ci};
        
        %initalize the columns in the table on 1st subject
        if si==1
            eval(sprintf('T.thresh_%s = NaN(nSubj,1);', thisCond));
            eval(sprintf('T.corrRT_%s = NaN(nSubj,1);', thisCond));
            eval(sprintf('T.aboveChance_%s = NaN(nSubj,1);', thisCond));
        end
        
        eval(sprintf('T.thresh_%s(si) = r.thresh_%s;', thisCond, thisCond));
        eval(sprintf('T.corrRT_%s(si) = r.corrRT_%s;', thisCond, thisCond));
        eval(sprintf('T.aboveChance_%s(si) = r.aboveChance_%s;', thisCond, thisCond));
        
    end
    
    %lapse rate parameter:
    T.lambda(si) = r.lambda;
    
    %whether is above chance overall
    T.aboveChance_Overall(si) = r.aboveChance_Overall;
end

%% Sort subjects into groups based on reading ability (DYS, CON, or neither)

%cutoff for being dyslexic:
readingCutoff = 85;

eval(sprintf('readScores = T.%s;', readMeasure));

%define "dyslexic" and "control" groups
isDyslexic = (T.readingProblems==1 | T.dyslexiaDiagnosis==1) & readScores <= readingCutoff;
isControl = (T.dyslexiaDiagnosis~=1) & (readScores > readingCutoff);

tableNotes.dyslexicDefinition = sprintf('%s<=%i and {reports reading problems or dyslexia diagnosis};', readMeasure, readingCutoff);
tableNotes.typicalDefinition = sprintf('%s>%i and no dyslexia diagnosis;', readMeasure, readingCutoff);

T.readingGroup = cell(size(T.age));
T.readingGroup(isDyslexic) = {'Dyslexic'};
T.readingGroup(isControl) = {'Typical'};
T.readingGroup(~isControl & ~isDyslexic) = {'Neither'};


%% exclude bad thresholds (and subjects who never before above chance)
includeSubjs = true(nSubj,1);
aboveChance = [T.aboveChance_Uncued T.aboveChance_Cued T.aboveChance_SingleStim T.aboveChance_SmallCue];
threshs = [T.thresh_Uncued T.thresh_Cued T.thresh_SingleStim T.thresh_SmallCue];

badThreshs = threshs(~aboveChance);

%set individual bad thresholds (in conditions in which an
%individual failed to perform above chance) to NaN:
for ci=1:length(r.condLabels)
    thisCond = r.condLabels{ci};
    eval(sprintf('T.thresh_%s(~T.aboveChance_%s) = NaN;', thisCond, thisCond));
    
    %also get rid of RTs when accuracy was not above chance
    eval(sprintf('T.corrRT_%s(~T.aboveChance_%s) = NaN;', thisCond, thisCond));
    
end

%how many subjects have bad thresholds in ALL the conditions they were tested in?
aboveChanceIncl = aboveChance;
aboveChanceIncl(isnan(threshs)) = NaN;
allBadThreshs = all(aboveChanceIncl==0 | isnan(aboveChanceIncl), 2);
nExcludedBecauseAllBadThreshs = sum(allBadThreshs);
%excludeThose subjects
includeSubjs = includeSubjs & ~allBadThreshs;
excludedSubjects = T.IDs(~includeSubjs);

excludeT = T(~includeSubjs,:);

T = T(includeSubjs,:);


%how many of the remaining subjects have bad thresholds?
subjsWithBadThreshs = any(~aboveChance(includeSubjs,:),2);
nSubjWithBadThreshs = sum(subjsWithBadThreshs,1);
%How many per condition?
nBadThreshsPerCond = sum(~aboveChance(includeSubjs,:),1);




%% save table
if strcmp(readMeasure, 'twre_swe_ss')
    tableName = fullfile(paths.data, 'AllSubjectResultsTable_SWE.mat');
else
    tableName = fullfile(paths.data, 'AllSubjectResultsTable.mat');
end
save(tableName,'T','tableNotes');

%% Run reliability analysis
analyzeThresholdReliability(T, paths);

%% Print out group demographics and run some comparisons
if strcmp(readMeasure, 'twre_swe_ss')
    statsFile = fullfile(paths.stats, 'GroupDemograpics_SWE.txt');
else
    statsFile = fullfile(paths.stats, 'GroupDemograpics.txt');
end
f = fopen(statsFile,'w');

fprintf(f,'Group demographics\n');

fprintf(f,'\nCompletely excluding %i subjects who didn''t perform above chance in any condition\n', nExcludedBecauseAllBadThreshs);

%information about excluded subjects
fprintf(f,'ID\t Gender\t Age\t Group\t Non-verbal IQ\t TOWRE PDE\n');
for exi=1:size(excludeT,1)
    fprintf(f,'%s\t %i\t %.2f\t %s\t %.1f\t %.1f\n', excludeT.IDs{exi}, excludeT.gender(exi), excludeT.age(exi), excludeT.readingGroup{exi}, excludeT.wasiMatrixReasoningTScore(exi), excludeT.twre_pde_ss(exi));
end

fprintf(f,'\nAfter that, excluding %i individual thresholds from %i participants due to accuracy not being above chance.\n', sum(nBadThreshsPerCond), nSubjWithBadThreshs);
iffySubjectAges = T.age(subjsWithBadThreshs);
fprintf(f,'Their ages ranges from %.1f to %.1f (mean=%.1f)\n', min(iffySubjectAges), max(iffySubjectAges), mean(iffySubjectAges));
fprintf(f,'\nNumber of bad thresholds in each condition:\n');
for ci=1:length(r.condLabels)
    thisCond = r.condLabels{ci};
    fprintf(f,'\n\t%s \t%i', thisCond, nBadThreshsPerCond(ci));
end
fprintf(f,'\n\n');
fprintf(f,'Those bad thresholds were:\n\t');
fprintf(f,'%.2f\t', badThreshs);
fprintf(f,'\n\n');
    
fprintf(f,'\nIncluding %i subjects in the data table\n\n', size(T,1));

fprintf(f,'Dyslexic definition:\t%s', tableNotes.dyslexicDefinition);
fprintf(f,'\n''Typical'' definition:\t%s\n', tableNotes.typicalDefinition);


readLabs = unique(T.readingGroup);
nReadGroups = length(readLabs);

readOrder = [1 3 2];

readLabs2 = readLabs;
readLabs2(strcmp(readLabs2,'Dyslexic')) = {'DYS'};
readLabs2(strcmp(readLabs2,'Typical')) = {'CON'};


Ns = NaN(1, nReadGroups);
nMales = NaN(1, nReadGroups);
nADHD = NaN(1, nReadGroups);
nDysDia = NaN(1, nReadGroups);
pMoreThan1Day = NaN(1, nReadGroups);

scoreNames = {'wasiMatrixReasoningTScore','wasiFullScale2Score','twre_pde_ss','twre_swe_ss'};
shortNames = {'WASI Matrix Reasoning T score', 'WASI Full-scale 2 score', 'TWRE PDE', 'TWRE SWE'};

fprintf(f,'\nGroup\tN\tN males\tN ADHD Diagnosis\tN Dyslexia Diagnosis');
for sri = 1:numel(shortNames)
    fprintf(f,'\t%s', shortNames{sri});
end
fprintf(f,'\n');

for ri=readOrder
    theseSubjs = strcmp(T.readingGroup,readLabs{ri});
    
    Ns(ri) = sum(theseSubjs);
    nMales(ri) = sum(T.gender(theseSubjs)==1);
    nADHD(ri) = sum(T.adhdDiagnosis(theseSubjs)==1);
    nDysDia(ri) = sum(T.dyslexiaDiagnosis(theseSubjs)==1);
    
    fprintf(f,'%s\t%i\t%i\t%i\t%i', readLabs2{ri}, Ns(ri), nMales(ri),nADHD(ri), nDysDia(ri));
    
    
    for sri = 1:numel(scoreNames)
        eval(sprintf('theseScores =  T.%s(theseSubjs);', scoreNames{sri}));
        meanScore = nanmean(theseScores);
        stdScore = nanstd(theseScores);
        fprintf(f,'\t%.1f (%.1f)', meanScore, stdScore);
        
    end
    fprintf(f,'\n');
end
fprintf(f,'\n');


fprintf(f,'\tComparing dyslexics and typicals with LMEs:');

subst = ~strcmp(T.readingGroup,'Neither');

for sri = 1:numel(scoreNames)
    fprintf(f,'\n\t%s:', shortNames{sri});
    eqtn = sprintf('%s  ~ readingGroup', scoreNames{sri});
    lm = fitlm(T(subst,:), eqtn);
    
    fprintf(f,'\tGroup effect = %.3f, \tt(%i) = %.3f, p=%.4f', lm.Coefficients.Estimate(2), lm.DFE, lm.Coefficients.tStat(2), lm.Coefficients.pValue(2));
    
end
fprintf(f,'\n');






