%% function kernelWidth = pairedSampleDensityPlot(data, opt)
% This function plots two smoothed distributions next to each other. 
% The distributions are arranged vertically. Smoothing is done with
% Matlab's ksdensity and a normal kernel. 
% 
% Inputs: 
% - data: a 1x2 cell array of vectors of data from the two samples. 
% - opt: a structure with various options. The first set refer to the
%  width of the Gaussian smoothing kernel. That is set to be the same for
%  both conditions. You can  set the kernel width by setting
%  opt.fixKernelWidth = true, and then setting opt.fixedKernelWidth to the
%  value you want. Or, if opt.fixKernelWidth = false you can let ksdensity
%  choose the best width for both data sets, then take the average, and
%  then multiple by some scale factor opt.kernelWidthFactor. 
%  Other parameters in opt: 
%  - midlineX: the horizontal x-value of the midline between the two
%  distributions. 
%  - fillColors: a 2x3 matrix of RGB color values for the fill of each distribution, with 1 row for each conditon 
%  - edgeColors: a 2x3 matrix of RGB color vlaues for the edge color of each distribution
%  - fillLineWidth: line width for the distributions 
%  - plotMean: whether or not to plot the mean of each distribution as a
%    horizontal line on top of the smoothed distribution
%  - opt.meanLineWidth: width of the line showing the mean 
%  - labelXVals: Boolean, whether or not to have x-tick values labeled.
%  - doXLabel: whether to have the x-axis labeled "Probability density"
%  - doLegend: whether to add a legend 
%  - legendLabs: 1x2 cell array for the legend labels 
%  - legendLoc: character string, the location of the legend in the plot
%  (e.g., 'NorthWest') 
%
% Output: 
% - kernelWidth: the kernel width used. 
% 
% By Alex L. White, University of Washington, 2019

function kernelWidth = pairedSampleDensityPlot(data, opt)

if opt.fixKernelWidth
    kernelWidth = opt.fixedKernelWidth;
else
    %first let ksdensity find optimal kernel widths for each group
    optKernelWidths = zeros(1,2);
    for jj = 1:2
        [~, ~, optKernelWidths(jj)] = ksdensity(data{jj},'kernel','normal');
    end
    
    %then set kernel width to some fraction of the average
    kernelWidth = mean(optKernelWidths)*opt.kernelWidthFactor;
    
end

legendHs = zeros(1,2);
maxXs = zeros(1,2);
for jj = 1:2
    [dens, yvals] = ksdensity(data{jj},'kernel','normal','Bandwidth',kernelWidth);
    
    if jj==1
        xvals = opt.midlineX - dens;
    else
        xvals = opt.midlineX + dens;
    end
    
    legendHs(jj) = fill(xvals,yvals,opt.fillColors(jj,:),'EdgeColor',opt.edgeColors(jj,:),'LineWidth',opt.fillLineWidth);
    %fill again in opposite direction to avoid weird lines
    fill(fliplr(xvals),fliplr(yvals),opt.fillColors(jj,:),'EdgeColor',opt.edgeColors(jj,:),'LineWidth',opt.fillLineWidth);
    
    %add mean
    meanY = nanmean(data{jj});
    
    %find matching x-value (probability density)
    ydiffs = abs(yvals - meanY);
    minDiff = min(ydiffs);
    diffI = find(ydiffs==minDiff);
    diffI = diffI(1);
    meanX = xvals(diffI);
    
    if opt.plotMean
        plot([opt.midlineX meanX], [meanY meanY], '-','Color',opt.meanColors(jj,:), 'LineWidth',opt.meanLineWidth);
    end
    
    maxXs(jj) = max(abs(xvals));
    
end

maxDev = max(maxXs) - opt.midlineX;
xlims = opt.midlineX + [-1 1]*1.1*maxDev;
xlim(xlims);

%add 0 line
plot(xlims,[0 0],'k-');

if opt.labelXVals
    
    xtickvals = round(xlims(1)):1:round(xlims(2));
    set(gca,'XTick',xtickvals);
    
    %set the negative x-tick-labels to positive
    xTickLabs = cell(1,length(xtickvals));
    for xti=1:length(xtickvals)
        if (xtickvals(xti)-round(xtickvals(xti))) == 0
            xTickLabs{xti} = sprintf('%i',abs(xtickvals(xti)));
        elseif abs*(xtickvals(xti))<1
            xTickLabs{xti} = sprintf('%.2f',abs(xtickvals(xti)));
        else
            xTickLabs{xti} = sprintf('%.1f',abs(xtickvals(xti)));
        end
    end
    set(gca,'XTickLabel',xTickLabs);
    
else
    xtickvals = linspace(xlims(1), xlims(2), 5);
    set(gca,'XTick',xtickvals,'XTickLabel',{});
end

if opt.doXLabel
    xlabel('Probability density');
end

if opt.doLegend
    legend(legendHs,opt.legendLabs,'Location',opt.legendLoc);
end

