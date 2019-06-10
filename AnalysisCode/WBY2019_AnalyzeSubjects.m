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

%% load table with subject info (demographics, test scores, etc)

%set paths
paths.repo = fileparts(fileparts(which('WBY2019_AnalyzeSubjects.m')));
addpath(genpath(paths.repo));
paths.code = fullfile(paths.repo,'AnalysisCode');
paths.data = fullfile(paths.repo,'Data');
paths.stats = fullfile(paths.repo,'Stats');
paths.figs = fullfile(paths.repo,'Figures');

if ~isdir(paths.stats), mkdir(paths.stats); end
if ~isdir(paths.figs), mkdir(paths.figs); end

tableFile = fullfile(paths.data,'SubjectInfoTable.mat');
load(tableFile);

%% analyze each subject's data

propTooSlow = NaN(size(T,1),1); 
accTooSlow = NaN(size(T,1),1);
for si=1:size(T,1)
    %load in the text file with information about each trial
    subj = T.IDs{si};
    subjFile = fullfile(paths.data, 'indiv', sprintf('%sAllDat.txt', subj));
    d = readtable(subjFile);
    
    %analyze the data
    r = analyzeSubject(d);
    
    %add this subject's results to the big table 
    
    %thresholds and RTs in each condition: 
    for ci=1:length(r.condLabels)
        thisCond = r.condLabels{ci};
        eval(sprintf('T.thresh_%s(si) = r.thresh_%s;', thisCond, thisCond));
        eval(sprintf('T.corrRT_%s(si) = r.corrRT_%s;', thisCond, thisCond));
    end
    
    %lapse rate parameter:
    T.lambda(si) = r.lambda;

    %also compute proportion of trials excluded for responses too slow
    propTooSlow(si) = r.propTrialsTooSlow; 
    %and accuracy on those excluded trials
    accTooSlow(si) = r.pcTooSlow;
end

fprintf(1,'\nMean (SEM) percent trials with responses >4SDs over the subject''s median: %.3f (%.3f)\n', mean(100*propTooSlow), standardError(100*propTooSlow,1));
fprintf(1,'\nMean (SEM) p(correct) on trials with responses >4SDs over the subject''s median: %.3f (%.3f)\n', mean(accTooSlow), standardError(accTooSlow,1));

%% Sort subjects into groups based on reading ability (DYS, CON, or neither)

%which reading ability measure to use: 
%the TOWRE phonemic decoding efficiency scaled score:
readMeasure = 'twre_pde_ss';
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

%% save table
tableName = fullfile(paths.data, 'AllSubjectResultsTable.mat');
save(tableName,'T','tableNotes');


%% Print out group demographics and run some comparisons
statsFile = fullfile(paths.stats,'GroupDemograpics.txt');
f = fopen(statsFile,'w');

fprintf(f,'Group demographics in Cueing experiment\n');
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

fprintf(f,'\nGroup\tN\tN males\tN ADHD Diagnosis\tN Dyslexia Diagnosis\t');
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






