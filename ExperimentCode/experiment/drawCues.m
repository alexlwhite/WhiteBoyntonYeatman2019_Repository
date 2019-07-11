function drawCues(cuedLocI, cuedColrI)

global task scr 

if cuedLocI == 0 %neutral
    colrs = [task.cue.neutralColor; task.cue.neutralColor]; 
elseif cuedLocI ~= cuedColrI
    colrs = flipud(task.cue.color);
else
    colrs = task.cue.color;
end

colrs = colrs';
colrs = colrs(:, [1 1 2 2]); %colors must be organized in columns with one column for each line start AND end 
    
Screen('DrawLines',scr.main,task.cue.allcords,task.cue.thick,colrs,[scr.centerX scr.centerY],2);