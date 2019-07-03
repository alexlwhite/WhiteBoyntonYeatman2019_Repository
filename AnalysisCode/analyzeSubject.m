%% function r = analyzeSubject(d)
% Analyze one subject's trial-level data for the cued visual search
% experiment in White, Boynton & Yeatman's 2019 paper: 
% "The link between visual spatial attention and reading ability across development"
% 
% This funciton fits psychometric functions to each condition. The slope is
% fixed to 1.77, which I found to be the mean across subjects when the
% slope was free. 
%
% It first fits each condition with the lapse rate parameter (lambda) free,
% fits again wtih lambda fixed to the average acrosss conditons. 
% 
% Inputs: 
% - d: table with 1 row for each trial, and fields for each variable of
% interest (e.g., gabor tilt, response, condition) 
% 
% Outputs: 
% - r: structure containing results for each condition, like thresholds
% (thresh_Uncued, thresh_Cued, etc) and mean RT on correct trials
% (corrRT_Uncued, corrRT_Cued, etc). Also contains the lapse rate
% parameter, lambda, a cell array of condition labels, and information
% about trials excluded for RTs that were >4 SDs above the median. 
% 
% by Alex L. White, University of Washington, 2019 
%
function r = analyzeSubject(d)


%Fit paraneters
psychFun = @PAL_Gumbel;
maxLapse = 0.125; %max lapse rate (when it's a free parameter)...halfway between threshold level and perfect
nFitGoodnessSim = 0; %1st entry for binned fit; second for unbinned fit. Set to 0 when lapse is free; set to this value when lapse rate is fixed

%Median slope, after averaging across conditions, excluding thresholds > 45deg:
fixedSlope = 1.77;


%trials to be analyzed:
goodTrials=find(d.trialDone & ~d.pressedQuit & ~d.responseTimeout);

% compute RT relative to post-cue onset
d.RT = d.tRes - d.tGaborsOns;

%only include trials from 1st day of testing (because some subjects, but
%not all, had more than 1 session) 
goodTrials = intersect(goodTrials, find(d.dateNum==1));


%% Label the  conditions:
conds = 0:3;
nConds = length(conds);
condLabels = cell(1,nConds);
for cci = 1:numel(condLabels)
    switch conds(cci)
        case 0
            condLabels{cci} = 'Uncued';
        case 1
            condLabels{cci} = 'Cued';
        case 2
            condLabels{cci} = 'SingleStim';
        case 3
            condLabels{cci} = 'SmallCue';
    end
end


%% Analyze trials!

%first fit with lapse rate free 
fitLapses = NaN(1,nConds);
fixedLapse = NaN;
for ci=1:nConds
    clear subRes;
    theseTrials = intersect(goodTrials, find(d.cueCond==conds(ci))); 
    if ~isempty(theseTrials)
        subRes=analyzeTrials(d(theseTrials,:), psychFun, maxLapse, fixedLapse, fixedSlope, nFitGoodnessSim);
        fitLapses(ci) = subRes.fitParams(4); 
    end
end
    

%then fit again with lapse fixed to the mean 
fixedLapse = nanmean(fitLapses); 
r.lambda = fixedLapse;

for ci=1:nConds
    theseTrials = intersect(goodTrials, find(d.cueCond==conds(ci))); 
    thisCond = condLabels{ci};
    clear subRes;

    if ~isempty(theseTrials)
        subRes=analyzeTrials(d(theseTrials,:), psychFun, maxLapse, fixedLapse, fixedSlope, nFitGoodnessSim);
        eval(sprintf('r.thresh_%s = subRes.fitThreshold;', thisCond)); 
        eval(sprintf('r.corrRT_%s = subRes.meanCorrRT;', thisCond));
        
        %also determine whether performance was above chance on these trials
        ncs = sum(d.respCorrect(theseTrials));
        nts = length(theseTrials);
        [~,dCI] = binofit(ncs,nts,0.05);
        eval(sprintf('r.aboveChance_%s = dCI(1)>0.5;', thisCond));
    else        
        eval(sprintf('r.thresh_%s = NaN;', thisCond)); 
        eval(sprintf('r.corrRT_%s = NaN;', thisCond));
        %if subject doesnt have this condition, set aboveChance to true (so
        %this subject isnt excluded for that criterion)
        eval(sprintf('r.aboveChance_%s = true;', thisCond));
    end
end

%also test if this subject is performance above chance, across all trials 
ncs = sum(d.respCorrect);
nts = size(d,1);
[~,dCI] = binofit(ncs,nts,0.05);
r.aboveChance_Overall = dCI(1)>0.5;

r.condLabels = condLabels;
