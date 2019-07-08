%% Small script to examine the relationship between TOWRE PDE and SWE in this data set 

%% load data
datpath = '/Users/alexwhite/Dropbox/PROJECTS/PsychDys/CueDL1/WhiteBoyntonYeatman2019_Repository/Data';
load(fullfile(datpath, 'AllSubjectResultsTable.mat'));

%subjects to exclude for not being above chance ever:
badSubjs = {'150_MG', '161_AK', '172_TH'};
goodSubjs = ~ismember(T.IDs,badSubjs);
T = T(goodSubjs,:);

%% compute correlation between SWE and PDE 
goodS = ~isnan(T.twre_pde_ss) & ~isnan(T.twre_swe_ss);

[rho, pval] = corr(T.twre_pde_ss(goodS), T.twre_swe_ss(goodS))

%% how similar are the reading ability groups (DYS, CON) if we divide by PDE vs SWE
%cutoff for being dyslexic:
readingCutoff = 85;

readMeasures = {'twre_pde_ss','twre_swe_ss'};

NsByGroup = NaN(2,2);
sNumsByGroup = cell(2,2);

isDyslexicByReadMeasure = NaN(size(T,1), 2);

for rmi = 1:2
    
    eval(sprintf('readScores = T.%s;', readMeasures{rmi}));
    
    %define "dyslexic" and "control" groups
    isDyslexic = (T.readingProblems==1 | T.dyslexiaDiagnosis==1) & readScores <= readingCutoff;
    isControl = (T.dyslexiaDiagnosis~=1) & (readScores > readingCutoff);
    
    NsByGroup(rmi, 1) = sum(isDyslexic);
    NsByGroup(rmi, 2) = sum(isControl);
    sNumsByGroup{rmi,1} = find(isDyslexic);
    sNumsByGroup{rmi,2} = find(isControl);
    
    isDyslexicByReadMeasure(:,rmi) = isDyslexic;
    
end

%compute overlap 
pOverlap = NaN(2,2);
for rgi=1:2
    pOverlap(1,rgi) = mean(ismember(sNumsByGroup{1,rgi},sNumsByGroup{2,rgi}));
    pOverlap(2,rgi) = mean(ismember(sNumsByGroup{2,rgi},sNumsByGroup{1,rgi}));
end

numBothTypesOfDyslexic = sum(all(isDyslexicByReadMeasure,2));