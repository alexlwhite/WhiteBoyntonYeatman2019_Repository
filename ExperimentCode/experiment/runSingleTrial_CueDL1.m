function [data] = runSingleTrial_CueDL1(td, trialNum, tTrialTransition)
%
% This version: works by updating "segments", more automated
%
% td = trial design
global scr task


% clear keyboard buffer
FlushEvents('KeyDown');

% predefine boundary information
cxm = task.fixation.newX(1); %Desired fixation position, defined on each trial
cym = task.fixation.newY(1);
chk = scr.fixCkRad;

circleCheck = length(chk)==1; %if fixation check is a circle or rectangle

ctrx = scr.centerX; ctry = scr.centerY;  ctrpx = 3;

% draw trial information on EyeLink operator screen
if task.EYE>=0
    Eyelink('command','clear_screen 0');
    
    Eyelink('command','draw_filled_box %d %d %d %d 15', round(ctrx-ctrpx), round(ctry-ctrpx), round(ctrx+ctrpx), round(ctry+ctrpx));    % fixation
    if circleCheck
        Eyelink('command','draw_filled_box %d %d %d %d 15', round(cxm-chk/8), round(cym-chk/8), round(cxm+chk/8), round(cym+chk/8));    % fixation
        Eyelink('command','draw_box %d %d %d %d 15', cxm-chk, cym-chk, cxm+chk, cym+chk);                   % fix check boundary
    else
        Eyelink('command','draw_filled_box %d %d %d %d 15', round(cxm-chk(1)/8), round(cym-chk(2)/8), round(cxm+chk(1)/8), round(cym+chk(2)/8));    % fixation
        Eyelink('command','draw_box %d %d %d %d 15', cxm-chk(1), cym-chk(2), cxm+chk(1), cym+chk(2));                   % fix check boundary
    end
end

% predefine time stamps and other variables
tFixBreak        = NaN;
tRes             = NaN;
tTrialEnd        = NaN;
tFeedback        = NaN;
chosenRes        = NaN;
respCorrect      = NaN;
fixBreak         = 0;   % fixation break detected
pressedQuit      = false;
responseTimeout  = false;

%% which "cue" parameters to use. Depends on if this is Version 3 and using Roach & Hogben style cue on this trial 
if td.cueCond == 3
    cue = task.cueRH; 
else
    cue = task.cue;
end
%uncued and single stimulus condition: use 1st row of cueColor (cueColorI = 1), which is same as background. 
if td.cueCond == 0 || td.cueCond == 2
    cueColorI = 1; 
%regular cued and R&H style cued, use 2nd row (cueColorI = 2)
elseif td.cueCond == 1 || td.cueCond == 3 
    cueColorI = 2; 
end

%% Define segments:

segNames = {'PreCue','CueStimISI','Gabors'};
durations = [td.preCueDur td.cueStimISI td.gaborDur];
checkEye =  [ task.EYE>=0  task.EYE>=0  task.EYE>=0];
doMovie  =  [ 0                0           0       ];
nSegments = length(durations);

%trim off any segments at the end with duration 0
while durations(nSegments)==0
    nSegments = nSegments - 1;
end
durations = durations(1:nSegments);

%Initialize counters for trial events:
segment = 0; %start counter of segments
fri = 0; %counter of movie frames
segStartTs = NaN(size(durations));


%% Finish the intertrial segment

%Complete the "totalITI" segment, by waiting remaining time not yet
%taken up by eyelink start and fixation check
postEyeITITimeLeft = td.ITIDur - (GetSecs - tTrialTransition) - scr.flipLeadTime;
if postEyeITITimeLeft>0
    WaitSecs(postEyeITITimeLeft);
end

%% Run the trial: continuous loop that advances through each section, present stimuli, and checks eye position
tTrlStart = GetSecs;

if task.EYE>=0
    Eyelink('message', 'TRIAL_START %d', trialNum);
    Eyelink('message', 'SYNCTIME');		% zero-plot time for EDFVIEW
end

t = tTrlStart;
updateSegment = true; %start 1st segment immediately

doStimLoop = true;

if any(doMovie)
    frameTimes = NaN(1,nMovieFrames);
end

while doStimLoop
    % Time counter
    if segment > 0
        t = GetSecs-segStartTs(segment);
        %update segment if this segment's duration is over, and it's not the last one
        updateSegment = t>(durations(segment)-scr.flipTriggerTime) && segment < nSegments;
    end
    
    %update segment counter.
    if updateSegment
        lastSeg = segment;
        doIncrement = segment < nSegments;
        while doIncrement
            segment = segment + 1;
            %stop at the last segment, and skip segments with duration 0:
            doIncrement = segment < nSegments && durations(segment) == 0;
        end
    end
    
    %update screen at switch of segment or if we're drawing the movie
    updateScreen = updateSegment || (doMovie(segment) && fri < task.noise.framesPerMovie);
    
    if updateScreen
        if ~doMovie(segment)
            if segment == 1 %immediately start first segment
                goalFlipTime = t;
            else
                goalFlipTime = segStartTs(lastSeg) + durations(lastSeg) - scr.flipLeadTime;
            end
        else
            fri = fri+1; %update movie frame counter
            if fri==1
                goalFlipTime = segStartTs(lastSeg) + durations(lastSeg) - scr.flipLeadTime;
            else
                goalFlipTime = frameTimes(fri-1)+movieFrameDur - scr.flipLeadTime;
            end
        end
        
        switch segment
            case 1 %pre-cue + beep
                drawFixation(1,1);
                switch task.cue.type
                    case 1
                        Screen('FrameOval',scr.main,cue.color(cueColorI,:),cue.rects(td.targPos,:),cue.thick);
                    case 2
                        Screen('FillOval',scr.main,cue.color(cueColorI,:),cue.rects(td.targPos,:));
                    case 3
                        Screen('DrawLine',scr.main,cue.color(cueColorI,:),cue.x1(td.targPos),cue.y1(td.targPos),cue.x2(td.targPos),cue.y2(td.targPos),cue.thick);
                end
                playPTB_DataPixxSound(4);
            case 2 %cue-stim ISI
                drawFixation(1,1);
                
            case 3 %Gabors
                for sli = 1:task.thisSetSize
                    Screen('DrawTexture', scr.main, task.gaborTex, [], task.thisTrialGaborRects(sli,:),task.gaborTextTilts(sli),scr.drawTextureFilterMode);
                end
                drawFixation(1,1);
        end
        
        Screen(scr.main,'DrawingFinished');
        tFlip = Screen('Flip', scr.main, goalFlipTime);
        
        if doMovie(segment)
            frameTimes(fri) = tFlip;
        end
        if updateSegment
            segStartTs(segment) = tFlip;
            if task.EYE==1, Eyelink('message', sprintf('EVENT_%s',segNames{segment}));
            elseif task.EYE == 0; fprintf(1,'\nEVENT_%s',segNames{segment}); end
        end
    end
    
    %Check eye position
    if task.EYE >= 0 && checkEye(segment)
        [x,y] = getCoord;
        %if either eye is outside of fixation region, count as fixation break
        if circleCheck
            badeye = any(sqrt((x-cxm).^2+(y-cym).^2)>chk);
        else
            badeye = any(abs(x-cxm)>chk(1)) || any(abs(y-cym)>chk(2));
        end
        
        if badeye
            fixBreak = 1;
            tFixBreak = GetSecs;
            if task.EYE==1, Eyelink('message', 'EVENT_fixationBreak'); end
        end
    end
    
    %Check if it's time to  break out of this stimulus presentation loop
    %if in the last segment, and its duration is within 1 frame of being over
    if segment == nSegments
        doStimLoop = (GetSecs-segStartTs(segment)) < (durations(segment)-scr.fd);
    end
end

%% Collect the response, provide feedback
drawFixation(1,1);
Screen(scr.main,'DrawingFinished');
tStimOff = Screen('Flip', scr.main);
if task.EYE==1, Eyelink('message', sprintf('EVENT_tStimOff%i',rsi));
elseif task.EYE == 0, fprintf(1,'\nEVENT_tStimOff%i',rsi); end

%Make the observer wait until a tone before responding (?)
if task.minRespDur>0, WaitSecs(task.minRespDur);    end
%Play response-prompting click (?)
if task.postCueSound, tResTone = playPTB_DataPixxSound(1);  end

%Get the response
chosenRes = false;
while ~chosenRes && (GetSecs-tStimOff)<(td.maxRespDur-scr.flipTriggerTime)
    [chosenRes, tRes] = checkTarPress(task.buttons.resp);
end

if chosenRes==task.buttons.quit %'q'
    pressedQuit = true;
    data = [];
elseif chosenRes>0
    
    if td.tiltDirctn == -1
        respCorrect = chosenRes == 1;
    else
        respCorrect = chosenRes == 2;
    end
    
    if task.feedback == 1 || task.feedback == 3
        if respCorrect
            tFeedback = playPTB_DataPixxSound(2);
        elseif task.doIncorrectTone
            tFeedback = playPTB_DataPixxSound(3);
        end
        if fixBreak
            tFeedback = playPTB_DataPixxSound(5);
        end
    end
    
else %behavioral response not recorded, timeout
    
    tRes(rsi) = NaN;
    if task.feedback == 1 || task.feedback == 3
        tFeedback(rsi) = playPTB_DataPixxSound(5);
    end
    responseTimeout = true;
end

if task.EYE == 1, Eyelink('message', 'EVENT_trialEnd');
elseif task.EYE == 0, fprintf(1,'\nEVENT_trialEnd'); end

if task.feedback > 1 && ~pressedQuit
    
    if responseTimeout
        fixColor = 4;
    else
        fixColor = 2+respCorrect(end);
    end
else
    fixColor = 1;
end

%% Draw fixation to start next trial's ITI
if ~pressedQuit && task.feedback > 1
    if task.feedbackPoints
        if respCorrect
            task.blockPoints = task.blockPoints+task.feedbackPointsGain;
        else
            task.blockPoints = task.blockPoints+task.feedbackPointsLoss;
        end
        Screen('DrawText',scr.main,task.feedbackPointsText{respCorrect+1},scr.centerX+task.feedbackPointsHShift(respCorrect+1),scr.centerY+task.feedbackPointsVShift(respCorrect+1),task.feedbackPointsColors(respCorrect+1,:));
    else
        if respCorrect
            Screen('DrawTexture',scr.main,task.starTex,[],task.starRect,[],scr.drawTextureFilterMode);
        elseif task.doIncorrectX
            Screen('DrawLines',scr.main, task.feedbackX.allxy, task.feedbackX.thick, task.feedbackX.color, [task.feedbackX.posX task.feedbackX.posY],2);
        end
    end
else
    drawFixation(1,fixColor);
end
Screen('DrawingFinished',scr.main);
tTrialEnd = Screen('Flip', scr.main);
if task.EYE == 1, Eyelink('message', 'EVENT_nextTrialITIStart');
elseif task.EYE == 0; fprintf(1,'\nEVENT_nextTrialITIStart'); end

%% -------------------------%
% PREPARE DATA FOR OUTPUT %
%-------------------------%

data.tInTrialStart    = tTrlStart;

%add times for onset and offset of each segment
%segNames = {'preCue','cueStimISI','noiseMovie','postCueDelay'};
for segI = 1:nSegments
    eval(sprintf('data.t%sOns = segStartTs(%i) - tTrlStart;',segNames{segI},segI));
    %define offset as the onset of the next segment that had duration > 0
    if segI<nSegments
        foundnext = false; nextSeg = segI;
        while ~foundnext
            nextSeg = nextSeg+1;
            foundnext = durations(nextSeg)>0 || nextSeg == nSegments;
        end
        eval(sprintf('data.t%sOff = segStartTs(%i) - tTrlStart;',segNames{segI},nextSeg));
    end
end

%add offset time for the last segment, which is when the post cue goes on
eval(sprintf('data.t%sOff = tStimOff - tTrlStart;',segNames{segI}));


data.postEyeITITimeLeft = postEyeITITimeLeft;

data.tStimOff           = tStimOff-tTrlStart;
data.tFixBreak          = tFixBreak-tTrlStart;
data.tRes               = tRes-tTrlStart;
data.tFeedback          = tFeedback-tTrlStart;
data.tTrialEnd          = tTrialEnd-tTrlStart;
data.chosenRes          = chosenRes;
data.respCorrect        = respCorrect;
data.pressedQuit        = pressedQuit;
data.fixBreak           = fixBreak;
data.responseTimeout    = responseTimeout;



