function stairRes = CueDL1_RunBlocks(subj, exptVersion, computerName)

%Peripheral spatial cueing in children with (and without) dyslexia
%Alex L White
%
%CueDL1_RunBlocks:  New function to start the program (February 5, 2016). 
%
%Inputs: 
% -subj: subject ID (character string, or number) 
% - exptVersion: 1 or 2. 1 is the orginal version. 2 is an updated version with the following change: 
%        (a) no single stimulus condition, 
%        (b) monitor luminance linearized
%        (c) 5 freebie trials per block (rather than 4) 
%        (d) freebie tilt fixed to 25deg (rather than a function of current threshold) 
% - computerName: name of computer, should be listed in getDisplayParameters. Defaults to 'CHDD' if not supplied
% 
% Output: 
% stairRes: structure with results of staricases 

%% which computer
%default is CHDD
if ~exist('computerName','var')
    computerName = 'CHDD'; %'Meriwether';
end


%% set directory and path
%always navigate to the "code" directory
if strcmp(computerName,'CHDD')
    cd('/home/bde/git/PsychDys/CueDL1/code');
else
    codeFolder = fullfile(CueDL1_base,'ExperimentCode');
    cd(codeFolder);
end

addpath(genpath(pwd));  


%% Which conditions? 
% by block:  0=uncued; 1=cued; 2=single stimulus;
% conditions will go in the order specified here (repeating): 
if exptVersion == 1
    cueBlockSet = [2 0 1 0 1 2];
    numBlocks = 6;
elseif exptVersion == 2  %no single stimulus
    cueBlockSet = [0 1 0 1 0 1];
    numBlocks = 6;
elseif exptVersion == 3 %additional cued condition with cue that matches Roach & Hogben (cueCond = 3);
    %two possible orders:
    if rand<0.05    
        cueBlockSet = [2 0 1 3 1 3 0 2]; 
    else
        cueBlockSet = [3 1 0 2 0 2 1 3];
    end
    numBlocks = 8; 
end
    

%% use calibration file to linearize monitor luminance?
if exptVersion  == 1  || exptVersion == 3
    linearizeMonitor = false;
elseif exptVersion == 2
    linearizeMonitor = true;
end

%% Load parameters
if exptVersion == 1
    params = CueDL1_Params;
elseif exptVersion == 2 %same parameters with slight changes 
    params = CueDL1_Params_V2; 
elseif exptVersion == 3 %slight changes for V3 with R&H-style cue 
    params = CueDL1_Params_V3;
end

params.subj = subj;
params.computerName = computerName;
params.linearizeMonitor = linearizeMonitor;
params.exptVersion = exptVersion;

if strcmp(computerName,'CHDD')
    PsychJavaTrouble;
end

%RESET RANDOM NUMBER GENERATOR
params.initialSeed = ClockRandSeed;

if ischar(subj)
    display(sprintf('\nSubject: %s\n', subj));
else
    display(sprintf('\nSubject: %i\n', subj));
end

cueLabs = {'Uncued','Cued','Single stim'};
if exptVersion == 3
    cueLabs = cat(2,cueLabs,{'RH Cued'});
end

%% Setup staircase starting levels or fixed intenstiy levels
taskIntensities = 'gabor tilt';

if isfield(params,'doStair')
    if params.doStair==1
        doStair = 'y';
    else
        doStair = 'n';
    end
else
    doStair = '';
end
while (~strcmp(doStair, 'n') && ~strcmp(doStair, 'y'))
    doStair = input(sprintf('Enter ''y'' or ''n'': Should this be an initial staircase session to adjust %s?\n',taskIntensities), 's');
end
doStair = strcmp(doStair, 'y');
params.doStair = doStair;


%% How many blocks to do?

if strcmp(subj,'XX')
    keepAskingBlockN = false;
    numBlocks = 1; %length(cueBlockSet);
else
    keepAskingBlockN = ~exist('numBlocks','var');
    if keepAskingBlockN, numBlocks = ''; end
end

nbs = length(cueBlockSet);

while keepAskingBlockN
    numBlocks = input(sprintf('\nEnter how many blocks you would like to do:\n'));
    keepAskingBlockN = all(isfloat(numBlocks)) && numBlocks<0;
end

if numBlocks==0
    return;
end
params.numBlocks = numBlocks;

%Set blocks of cueing conditions, for each block
numSets = ceil(params.numBlocks/nbs);
if nbs>1
    cueBlocks = repmat(cueBlockSet,1,numSets);
else
    cueBlocks = ones(1,numBlocks)*cueBlockSet;
end

params.cueBlocks = cueBlocks;

fprintf(1,'\nCue conditions by block:\n');
disp(cueBlocks);


%% %%%% PRACTICE %%%%%%%%%%%

params.shutDownScreen = true; %length(Screen('Screens'))<2;
params.reinitScreen   = true;

if strcmp(subj,'XX')
    doPracticeResp = 'n';
else
    aquestion = 'Do you want to do any practice trials?\n Enter ''y'' or ''n''\n';
    doPracticeResp='xxx';
end

while (~strcmp(doPracticeResp, 'n') && ~strcmp(doPracticeResp, 'y'))
    doPracticeResp = input(aquestion, 's');
end
doPractice = strcmp(doPracticeResp, 'y');
params.doPracEye = params.EYE == 1;

repeat = '';
nrep = 1;

while doPractice
    params.practice = true;
    params.blockNum = 1; params.numBlocks = 1;
    
    if doStair, practStair = 'n'; else practStair='n'; end
    while (~strcmp(practStair, 'n') && ~strcmp(practStair, 'y'))
        practStair = input('\nDo you want to run a staircase during practice?\n (Press y or n)\n', 's');
    end
    params.doPracticeStair = strcmp(practStair,'y');
    params.useOldStair = false;
    
    params.blockNum = nrep;
    
    nbi = nrep - (nrep>numBlocks)*(nrep-numBlocks)*numBlocks;
    
    %SET UP CUE CONDITIONS
    keepAskingCue = true;
    while keepAskingCue
        if exptVersion < 3
            cueType = input('\nEnter the cueing condition for this practice block: \n   0 = uncued\n   1 = cued\n   2 = single stimulus\n');
            keepAskingCue = ~all(isfloat(cueType)) || (cueType<0 || cueType>2);
        else
            cueType = input('\nEnter the cueing condition for this practice block: \n   0 = uncued\n   1 = cued\n   2 = single stimulus\n   3 = small cue\n');
            keepAskingCue = ~all(isfloat(cueType)) || (cueType<0 || cueType>3);
        end
    end
    params.cueCond = cueType;
    
    %Extra-long stimulus duration?
    demoTime = 'x';
    while (~strcmp(demoTime, 'n') && ~strcmp(demoTime, 'y'))
        demoTime = input('\nLong stimulus duration for demo?\n (Press y or n)\n', 's');
    end
    params.demoDuration = strcmp(demoTime,'y');
    
    %SET UP TILT LEVEL
    gotCs = false;
    while ~gotCs
        pracTilt = input('Enter the tilt level in degrees\n');
        gotCs = all(isfloat(pracTilt)) && (numel(pracTilt)==1);
        gotCs = gotCs && pracTilt<=params.gabor.maxTilt && pracTilt>=params.gabor.minTilt;
    end
    params.gaborTilt = pracTilt;
    %Run the experiment!
    try
        res = CueDL1(params);
    catch me
        sca; ListenChar(1);
        rethrow(me);
    end
    
    aquestion = 'Do you want to do another practice block?\n Enter ''y'' or ''n''\n';
    repeat='xxx';
    
    while (~strcmp(repeat, 'n') && ~strcmp(repeat, 'y'))
        repeat = input(aquestion, 's');
    end
    if strcmp(repeat, 'n')
        doPractice = false;
    elseif strcmp(repeat, 'y')
        doPractice = true;
        nrep = nrep+1;
        params.doPracEye = params.EYE == 1;
    end
    params.reinitScreen = params.shutDownScreen;
end

%% %%%%%% REAL TRIALS
params.practice = false;
keepGoing = true;
nBlocksDone = 0;
params.demoDuration = false;
params.totalPoints = 0;
if params.doStair
    meanThreshs = NaN(3+(exptVersion==3),numBlocks);
else
    blockPCs = NaN(1,numBlocks);
end

doMainExpt = '';
while (~strcmp(doMainExpt, 'n') && ~strcmp(doMainExpt, 'y'))
    doMainExpt = input('\nDo you want to continue to the main task?\n (Press y or n)\n', 's');
end
if strcmp(doMainExpt, 'y')
    
    if doStair
        display(sprintf('\n STARTING A SESSION OF STAIRCASES FOR %s\n\n',taskIntensities));
        setGaborTilt;
        if params.stair.nPerType==2
            params.stair.startC = [0.7 1.3]*params.gaborTilt;
        else
            params.stair.startC = params.gaborTilt;
        end
        if rand<0.5, params.stair.startC = fliplr(params.stair.startC); end %flip which one is low on 1/2 runs
    else
        fprintf(1,'\n STARTING MAIN TESTING SESSION\n');
        
        if ~exist(gaborTilt) %if not already set by subject's own script
            setGaborTilt;
        else %use the value set in subject's start script
            params.gaborTilt = gaborTilt;
        end
        
    end
    
    
    if params.doStair
        params.numTrials = params.numTrialsStair;
        params.useOldStair = false;
    else
        params.numTrials = params.numTrialsPC;
    end
    
    blockNum = 0;
    continueBlocks = true;
    
    %Run through all the blocks:
    while continueBlocks
        blockNum = blockNum+1;
        params.blockNum = blockNum; params.numBlocks = numBlocks;
        params.shutDownScreen = blockNum==numBlocks;
        
        %Set the cue condition:
        params.cueCond = cueBlocks(blockNum);
        
        %set next staircase off near mean of previous thresholds
        %for this condition
        if doStair && blockNum>1 && params.stair.startFromPrevMeanThisCond
            prevThreshs = meanThreshs(params.cueCond+1,:);
            threshGuess = nanmean(prevThreshs);
            
            if ~isempty(threshGuess) && ~all(isnan(threshGuess))
                if params.stair.nPerType==2
                    params.stair.startC = threshGuess*[.7 1.3];
                else
                    params.stair.startC = threshGuess;
                end
                if rand<0.5, params.stair.startC = fliplr(params.stair.startC); end %flip which one is low on 1/2 runs
            end
        end
        
        %% RUN THE EXPERIMENT!
        try
            res = CueDL1(params);
        catch me
            sca;
            rethrow(me);
        end
        
        if params.doStair
            if res.stairDone
                meanThreshs(params.cueCond+1,blockNum) = res.meanThreshs;
                saveStaircase;
                
                figure(1);
                for si=1:params.stair.nPerType
                    nStrs = numBlocks*params.stair.nPerType;
                    if nStrs>3, nCols = 2; else nCols = 1; end
                    nRows = ceil(nStrs/nCols);
                        
                    sbpi = (blockNum-1)*params.stair.nPerType+si;
                    subplot(nRows,nCols,sbpi); hold on;
                    switch params.stairType
                        case 1
                            plotQuest(res.stair.q{si},params.stair.inLog10);
                        case 2
                            plotUpDownStair(res.ss{si},params.stair);
                        case 3 
                            plotSIAM(res.stair.ss{si},params.stair.threshType);
                    end
                    title(sprintf('Block %i, %s, stair %i',blockNum, cueLabs{params.cueCond+1},si));
                end

                params.useOldStair = false;
            else
                params.useOldStair = false; % actually, for now, never keep staircases going! 
                params.oldStair = res.oldStair;
            end
        else
            %CHANGE DIFFICULTY LEVEL IF PERFORMANCE IS NOT IN A GOOD RANGE:...?
            perfOutOfRange = ~doStair && (res.pc(1)<params.minPC || res.pc(1)>params.maxPC);
            if perfOutOfRange && blockNum<numBlocks && params.adjustIntensities
                fprintf(1,'\n\nPERFORMANCE IS BELOW 60 OR ABOVE 90%% CORRECT\n\n');
            end
            blockPCs(blockNum) = mean(res.pc); %average over first and second responses
        end
        
        if params.feedbackPoints
            fprintf(1,'\n\nTotal points earned: %i',res.totalPoints);
            params.totalPoints = res.totalPoints;
        end
        
        params.reinitScreen = params.shutDownScreen;
        nBlocksDone = nBlocksDone+1;
        continueBlocks = blockNum<numBlocks && ~res.abort;
    end
end

%% Compute final and save threshold
if params.doStair && nBlocksDone>0
    meanThreshs = meanThreshs(:,1:nBlocksDone);
    allBlocksMeanThreshs = nanmean(meanThreshs,2);
    stairRes               = params.stair;
    stairRes.subj          = subj;
    stairRes.date          = date;
    stairRes.numBlocksDone = nBlocksDone;
    stairRes.numBlocks = numBlocks;
    stairRes.thresholds = allBlocksMeanThreshs;
    stairRes.allBlockThresholds = meanThreshs;
    stairRes.cueCondbyBlock = cueBlocks;
    
    fprintf(1,'\n\nMean staircase threshold:');
    fprintf(1,'\t%.3f',stairRes.thresholds);
    
    if ischar(subj)
        subjN = subj;
    else
        subjN = sprintf('s%i',subj);
    end
    
    dataFolders = {scr.datadir};
    for dfi = 1:numel(dataFolders)
        goodName = false; bn = 0;
        while ~goodName
            bn = bn+1;
            stairName = sprintf('%s_StairFinal_%s_%i.mat',subjN,date,bn);
            fullFileName = fullfile(dataFolders{dfi},stairName);
            goodName = ~isfile(fullFileName);
        end
        
        save(fullFileName,'stairRes');
        fprintf(1,'\n\nSaving FINAL staircase results to: %s\n\n',fullFileName);
    end
    %save figure
    print(gcf,fullfile(res.datadir,sprintf('%s_%s_stairFig.eps',subj,date)),'-depsc')
%%
elseif nBlocksDone>0
    printOverallPCRes;
else
    stairRes = [];
end


if ~params.shutDownScreen
    % re-enable keyboard
    ListenChar(1);
    ShowCursor;
    Screen('CloseAll');
end
clear mex;
clear fun;


