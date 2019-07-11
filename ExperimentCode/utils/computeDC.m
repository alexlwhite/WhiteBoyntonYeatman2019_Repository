function [d c c2 hitR FAR] = computeDC(pres, resp)
%Compute d' (d) and criterion (c) 
% by Alex White, 2011
% 
% Usage: 
% Input: 
% - pres should be vector of 1s (for signal present) and 0s (for signal
% absent) 
% 
% - resp should be vector of 1s (for 'yes' response) and 0s (for 'no'
% response)
%
%
% Output: 
% - d, d' 
% - c, criterion as distance from 0 
% - c2, criterion as distance from d/2
%
%


hits=(pres & resp); 
FAs=(~pres & resp); 

hitR=sum(hits)/sum(pres); 
FAR=sum(FAs)/sum(~pres); 

%Deal with case when there are too few trials, or hit rate is 1 or 0
if sum(pres)<2
    if sum(pres)>0
        if hitR==1, hitR=0.99;
        elseif hitR==0, hitR=0.01; end
    else
        hitR=NaN;
    end
    
elseif hitR==0
    hitR=1/sum(pres);
elseif hitR==1
    hitR=(sum(pres)-1)/sum(pres);
end

%Deal with case when there are too few trials, or FA rate is 1 or 0
if sum(~pres)<2
    if sum(~pres)>0
        if FAR==1, FAR=0.99;
        elseif FAR==0, FAR=0.01; end
    else
        FAR=NaN;
    end
elseif FAR==0
    FAR=1/sum(~pres);
elseif FAR==1
    FAR=(sum(~pres)-1)/sum(~pres);
end


d=norminv(hitR)-norminv(FAR);

%don't accept d' less than 0. 
%if d<0, d=0; end;

%Criterion: 
%First, just the z-score of the correct rejection rate. Simple, on same
%units as d'
c=norminv(1-FAR); 

%Second formula: a measure of how far the criterion is from neutral, which
%is d/2. This is equivalent to c-d/2 (using the first c)
c2= -0.5*(norminv(hitR) + norminv(FAR));
