function drawFixation(fixNum,colrI)
%by Alex White
global scr task

Screen('DrawLines',scr.main, task.fixation.allxy, task.fixation.width, task.fixation.color(colrI,:)', [task.fixation.posX(fixNum) task.fixation.posY(fixNum)],2);
