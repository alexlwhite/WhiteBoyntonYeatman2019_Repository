function params = CueDL1_Params

%% Gabors  
%Background luminance 
params.bgLum                = 0.5; 

%Gabor targets
params.gabor.standardOri    = 90; %0 is horizontal 
params.gabor.sd             = 0.28; %Roach: 0.25; 
params.gabor.size           = params.gabor.sd*5;
params.gabor.sf             = 2.0; 
params.gabor.phase          = 0; %'random';  
params.gabor.contrast       = 0.50;
params.gabor.ecc            = 5;  %dva
params.gabor.nLocs          = 8;  %how many positions for Gabors. Except in single-stimulus condition, this is also the set size. 
params.gabor.posPolarAngles = 0:(360/params.gabor.nLocs):(360*(params.gabor.nLocs-1)/params.gabor.nLocs);

params.gabor.minTilt        = 0.1;
params.gabor.maxTilt        = 25;

%% all stimuli grayscale, or cue & feedback colored? 
params.grayscale = false;

%% SPATIAL CUE
params.cue.type             = 2; %1=ring; 2=dot; 3=line from fixation 

%cueColors:
hues = 0; %red 
sats = 1*~params.grayscale;
vals = 1-0.8*params.grayscale; 
params.cue.color            = round(255*hsv2rgb([hues' sats' vals']));

switch params.cue.type
    case 1 %ring
        params.cue.ecc              = params.gabor.ecc;
        params.cue.thick            = 4;
        params.cue.rad              = params.gabor.size;
    case 2 %dot
        params.cue.ecc              = 3; %Roach: 4
        params.cue.rad              = 0.3; %Roach: 0.0917
    case 3 %line
        params.cue.minEcc           = 0.4; 
        params.cue.maxEcc           = params.gabor.ecc/2.5;
        params.cue.thick            = 5;
end
params.cue.posPolarAngles   = params.gabor.posPolarAngles;

%Whether to play a click to prompt reponse 
params.postCueSound = false;


%% FIXATION MARK and EYETRACKING
params.fixation.contrast         = 1; 
params.fixation.ecc              = 0; 
params.fixation.posPolarAngles   = 0; 
params.fixation.width            = 2;   %pix 
params.fixation.length           = 0.3; %dva 
%Fixation colors: 
%  row 1: black, normal; 
%  row 2: red, incorrect response; 
%  row 3: green, correct response; 
%  row 4: blue, response timeout; 
%  row 5: yellow, fixation error
hues = [0  0   0.333 0.667 0.15];
sats = [0  1   1     1     1  ]; 
vals  =[0  0.7 0.6   1     1]; 

params.fixation.color = round(255*hsv2rgb([hues' sats' vals']));

%let's actually not color fixation red for errors
params.fixation.color(2,:)=params.fixation.color(1,:);

%% STAIRCASE 
params.doStair                  = 1; %always do staircase! 

params.stairType                = 2; %1=Quest; 2=up/down; 3=SIAM

if params.stairType == 1
    
    %Quest staircase
    params.stair.threshLevel        = 0.75; 
    params.stair.trialsIgnored      = 5;
    params.stair.inLog10            = true; 
    params.stair.gamma              = 0.5;
    params.stair.beta               = 3;
    params.stair.delta              = 0.03; 
    params.stair.threshSDStartGuess = .12; %in units of dSat
    params.stair.minNTrials         = 40;

elseif params.stairType == 2
    
    %transformed, weighted up-down staircase    
    params.stair.inLog10            = true;
    params.stair.nUp                = 1;
    params.stair.nDn                = 1;
    params.stair.dnUpStepRatio      = 1/3; %0.2845; %following Garcia-Perez, 1998; this is one of the few settings that works
    params.stair.stepUp             = log10(4); %in log units
    params.stair.stepDn             = params.stair.stepUp*params.stair.dnUpStepRatio;
    params.stair.threshLevel        = (params.stair.stepUp/(params.stair.stepUp+params.stair.stepDn))^(1/params.stair.nDn);
    params.stair.stopCriterion      = 'trials';
    params.stair.stopRule           = 20000;
    params.stair.truncate           = 'yes';
    params.stair.trialsIgnored      = 3;
    params.stair.minRevsForThresh   = 3; 
    params.stair.revsToIgnore       = 4; %initial reversals to leave out of threshold estimate 
    params.stair.trialsIgnoredThresh= 5; 
    params.stair.reduceStepSize     = true;
    params.stair.revsToReduceStep   = 4; 
    params.stair.minNTrials         = 40;
    params.stair.nTypes             = 1; 
    params.stair.nPerType           = 1; 
    
    
else
    %SIAM staircase
    params.stair.t                   = 0.5;  %desired maximum reduced hit rate (HR-FAR)
    params.stair.startStep           = log10(0.1)-log10(0.05);
    params.stair.nTypes              = 1; 
    params.stair.nPerType            = 2;
    params.stair.nRevToStop          = 6;     %number of "good" reversals with stable step size before terminating 
    params.stair.revsToHalfContr     = [1 2]; %on which reversals to halve step size, starting from first trial or starting just after step size reset 
    params.stair.revsToReset         = 100;   %on which reversals to reset, in case staircase continues
    params.stair.nStuckToReset       = 5;     %the number of sequential hits all at the same intensity at which step size is reset  
    params.stair.threshType          = 1;     % 1 (for reversal values) or 2 (for all intensity values)
    params.stair.inLog10             = true;
    params.stair.trialsIgnored       = 2; 
    
    params.stair.terminateByReversalCount   = true;
end

%whether to start at each staircase off at the mean of previous thresholds
%with this condition specifically. Otherwise, don't adjust starting level
params.stair.startFromPrevMeanThisCond = true; 

%% Feedback
params.feedback                 = 3; %0 = none; 1 = auditory, 2 = visual, 3 = both; 
params.feedbackPoints           = true;
params.feedbackPointsGain       = 3; 
params.feedbackPointsLoss       = 0;
params.feedbackPointsColors     = [115 0 0; 0 110 0];
params.doIncorrectTone          = true; %whether to play low beep for incorrect responses
params.doIncorrectX             = true;
params.feedbackX.length         = 0.4;  
params.feedbackX.thick          = 3;  %pixels 
params.feedbackX.color          = [200 0 0];
params.blockEndFeedback         = false;

%% Eyetracking 

%whether to do any eye-tracking: 
%-1 = test without checking fixation; 0 = test in eyelink dummy mode (cursor as eye);  1= test in eyelink mode;  
params.EYE                      = -1; 

% initlFixCheckRad: 
% if just 1 number, it's the radius of circle in which gaze position must land to start trial. 
% if its a 1x2 vector, then it defines a rectangular region of acceptable
% gaze potiion. 
% Then new fixation position is defined as mean gaze position in small time window at trial start 
params.initlFixCheckRad         = [1.5 4];  
params.fixCheckRad              = [1 2]; % radius of circle (or dims of rectangle) in which gaze position must remain to avoid fixation breaks. [deg]
params.maxFixCheckTime          = 0.30; % maximum fixation check time  
params.minFixTime               = 0.200; % minimum correct fixation time
params.nMeanEyeSamples          = 10;    %number of eyelink samples over which to average gaze position to determine new fixation point 
params.calibShrink              = 0.7;   %shrinkage of calibration area in vertical dimension (horizontal is adjusted further by aspect ratio to make square
params.squareCalib              = false;  %whether calibration area should be square 


%% Timing parameters
t.startRecordingTime  = 0.100; % time to wait after initializing eyelink recording before continuing 
t.timeAfterKey        = 0.100; % recording time after keypress [s]

t.ITIMinDur           = 1.333; 
t.ITIMaxDur           = 1.333; %fixed timing
t.ITIQuant            = 0.1;

t.preCueDur           = 0.035;
t.cueStimISI          = 0; 
t.gaborDur            = 0.085;                
t.minRespDur          = 0;
t.maxRespDur          = Inf;
t.visFeedbackDur      = 0.75;

params.time = t;

%long stimulus durations for demo
params.demoPreCueDur  = 0.150; 
params.demoGaborDur   = 0.400; 

%Tolerance in rounding durations to be in multiples of monitor frame
%duration. If rounding up would make an error less than this tolerance,
%then round up. Otherwise, round down. 
params.durationRoundTolerance = 0.0002; 

%To precisely control timing, determine when frame flips are asked for 
params.flipperTriggerFrames = 1.25;  %How many video frames before desired stimulus time should the screen Flip command be executed 
params.flipLeadFrames = 0.5;         %Within the screen Flip command, how many video frames before desired time should flip be asked for 


%% TEXT
params.fontName                 = 'Arial';
params.textColor                = [0 0 0];  
params.textSize                 = 25;
params.instructTextSize         = 25; 
%make color for text in initial instructions (same as cue colors but lower
%saturation)
chsv = rgb2hsv(params.cue.color/255);
chsv(:,2) = chsv(:,2)*0.9;
params.instructCueColrs = round(255*hsv2rgb(chsv));

params.doFadeOut   = false;  %whether instructions text fades out

%% Feedback Sounds
params.sounds(1).name             = 'responseTone'; 
params.sounds(2).name             = 'correctTone'; 
params.sounds(3).name             = 'incorrectTone';
params.sounds(4).name             = 'cueTone'; %to be played simultaneous with pre-cue 
params.sounds(5).name             = 'fixBreakTone'; 

params.sounds(1).toneDur         = 0.050; 
params.sounds(2).toneDur         = 0.075; 
params.sounds(3).toneDur         = 0.075; 
params.sounds(4).toneDur         = t.preCueDur;
params.sounds(5).toneDur         = 0.150; %this is actually 2 incorrect tones concatenated 

params.sounds(1).toneFreq        = 400; 
params.sounds(2).toneFreq        = 600; 
params.sounds(3).toneFreq        = 180; 
params.sounds(4).toneFreq        = 675; 
params.sounds(5).toneFreq        = 180; %this is actually 2 incorrect tones concatenated 

params.soundsOutFreq             = 48000; %output sampling frequency 
params.soundsBlankDur            = 0;  %amount of blank time before sound signal starts 

params.doDataPixx               = false;

%% Trial structure
% FREEBIE TRIALS 
params.doFreebies               = true;
params.doCatch                  = false;
params.nFreebieTrials           = 4; 
params.nCatchTrials             = 3; 
params.freebieIntensityMult     = 2;
params.catchIntensityMult       = 0.1; 

%adjust intensities by block? 
params.adjustIntensities        = false;
params.minPC                    = 0.6; 
params.maxPC                    = 0.9; 

% Number of trials per block:
params.numTrialsPC              = 48;  
params.numTrialsStair           = 48;   %max number of trials for staircase (may stop earlier if requested to do so when some conditions are met)
params.practiceNTrials          = 8;

params.nTrialsLeftRepeatAbort   = 3000; %avoid repeating trials with fixation breaks or timeouts  
params.numTrialsStairBreak      = params.numTrialsPC; 
params.numTrialsDrift           = 1000; % number of trials between drift corrections 


%Whether to print out data to text files: 
params.dataToTxt = true;

