%% Master analysis script for:
% White, Boynton & Yeatman (2019): The link between visual spatial attention and reading ability across development 
%
% This script makes each figure and prints out statistical analyses 
% 
% By Alex L. White, University of Washington, 2019
clear; close all; 


%% whether to exclude subjects or individual conditions based on performance not above chance: 
dataQualityControl = 2;
QCLabels = {'NoExcl','ExcludeBadThreshs','ExcludeBadSubjs'};
QCLabel = QCLabels{dataQualityControl};

%threshold cap, to be used if no other quality control  
thresholdCap = 90; 

%% which reading ability measure to use 
%the TOWRE phonemic decoding efficiency scaled score:
readMeasure = 'twre_pde_ss';

if strcmp(readMeasure, 'twre_pde_ss')
    readMeasureLabel = 'TOWRE PDE';
elseif strcmp(readMeasure, 'twre_swe_ss')
    readMeasureLabel = 'TOWRE SWE';
end


%% other choices 
opt.nBootstraps      = 5000; 
opt.fontSize         = 11; 

opt.qualityControl   = dataQualityControl; 
opt.QCLabel          = QCLabel;
opt.readMeasure      = readMeasure;
opt.readMeasureLabel = readMeasureLabel;

%% set paths and load data 

paths.repo = fileparts(fileparts(which('WBY2019_FiguresAndStats.m'))); 
addpath(genpath(paths.repo));
paths.code = fullfile(paths.repo,'AnalysisCode');
paths.data = fullfile(paths.repo,'Data');
paths.stats = fullfile(paths.repo,'Stats');
paths.figs = fullfile(paths.repo,'Figures');

if strcmp(readMeasure, 'twre_swe_ss')
    tableFile = fullfile(paths.data, sprintf('AllSubjectResultsTable%s_SWE.mat',QCLabel));
    paths.stats = fullfile(paths.stats,'SWE',QCLabel);
    paths.figs = fullfile(paths.figs,'SWE',QCLabel);
else
    tableFile = fullfile(paths.data, sprintf('AllSubjectResultsTable%s.mat',QCLabel));
    paths.stats = fullfile(paths.stats,QCLabel);
    paths.figs = fullfile(paths.figs,QCLabel);
end

if ~isdir(paths.stats), mkdir(paths.stats); end
if ~isdir(paths.figs), mkdir(paths.figs); end

opt.paths = paths;

load(tableFile); 

%if no performance exclusion, cap thresholds at 90deg
if dataQualityControl==1
    T.thresh_Uncued(T.thresh_Uncued>thresholdCap) = thresholdCap; 
    T.thresh_Cued(T.thresh_Cued>thresholdCap) = thresholdCap;
    T.thresh_SingleStim(T.thresh_SingleStim>thresholdCap) = thresholdCap; 
    T.thresh_SmallCue(T.thresh_SmallCue>thresholdCap) = thresholdCap; 
end
    
%add reading score
eval(sprintf('T.readScores = T.%s;', readMeasure));


%% Figure 2: Development of thresholds and cueing effects on thresholds 

fig2PanelSize = [9 10];

[thresholdDevResiduals, thresholdDevConds] = Fig2A_ThresholdDevelopmentCurve(T, fig2PanelSize, opt);
%add residuals to the table: 
for ci=1:numel(thresholdDevConds)
   eval(sprintf('T.%sThresholdDevResids = thresholdDevResiduals(:,ci);', thresholdDevConds{ci}));
end

T.bigCueEffectDevResiduals = Fig2B_ThresholdCueEffectDevelopmentCurve(T, fig2PanelSize, opt);

%% Figure 3: Thresholds as a function of reading ability 

%set up subplot sizes
fig3Size = [16 16]; 

nRows = 3; nCols = 3;

leftMargin = 0.1;
rightMargin = 0.08;
topMargin = 0.05;
bottomMargin = 0.1;

verticalSpace = 0.09;
horizontalSpace = [0.12 0.05];

relativeHeights = [1 1 1];
relativeWidths = [0.9 1.5 0.9];

margins = [topMargin bottomMargin leftMargin rightMargin];
subplotPositions = makeVariableSubplots(nRows, nCols, margins, verticalSpace, horizontalSpace, relativeHeights, relativeWidths);

%column 1: bar plots of mean thresholds for each age group (<20,>=20) and reading ability group (DYS, CON).
fig3Handle = Fig3A_ThresholdReadGroupBars(T, subplotPositions, opt);

%Colums 2-3: residuals of developmental fits to thresholds in individual conditions 
Fig3BC_ThresholdDevelopmentResiduals(T, thresholdDevConds, fig3Handle, fig3Size, subplotPositions, opt)



%% Figure 4: Cueing effects as a function of reading ability 
fig4Size = [16 6];

nRows = 1; nCols = 3;

leftMargin = 0.1;
rightMargin = 0.08;
topMargin = 0.12;
bottomMargin = 0.19;

verticalSpace = 0;
horizontalSpace = [0.12 0.05];

relativeHeights = 1;
relativeWidths = [0.9 1.5 0.9];

margins = [topMargin bottomMargin leftMargin rightMargin];
subplotPositions = makeVariableSubplots(nRows, nCols, margins, verticalSpace, horizontalSpace, relativeHeights, relativeWidths);

fig4Handle = Fig4A_CueEffectReadGroupBars(T, subplotPositions, opt);

Fig4BC_CueEffectDevelopmentResiduals(T, fig4Size, fig4Handle, subplotPositions, opt)


%% Figure 5: Reading vs threshold residual correlations in a sliding window across the age range  
fig5Size = [10 17];
Fig5_ThresholdResidsVsReading_SlidingWindow(T, thresholdDevConds, fig5Size, opt);


%% Supplemental data: Lapse rate development
figSize = [10 10];
T.lapseDevResiduals = FigZ_LapseRateDevelopmentCurve(T, figSize, opt);

%% Supplemental data: Lapse rate as a fucntion of reading ability 
figLSize = [16 6];

nRows = 1; nCols = 3;

leftMargin = 0.1;
rightMargin = 0.08;
topMargin = 0.12;
bottomMargin = 0.19;

verticalSpace = 0;
horizontalSpace = [0.12 0.05];

relativeHeights = 1;
relativeWidths = [0.9 1.5 0.9];

margins = [topMargin bottomMargin leftMargin rightMargin];
subplotPositions = makeVariableSubplots(nRows, nCols, margins, verticalSpace, horizontalSpace, relativeHeights, relativeWidths);

figH = FigZ_LapseRateReadGroupBars(T, subplotPositions, opt);

FigZ_LapseRateVsReadingROCs(T, figH, subplotPositions, figLSize, opt);


%% Figure S1: small cue thresholds and cueing effects

close all;

figS1Size = [12 12]; 

nRows = 2; nCols = 2;

leftMargin = 0.14;
rightMargin = 0.06;
topMargin = 0.05;
bottomMargin = 0.1;

verticalSpace = 0.09;
horizontalSpace = 0.05;

relativeHeights = [1 1];
relativeWidths = [1.5 0.9];

margins = [topMargin bottomMargin leftMargin rightMargin];
subplotPositions = makeVariableSubplots(nRows, nCols, margins, verticalSpace, horizontalSpace, relativeHeights, relativeWidths);

figS1H = FigS1A_SmallCueThresholds(T, subplotPositions, opt);

FigS1B_SmallCueEffects(T, figS1H, subplotPositions, figS1Size, opt)


%% Figure S2: RTs as a function of age 
fig2PanelSize = [9 10];

[rtResiduals, rtDevConds] = FigS2A_CorrRTsDevelopment(T, fig2PanelSize, opt);
for ci=1:numel(rtDevConds)
   eval(sprintf('T.%sRTDevResids = rtResiduals(:,ci);', rtDevConds{ci}));
end

T.RTCueEffectResiduals = FigS2B_CorrRT_CueEffectDevelopment(T, fig2PanelSize, opt);

%% Figure S3: RTs as a function of reading ability 
figSize = [16 16]; 

nRows = 3; nCols = 3;

leftMargin = 0.1;
rightMargin = 0.08;
topMargin = 0.05;
bottomMargin = 0.1;

verticalSpace = 0.09;
horizontalSpace = [0.12 0.05];

relativeHeights = [1 1 1];
relativeWidths = [0.9 1.5 0.9];

margins = [topMargin bottomMargin leftMargin rightMargin];
subplotPositions = makeVariableSubplots(nRows, nCols, margins, verticalSpace, horizontalSpace, relativeHeights, relativeWidths);

rtFigHandle = FigS3A_RTReadGroupBars(T, subplotPositions, opt);

FigS3BC_RTDevelopmentResiduals(T, rtDevConds, rtFigHandle, figSize, subplotPositions, opt);

%% Figure S4: RTs cueing effects as a function of reading ability 

fig4Size = [16 6];

nRows = 1; nCols = 3;

leftMargin = 0.1;
rightMargin = 0.08;
topMargin = 0.12;
bottomMargin = 0.19;

verticalSpace = 0;
horizontalSpace = [0.12 0.05];

relativeHeights = 1;
relativeWidths = [0.9 1.5 0.9];

margins = [topMargin bottomMargin leftMargin rightMargin];
subplotPositions = makeVariableSubplots(nRows, nCols, margins, verticalSpace, horizontalSpace, relativeHeights, relativeWidths);

fig4Handle = FigS4A_RT_CueEffectReadGroupBars(T, subplotPositions, opt);

FigS4BC_RT_CueEffectDevelopmentResiduals(T, fig4Size, fig4Handle, subplotPositions, opt)




