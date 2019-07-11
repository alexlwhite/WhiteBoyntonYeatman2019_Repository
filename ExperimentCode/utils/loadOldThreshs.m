loadedT = false;
clear stair; clear stairRes;
while ~loadedT
    uiopen('load');
    
    %accept either "stair" file (saved at end of each block) or "stairRes"
    %file saved at end of all blocks run in that session 
    if exist('stair','var') || exist('stairRes','var')
        if exist('stairRes','var') && ~exist('stair','var')
            stair=stairRes;
        
            fprintf(1,'Successfully loaded staircase threshold for subject %i from date %s\n',stair.subj, stair.date);
            threshC = stair.thresholds;
            loadedT = true;
            fprintf(1,'Threshold = %.3f\n',threshC);
        end
    else
        loadedT = false;
    end
end
