%% function residuals = Fig2B_ThresholdCueEffectDevelopmentCurve(T, figSize, fontSize, paths, nBoots)
% Make Figure 2B in White, Boynton & Yeatman (2019)
% Individual cueing effects on thresholds as a function of age in each condition, with a
% piecewise linear model of development.
% Saves 1 figure and prints statistics to one text file.
%
% Inputs :
% - T: table with information about each subejct and their thresholds in
%   each condition
% - figSize: a 2x1 vector of figure size in cm
% - fontSize: size of the font in the fiture
% - paths: a structure with full directory names for the figure folder
%   (paths.figs) and stats folder (paths.stats)
% - nBoots: number of bootstrapping repetitions to do
%
% Outputs:
% - residuals: a Nx1 matrix of residuals from the fitted function, for each
%   of N subjects
% 
% % By Alex L. White, University of Washington, 2019

function residuals = Fig2B_ThresholdCueEffectDevelopmentCurve(T, figSize, fontSize, paths, nBoots)


log10Dat = true;

ageMin = floor(min(T.age));
ageMax = ceil(max(T.age));

xlims = [ageMin-2 ageMax+2];
ylims = [-1.0 1.0];

datMarkSz = 4;

%% Pull out data
ds = [T.thresh_Uncued T.thresh_Cued];
cueLabels = {'Uncued','Cued'};

ages = T.age;
readGroups = T.readingGroup;

% log?
if log10Dat
    ds = log10(ds);
    ylab = 'diff. of log thresholds';

else
    ylab = 'diff. of threhsolds';
end

effects = ds(:,1) - ds(:,2);


%filter any missing data
goodpts = find(~isnan(effects));
x = ages(goodpts);
y = effects(goodpts);
readGroups = readGroups(goodpts);

%% colors for plot

effectColr = hsv2rgb([0.5 0.8 0.6]);
fitColr = effectColr*0.8;

%fill colors for individual subject points on scatterplot:
typFillColr = effectColr;
bothColrs = cat(3,ones(size(effectColr)), typFillColr);
neitherFillColr = mean(bothColrs,3);
dysFillColr = ones(size(effectColr)); %mean(cat(3,ones(size(effectColr)), neitherFillColr),3);


figure; hold on;

%% plot raw data
plot(xlims,[0 0],'k-');
for si=1:length(x)
    switch readGroups{si}
        case 'Dyslexic'
            fcolr = dysFillColr;
            marker = 'o';
            lineWidth = 1;
        case 'Typical'
            fcolr = typFillColr;
            marker = 'o';
            lineWidth = 1;
        case 'Neither'
            fcolr = neitherFillColr;
            marker = 'o';
            lineWidth = 0.5;
    end
    
    plot(x(si),y(si),marker,'MarkerSize',datMarkSz,'MarkerEdgeColor',effectColr, 'MarkerFaceColor',fcolr,'LineWidth',lineWidth);
    
end


%% Simple linear regression
design = [x ones(size(x))];
[betas, rSqr] = linearRegressionWithStats(design, y);

linearFitParams = betas';
linearRSqr = rSqr;

%cross-validated r-squared
xValResids = NaN(size(x));
sNums = 1:length(x);

for sOut = sNums
    sIs = setdiff(sNums, sOut);
    newBetas = linearRegressionWithStats(design(sIs,:), y(sIs));
    yHat = newBetas(1)*x(sOut) + newBetas(2);
    xValResids(sOut) = y(sOut) - yHat;
end

meanB = nanmean(y);
SSres = sum(xValResids.^2);
SStot = sum((y - meanB).^2);
linearXValRSqr = 1-SSres/SStot;

%% fit the piecewise linear model
fitFun = @lineThenFlat;
startParams=[0 0.01 20]; %slope y-intercept infleciton

fitParams = lsqcurvefit(fitFun,startParams,x,y);

% plot the fit
yhat = fitFun(fitParams,ageMin:ageMax);
plot(ageMin:ageMax,yhat,'-','Color',fitColr,'LineWidth',1.5);

%compute residuals
predy = fitFun(fitParams, x);
resids = y - predy;

residuals = NaN(size(ds,1),1);
residuals(goodpts) = resids;

%regular RSqr
meanB = nanmean(y);
SStot = nansum((y - meanB).^2);
SSres = nansum(resids.^2);
model2RSqr = 1-SSres/SStot;


%cross-validated R2
xValResids = NaN(size(x));
for sOut = sNums
    sIs = setdiff(sNums, sOut);
    newBetas = lsqcurvefit(fitFun,startParams,x(sIs),y(sIs));
    yHat = fitFun(newBetas, x(sOut));
    xValResids(sOut) = y(sOut) - yHat;
end

SSres = sum(xValResids.^2);
model2XValRSqr = 1-SSres/SStot;


%finish the figure: 
ylim(ylims);
xlim(xlims);

set(gca,'XTick',10:10:70,'YTick',-1:0.25:1);
set(gca,'LabelFontSizeMultiplier',1.0);

xlabel('Age');
ylabel(ylab);


set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);
figTitle = sprintf('Fig2B_ThresholdCueEffectDevelopment.eps');

exportfig(gcf,fullfile(paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',fontSize);



%% bootstrapping
if nBoots>0
    
    bootLinearFitParams = NaN(nBoots,2);
    bootParams = NaN(nBoots, length(fitParams));
    nSubj = length(x);
    for bi=1:nBoots
        ss = randsample(nSubj, nSubj, 'true');
        
        %simple linear model
        [betas] = linearRegressionWithStats([x(ss) ones(size(ss))], y(ss));
        bootLinearFitParams(bi,:) = betas';
        
        %piecewise linear model
        bootParams(bi,:) = lsqcurvefit(fitFun,startParams,x(ss),y(ss));
        
    end
end



%% print stats

statsF = fopen(fullfile(paths.stats,'Stats2B_ThresholdCueEffectDevelopmentCurve.txt'),'w');

fprintf(statsF,'Fitting the ''line then flat'' model to the threshold cueing effect: %s - %s\n',cueLabels{1},cueLabels{2});

if log10Dat
    fprintf(statsF,'Cueing effect is difference in log thresholds.\n');
else
    fprintf(statsF,'Cueing effect is difference in raw thresholds.\n');
end


%print basic linear model parameters
fprintf(statsF,'\n------------------------------------------\n');
fprintf(statsF,'Basic linear regression parameters:\n');

range95 = [2.5 97.5];

bootLinear95CIs = prctile(bootLinearFitParams,range95)';

linearParamNames = {'slope','intercept'};
for pi=1:2
    fprintf(statsF,'\n\n%s\n', linearParamNames{pi});
    fprintf(statsF,'\nBestFit\t booted95%%CI\t\n');
    fprintf(statsF,'%.4f\t [%.4f %.4f]\t', linearFitParams(pi), bootLinear95CIs(pi,1), bootLinear95CIs(pi,2));
    fprintf(statsF,'\n');
end

fprintf(statsF,'\n------------------------------------------\n');
fprintf(statsF,'More complex piecewise linear model parameters:\n');


fitParamNames = {'slope','intercept','inflection'};

fprintf(statsF,'\n');
for yi=1:size(fitParams,2)
    fprintf(statsF,'\n%s:',fitParamNames{yi});
    
    fprintf(statsF,'\n\ttrue fit:\t%.4f',fitParams(yi));
    bootCI = prctile(bootParams(:,yi),[2.5 97.5]);
    fprintf(statsF,'\n\tBootstrapped 95%% CI: [%.3f %.3f]\n', bootCI(1), bootCI(2));
    
    
end

fprintf(statsF,'\n------------------------------------------\n');
fprintf(statsF,'\nMODEL FIT QUALITY AND COMPARISON TO SIMPLE LINEAR REGRESSION:\n');
fprintf(statsF,'\nSimpleLinearRSqr \tModel2RegularRSqr \tSimpleLinearXValRSqr \tModel2XValRSqr\n');
fprintf(statsF,'%.4f\t%.4f\t', linearRSqr, model2RSqr, linearXValRSqr, model2XValRSqr);



