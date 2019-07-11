stair = params.stair;

if params.stairType==1
    stair.type      = 'Quest';
    stair.q=res.q;
elseif params.stairType==2
    stair.type      = 'UpDown';
    stair.ss = res.ss;
elseif params.stairType==3
    stair.type      = 'SIAM'; 
    stair.ss        = res.stair.ss;
end

stair.subj          = subj;
stair.date          = date;
stair.allThreshs    = res.threshEstimates;
stair.threshold     = res.meanThreshs;
stair.threshSDs     = res.threshSDs;
stair.blockNum      = blockNum;
stair.cueCond       = params.cueCond;

fprintf(1,'\n\nBlock %i staircase threshold:',blockNum); 
fprintf(1,'\t%.3f',stair.threshold); 

%save stair structure to subject's data folder
global scr;

if ischar(subj)
    subjN = subj;
else
    subjN = sprintf('s%i',subj);
end

bn = 0; goodName = false;
while ~goodName
    bn = bn+1;
    stairName = sprintf('Staircase_%s_%s_%i.mat',subjN,date,bn);
    fullFileName = fullfile(scr.datadir,stairName);
    goodName = ~isfile(fullFileName);
end

save(fullFileName,'stair');

fprintf(1,'\nSaving staircase results to: %s\n\n',fullFileName);
