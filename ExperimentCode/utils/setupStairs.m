if task.stairType==1
    if task.stair.inLog10
        tGuess= log10(task.stair.threshStartGuess(task.cueType,:,:,:));
        tGuessSd=log10(task.stair.threshSDStartGuess);
    else
        tGuess= task.stair.threshStartGuess(task.cueType,:,:,:);
        tGuessSd=task.stair.threshSDStartGuess;
    end
    tGuess=squeeze(tGuess);
    pThreshold=task.stair.threshLevel;
    for feati=1:task.stair.nFeatrTypes
        for i=1:task.stair.nCueVals
            for c=1:task.stair.nPerType
                task.stair.q{feati,i,c}=QuestCreate(tGuess(feati,i,c),tGuessSd,pThreshold,task.stair.beta,task.stair.delta,task.stair.gamma);
                task.stair.q{feati,i,c}.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
                task.stair.q{feati,i,c}.ntrials = 0;
            end
        end
    end
    task.stair.q{1,1,1}.subj=task.subj;
    task.stair.q{1,1,1}.nblocks=1;
    task.stair.q{1,1,1}.date=date;
    
elseif task.stairType==2
    if task.stair.inLog10
        tGuess= log10(task.stair.startC);
        tMax = log10(task.stair.maxIntensity); tMin=log10(task.stair.minIntensity);
    else
        tGuess= task.stair.startC;
        tMax = task.stair.maxIntensity; tMin=task.stair.minIntensity;
    end
    for cvi=1:task.stair.nTypes
        for ssi=1:task.stair.nPerType
            task.stair.ss{cvi,ssi}=PAL_AMUD_setupUD('Up',task.stair.nUp,'Down',task.stair.nDn,'stepSizeUp',task.stair.stepUp,'stepSizeDown',task.stair.stepDn,'stopCriterion',task.stair.stopCriterion,'stopRule',task.stair.stopRule,'startValue',tGuess(cvi,ssi),'xMax',tMax,'xMin',tMin,'truncate',task.stair.truncate);
        end
    end
elseif task.stairType==3
    startlev = task.stair.startC;
    %set bounds, [min max]
    if task.stair.inLog10
        theStart = log10(startlev);
        theBounds  = log10(bounds);
    else
        theStart = startLev;
        theBounds = bounds;
    end
    for cvi=1:task.stair.nTypes
        for ssi=1:task.stair.nPerType
            task.stair.ss{cvi,ssi} = initSIAM(task.stair.t, task.stair.startStep, theStart(cvi,ssi), theBounds, task.stair.revsToHalfContr, task.stair.revsToReset, task.stair.nStuckToReset); 
        end
    end
end