function prepScreen()
%
% 2006 by Martin Rolfs, edited by Alex White

global scr; 
global task


%% set up parameters 
scr.colDept = []; %just do the default.

% general information on task computer
scr.computer = Screen('Computer');  % get information about display computers

% If there are multiple displays guess that one without the menu bar is the
% best choice.  Dislay 0 has the menu bar.
scr.allScreens = Screen('Screens');
scr.nScreens   = length(scr.allScreens);
scr.expScreen  = max(scr.allScreens);

% get rid of PsychtoolBox Welcome screen
Screen('Preference', 'VisualDebugLevel',3);


scr.normalizedLums = false;

scr.nBits = 8;
scr.nLums = 2^scr.nBits;

if scr.normalizedLums
    PsychImaging('PrepareConfiguration');                                       %copied from M16 Demo
    PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange');
    task.bgColor = task.bgLum;
else
    task.bgColor = floor(task.bgLum*(2^scr.nBits));
end


%% load monitor information stored on this computer. 

[monParams, monStatus] = getDisplayParameters(task.computerName);
if monStatus == 0
    fprintf(1,'\n\n(prepScreen)\t No monitor parameters set for this computer! Using defualt!!!\n\n');
    scr.screenComputerName = 'default';
else
    scr.screenComputerName = task.computerName;
end
scr.monParams = monParams;


scr.subDist=monParams.subDist;
scr.width=monParams.width*10; %in mm
scr.height=monParams.height*10; %in mm

%Skip sync tests? Should only do that when necessary 
if monParams.skipSyncTests
    Screen('Preference', 'SkipSyncTests',1);
end


%% Set resolution of screen 
if ~isempty(monParams.goalResolution)
    scr.oldRes = Screen('Resolution',scr.expScreen);
    scr.changeRes = ~(scr.oldRes.width == monParams.goalResolution(1) && scr.oldRes.height == monParams.goalResolution(2) && scr.oldRes.hz == monParams.goalFPS);
    if scr.changeRes
            scr.oldRes = SetResolution(scr.expScreen, monParams.goalResolution(1), monParams.goalResolution(2), monParams.goalFPS);
    end
else
    scr.changeRes = false;
end

%% % Open a window.  
% Note the argument to open window with value 2, specifying the number of buffers to the onscreen window.
[scr.main,scr.rect] = Screen('OpenWindow',scr.expScreen,ones(1,3)*task.bgColor,[],scr.colDept,2,0,4);
scr.drawTextureFilterMode = [];%default filter mode for texture drawing


% Check screen paramers: 
[scr.xres, scr.yres]    = Screen('WindowSize', scr.main);       % heigth and width of screen [pix]

scr.ppd       = va2pix(1,scr);   % pixel per degree

%Check if pixels are square: 
horizRes=scr.xres/scr.width;
vertRes=scr.yres/scr.height;

% determine the main window's center
[scr.centerX, scr.centerY] = WindowCenter(scr.main);

[scr.fd, nsamp, sdev] = Screen('GetFlipInterval',scr.main,50,0.00005,5);    % frame duration [s]

scr.fps = 1/scr.fd;
scr.nominalFPS = Screen('FrameRate',scr.main,1);

%To precisely control timing, determine when frame flips are asked for 
scr.flipTriggerTime = task.flipperTriggerFrames*scr.fd;  %How long before desired time should the screen Flip command be executed 
scr.flipLeadTime = task.flipLeadFrames*scr.fd;           %Within the screen Flip command, how long before desired time should flip be asked for 


%Alpha blending for good dots:
% They are needed for proper anti-aliasing (smoothing) by Screen('DrawLines'), Screen('DrawDots') and for
% drawing masked stimuli with the Screen('DrawTexture') command. 
Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% get max priority of window activities 
scr.maxPriorityLevel = MaxPriority(scr.main);


%% load calibration file - normalized gamma table
if ~task.linearizeMonitor
    monParams.calibFile = '';
    fprintf(1,'\n\n(prepScreen) Not using screen calibration file (because task.linearizeMonitor = false)\n');
end
scr.lumCalibration = loadPTBNormGammaTable(monParams.calibFile); 

%% Colors and contrast levels available

%Colors:
scr.black = BlackIndex(scr.main); %always returns 0
scr.white = WhiteIndex(scr.main); %returns 255 for an 8-bit display, may be higher for higher bits...unless NormalizedHighresColorRange, in which case whiteIndex is 1
scr.bgColor = scr.black+(task.bgLum*(scr.white-scr.black));  % background color
scr.fgColor = scr.white;

if scr.normalizedLums
    contStep = 1/scr.nLums;
else
    contStep = 1;
    scr.bgColor=round(scr.bgColor);
end
scr.deltaColor = min([(scr.white-scr.bgColor) (scr.bgColor-scr.black)]); 

%Which nonzero contrasts are really available
cUps=(scr.bgColor+contStep):contStep:scr.white;
cDns=(scr.bgColor-contStep):-contStep:scr.black; 

if length(cDns)>length(cUps)
    cDns=cDns(1:length(cUps));
elseif length(cUps)>length(cDns) 
    cUps=cUps(1:length(cDns));
end

scr.availableCs=(cUps-cDns)./(cUps+cDns);

%% Open a second window if not in mirror mode on the unused (operator's) monitor
% (recommended by "help MirrorMode") 
if scr.nScreens==2
    otherScreenNum = scr.allScreens(scr.allScreens~=scr.expScreen);
    otherRes = Screen('Resolution',otherScreenNum);
    
    scr.mirrored = (otherRes.width == scr.xres) && (otherRes.height == scr.yres);
    [scr.otherWin,resn]=Screen('OpenWindow',otherScreenNum,ones(1,3)*task.bgColor);
    scr.otherResolution = resn([3,4]);
    scr.otherCenter = floor(scr.otherResolution/2);
    Screen('Flip',scr.otherWin);
else
    scr.otherWin = scr.main;
    scr.mirrored = 2;
end


%% print output

fprintf(1,'\n\n--------------------------------------------------------------\n');
fprintf(1,'(prepScreen) Loaded parameters for screen %s on computer %s.\n',monParams.monName,monParams.computerName); 
fprintf(1,'(prepScreen) screen height (mm) = %.1f; screen width (mm) = %.1f\n',scr.height, scr.width);
fprintf(1,'(prepScreen) vertical pixels = %i; horizontal pixels = %i\n',scr.yres, scr.xres);


fprintf(1,'\n(prepScreen) horizontal resolution: %.1f pix/cm; vertical resolution: %.1f pix/cm\n',horizRes,vertRes);
if (horizRes/vertRes)<0.9 || (horizRes/vertRes)> 1.1
    fprintf(1,'\n\n(prepScreen) Warning! Pixels deviate from being square by more than 10%%, so circles will be ovals, squares will be rectangles!\n\tAdjust screen size manually.\n\n');
end

fprintf(1,'\n(prepScreen) scr.fd, scr.fps, scr.nominalFPS, nsamp, sdev = %.5f, %.5f, %.3f, %i, %.5f\n',scr.fd, scr.fps, scr.nominalFPS, nsamp, sdev);
fprintf(1,'\n(prepScreen) Screen runs at %.1f Hz.\n',1/scr.fd);

fprintf(1,'(prepScreen) subject''s viewing distance: %.1f\n',scr.subDist); 


%Skip sync tests? Should only do that when necessary 
if monParams.skipSyncTests
    fprintf(1,'\n(prepScreen):SKIPPING MONITOR SYNC TESTS!!!!\n');
end
fprintf(1,'--------------------------------------------------------------\n');


%% Give the display a moment to recover from the change of display mode when
% opening a window. It takes some monitors and LCD scan converters a few seconds to resync.
WaitSecs(2);

