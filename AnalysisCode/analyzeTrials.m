%function r = analyzeTrials(d,r,binFit,fixedLapse,fixedSlope,nGoodSim)
%
% Analyze a subset of trials in the cued visual search experiment in White, Boynton & Yeatman's 2019 paper: 
% "The link between visual spatial attention and reading ability across development"
% 
% This function fits psychometric functions using the Palamedes toolbox (http://www.palamedestoolbox.org/) 
%
%Inputs:
% - d: data table, with 1 row for each trial to be analyzed
% - psychFun: handle to the Palamedes psychometric function to use (e.g.,
%   @PAL_Gumble)
% - maxLapse: upper limit on lapse rate parameter lambda
% - fixedLapse: value to fix the lambda parameter to; NaN if lambda should be free.
% - fixed slope: value to fix the slope at; NaN if slope should be free.
% - nGoodSim: number of simulations to do in Palamedes goodnesss of fit tests.
% 
% Outputs: 
% - r: a structure containing results for this set of trials. Includes the
% vector fitParams, a single value fitThreshold (75% correct threshold) and
% various measures returned by Palamedes for the fit quality. Also returns
% the geometric mean RTs. 
% 
% % By Alex L. White, University of Washington, 2019


function r = analyzeTrials(d, psychFun, maxLapse, fixedLapse, fixedSlope, nGoodSim)


%% Fit psychometric function

doBoot = false;


%structure defining grid to search for initial values:
searchGrid.alpha = -0.5:.02:1.3;    %threshold
searchGrid.beta = 10.^[-1:.025:2];  %slope
searchGrid.gamma = 0.5; %guess rate (fixed)
searchGrid.lambda = 0:.01:maxLapse;%lapse rate

%2nd try search grid
searchGrid2.alpha = -0.45:.01:1.4;    %threshold
searchGrid2.beta = 10.^[-.93:.02:2.1];  %slope
searchGrid2.gamma = 0.5; %guess rate (fixed)
searchGrid2.lambda = 0:.01:maxLapse;%lapse rate


%search grid for goodness-of-fit: make it less dense
searchGridGoF.alpha = -1:.05:1.3;    %threshold
searchGridGoF.beta = 10.^[-1:.05:2];  %slope
searchGridGoF.gamma = 0.5; %guess rate (fixed)
searchGridGoF.lambda = 0:.01:maxLapse;%lapse rate

if ~isnan(fixedSlope)
    searchGrid.beta = fixedSlope;
    searchGrid2.beta = fixedSlope;
    searchGridGoF.beta = fixedSlope;
end

if ~isnan(fixedLapse)
    searchGrid.lambda = fixedLapse;
    searchGrid2.lambda = fixedLapse;
    searchGridGoF.lambda = fixedLapse;
end

lapseLimits = [0 maxLapse];

%[threshold slope guess-rate lapse-rate]
freeParams = [1 isnan(fixedSlope) 0 isnan(fixedLapse)]; %4th parameter is lapse rate, which is free if input fixedLapse is NaN

%compute p(ccorrect) and num trials at each unique tilt
tilts = d.gaborTilt;
lTilts = log10(tilts);

uLTilts = unique(lTilts);

nUBin = length(uLTilts);
nc = zeros(1,nUBin); %number correct
nt = zeros(1,nUBin); %total trials
for i=1:nUBin
    binTs = find(lTilts==uLTilts(i));
    nc(i) = sum(d.respCorrect(binTs));
    nt(i) = length(binTs);
end

%p(correct)
pc = nc./nt; 

fitTiltLevels = uLTilts';

if isnan(fixedLapse) %set lapse limits if lapse rate (lambda) is free
    [fitParams, LL, exitflag] = PAL_PFML_Fit(fitTiltLevels, nc, nt, searchGrid, freeParams, psychFun,'lapseLimits',lapseLimits);
else %otherwise, lambda is fixed in the searchGrid and freeParams inputs 
    [fitParams, LL, exitflag] = PAL_PFML_Fit(fitTiltLevels, nc, nt, searchGrid, freeParams, psychFun); 
end
firstTryWorked = exitflag;
if exitflag == 0 %if fit didn't converge the first time, try again
    [fitParams, LL, exitflag] = PAL_PFML_Fit(fitTiltLevels, nc, nt, searchGrid2, freeParams, psychFun,'lapseLimits',lapseLimits);
end

%goodness of fit
%r^2
resid=pc-psychFun(fitParams,fitTiltLevels);
SSTot=sum((pc-mean(pc)).^2);
SSE=sum(resid.^2);
rSqr=1-SSE/SSTot;

%pdev
if nGoodSim(1)>0
    [dev, pdev] = PAL_PFML_GoodnessOfFit(fitTiltLevels, nc, nt, fitParams, freeParams, nGoodSim(1), psychFun,'searchGrid', searchGridGoF,'lapseLimits',lapseLimits);
else
    dev = NaN; pdev = NaN;
end
%this function compares our "target" model (from fitting in the previous step) to a "saturated model" in
%which accuracy at each stimulus level is a free parameter. Target model is
%nested inside the saturated model. This function simulates an observer
%using the target model, then fits with the assumptions of the target model
%(certain nPFBins shape with some free parameters), and fits with the less
%restrictive assumptions of the saturated model. For each fit, a
%likelihood, and for each simulation, a likelihood ratio. Likelihood for
%saturated model will always be greater, can always get closer.
%If likelihood ratio from experimental data is often lower than what comes
%from simulations, then some assumptions made by target model are bad.
%"dev": Deviance (transformed likelihood ratio comparing fit of psychometric function to fit of saturated model)
%"pdev": proportion of the B Deviance values from simulations that were
%        greater than Deviance value of data. The greater the value of pDev,
%        the better the fit.
%        "By somewhat arbitrary convention, researchers agree that the
%        fit is unacceptably poor if pDev is less than 0.05" (Kingdom &
%        Prins, page 73)

%error bars:
%se is std dev. of parametres across the 500 bootstrap reps, which is same
%as standard errors of initial parmeter estimates.
%BootstrapParametric is better than NonParametric when adaptive staircase procedure was used
if doBoot
    se = PAL_PFML_BootstrapParametric(fitTiltLevels, nt, fitParams, freeParams, 500, psychFun);
else
    se = NaN(size(fitParams));
end

thresh = 10^psychFun(fitParams,0.75,'Inverse');

r.fitParams = fitParams;
r.fitThreshold = thresh;
r.fitSuccess = exitflag;
r.fitSuccessTry1 = firstTryWorked;
r.fitLogLikeli = LL;

r.fitRSqr = rSqr;
r.fitDev = dev;
r.fitPDev = pdev;
r.fitParamSE = se;

%%  RTs
r.meanRT = 10.^mean(log10(d.RT));
r.meanCorrRT = 10.^mean(log10(d.RT(d.respCorrect==1)));

