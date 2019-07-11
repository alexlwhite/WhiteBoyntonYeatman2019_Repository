% design = makeTrialOrder(design,task) 
% by Alex White
%
% This function assigns experimental parameters to a set of trials 
% in a fully randomlized, counterbalanced fasion. 
% 
% Inputs: 
% - design: a structure with fields "parameters" and "uniformRandVars." 
%
%   parameters is a structure with fields corresponding to the experimental parameters 
%   that you want to be fully counterbalanced. The name of each field is the name of the parameter. Each 
%   field should be a vector containing the values that parameter can take. 
%   For example, design.parameters.targetPosition=[1 2]; and design.parameters.targetOrientation=[-45 45] 
%   would ensure that you have an equal number of trials with the target at
%   position 1 and orientation -45, at position 2 and orientation 45, etc. 
% 
%   uniformRandVars is a structure with fields corresponding to the
%   experimental parameters that you don't need fully counterbalanced. For
%   example, design.uniformRandVars.targetDelay=[0.2 0.25 0.3 0.35 0.45]
%   would be used to set a delay to one of those values, randomly on each
%   trial, but the function will not ensure that there are an equal number
%   of each on each trial. 
%
% - task: a structure with fields "numTrials" the total number of trials in
%   the block you desire, and "practice" which is a boolean variable
%   indicating whether this is just a practice block or not. If it is
%   practice, then the function will make not change numTrials to ensure
%   perfect counterbalancing. If this is not a practice block, the function
%   will add however many trials to numTrials as is needed to ensure perfect
%   counterbalancing. 
% 
% Output: 
% - design: the same input structure but with a new field, "trials." trials
% is a structure array, and each element of it has fields for each parameter and
% uniformRandVar. For example, trials(2).targetPosition may be 2, and trials(2).targetDelay may be 0.3. 

function [task] = makeTrialOrder(design, task) 


%%%%%%%%%%%%%%%%
%calculate how many trials to counterbalance everything 
%%%%%%%%%%%%%%%%
t=0;
paramNames=fieldnames(design.parameters);

acommand='';
oneRunTs=1;
for p=1:length(paramNames) 
    acommand=sprintf('%s\noneRunTs=oneRunTs*length(design.parameters.%s);', acommand, paramNames{p});
end
eval(acommand); 

numReps=ceil(task.numTrials/oneRunTs);

if task.numTrials<oneRunTs
    fprintf(1,'\nWarning: Asked for doing %i trials, but %i required for 1 trial of each parameter combination.\n', task.numTrials, oneRunTs);
end
if mod(task.numTrials,oneRunTs)~=0
    fprintf(1,'\nWarning: Asked for %i trials, which is not a multiple of the %i trials required for 1 of each parameter combination.\n', task.numTrials, oneRunTs);
end

if ~task.practice
    if task.numTrials<oneRunTs || mod(task.numTrials,oneRunTs)~=0
        fprintf(1,'\nRe-setting number of trials to: %i\n',numReps*oneRunTs);
    end
    
    task.numTrials=numReps*oneRunTs;
end
%%%%%%%%%%%%%%
% Compute Counterbalancing 
%%%%%%%%%%%%%%

bigCommand='';
for nr=1:numReps
    for p=1:length(paramNames) 
        bigCommand=sprintf('%s\nfor %sI=1:length(design.parameters.%s)',bigCommand, paramNames{p},paramNames{p});
    end
    bigCommand=sprintf('%s\nt=t+1;',bigCommand);
    for pp=1:length(paramNames)
        bigCommand=sprintf('%s\ntrials(t).%s=design.parameters.%s(%sI);', bigCommand, paramNames{pp}, paramNames{pp}, paramNames{pp});
    end
    for ppp=1:length(paramNames);
        bigCommand=sprintf('%s\nend',bigCommand);
    end
end

eval(bigCommand);

%shuffle order
shuff=randperm(numReps*oneRunTs);
trials=trials(shuff);


design.oneRunTs=oneRunTs;

%%%%%%%%%%%%%
% Make Random Variables 
%%%%%%%%%%%%%

if isfield(design,'uniformRandVars')
    randParamNames=fieldnames(design.uniformRandVars); 

    for p=1:length(randParamNames) 
        pname=randParamNames{p};
        eval(sprintf('doRandSamp=length(design.uniformRandVars.%s)>1;',pname));
        if doRandSamp
            eval(sprintf('all%s = randsample(design.uniformRandVars.%s, task.numTrials, true);', pname, pname));
        else
            eval(sprintf('all%s = ones(1, task.numTrials)*design.uniformRandVars.%s;', pname, pname));
        end
        for t=1:task.numTrials
            eval(sprintf('trials(t).%s=all%s(t);',pname, pname));
        end
    end
end

%shuffle order
shuff=randperm(task.numTrials);
trials=trials(shuff);

design.trials=trials;
task.design=design;

