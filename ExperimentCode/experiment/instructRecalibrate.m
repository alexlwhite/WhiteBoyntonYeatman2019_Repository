%TELL THE SUBJECT THAT WE NEED TO RECALIBRATE
%ALSO, PRESSING "q" INSTEAD OF SPACE BAR WILL END THE EXPERIMENT

Screen('TextSize',scr.main,task.instructTextSize);

c=task.textColor;

rubber([]);

successText='Let''s recalibrate.';


continueButtonText='the space bar';

%continueButton = KbName('space');
continueButton = [KbName('space') task.respButtons];

quitButton = KbName('q');


continueText=sprintf('To recalibrate or correct the calibration, press %s.', continueButtonText);
continueText2=sprintf('If there''s no need to recalibrate, press %s,', continueButtonText);
continueText3='then press escape to go to the next trial.';

Screen('TextSize',scr.main,task.instructTextSize);
ptbDrawText(successText, dva2scrPx(0, 2),c);


Screen('TextStyle',scr.main,0);  
ptbDrawText(continueText, dva2scrPx(0, -1),c);
ptbDrawText(continueText2, dva2scrPx(0, -2),c);
ptbDrawText(continueText3, dva2scrPx(0, -3),c);

Screen('TextStyle',scr.main,0); %normal

vbl=Screen(scr.main,'Flip');

keyPress = 0;
while keyPress==0
   [keyPress, dummy] = checkTarPress([continueButton quitButton]);
   % keyPress = KbCheck(-1); %input argument -1 will query all keyboards

end

if keyPress==1
    
    if task.doFadeOut
        %Martin's fadeout:
        nBlank = round(0.20*1/scr.fd); % fade out takes 0.2 secs
        oc = task.textColor(1);
        bc = scr.bgColor(1);
        for i = 1:nBlank
            c = bc + (oc-bc)*(nBlank-i)/nBlank;
            if ~scr.normalizedLums
                c=round(c);
            end
            Screen('TextSize',scr.main,task.instructTextSize);
            ptbDrawText(successText, dva2scrPx(0, 2),c);
            
            
            Screen('TextStyle',scr.main,2); %italic
            ptbDrawText(continueText, dva2scrPx(0, -2),c);
            ptbDrawText(continueText2, dva2scrPx(0, -4),c);
            ptbDrawText(continueText3, dva2scrPx(0, -6),c);
            
            
            Screen('TextStyle',scr.main,0); %normal
            
            
            Screen(scr.main,'Flip',vbl + (i-0.5)*scr.fd);
        end
    end
    rubber([]);
    Screen(scr.main,'Flip');
    
    
elseif keyPress==2 %quit the program
    %reddUp(1);
    %return;
    doRunTrial = false;
    expDone = true;
    data.pressedQuit = true;
end


