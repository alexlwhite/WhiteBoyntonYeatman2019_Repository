task.stair.threshEstimates = zeros(1,task.stair.nPerType);
task.stair.threshSDs = zeros(1,task.stair.nPerType);
task.stair.meanThreshs = zeros(1,1);
for ssi = 1:task.stair.nPerType
    if task.stairType == 1
        task.stair.threshEstimates(ssi) = QuestMean(task.stair.q{ssi});
        task.stair.threshSDs(ssi) = QuestSd(task.stair.q{ssi});
        res.q = task.stair.q;
        
    elseif task.stairType == 2
        res.ss = task.stair.ss;
        lastRevsToCount = max(task.stair.ss{ssi}.reversal)-task.stair.revsToIgnore;
        if lastRevsToCount>=task.stair.minRevsForThresh
            task.stair.threshEstimates(ssi) = PAL_AMUD_analyzeUD(task.stair.ss{ssi},'reversals',lastRevsToCount);
            task.stair.threshSDs(ssi) = std(task.stair.ss{ssi}.x(task.stair.ss{ssi}.reversal>task.stair.revsToIgnore));
        else
            ntsStair = length(task.stair.ss{ssi}.response);
            lastTrlsToCount = ntsStair-task.stair.trialsIgnoredThresh;
            if lastTrlsToCount<1, lastTrlsToCount=ntsStair; end
            task.stair.threshEstimates(ssi) = PAL_AMUD_analyzeUD(task.stair.ss{ssi},'trials',lastTrlsToCount);
            cntTrlIs = (ntsStair-(lastTrlsToCount-1)):ntsStair;
            task.stair.threshSDs(ssi) = std(task.stair.ss{ssi}.x(cntTrlIs));
        end
    elseif task.stairType == 3
        [thrsh, ntrls, sd] = estimateSIAM(task.stair.ss{ssi},task.stair.threshType);
        task.stair.threshEstimates(ssi) = thrsh;
        task.stair.threshSDs(ssi) = sd;
        task.stair.numThreshTrials(ssi) = ntrls;
        res.stair.ss=task.stair.ss;
        res.numThreshTrials = task.stair.numThreshTrials;
    end
end
if task.stair.inLog10
    task.stair.threshEstimates = 10.^task.stair.threshEstimates;
    task.stair.threshSDs = 10.^task.stair.threshSDs;
end

task.stair.meanThreshs=nanmean(task.stair.threshEstimates);
task.stair.meanThreshs(task.stair.meanThreshs>task.stair.maxIntensity)=task.stair.maxIntensity;
res.threshEstimates = task.stair.threshEstimates;
res.threshSDs = task.stair.threshSDs;
res.meanThreshs = task.stair.meanThreshs;