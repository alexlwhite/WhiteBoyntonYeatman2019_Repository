% initialInstruct

% clear keyboard buffer
FlushEvents('KeyDown');

%clear screen to background color
rubber([]);

Screen('TextSize',scr.main,task.instructTextSize);

continueButton = KbName('space');

c=task.textColor;
textSep=1.25;

if task.practice
    blockText = 'PRACTICE';
else
    blockText=sprintf('Block number %i', task.blockNum);
end
if ~task.doStair && ~task.practice
    blockText = sprintf('%s of %i', blockText, task.numBlocks);
end

if task.grayscale
    colorText = 'black';
else
    if task.cueCond == 3 %version 3, Roach style cue
        colorText = 'small black';
    else
        colorText = 'red';
    end
end

cueTypes = {'ring','dot','line'};

if task.cueCond == 0
    cueText = sprintf('There will be no %s %ss, so you have to find the tilted stripes on your own.',colorText,cueTypes{task.cue.type});
elseif task.cueCond == 1 || task.cueCond == 3
    switch task.cue.type
        case 1
            cueText = sprintf('The %s ring will appear around the tilted stripes.', colorText);
        case 2
            cueText = sprintf('The %s dot will appear near the tilted stripes.', colorText);
        case 3
            cueText = sprintf('The %s line will point to the tilted stripes.', colorText);
    end
elseif task.cueCond == 2
    cueText = 'There will only be 1 patch of stripes at a time.';
end

continueText = 'Press the space bar to continue';

%% Draw a blank texture, to initalize all that functionality
blankTex = Screen('MakeTexture',scr.main,ones(10,10)*scr.bgColor);
Screen('DrawTexture', scr.main, blankTex, [], [10 10 20 20],[],scr.drawTextureFilterMode);

%%%%%
%% Now actually draw all the text

%to both screens if there are 2 non-mirrored screens open
if scr.nScreens==2 && ~scr.mirrored
    sIs = [scr.main, scr.otherWin];
else
    sIs = scr.main;
end

for sI = sIs
    
    vertpos = 3;
    
    ptbDrawFormattedText(sI,blockText, dva2scrPx(0, vertpos),c,true,true,false,false);
    
    Screen('TextStyle',sI,0); %normal
    
    vertpos = vertpos - 2.5;
    
    ptbDrawFormattedText(sI,cueText, dva2scrPx(0,vertpos),c,true,true,false,false);
    
    vertpos=vertpos-textSep*3;
    Screen('TextStyle',sI,2); %italic
    ptbDrawFormattedText(sI,continueText, dva2scrPx(0, vertpos),c,true,true,false,false);
    Screen('TextStyle',sI,0); %normal
    
    
    vbl=Screen(sI,'Flip');
    
end

keyPress = 0;
while ~keyPress
    [keyPress, dummy] = checkTarPress(continueButton);
end

rubber([]);
for sI = sIs
    Screen(sI,'Flip');
end

Screen('Close',blankTex);


