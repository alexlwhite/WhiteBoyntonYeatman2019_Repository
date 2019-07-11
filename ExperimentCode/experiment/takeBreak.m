%DISPLALY OVERALL PC FOR THE SUBJECT

c=task.textColor;

rubber([]);

successText='Take a break.'; %sprintf('Pretest %i%% complete ',round(100*propDone));

continueButtonText = 'a key';


continueButton = [KbName('space') task.respButtons];


%if nBreaks > 1 %Only show progress on the second break. On the first it's often way too low.
%    progressText=sprintf('You are approximately %i%% done with this block.',propDone);
%else
    progressText = ' '; %never show, b/c so innacurate 
%end

nextText =' ';
continueText=sprintf('Press %s when you''re ready to continue', continueButtonText);


Screen('TextSize',scr.main,task.instructTextSize);
ptbDrawText(successText, dva2scrPx(0, 2),c);
ptbDrawText(progressText, dva2scrPx(0, 0),c);


%Screen('TextStyle',scr.main,2); %italic
ptbDrawText(nextText, dva2scrPx(0, -2),c);
ptbDrawText(continueText, dva2scrPx(0, -5),c);
%Screen('TextStyle',scr.main,0); %normal

vbl=Screen(scr.main,'Flip');

keyPress = 0;
while ~keyPress
    [keyPress, dummy] = checkTarPress(continueButton);   % accept all buttons
end


%Martin's fadeout:

if task.doFadeOut
    nBlank = round(0.20*1/scr.fd); % fade out takes 0.2 secs
    WaitSecs(round(0.2/scr.fd)*scr.fd - scr.fd);
    oc = task.textColor(1);
    bc = scr.bgColor(1);
    for i = 1:nBlank
        c = bc + (oc-bc)*(nBlank-i)/nBlank;
        if ~scr.normalizedLums
            c=round(c);
        end
        ptbDrawText(successText, dva2scrPx(0, 2),c);
        ptbDrawText(progressText, dva2scrPx(0, 0),c);
        
        
        %Screen('TextStyle',scr.main,2); %italic
        ptbDrawText(nextText, dva2scrPx(0, -2),c);
        ptbDrawText(continueText, dva2scrPx(0, -5),c);
        %Screen('TextStyle',scr.main,0); %normal
        
        Screen(scr.main,'Flip',vbl + (i-0.5)*scr.fd);
    end
    
end

rubber([]);
Screen(scr.main,'Flip');



