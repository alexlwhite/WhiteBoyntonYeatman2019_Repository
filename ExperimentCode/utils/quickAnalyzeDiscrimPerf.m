function res = quickAnalyzeDiscrimPerf(task)

goodTrials=find(task.data.trialDone & ~task.data.pressedEscape);

if task.cueType==3
    anaCueTypes=1:2;
else
    anaCueTypes=task.cueType;
end

for ctp = anaCueTypes
for feati=1:task.stair.nFeatrTypes
    if task.stair.sepPerFeature
        featTrials=find(task.data.targColorI==feati);
    else
        featTrials=1:length(task.data.respCorrect);
    end
    for cv=1:length(task.cueValsUsed)
        if ctp==1
            cvTrials=find(task.data.loctnCueValidity==task.cueValsUsed(cv));
        else
            cvTrials=find(task.data.colorCueValidity==task.cueValsUsed(cv));
        end
        ts=intersect(intersect(featTrials,cvTrials),goodTrials);
        
        res.pc(anaCueTypes,feati,cv) = mean(task.data.respCorrect(ts));
    end
end
end
