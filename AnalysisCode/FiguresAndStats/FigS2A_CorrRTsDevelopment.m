%% function[residuals, condLabelShort] = FigS2A_CorrRTsDevelopment(T, figSize, fontSize, paths, nBoots)
% Make Figure S2A in White, Boynton & Yeatman (2019)
% Individual mean correct RTs as a function of age in each condition, with a
% j-shaped model of development. 
% Saves 1 figure and prints statistics to one text file. 
%
% Inputs : 
% - T: table with information about each subject and their thresholds in
%   each condition 
% - figSize: a 2x1 vector of figure size in cm 
% - fontSize: size of the font in the figure 
% - paths: a structure with full directory names for the figure folder
%   (paths.figs) and stats folder (paths.stats) 
% - nBoots: number of bootstrapping repetitions to do
% 
% Outputs: 
% - residuals: a Nx3 matrix of residuals from the fitted functions and each
%   of the N subjects' true RTs, in each of 3 conditions 
% - condLabelShort: a 1x3 cell array of labels for the 3 columns in residuals 
% 
% by Alex L. White, University of Washington, 2019

function [residuals, condLabelShort] = FigS2A_CorrRTsDevelopment(T, figSize, fontSize, paths, nBoots)


ageMin = floor(min(T.age));
ageMax = ceil(max(T.age));

xlims = [ageMin-2 ageMax+2];

devFitType = 3; % 1=line then flat, 2= two lines joined; 3 =j-shaped function;


%% Pull out data
ds = 1000*[T.corrRT_Uncued T.corrRT_Cued T.corrRT_SingleStim T.corrRT_SmallCue];
condLabels = {'Uncued','Cued','Single Stim.','Small Cue'};
condLabelShort = {'Uncued','Cued','SingleStim','SmallCue'};
nCueConds = size(ds,2);

cueCondsToPlot = 1:3;

ages = T.age;
nSubj = length(ages);
readGroups = T.readingGroup;


%% plot choices and colors of data points, one per condition, with differing fill for each reading group

cueHues = [0.6 0.4 0.12 0.3];
cueSats = [0.5 0.6 0.7 0.4];
cueVals = [0.5 0.6 1 0.8];

edgeColrs = hsv2rgb([cueHues' cueSats' cueVals']);

dysFillColrs = ones(size(edgeColrs));
typFillColrs = edgeColrs;
bothColrs = cat(3, ones(size(edgeColrs)), typFillColrs);
neitherFillColrs = mean(bothColrs,3);

fillSats = 0.4*cueSats;
fillVals = 1.3*cueVals;
fillVals(fillVals>1) = 1;

fillColors = hsv2rgb([cueHues' fillSats' fillVals']);
fitColors = fillColors/1.4;


datMarkSz = 4;

ylims = [0 max(ds(:))*1.1];

if ylims(2)<1800
    ylims(2) = 1800;
    yticks = 0:300:1800;
end

%% fit and plot

switch devFitType
    case 1 %line then flat
        fitFun = @lineThenFlat;
        startParams=[0 20 20];
        fitTypeName = 'line then flat';
        fitParamNames = {'a=slope','b=y-intercept','c=inflection point'};
        nParams = 3;
    case 2 %two lines joined at inflection point
        fitFun = @twoLinesJoined;
        startParams = [-50 2000 20 20];
        fitTypeName = 'two lines joined';
        fitParamNames = {'a1=slope1','b1=y-intercept1','c=inflection point','a2=slope2'};
        nParams = 4;
        
    case 3 %j-function
        fitFun = @jcurve;
        startParams = [2 0.5  0.3 0.01 1000];
        fitTypeName = 'j-shaped function';
        fitParamNames = {'a1','a2','b1','b2','scaleFactor'};
        nParams = 5;
end

hs = zeros(1,length(cueCondsToPlot));
hsr = zeros(1,length(cueCondsToPlot));
allFitParams = NaN(nCueConds,nParams);
%vector of fit 'asympotes':
fitTotes = zeros(1,nCueConds);


figure; hold on;

%plot raw data, by subject, so no condition ends up on top
for si=1:length(ages)
    for cii=1:length(cueCondsToPlot)
        cueI=cueCondsToPlot(cii);
        x = ages(si);
        y=ds(si,cueI);
        switch readGroups{si}
            case 'Dyslexic'
                fcolr = dysFillColrs(cueI,:);
                marker = 'o';
                lineWidth = 1;
                
            case 'Typical'
                fcolr = typFillColrs(cueI,:);
                marker = 'o';
                lineWidth = 1;
                
            case 'Neither'
                fcolr = neitherFillColrs(cueI,:);
                marker = 'o';
                lineWidth = 0.5;
                
        end
        newhandl = plot(x,y,marker,'MarkerSize',datMarkSz,'MarkerEdgeColor',edgeColrs(cueI,:), 'MarkerFaceColor',fcolr,'LineWidth',lineWidth);
        
        if strcmp(readGroups{si}, 'Typical')
            hsr(cii) = newhandl;
        end
    end
end

residuals = NaN(nSubj, nCueConds);

linearFitParams = NaN(nCueConds,2);
linearRSqr = NaN(1,nCueConds);
linearXValRSqr  = NaN(1,nCueConds);
model2RSqr      = NaN(1,nCueConds);
model2XValRSqr = NaN(1,nCueConds);

x = ages';

for cueI = 1:nCueConds
    cii = find(cueCondsToPlot==cueI);
    y = ds(:,cueI)';
    
    goodpts = find(~isnan(y));
    fitx = x(goodpts);
    fity = y(goodpts);
    
    %% First do a linear regression for comparison
    design = [fitx' ones(size(fitx))'];
    [betas, rSqr] = linearRegressionWithStats(design, fity');
    
    linearFitParams(cueI,:) = betas';
    linearRSqr(cueI) = rSqr;
    
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
    linearXValRSqr(cueI) = 1-SSres/SStot;
    
    
    %% Then fit the chosen more complicated function and plot best fit:
    
    fitParams = lsqcurvefit(fitFun,startParams,fitx,fity);
    allFitParams(cueI,:) = fitParams;
    
    yhat = fitFun(fitParams,ageMin:ageMax);
    
    predy = fitFun(fitParams, x);
    residuals(:,cueI) = y - predy;
    
    %regular RSqr
    meanB = nanmean(fity);
    SStot = nansum((fity - meanB).^2);
    SSres = nansum(residuals(:,cueI).^2);
    
    model2RSqr(cueI) = 1-SSres/SStot;
    
    if any(cueCondsToPlot==cueI)
        hs(cii) = plot(ageMin:ageMax,yhat,'-','Color',fitColors(cueI,:),'LineWidth',1.5);
    end
    
    
    if devFitType==1
        fitTotes(cueI) = lineThenFlat(fitParams,fitParams(3)+1);
    end
    
    %cross-validated r-squared
    xValResids = NaN(size(fitx));
    
    for sOut = sNums
        sIs = setdiff(sNums, sOut);
        newBetas = lsqcurvefit(fitFun,startParams,fitx(sIs),fity(sIs));
        yHat = fitFun(newBetas, fitx(sOut));
        xValResids(sOut) = fity(sOut) - yHat;
    end
    
    SSres = sum(xValResids.^2);
    model2XValRSqr(cueI) = 1-SSres/SStot;
    
end


ylim(ylims);
xlim(xlims);

set(gca,'XTick',10:10:70,'YTick',yticks);
set(gca,'LabelFontSizeMultiplier',1.0);

xlabel('Age');
ylabel('Mean correct RT (ms)');
legend(hsr,condLabels(cueCondsToPlot),'Location','NorthEast');

figTitle = 'FigS2A_CorrRT_DevelopCurve.eps';
set(gcf,'color','w','units','centimeters','pos',[5 5 figSize(1) figSize(2)]);
exportfig(gcf,fullfile(paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',fontSize);

%% bootstrap parameter estimates
range95 = [2.5 97.5];
range68 = 100*normcdf([-1 1]);

bootFitParams = NaN(nCueConds,nParams,nBoots);
%vector of fit 'asympotes':
bootFitTotes = NaN(nCueConds,nBoots);

boot95CIs = NaN(nCueConds,nParams,2);
boot68CIs = NaN(nCueConds,nParams,2);

%also linear model
bootLinearFitParams = NaN(nCueConds,2,nBoots);
bootLinear95CIs = NaN(nCueConds,2,2);

%comparisons
condComps = [1 2; 1 3; 2 3];
nComps = size(condComps,1);

comp95CIs = NaN(nComps,nParams,2);

toteComp95CIs = NaN(nComps,2);


for bi=1:nBoots
    ss = randsample(nSubj, nSubj, 'true');
    
    for cueI = 1:nCueConds
        x = ages(ss)';
        y = ds(ss,cueI)';
        
        goodpts = find(~isnan(y));
        fitx = x(goodpts);
        fity = y(goodpts);
        
        %linear model
        [betas] = linearRegressionWithStats([fitx' ones(size(fitx))'], fity');
        bootLinearFitParams(cueI,:,bi) = betas';
        
        %more complex model
        fitParams = lsqcurvefit(fitFun,startParams,fitx,fity);
        bootFitParams(cueI,:,bi)  = fitParams;
        
        if devFitType==1
            bootFitTotes(cueI,bi) = fitParams(3);
        elseif devFitType==2
            bootFitTotes(cueI,bi) = lineThenFlat(fitParams,fitParams(3)+1);
        end
    end
end

%CIs on parameter estimates
for ci=1:nCueConds
    bps = squeeze(bootFitParams(ci,:,:))';
    boot95CIs(ci,:,:) = prctile(bps,range95)';
    boot68CIs(ci,:,:) = prctile(bps,range68)';
    
    lbps = squeeze(bootLinearFitParams(ci,:,:))';
    bootLinear95CIs(ci,:,:) = prctile(lbps,range95)';
end

asymptote95CIs = prctile(bootFitTotes', range95)';
asymptote68Is =  prctile(bootFitTotes', range68)';

%CIs on differences across conditions
for compi=1:nComps
    bootDiffs = squeeze(bootFitParams(condComps(compi,1),:,:) - bootFitParams(condComps(compi,2),:,:));
    bootDiffs = bootDiffs';
    comp95CIs(compi,:,:) = prctile(bootDiffs,range95)';
    
    toteDiffs = squeeze(bootFitTotes(condComps(compi,1),:) - bootFitTotes(condComps(compi,2),:));
    toteComp95CIs(compi,:) = prctile(toteDiffs,range95);
end


%% print stats
statsF = fopen(fullfile(paths.stats,'StatsS2A_CorrRT_Development.txt'),'w');
fprintf(statsF,'STATS ON DEVELOPMENTAL EFFECTS ON MEAN CORRECT RTs\n');

fprintf(statsF,'\nFit type: %s\n\n', fitTypeName);
fprintf(statsF,'Bootstrapping %i repetitions\n',nBoots);



paramsToPrint = 1:nParams;

%print basic linear model parameters
fprintf(statsF,'\n==========================================\n');
fprintf(statsF,'Basic linear regression parameters:\n');

linearParamNames = {'slope','intercept'};
for pi=1:2
    fprintf(statsF,'\n\n%s\n', linearParamNames{pi});
    fprintf(statsF,'\nCondition\t BestFit\t booted95%%CI\t\n');
    for ci=1:nCueConds
        fprintf(statsF,'\n%s\t', condLabels{ci});
        fprintf(statsF,'%.4f\t [%.4f %.4f]\t', linearFitParams(ci,pi), bootLinear95CIs(ci,pi,1), bootLinear95CIs(ci,pi,2));
    end
    fprintf(statsF,'\n');
end

fprintf(statsF,'\n==========================================\n');
if devFitType==1
    fprintf(statsF,'More complex piecewise linear model parameters:\n');
elseif devFitType==2
    fprintf(statsF,'More complex piecewise two-line model parameters:\n');
    
elseif devFitType==3
    fprintf(statsF,'More complex j-shaped model parameters:\n');
end

%print more complex model parameters
for pi=paramsToPrint
    fprintf(statsF,'\n\n%s\n', fitParamNames{pi});
    fprintf(statsF,'\nCondition\t BestFit\t booted95%%CI\n');
    for ci=1:nCueConds
        fprintf(statsF,'\n%s\t', condLabels{ci});
        fprintf(statsF,'%.4f\t [%.4f %.4f]\t', allFitParams(ci,pi), boot95CIs(ci,pi,1), boot95CIs(ci,pi,2));
    end
    fprintf(statsF,'\n');
    %stats on differences
    for compi=1:nComps
        fprintf(statsF,'\nComparison %s - %s\n', condLabels{condComps(compi,1)}, condLabels{condComps(compi,2)});
        fprintf(statsF,'Best-fitting difference:\t %.4f\n', allFitParams(condComps(compi,1),pi) - allFitParams(condComps(compi,2),pi));
        fprintf(statsF,'Bootstrapped 95%% CI:\t [%.4f %.4f]\n', comp95CIs(compi,pi,1),comp95CIs(compi,pi,2));
    end
end

%Model comparison to simple linear regression
fprintf(statsF,'\n\n==========================================\n');
fprintf(statsF,'\nMODEL FIT QUALITY AND COMPARISON TO SIMPLE LINEAR REGRESSION:\n');
fprintf(statsF,'\nCondition \tSimpleLinearRSqr \tModel2RegularRSqr \tSimpleLinearXValRSqr \tModel2XValRSqr');
for ci=1:nCueConds
    fprintf(statsF,'\n%s\t', condLabels{ci});
    fprintf(statsF,'%.4f\t%.4f\t%.4f\t', linearRSqr(ci), model2RSqr(ci), linearXValRSqr(ci), model2XValRSqr(ci));
end


