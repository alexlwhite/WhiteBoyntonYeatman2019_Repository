%DISPLALY OVERALL PC FOR THE SUBJECT

Screen('TextSize',scr.main,task.instructTextSize);

c=task.textColor;

rubber([]);

if task.practice
    blockText = 'Practice block done!';
else
    blockText = sprintf('Block %i done!',task.blockNum);
end

if task.blockEndFeedback
    successText=sprintf('Overall percent correct = %i%%',round(100*res.pc));
else
    successText='Great job!';
end

if task.feedbackPoints
    pointsText1 = sprintf('You earned %i points this round! Great job!!',task.blockPoints);
    if task.blockNum==1
        pointsText2 = 'How many more can you get?';
    else
        pointsText2 = sprintf('Total points so far: %i. How many more can you get?',task.totalPoints);
    end
end
 
continueButton = [KbName('space')]; % task.buttons.resp];

continueButtonText='the space bar'; %'any key';

if savingData
    if (task.numBlocks-task.blockNum)>=1 || task.practice
        continueText = 'Saving data...please wait...';
    else
        continueText = 'All done, thanks!';
    end
    contV = -3;
else
    contV = -4.5;
    if (task.numBlocks-task.blockNum)>=1 || task.practice
        continueText=sprintf('Press %s to continue', continueButtonText);
    else
        continueText=sprintf('All done, thanks! (Press %s to finish)',continueButtonText);
    end
end

Screen('TextSize',scr.main,task.instructTextSize);
ptbDrawText(blockText,   dva2scrPx(0, 6),c);
if task.feedbackPoints
    ptbDrawText(pointsText1, dva2scrPx(0, 3.5),task.feedbackPointsColors(2,:));
    ptbDrawText(pointsText2, dva2scrPx(0, 1.5),c);
else
    ptbDrawText(successText, dva2scrPx(0, 3.5),c);
end

Screen('TextStyle',scr.main,2); %italic
ptbDrawText(continueText, dva2scrPx(0, contV),c);
Screen('TextStyle',scr.main,0); %normal

vbl=Screen(scr.main,'Flip');


if ~savingData
    
    keyPress = 0;
    while ~keyPress
        [keyPress, dummy] = checkTarPress(continueButton);   % accept all buttons
%         keyPress = KbCheck(-1); %input argument -1 will query all keyboards
    end
    
    rubber([]);
    Screen(scr.main,'Flip');
end




