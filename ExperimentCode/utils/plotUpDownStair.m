function [] = plotUpDownStaircaseRes(ss,stairParams)

hold on;


is = ss.x;

lastRevsToCount = max(ss.reversal)-stairParams.revsToIgnore;
if lastRevsToCount>=stairParams.minRevsForThresh
    thresh = PAL_AMUD_analyzeUD(ss,'reversals',lastRevsToCount);
else
    ntsStair = length(ss.response);
    lastTrlsToCount = ntsStair-stairParams.trialsIgnoredThresh;
    if lastTrlsToCount<1, lastTrlsToCount=ntsStair; end
    thresh = PAL_AMUD_analyzeUD(ss,'trials',lastTrlsToCount);
end

if stairParams.inLog10
    is = 10.^is; 
    thresh = 10.^thresh;
end

nts = length(is);

plot(1:nts,is,'b-');

corTrls = find(ss.response);
corH = plot(corTrls, is(corTrls), 'g.','MarkerSize',10);

incTrls = find(~ss.response);
incH = plot(incTrls,is(incTrls),'r.','MarkerSize',10);

for ri=find(ss.reversal)
    plot([ri ri],[0 is(ri)],'k-');
end

plot([0 length(is)],[thresh thresh],'r-');

xlabel('Trial');
ylabel('Intensity');


set(gca,'FontSize',12);