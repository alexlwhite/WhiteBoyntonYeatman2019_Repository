%% function [residuals] = FigZ_LapseRateDevelopmentCurve(T, figSize, opt)
% Analyze lapse rate in White, Boynton & Yeatman (2019)
% This is the basis for results reported verbally in the Supplmenet. 
% It plots individual lambda parameters (1-upper asymptote) as a function
% of age, with a piecewise linear model of development. 
% Saves 1 figure and prints statistics to one text file. 
%
% Inputs : 
% - T: table with informaiton about each subejct and their thresholds in
%   each condition 
% - figSize: a 2x1 vector of figure size in cm 
% - opt: structure with fields: 
%    - fontSize: size of the font in the fiture 
%    - paths: a structure with full directory names for the figure folder
%     (opt.paths.figs) and stats folder (opt.paths.stats) 
%    - nBootstraps: number of bootstrapping repetitions to do
% 
% Outputs: 
% - residuals: a Nx1 vector of residuals from the fitted function
%
% By Alex L. White, University of Washington, 2019


function [residuals] = FigZ_LapseRateDevelopmentCurve(T, figSize, opt)

ageMin = floor(min(T.age));
ageMax = ceil(max(T.age));

xlims = [ageMin-2 ageMax+2];


%% Pull out data
ds = T.lambda;

ages = T.age;
nSubj = length(ages);

ylims = [0 max(ds(:))*1.07];

%% colors of data points, one per condition

datColr = hsv2rgb([0.6 0.5 0.5]);

fitColr = datColr/1.4;

datMarkSz = 10;

%% fit and plot

% piecewise linear model
fitFun = @lineThenFlat;
startParams=[0 0.18 20];
fitTypeName = 'line then flat';
fitParamNames = {'a=slope','b=y-intercept','c=inflection point'};
nParams = 3;
figure; hold on;

%plot raw data, by subject, so no condition ends up on top
for si=1:length(ages)
    plot(ages(si),ds(si),'.','MarkerSize',datMarkSz,'Color',datColr);
end


%% First do a linear regression for comparison
x = ages';
y = ds';

goodpts = find(~isnan(y));
fitx = x(goodpts);
fity = y(goodpts);

design = [fitx' ones(size(fitx))'];
[linearFitParams, linearRSqr] = linearRegressionWithStats(design, fity');

%cross-validated r-squared
xValResids = NaN(size(fitx));
sNums = 1:length(fitx);

for sOut = sNums
    sIs = setdiff(sNums, sOut);
    newBetas = linearRegressionWithStats(design(sIs,:), fity(sIs)');
    yHat = newBetas(1)*fitx(sOut) + newBetas(2);
    xValResids(sOut) = fity(sOut) - yHat;
end

meanB = nanmean(fity);
SSres = sum(xValResids.^2);
SStot = sum((fity - meanB).^2);
linearXValRSqr = 1-SSres/SStot;


%% Then fit the more complicated piecewise linear function and plot best fit:

fitParams = lsqcurvefit(fitFun,startParams,fitx,fity);
fitTote = lineThenFlat(fitParams,fitParams(3)+1);

yhat = fitFun(fitParams,ageMin:ageMax);
plot(ageMin:ageMax,yhat,'-','Color',fitColr,'LineWidth',1.5);

predy = fitFun(fitParams, x);
residuals = y - predy;



%regular RSqr
meanB = nanmean(fity);
SStot = nansum((fity - meanB).^2);
SSres = nansum(residuals.^2);
model2RSqr = 1-SSres/SStot;


%cross-validated r-squared
xValResids = NaN(size(fitx));
for sOut = sNums
    sIs = setdiff(sNums, sOut);
    newBetas = lsqcurvefit(fitFun,startParams,fitx(sIs),fity(sIs));
    yHat = fitFun(newBetas, fitx(sOut));
    xValResids(sOut) = fity(sOut) - yHat;
end

SSres = sum(xValResids.^2);
model2XValRSqr = 1-SSres/SStot;

ylim(ylims);
xlim(xlims);

set(gca,'XTick',10:10:70);
set(gca,'LabelFontSizeMultiplier',1.0);

xlabel('Age');
ylabel('Lambda)');

figTitle = 'FigZ_LapseDevelopCurve.eps';
set(gcf,'color','w','units','centimeters','pos',[5 5 figSize(1) figSize(2)]);
exportfig(gcf,fullfile(opt.paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',opt.fontSize);

%% bootstrap parameter estimates
range95 = [2.5 97.5];
range68 = 100*normcdf([-1 1]);

bootFitParams = NaN(nParams,opt.nBootstraps);
boot95CIs = NaN(nParams,2);

%vector of fit 'asympotes':
bootFitTotes = NaN(1,opt.nBootstraps);

%also linear model
bootLinearFitParams = NaN(2,opt.nBootstraps);
bootLinear95CIs = NaN(2,2);
for bi=1:opt.nBootstraps
    ss = randsample(nSubj, nSubj, 'true');
    
    x = ages(ss)';
    y = ds(ss)';
    
    goodpts = find(~isnan(y));
    fitx = x(goodpts);
    fity = y(goodpts);
    
    %linear model
    [betas] = linearRegressionWithStats([fitx' ones(size(fitx))'], fity');
    bootLinearFitParams(:,bi) = betas';
    
    %more complex model
    fitParams = lsqcurvefit(fitFun,startParams,fitx,fity);
    bootFitParams(:,bi)  = fitParams;
    
    bootFitTotes(bi) = lineThenFlat(fitParams,fitParams(3)+1);
end

%CIs on parameter estimates
bps = squeeze(bootFitParams)';
boot95CIs(:,:) = prctile(bps,range95)';

lbps = squeeze(bootLinearFitParams(:,:))';
bootLinear95CIs(:,:) = prctile(lbps,range95)';

asymptote95CIs = prctile(bootFitTotes', range95)';
asymptote68Is =  prctile(bootFitTotes', range68)';

%% print stats
statsF = fopen(fullfile(opt.paths.stats,'StatsZ_LapseRateDevelopmentCurveFitStats.txt'),'w');
fprintf(statsF,'STATS ON DEVELOPMENTAL EFFECTS ON LAPSE RATES\n');

%print some useful summaries 
lapsesUnder11 = ds(ages<11)'; 
fprintf(statsF,'\n\nMean lapse rate under age 11: %.3f (SEM = %.3f)', mean(lapsesUnder11), standardError(lapsesUnder11));
lapsesOver20 = ds(ages>20)'; 
fprintf(statsF,'\n\nMean lapse rate under age 20: %.3f (SEM = %.3f)', mean(lapsesOver20), standardError(lapsesOver20));

fprintf(statsF,'\nFit type: %s\n\n', fitTypeName);
fprintf(statsF,'Bootstrapping %i repetitions\n',opt.nBootstraps);

paramsToPrint = 1:nParams;

%print basic linear model parameters
fprintf(statsF,'\n==========================================\n');
fprintf(statsF,'Basic linear regression parameters:\n');

linearParamNames = {'slope','intercept'};
for pi=1:2
    fprintf(statsF,'\n\n%s\n', linearParamNames{pi});
    fprintf(statsF,'\nBestFit\t booted95%%CI\t\n');
    
    fprintf(statsF,'%.4f\t [%.4f %.4f]\t', linearFitParams(pi), bootLinear95CIs(pi,1), bootLinear95CIs(pi,2));
    fprintf(statsF,'\n');
end

fprintf(statsF,'\n==========================================\n');
fprintf(statsF,'More complex piecewise linear model parameters:\n');

%print more complex model parameters
for pi=paramsToPrint
    fprintf(statsF,'\n\n%s\n', fitParamNames{pi});
    fprintf(statsF,'\n BestFit\t booted95%%CI\t\n');
    fprintf(statsF,'%.4f\t [%.4f %.4f]', fitParams(pi), boot95CIs(pi,1), boot95CIs(pi,2));
end
fprintf(statsF,'\n');


%Model comparison to simple linear regression
fprintf(statsF,'\n\n==========================================\n');
fprintf(statsF,'\nMODEL FIT QUALITY AND COMPARISON TO SIMPLE LINEAR REGRESSION:\n');
fprintf(statsF,'\nSimpleLinearRSqr \tModel2RegularRSqr \tSimpleLinearXValRSqr \tModel2XValRSqr');
fprintf(statsF,'%.4f\t%.4f\t%.4f\t', linearRSqr, model2RSqr, linearXValRSqr, model2XValRSqr);


fprintf(statsF,'\n\nAsymptote:\n');
fprintf(statsF,'\nBestFit\t 68%%CI\t 95%%CI\t\t\n');
fprintf(statsF,'%.4f\t [%.4f %.4f]\t [%.4f %.4f]\t', fitTote, asymptote68Is(1), asymptote68Is(2),asymptote95CIs(1), asymptote95CIs(2));
fprintf(statsF,'\n');

residuals = residuals';

