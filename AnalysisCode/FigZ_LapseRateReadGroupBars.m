%% function figH = FigZ_LapseRateReadGroupBars(T, subplotPositions, paths, nBoots)
% Analyze lapse rate in White, Boynton & Yeatman (2019)
% This is the basis for results reported verbally in the Supplmenet. 
% It plots mean lambda parameters (1-upper asymptote) in 2 age groups (<20, >20 years)
% and 2 reading abillity groups (DYS, CON). 
% This plots 1 panel of a figure that is completed in 2 other functions.
% Also prints statistics to one text file. 
%
% Inputs : 
% - T: table with information about each subject and their lapse rates.
% - subplotPositions: a matrix indicating position of each subplot by row
% and column 
% - paths: a structure with full directory names for the figure folder
%   (paths.figs) and stats folder (paths.stats) 
% - nBoots: number of bootstrapping repetitions to do
% 
% Outputs: 
% - figH:handle to this figure, to be completed in 2 other functions
%   plotting lapse rates as a function of reading ability 
% 
% By Alex L. White, University of Washington, 2019

function figH = FigZ_LapseRateReadGroupBars(T, subplotPositions, paths, nBoots)

statType = 'mean';
eval(sprintf('summaryStat = @%s;', statType));

%% Pull out data
ds = T.lapseRate;

ages = T.age;

%sort into two age groups, pre-and post-maturation
[T, ageLabs] = assignTwoAgeGroups(T);
nAgeGroups = numel(ageLabs);

readLabs = unique(T.readingGroup);
nReadGroups = length(readLabs);

CIRange = 68.27;
bootstrapBCACorrection = true; %whether to do fancy bias correction of bootstrapped confidence intervals


%compute statistics in each group
ms = NaN(nAgeGroups, nReadGroups);
sems = ms;
cis = NaN(nAgeGroups, nReadGroups, 2);

Ns = NaN(nAgeGroups, nReadGroups);

for ai = 1:nAgeGroups
    ageS = T.ageGroup==ai;
    for ri=1:nReadGroups
        
        readS = strcmp(T.readingGroup,readLabs{ri});
        
        Ns(ai,ri) = sum(ageS & readS);
        
        %compute means/median thresholds and CIs for this subject group
        ss = ageS & readS & ~isnan(ds);
        if sum(ss)>1
            ms(ai,ri) = summaryStat(ds(ss));
            sems(ai,ri) = standardError(ds(ss)');
            cis(ai,ri,:) = boyntonBootstrap(summaryStat, ds(ss), nBoots, CIRange, bootstrapBCACorrection);
        end
    end
end


%% plot thresholds as a function of age group and reading group
ageGroupsToPlot = 1:nAgeGroups;
readGroupsToPlot = find(~strcmp(readLabs,'Neither'));

opt.barWidth = 0.1;
opt.edgeLineWidth = 1;
opt.errorBarWidth = 1;
opt.level1Sep = 0.4;
opt.level2Sep = 0.18;

opt.xLab = 'Age';
opt.xTickLabs = ageLabs(ageGroupsToPlot);


opt.ylims = [0 0.12];
opt.yticks = 0:0.03:0.12;
opt.yLab = sprintf('%s Lambda',statType);

opt.legendLabs = readLabs(readGroupsToPlot);
opt.legendLoc = 'NorthEast';

%colors
%cueLabels = {'Uncued','Big Cue','Small cue','Single stim'};

readHues = [0.6 0.6];
readSats = [0.6 0.6];
readVals = [0.5 0.5];

readColr = hsv2rgb([readHues' readSats' readVals']);
readColr = reshape(readColr,[1 2 3]);
ageXReadColr = repmat(readColr, [length(ageGroupsToPlot) 1 1]);

opt.edgeColors = ageXReadColr;
opt.fillColors = ageXReadColr;
opt.fillColors(:,1,:) = 1; %dyslexics should be filled white


opt.errorBarColors = 0.5*opt.edgeColors;

figH = figure;
rowI = 1; colI = 1;
subplot('position',squeeze(subplotPositions(rowI,colI,:)));
hold on;

datsToPlot = squeeze(ms(ageGroupsToPlot,readGroupsToPlot,:));
cisToPlot = squeeze(cis(ageGroupsToPlot,readGroupsToPlot,:));

barPlot_AW(datsToPlot, cisToPlot, opt);


set(gca,'LabelFontSizeMultiplier',1.0);
set(gca,'TitleFontWeight','normal','TitleFontSizeMultiplier',1.0);

%% run LME


statsFile = fullfile(paths.stats,'StatsZ_LapseByAgeAndReadGroup.txt');
diary(statsFile);
statsF = fopen(statsFile,'w');

fprintf(1,'\n\n');

%Print means in each group
fprintf(1,'%s (SEM) Lambdas in each group:\n\t');
for ri=1:nReadGroups
    fprintf(1,'%s\t', readLabs{ri});
end
for ai=1:nAgeGroups
    fprintf('\n%s\t', ageLabs{ai});
    for ri=1:nReadGroups
        fprintf('%.3f (%.3f)\t', ms(ai,ri), sems(ai,ri));
    end
end


adhdLabs = cell(size(T.adhdDiagnosis));
adhdLabs(T.adhdDiagnosis==1) = {'Yes'};
adhdLabs(T.adhdDiagnosis==0) = {'No'};
T.adhdYesNo = adhdLabs;

%ONLY INCLUDE DYSLEXICS AND TYPICALS
readSubst = ~strcmp(T.readingGroup,'Neither');


fprintf(1,'\nEXCLUDING %i PARTICIPANTS WHO ARENT CATEGORIZED AS DYSLEXIC OR TYPICAL\n', sum(~readSubst));

eqtn = 'lapseRate ~ ageGroupLabel*readingGroup + adhdYesNo + wasiMatrixReasoningTScore';

lme = fitlme(T(readSubst,:), eqtn, 'DummyVarCoding','effects');
display(lme);

fprintf(1,'\n---Corresponding ANOVA---\n');
display(lme.anova);

for aii=1:length(ageGroupsToPlot)
    %typical vs dyslexic in each age group
    ai = ageGroupsToPlot(aii);
    
    fprintf(1,'\n\nCOMPARISON OF READING LEVEL GROUPS IN JUST AGES %s\n', ageLabs{ai});
    
    ageSubst = strcmp(T.ageGroupLabel,ageLabs{ai});
    
    eqtn = 'lapseRate ~ readingGroup + adhdYesNo + wasiMatrixReasoningTScore';
    
    
    lme = fitlme(T(ageSubst & readSubst,:), eqtn, 'DummyVarCoding','effects');
    display(lme);
    
end

diary off;


