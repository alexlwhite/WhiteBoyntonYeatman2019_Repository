%TELL THE SUBJECT TO GET THE EXPERIMENTER SO HE CAN ADJUST CONTRAST LEVELS
global scr; 
global task; 

Screen('TextSize',scr.main,48);

c=task.textColor;

rubber([]);

successText='Please contact the experimenter so he can ajdust the parameters';
continueButtonText='the space bar';
if task.doDataPixx
    continueButton = 66;
else
    continueButton=44;
end

if (task.numBlocks-task.blockNum)>=1
    continueText=sprintf('Press %s to continue', continueButtonText);
else
    continueText=sprintf('Press %s to finish!',continueButtonText);
end

Screen('TextSize',scr.main,30);
ptbDrawText(successText, dva2scrPx(0, 2),c);


Screen('TextStyle',scr.main,2); %italic
ptbDrawText(continueText, dva2scrPx(0, -5),c);
Screen('TextStyle',scr.main,0); %normal

vbl=Screen(scr.main,'Flip');

keyPress = 0;
while ~keyPress
%    [keyPress, dummy] = checkTarPress(continueButton);   % accept all buttons
    keyPress = KbCheck(-1); %input argument -1 will query all keyboards
end

%Martin's fadeout:
nBlank = round(0.20*1/scr.fd); % fade out takes 0.2 secs
WaitSecs(round(0.2/scr.fd)*scr.fd - scr.fd);
for i = 1:nBlank
    c = round(task.textColor(1)+(scr.bgColor(1)-task.textColor(1))*i/nBlank);
    
    Screen('TextSize',scr.main,30);
    ptbDrawText(successText, dva2scrPx(0, 2),c);
    
        
    Screen('TextStyle',scr.main,2); %italic
    ptbDrawText(continueText, dva2scrPx(0, -5),c);
    Screen('TextStyle',scr.main,0); %normal
    
    
    Screen(scr.main,'Flip',vbl + (i-0.5)*scr.fd);
end
rubber([]);
Screen(scr.main,'Flip');



