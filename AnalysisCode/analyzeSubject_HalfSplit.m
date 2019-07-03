%% function r = analyzeSubject_HalfSplit(d)
% Analyze one subject's trial-level data for the cued visual search
% experiment in White, Boynton & Yeatman's 2019 paper:
% "The link between visual spatial attention and reading ability across development"
%
% This funciton fits psychometric functions to each condition, for the first and second half of trials, 
% for the purpose of analyzing reliability. 
% The slope is fixed to 1.77, which I found to be the mean across subjects when the
% slope was free.
%
% For each half, it first fits each condition with the lapse rate parameter (lambda) free,
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
% each element of R is a 1x2 vector, for the 1st and second half of the
% data set. 
%
% by Alex L. White, University of Washington, 2019
%
function r = analyzeSubject_HalfSplit(d, maxSession)


%Fit parameters
psychFun = @PAL_Gumbel;
maxLapse = 0.125; %max lapse rate (when it's a free parameter)...halfway between threshold level and perfect
nFitGoodnessSim = 0; %1st entry for binned fit; second for unbinned fit. Set to 0 when lapse is free; set to this value when lapse rate is fixed

%Median slope, after averaging across conditions, excluding thresholds > 45deg:
fixedSlope = 1.77;

%trials to be analyzed:
goodTrials=find(d.trialDone & ~d.pressedQuit & ~d.responseTimeout);

%only include trials from the first N days (aka sessions)
goodTrials = intersect(goodTrials, find(d.dateNum<=maxSession));


% compute RT relative to post-cue onset
d.RT = d.tRes - d.tGaborsOns;

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
fitLapses = NaN(2,nConds);
r.lambda = NaN(1,2);

for half = 1:2
    
    %first fit with lapse rate free
    fixedLapse = NaN;
    for ci=1:nConds
        clear subRes;
        condTrials = intersect(goodTrials, find(d.cueCond==conds(ci)));
        n = length(condTrials);
        if half==1
            halfTrials = condTrials(1:floor(n/2));
        else
            halfTrials = condTrials((floor(n/2)+1):end);
        end
        
        if ~isempty(halfTrials)
            subRes=analyzeTrials(d(halfTrials,:), psychFun, maxLapse, fixedLapse, fixedSlope, nFitGoodnessSim);
            fitLapses(half,ci) = subRes.fitParams(4);
        end
    end
    
    
    %then fit again with lapse fixed to the mean
    fixedLapse = nanmean(fitLapses(half, :));
    r.lambda(half) = fixedLapse;
    
    for ci=1:nConds
        condTrials = intersect(goodTrials, find(d.cueCond==conds(ci)));
        n = length(condTrials);
        if half==1
            halfTrials = condTrials(1:floor(n/2));
        else
            halfTrials = condTrials((floor(n/2)+1):end);
        end
        
        
        thisCond = condLabels{ci};
        clear subRes;
        
        if ~isempty(halfTrials)
            subRes=analyzeTrials(d(halfTrials,:), psychFun, maxLapse, fixedLapse, fixedSlope, nFitGoodnessSim);
            eval(sprintf('r.thresh_%s(half) = subRes.fitThreshold;', thisCond));
            eval(sprintf('r.corrRT_%s(half) = subRes.meanCorrRT;', thisCond));
            
            %also determine whether performance was above chance on these trials
            ncs = sum(d.respCorrect(halfTrials));
            nts = length(halfTrials);
            [~,dCI] = binofit(ncs,nts,0.05);
            eval(sprintf('r.aboveChance_%s(half) = dCI(1)>0.5;', thisCond));
        else
            eval(sprintf('r.thresh_%s(half) = NaN;', thisCond));
            eval(sprintf('r.corrRT_%s(half) = NaN;', thisCond));
            %if subject doesnt have this condition, set aboveChance to true (so
            %this subject isnt excluded for that criterion)
            eval(sprintf('r.aboveChance_%s(half) = true;', thisCond));
        end
    end
    
end
r.condLabels = condLabels;
