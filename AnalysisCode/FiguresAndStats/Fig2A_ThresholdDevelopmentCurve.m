%% function [residuals, condLabelShort] = Fig2A_ThresholdDevelopmentCurve(T, figSize, opt)
% Make Figure 2A in White, Boynton & Yeatman (2019)
% Individual thresholds as a function of age in each condition, with a
% piecewise linear model of development. 
% Saves 1 figure and prints statistics to one text file. 
%
% Inputs : 
% - T: table with information about each subject and their thresholds in
%   each condition 
% - figSize: a 2x1 vector of figure size in cm 
% - opt: structure with fields: 
%   - fontSize: size of the font in the figure 
%   - paths: a structure with full directory names for the figure folder
%   (paths.figs) and stats folder (paths.stats) 
%   - nBootstraps: number of bootstrapping repetitions to do
% 
% Outputs: 
% - residuals: a Nx3 matrix of residuals from the fitted functions and each
%   of the N subjects' true thresholds, in each of 3 conditions 
% - condLabelShort: a 1x3 cell array of labels for the 3 columns in residuals 
% 
% by Alex L. White, University of Washington, 2019

function [residuals, condLabelShort] = Fig2A_ThresholdDevelopmentCurve(T, figSize, opt)

log10Dat = true;

ageMin = floor(min(T.age));
ageMax = ceil(max(T.age));

xlims = [ageMin-2 ageMax+2];
datMarkSz = 4;


%% Pull out data
ds = [T.thresh_Uncued T.thresh_Cued T.thresh_SingleStim];
condLabels = {'Uncued','Cued','Single Stim.'};
condLabelShort = {'Uncued','Cued','SingleStim'};
nCueConds = size(ds,2);

ages = T.age;
readGroups = T.readingGroup;
nSubj = length(ages);

% log?
if log10Dat
    minT = min(ds(:));
    ylims = [log10(minT*0.75) max(log10(ds(:)))*1.07];
    ds = log10(ds);
else
    ylims = [0 max(ds(:))*1.07];
end


%% colors of data points, one per condition, with differing fill for each reading group
cueHues = [0.6 0.4 0.12 0.3];
cueSats = [0.5 0.6 0.7 0.4];
cueVals = [0.5 0.6 1 0.8];

edgeColrs = hsv2rgb([cueHues' cueSats' cueVals']);

%different feill colors for each reading bgroup:
dysFillColrs = ones(size(edgeColrs));
typFillColrs = edgeColrs;
bothColrs = cat(3, dysFillColrs, typFillColrs);
neitherFillColrs = mean(bothColrs,3);

%colors for the line fits: 
fitSats = 0.4*cueSats;
fitVals = 1.3*cueVals;
fitVals(fitVals>1) = 1;

fitColors = hsv2rgb([cueHues' fitSats' fitVals'])/1.4;

%% plot raw data 

figure; hold on;

%plot raw data, by subject, so no condition ends up on top
hsr = zeros(1,nCueConds);
for si=1:length(ages)
    for cueI=1:nCueConds
        x = ages(si);
        y = ds(si,cueI);
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
            hsr(cueI) = newhandl;
        end
    end
end

%% fit the data 
%piecewise-linear model:
fitFun = @lineThenFlat;
if log10Dat
    startParams=[0 1.3 20];
else
    startParams=[0 20 20];
end
fitTypeName = 'line then flat';
fitParamNames = {'a=slope','b=y-intercept','c=inflection point'};
nParams = 3;


hs = zeros(1,nCueConds);
allFitParams = NaN(nCueConds,3);

%vector of fit 'asympotes':
fitTotes = zeros(1,nCueConds);

residuals = NaN(nSubj, nCueConds);

linearFitParams = NaN(nCueConds,2);
linearRSqr = NaN(1,nCueConds);
linearXValRSqr  = NaN(1,nCueConds);
model2RSqr      = NaN(1,nCueConds);
model2XValRSqr = NaN(1,nCueConds);

%x-value: ages 
x = ages';

for cueI = 1:nCueConds
    y = ds(:,cueI)';
    
    goodpts = find(~isnan(y));
    fitx = x(goodpts);
    fity = y(goodpts);
    
    %% First do a simple linear regression for comparison
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
    
    
    %% Then fit the piecewise linear model and plot best fit:
    
    fitParams = lsqcurvefit(fitFun,startParams,fitx,fity);
    allFitParams(cueI,:) = fitParams;
    
    %compute the asymptote: the level of the function just after the inflection point
    fitTotes(cueI) = lineThenFlat(fitParams,fitParams(3)+1);
  
    %plot the best fit
    yhat = fitFun(fitParams,ageMin:ageMax);
    hs(cueI) = plot(ageMin:ageMax,yhat,'-','Color',fitColors(cueI,:),'LineWidth',1.5);

    %compute residuals
    predy = fitFun(fitParams, x);
    residuals(:,cueI) = y - predy;
    
    %regular RSqr
    meanB = nanmean(fity);
    SStot = nansum((fity - meanB).^2);
    SSres = nansum(residuals(:,cueI).^2);
    model2RSqr(cueI) = 1-SSres/SStot;
    
    
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

set(gca,'XTick',10:10:70);
set(gca,'LabelFontSizeMultiplier',1.0);

if log10Dat
    yticks = get(gca,'YTick');
    newticks = 10.^yticks;
    ylabs = cell(1,length(yticks));
    for yti=1:length(yticks)
        ylabs{yti} = sprintf('%.1f',newticks(yti));
    end
    set(gca,'YTickLabels',ylabs);
end

xlabel('Age');
ylabel('Threshold (deg)');
legend(hsr,condLabels,'Location','NorthEast');

figTitle = 'Fig2A_ThreshDevelopCurve.eps';
set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);
exportfig(gcf,fullfile(opt.paths.figs,figTitle),'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',opt.fontSize);

%% bootstrap parameter estimates
if opt.nBootstraps>0
    range95 = [2.5 97.5];
    range68 = 100*normcdf([-1 1]);
    
    bootFitParams = NaN(nCueConds,nParams,opt.nBootstraps);
    %vector of fit 'asympotes':
    bootFitTotes = NaN(nCueConds,opt.nBootstraps);
    
    boot95CIs = NaN(nCueConds,nParams,2);
    boot68CIs = NaN(nCueConds,nParams,2);
    
    %also the simple linear model
    bootLinearFitParams = NaN(nCueConds,2,opt.nBootstraps);
    bootLinear95CIs = NaN(nCueConds,2,2);
    
    %comparisons between conditions 
    condComps = [1 2; 1 3; 2 3];
    nComps = size(condComps,1);
    
    comp95CIs = NaN(nComps,nParams,2);
    
    toteComp95CIs = NaN(nComps,2);
    
    for bi=1:opt.nBootstraps
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
            bootFitTotes(cueI,bi) = lineThenFlat(fitParams,fitParams(3)+1);
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
    statsF = fopen(fullfile(opt.paths.stats,'Stats2A_ThresholdDevelopmentCurves.txt'),'w');
    fprintf(statsF,'STATS ON DEVELOPMENTAL EFFECTS ON ORIENTATION DISCRIMINATION THRESHOLDS\n');
    fprintf(statsF,'\n');
    
    if log10Dat
        fprintf(statsF,'\nRan analysis on log10 thresholds\n');
    else
        fprintf(statsF,'\nRan analysis on thresholds not log-transformed\n');
    end
    fprintf(statsF,'\nFit type: %s\n\n', fitTypeName);
    fprintf(statsF,'Bootstrapping %i repetitions\n',opt.nBootstraps);
    
    
    for unlog = [0 1]
        if unlog
            fprintf(statsF,'\n-------------------------------------------\n');
            fprintf(statsF,'Now stats un-logged (10^s) so in units of degrees:\n');
            fprintf(statsF,'\n-------------------------------------------\n');
            paramsToPrint = 1:2;
            allFitParams = 10.^allFitParams;
            boot68CIs = 10.^boot68CIs;
            boot95CIs = 10.^boot95CIs;
            
            linearFitParams = 10.^linearFitParams;
            bootLinear95CIs = 10.^bootLinear95CIs;
            
            fitTotes = 10.^fitTotes;
            asymptote68Is = 10.^asymptote68Is;
            asymptote95CIs = 10.^asymptote95CIs;
            
        else
            paramsToPrint = 1:nParams;
        end
        
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
        fprintf(statsF,'More complex piecewise linear model parameters:\n');
        
        %print more complex model parameters
        for pi=paramsToPrint
            fprintf(statsF,'\n\n%s\n', fitParamNames{pi});
            fprintf(statsF,'\nCondition\t BestFit\t booted95%%CI\t\n');
            for ci=1:nCueConds
                fprintf(statsF,'\n%s\t', condLabels{ci});
                fprintf(statsF,'%.4f\t [%.4f %.4f]\t', allFitParams(ci,pi), boot95CIs(ci,pi,1), boot95CIs(ci,pi,2));
            end
            fprintf(statsF,'\n');
            if ~unlog
                %stats on differences
                for compi=1:nComps
                    fprintf(statsF,'\nComparison %s - %s\n', condLabels{condComps(compi,1)}, condLabels{condComps(compi,2)});
                    fprintf(statsF,'Best-fitting difference:\t %.4f\n', allFitParams(condComps(compi,1),pi) - allFitParams(condComps(compi,2),pi));
                    fprintf(statsF,'Bootstrapped 95%% CI:\t [%.4f %.4f]\n', comp95CIs(compi,pi,1),comp95CIs(compi,pi,2));
                end
            end
        end
        
        
        %Model comparison to simple linear regression
        if ~unlog
            fprintf(statsF,'\n\n==========================================\n');
            fprintf(statsF,'\nMODEL FIT QUALITY AND COMPARISON TO SIMPLE LINEAR REGRESSION:\n');
            fprintf(statsF,'\nCondition \tSimpleLinearRSqr \tModel2RegularRSqr \tSimpleLinearXValRSqr \tModel2XValRSqr');
            for ci=1:nCueConds
                fprintf(statsF,'\n%s\t', condLabels{ci});
                fprintf(statsF,'%.4f\t%.4f\t%.4f\t', linearRSqr(ci), model2RSqr(ci), linearXValRSqr(ci), model2XValRSqr(ci));
            end
        end
        
        
        fprintf(statsF,'\n\nAsymptote:\n');
        fprintf(statsF,'\nCondition\t BestFit\t 68%%CI\t 95%%CI\t\t\n');
        for ci=1:nCueConds
            fprintf(statsF,'\n%s\t', condLabels{ci});
            fprintf(statsF,'%.4f\t [%.4f %.4f]\t [%.4f %.4f]\t', fitTotes(ci), asymptote68Is(ci,1), asymptote68Is(ci,2),asymptote95CIs(ci,1), asymptote95CIs(ci,2));
        end
        fprintf(statsF,'\n');
        
        if ~unlog
            %stats on differences
            for compi=1:nComps
                fprintf(statsF,'\nComparision %s - %s\n', condLabels{condComps(compi,1)}, condLabels{condComps(compi,2)});
                fprintf(statsF,'Bootstrapped 95%% CI:\t [%.4f %.4f]\n', toteComp95CIs(compi,1),toteComp95CIs(compi,2));
            end
            fprintf(statsF,'\n');
        end
    end
end

%% finally, for adults, compute percent reduction from cued to single stimulus 
minAge = 20;
goodS = T.age<=minAge & ~isnan(T.thresh_SingleStim); 
someThreshs = [T.thresh_Uncued T.thresh_Cued T.thresh_SingleStim]; 
someThreshs = someThreshs(goodS,:);

if log10Dat
    someThreshs = log10(someThreshs); 
end

cueBenefitPropOfMax = (someThreshs(:,1) - someThreshs(:,2)) ./ (someThreshs(:,1) - someThreshs(:,3));

fprintf(statsF,'\n\nFor participants >= age %i, (uncued - cued) / (uncued - single):\n', minAge);
fprintf(statsF,'\tmean = %.4f, median = %.4f, SEM = %.4f\n', mean(cueBenefitPropOfMax), median(cueBenefitPropOfMax), standardError(cueBenefitPropOfMax,1));

%or, average first! 
meanTs = mean(someThreshs,1);
meanCueBenefitPropOfMax = (meanTs(1) - meanTs(2)) ./ (meanTs(1) - meanTs(3));
fprintf(statsF,'\tAveraging thresholds over subjects first:  %.3f\n\n', meanCueBenefitPropOfMax);


