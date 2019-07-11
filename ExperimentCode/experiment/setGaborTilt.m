fprintf(1,'\n\n----SET GABOR TILT----\n');
if strcmp(subj,'XX')
    gotCs = true;
    threshC = 10;
else
    gotCs = false;
end

while ~gotCs
    
    if doStair
        loadThresh = 'n';
    else
        loadThresh = 'x';
    end
    while (~strcmp(loadThresh, 'n') && ~strcmp(loadThresh, 'y'))
        loadThresh = input('\nDo you want to load a staircase to set the tilt ?\n (Press y or n)\n', 's');
    end
        
    if strcmp(loadThresh,'y')
        loadOldThreshs;
    else
        enterStimLevels;
    end
    
    fprintf(1,'\nRequested tilt: '); fprintf(1,'%.3f\t',threshC); fprintf(1,'\n');
    if threshC>params.gabor.minTilt && threshC<=params.gabor.maxTilt
        acceptCs = 'y';
    else
        fprintf(1,'\nRequested value out of range (min = %.2f, max = %.2f). Try again.\n',params.gabor.minTilt, params.gabor.maxTilt);
        acceptCs = 'n';
    end
    while (~strcmp(acceptCs, 'n') && ~strcmp(acceptCs, 'y'))
        acceptCs = input('\nDo you want to use this tilt level?\n','s');
    end
    gotCs = strcmp(acceptCs,'y');
    
end

params.gaborTilt = threshC;