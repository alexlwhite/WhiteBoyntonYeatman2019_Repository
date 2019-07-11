% CueDL1: Measuring the effects of spatial cueing (endogenous+exogenous
% mix) on singleton search performance (orientation discrimination task), in
% children with and without dyslexia (DL).
%
%        $Id: CueDL1.m, v1 2015/9/21
%      usage: res = CueDL1(params)
%         by: Alex White
%       date: August 2015
%  copyright: (c) 2015 Alex White
%    purpose: Displays the stimuli and collects responses for 1 block


function [res] = CueDL1(params)

tic;

global task scr

task=params;
task.startTime=clock;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get response keys
task.buttons = getKeyAssignment();

% disable keyboard
ListenChar(2);

% prepare screens
if task.reinitScreen
    prepScreen;
end

if task.EYE == 0 %dummy mode
    ShowCursor;
else
    HideCursor(scr.main);
end

%staircase? not during practice unless specified
if task.practice && ~task.doPracticeStair
    task.doStair = false;
end

%%%%%%%%%%%%%%%%%%
% Prepare stimuli
%%%%%%%%%%%%%%%%%%
prepStim_CueDL1;


if task.doStair
    task.stair.minIntensity = task.gabor.minTilt;
    task.stair.maxIntensity = task.gabor.maxTilt;
    bounds = [task.stair.minIntensity task.stair.maxIntensity];
    
    %make staircase be done when trials are done: 
    task.stair.stopRule = floor((task.numTrials-task.stair.trialsIgnored)/(task.stair.nPerType*task.stair.nTypes));
    
    if task.useOldStair
        task.stair = params.oldStair;
        trialsStairIgnores  = 0;
    else
        setupStairs;
        trialsStairIgnores = task.stair.trialsIgnored;
    end
end


% Set where to store the data
[fullFileName, eyelinkFileName] = setupDataFile(task.blockNum);

%Extract the name of this m file
[st,i] = dbstack;
scr.codeFilename = st(min(i,length(st))).file;

if task.practice
    if task.EYE==1 && ~task.doPracEye;
        task.EYE=-1;
    end
    %%% Number of trials
    task.numTrials = task.practiceNTrials;
    task.trialsPerBlock = task.practiceNTrials;
end

%Initialize eyelink:
if task.EYE>=0
    [el, elStatus] = initializeEyelink(eyelinkFileName);
    if task.EYE == 1
        if elStatus == 1
            fprintf(1,'\nEyelink initialized with edf file: %s.edf\n\n',eyelinkFileName);
        else
            fprintf(1,'\nError in connecting to eyelink!\n');
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Timing Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fps = scr.fps;
task.fps = fps;

%SET EACH TIMING PARAM TO MULTIPLE OF FRAME DURATION
tps = fullFieldnames(task.time);

for ti = 1:numel(tps)
    tv = tps{ti};
    eval(sprintf('task.%s = durtnMultipleOfRefresh(task.time.%s, fps, task.durationRoundTolerance);', tv, tv));
    eval(sprintf('%s = task.%s;',tv,tv));
end

%if "demo" mode for long duration 
if task.practice && task.demoDuration
    preCueDur = task.demoPreCueDur;
    gaborDur = task.demoGaborDur; 
elseif all(task.cueCond == 3) %version 3, matched to R&H
    preCueDur = task.preCueDurRH;
    task.preCueDur = task.preCueDurRH;
end


%%%%%%%%%%%%%%%%%%%
%%% PARAMETERS THAT NEED TO BE COUNTERBALANCED
%%%%%%%%%%%%%%%%%%%
design.parameters.cueCond              = task.cueCond;
design.parameters.gaborContrast        = task.gabor.contrast;
design.parameters.targPos              = 1:task.gabor.nLocs;

if task.doStair
    design.parameters.whichStair        = 1:task.stair.nPerType;
else
    design.parameters.whichStair        = 1;
end

%%%%%%%%%%%%%%%%%%%
%%% PARAMETERS THAT DON'T NEED TO BE COUNTERBALANCED
%%%%%%%%%%%%%%%%%%%
design.uniformRandVars.tiltDirctn       = [-1 1];

%Timing parameters:
design.uniformRandVars.ITIDur           = ITIMinDur:ITIQuant:ITIMaxDur;
design.uniformRandVars.preCueDur        = preCueDur;
design.uniformRandVars.cueStimISI       = cueStimISI;
design.uniformRandVars.gaborDur         = gaborDur;
design.uniformRandVars.minRespDur       = minRespDur;
design.uniformRandVars.maxRespDur       = maxRespDur;
design.uniformRandVars.visFeedbackDur   = visFeedbackDur;
design.uniformRandVars.freebie          = false;
design.uniformRandVars.catch            = false;

% Make random trial order:
task = makeTrialOrder(design, task);


%ADD FREEBIES
if task.doFreebies && ~task.practice
    task = addFreebiesOrCatchTrials(task,1);
end
if task.doCatch && ~task.practice
    task = addFreebiesOrCatchTrials(task,2);
end

% Create data text file:
if task.dataToTxt
    datFid = fopen(sprintf('%s.txt',fullFileName), 'w'); %fullFileName determined above in setupDataFile
else
    datFid = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calibrate eye-tracker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if task.EYE > 0
    
    calibresult = EyelinkDoTrackerSetup(el);
    if calibresult==el.TERMINATE_KEY
        return
    end
    
    %Re-set some aspects of screen in case eyelink calibration messed withit
    Screen('Preference', 'TextAntiAliasing', 0);    % need text in binary colors for my cluts
    Screen('TextFont',scr.main,task.fontName);
    Screen('TextSize',scr.main,task.textSize);
    Screen('TextStyle',scr.main,0);
    
    %also need to re-load normalized gamma table.
    %eyelink calibration seems to screw with it
    loadPTBNormGammaTable(scr.calibrationFile);
    
    Screen('Flip',scr.main);                       	% flip to erase
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Instructions - actually no, not for this MRI experiment (don't want
% different text at start of blocks of different conditions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
initialInstruct;

Screen(scr.main, 'Flip');
GetSecs;
WaitSecs(.2);
FlushEvents('keyDown');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop through trials
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nts = task.numTrials;
origTrialNums = 1:nts;
resposInBlock = [];

% RUN TRIALS
t = 0;
expDone = false;
task.prevFixBreak = false;
prevDidDriftCorr = false;
tookBreak = false;
nBreaks = 0;
stairsDone = false(1,task.stair.nPerType);
task.blockPoints = 0;
Screen('TextSize',scr.main,task.textSize);
Screen('TextStyle',scr.main,0); %normal


while ~expDone
    t = t+1;
    td = task.design.trials(t);
    
    
    %% start current trial
    tTrialStart = GetSecs;
    if t==1
        tTrialTransition = tTrialStart;
    end
    
    doRunTrial = true; %can be set to false in instructRecalibrate if user presses q
    
    trialDone = 0;
    origTNum = origTrialNums(t);
    task.origTNum=origTNum;
    
    %% Intertrial interval with fixation
    if t==1
        drawFixation(1,1);
        Screen('DrawingFinished',scr.main);
        tTrialFixStart = Screen('Flip', scr.main);
        if task.EYE == 1, Eyelink('message', 'EVENT_nextTrialITIStart');
        elseif task.EYE == 0; fprintf(1,'\nEVENT_nextTrialITIStart'); end
        
    else %fixation was drawn at end of previous trial's runSingleTrial
        tTrialFixStart = tTrialTransition;
    end
    didRecalib = false;
    
    %% Stimulus intensity levels (word duration and color change magnitude)
    if task.doStair
        if t>trialsStairIgnores
            switch task.stairType
                case 1
                    newLevel = QuestQuantile(task.stair.q{td.whichStair});
                case 2
                    newLevel = task.stair.ss{td.whichStair}.xCurrent;
                case 3
                    newLevel = task.stair.ss{1,td.whichStair}.intensity;
            end
            if task.stair.inLog10, newLevel = 10^newLevel; end
        else
            newLevel = task.stair.startC(end);
        end
        
        if td.freebie
            newLevel = newLevel*task.freebieIntensityMult;
        elseif td.catch
            newLevel = newLevel*task.catchIntensityMult;
        end
        
        
        newLevel(newLevel>task.stair.maxIntensity) = task.stair.maxIntensity;
        newLevel(newLevel<task.stair.minIntensity) = task.stair.minIntensity;
        
        thisIntensity = newLevel;
        fprintf(1,'\n\nTrial %i: ',t);
        fprintf(1,'Staircase %i, setting intensity to %.4f\n',td.whichStair,thisIntensity);
        
        task.gaborTilt = thisIntensity;
    else
        thisIntensity = task.gaborTilt;
    end
    %update "td" structure
    td.gaborTilt = task.gaborTilt;
    
    %% Make Gabors
    if td.cueCond==2 %single stimulus condition 
        task.thisSetSize = 1;
    else 
        task.thisSetSize = task.gabor.nLocs; 
    end
    task.gaborTextTilts = zeros(1,task.gabor.nLocs);
    task.gaborTextTilts(td.targPos) = td.tiltDirctn*td.gaborTilt;
    %set target position in single-stimulus condition 
    if task.thisSetSize == 1
        task.thisTrialGaborRects = task.gabor.rects(td.targPos,:);
        task.gaborTextTilts = task.gaborTextTilts(td.targPos);
    else
        task.thisTrialGaborRects = task.gabor.rects;
    end
    
    %% Wait some amount of time with visual feedback present 
    % wait whatever time is left in preEyeITIDur since fixation started
    preEyeITITimeLeft = (td.visFeedbackDur - (GetSecs - tTrialFixStart)); 
    WaitSecs(preEyeITITimeLeft - scr.flipTriggerTime);

    
    %Then re-draw black fixation mark: 
    fixColor = 1;
    drawFixation(1,fixColor);
    Screen('DrawingFinished',scr.main);
    tITI_Fix2Start = Screen('Flip', scr.main, tTrialFixStart + (td.visFeedbackDur - scr.flipLeadTime));
    if task.EYE == 1, Eyelink('message', 'EVENT_ITIFixtn2');
    elseif task.EYE == 0, fprintf(1,'\nEVENT_ITIFixtn2'); end
    
    %% Start eyelink recording and establish fixation
    
    % clean operator screen
    if task.EYE >= 0
        if task.EYE == 1
            Eyelink('command','clear_screen');
            if Eyelink('isconnected')==el.notconnected		% cancel if eyeLink is not connected
                return
            end
        end
        % This supplies a title at the bottom of the eyetracker display
        Eyelink('command', 'record_status_message ''Block %d of %d, Trial %d of %d''', task.blockNum, task.numBlocks, t, nts);
        % this marks the start of the trial
        Eyelink('message', 'TRIALID %d', t);
        
        fixtnStatus = task.EYE < 0; %if no eye checking (not even dummy mode)
        record      = task.EYE==-1;
        startEyeTime = GetSecs;
        if ~record
            record = startEyelinkRecording(el);
        end
        
        if record && ~fixtnStatus
            Eyelink('command','clear_screen 0');
            %Check fixation and determine new fixation point
            [fixtnStatus, newFixPos] = establishFixationLenient();
            
            %store new fixation position for this trial
            task.fixation.newX = round(newFixPos(1));
            task.fixation.newY = round(newFixPos(2));
        end
    else %if no eye-tracking, keep fixation position the same
        fixtnStatus = 1;
        task.fixation.newX = task.fixation.posX(1);
        task.fixation.newY = task.fixation.posY(1);
    end
    
    
    if doRunTrial
        if task.EYE == 0
            ShowCursor;
        else
            HideCursor(scr.main);
        end
        
        %% RUN THE TRIAL
        
        Priority(scr.maxPriorityLevel); %set priority to max just for running trial
        
        data = runSingleTrial_CueDL1(td,t,tTrialTransition);
        
        %Time stamp for transition from 1 trial to next. Defined as time of trial end from within runSingleTrial
        %Keep ITI constant using this time
        tTrialTransition = data.tTrialEnd + data.tInTrialStart;
        Priority(0); %set priority back to 0
        
        %For eyelink recording, wait a bit more: (timeAfterKey counts as part of
        %total ITI)
        WaitSecs(task.timeAfterKey);
        if task.EYE>=0, Eyelink('stoprecording'); end
        
        %% Determine what happened in last trial
        expDone = data.pressedQuit;
        
        trialDone = ~data.responseTimeout;
        
        % go to next trial if fixation was not broken
        if data.fixBreak
            task.prevFixBreak = true;
            if task.EYE < 1, fprintf(1,'\nFixation break'); end
            
        elseif data.responseTimeout
            task.prevFixBreak = false;
            if task.EYE < 1, fprintf(1,'\nResponse timeout'); end
        else
            task.prevFixBreak = false;
            resposInBlock = [resposInBlock; data.respCorrect];
        end
        
        %% Update staircase:
        if task.doStair && trialDone && ~data.fixBreak && ~data.pressedQuit && t>trialsStairIgnores && ~td.freebie && ~td.catch
            
            if task.stairType == 1
                if task.stair.inLog10
                    thisIntensity = log10(thisIntensity);
                end
                task.stair.q{td.whichStair} = QuestUpdate(task.stair.q{td.whichStair},thisIntensity,data.respCorrect(1));
                task.stair.q{td.whichStair}.ntrials = task.stair.q{td.whichStair}.ntrials+1;
            elseif task.stairType == 2
                task.stair.ss{td.whichStair} = PAL_AMUD_updateUD(task.stair.ss{td.whichStair},data.respCorrect(1));
                if task.stair.reduceStepSize %CHECK IF TIME TO HALF THE STEP SIZE
                    if task.stair.ss{td.whichStair}.reversal(end)==task.stair.revsToReduceStep
                        task.stair.ss{td.whichStair}.stepSizeUp=task.stair.ss{td.whichStair}.stepSizeUp*0.5;
                        task.stair.ss{td.whichStair}.stepSizeDown=task.stair.ss{td.whichStair}.stepSizeDown*0.5;
                    end
                end
            elseif  task.stairType == 3
                respPres = any(data.chosenRes(1) == task.buttons.pres);                
                task.stair.ss{td.whichStair} = updateSIAM(task.stair.ss{td.whichStair},td.targPres,respPres);
            end
        end
        
        %% %% OUTPUT DATA %% %%%%
        
        %Add some extra variables to data structure that weren't already
        %there or in td structrue
        %data.tTrialTransition = tTrialTransition; %time at end of previous runSingleTrial
        data.tTrialStart  = tTrialStart; %time at start of trial loop
        data.tTrialFixStart = tTrialFixStart; %time at onset of fixation mark before this trial's eye check
        data.tITI_Fix2Start = tITI_Fix2Start; %time at 2nd fixation mark onset, after eye check, new color
        data.blockNum = task.blockNum;
        data.trial = t;
        data.origTrial = origTNum;
        
        data.trialDone = trialDone;
        data.initlFixtnStatus = fixtnStatus; %whether fixation was established at start (-1 = no good eye data; 0 = fixation out of bounds; 1=good)
        data.prevDidDriftCorr = prevDidDriftCorr;
        data.didRecalib = prevDidDriftCorr;
                
        %store fixation position established at start of trial
        data.trialFixX = task.fixation.newX;
        data.trialFixY = task.fixation.newY;
        
        data.preEyeITITimeLeft = preEyeITITimeLeft;
        
        dataToOut = catstruct(td,data,'sorted');

        %if this is the first trial & response, initialize data
        %structures:
        if data.trial == 1
            task = initDataOutput(task, dataToOut, datFid);
        end
        
        %output this trial/response data to mat, edf, and txt files:
        task = outputData(task, dataToOut, datFid);
        
        %% Move on to next trial or end experiment
        if task.EYE < 1, fprintf(1,'\nTrial %i done',t); end
        
        %If fixation break or response timeout, add this trial back to the
        %end, unless this is almost the last trial
        if ~trialDone  && t<=(length(task.design.trials)-task.nTrialsLeftRepeatAbort)
            ntn = length(task.design.trials)+1;     % new trial number
            task.design.trials(ntn) = td;           % add trial at the end of the block
            
            nts = nts+1;
            
            origTrialNums = [origTrialNums origTNum];
            
            if task.EYE < 1; fprintf(1,' ... trial added, now total of %i trials',nts); end
        end
        
        
        if ~expDone
            if task.doStair %let staircase decide when to stop?
                if task.stairType==2
                    stairsDone = false(task.stair.nPerType);
                    
                    for c=1:task.stair.nPerType
                        stairsDone(c) = task.stair.ss{c}.stop;
                    end
                    if strcmp(task.stair.stopCriterion,'trials')
                        expDone = t>=nts;
                    else
                        expDone = all(stairsDone(:)) || t>=nts;
                    end
                elseif task.stairType==3
                    
                    if task.stair.terminateByReversalCount
                        stairsDone = false(1,task.stair.nPerType);
                        propDones   = zeros(1,task.stair.nPerType);
                        for c=1:task.stair.nPerType
                            stairsDone(c) = task.stair.ss{c}.nRevStableSteps>=task.stair.nRevToStop;
                            propDones(c)  = task.stair.ss{c}.nRevStableSteps/task.stair.nRevToStop;
                        end
                        propDone = round(100*mean(propDones));
                        if propDone>=1
                            propDone = round(100*min(propDones));
                        end
                        expDone = t>=nts; %all(stairsDone(:)) || t>=nts;
                    else
                        expDone = t>=nts;
                        propDone = round(100*t/nts);
                    end
                end
            else
                expDone = t==nts;
                propDone = round(100*t/nts);
            end
            
            %Drift correct?
            if task.EYE>0 && ((~expDone && mod(t,task.numTrialsDrift)==0 && propDone<95)) %% || tookBreak)
                doDriftCorrect;
            else
                prevDidDriftCorr = false;
            end
            
        end
        
    end
end

 %finish drawing feedback at fixation for last trial
 preEyeITITimeLeft = td.visFeedbackDur - (GetSecs - tTrialTransition);
 WaitSecs(preEyeITITimeLeft - scr.flipTriggerTime);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End task, clear screen, save data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
task.numTrialsDone = t;
task.totalNTs = t;

if task.feedbackPoints && ~task.practice
    task.totalPoints = task.totalPoints + task.blockPoints;
end

if data.pressedQuit && task.dataToTxt
    fprintf(datFid,'\n\nUser pressed escape to end block early\n\n');
end
if task.dataToTxt
    fclose(datFid); % close datFile
end

% end eye-movement recording
if task.EYE>0
    Screen(el.window,'FillRect',el.backgroundcolour);   % hide display
    WaitSecs(0.1);Eyelink('stoprecording');             % record additional 100 msec of data
end

rubber([]);
Screen(scr.main,'Flip');
if task.EYE>=0
    Eyelink('command','clear_screen');
    Eyelink('command', 'record_status_message ''ENDE''');
end

%Compute and display the subject's performance
res.pc=nanmean(resposInBlock);

%was block ended early by pressing 'q'?
%if so, turn res.abort on so that next block wont run either
if exist('data','var')
    if isfield(data,'pressedQuit')
        res.abort = data.pressedQuit;
    else
        res.abort = false;
    end
else
    res.abort = false;
end

res.nTrialsBadInitlFix = sum(task.data.initlFixtnStatus<1);
res.nTrialsFixBreak = sum(task.data.fixBreak);
res.nTrialsTimeout = sum(task.data.responseTimeout);

if task.feedbackPoints && ~task.practice
    res.totalPoints = task.totalPoints;
end

savingData=task.EYE>0;
if ~task.practice && savingData
    finalInstructRes;
end

%Extract threshold estimates
if task.doStair
    extractStaircaseData;
    if all(stairsDone(:)) || (task.blockNum == task.numBlocks) || res.abort
        res.stairDone = true;
    else %keep staircase going in the next block: 
        res.stairDone = false;
        res.oldStair = task.stair;
    end
    
else
  
    %CHANGE DIFFICULTY LEVEL IF PERFORMANCE IS NOT IN A GOOD RANGE:
    perfOutOfRange = (res.pc<task.minPC || res.pc>task.maxPC);
    if  task.blockNum<task.numBlocks && perfOutOfRange && task.adjustIntensities
        %TELL THE SUBJECT, CLOSE THE SCREEN
        instructSubjAdjustLevels;
    end
    
end

res.datadir = scr.datadir;

task.res=res;
task.endTime=clock;
task.duration=(toc)/60;
if task.EYE>=0
    task.el = el;
end

%Save mat files
save(sprintf('%s.mat',fullFileName),'task','scr');
fprintf(1,'\n\nSaving data mat files to: %s.mat',fullFileName);


% shut down everything, get EDF file
reddUp(task.shutDownScreen);

%move edf file to data folder
if task.EYE>=0, [success message] = movefile(sprintf('%s.edf',scr.eyelinkFileName),sprintf('%s.edf',scr.dataFileName)); end

savingData=false;
if ~task.practice && ~task.shutDownScreen
    finalInstructRes;
end

fprintf(1,'\n\nOverall Percent Correct: %5g\n', res.pc*100);
fprintf(1,'\nThis part of the experiment took %.1f min.\n\n',(toc)/60);

