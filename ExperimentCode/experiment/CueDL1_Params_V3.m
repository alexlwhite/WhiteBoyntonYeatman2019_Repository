function params = CueDL1_Params_V3
% params for version 2: 
% Same as Version 1 with slight changes: 

params = CueDL1_Params;

params.cueRH                = params.cue; 

%In Roach & Hogben, their Gabor was at 5deg ecc (as is ours), and cue was at 4 deg ecc. 
%Their gabors had SD of 0.25, whereas ours are 0.28. So to sort of match
%their cue display, let's also put the cue 4 gabor SDs from the Gabor
%center (3.88 deg ecc). 
params.cueRH.ecc            = params.gabor.ecc - 4*params.gabor.sd; 

params.cueRH.rad            = 0.0917;

params.cueRH.color          = [0 0 0];

params.time.preCueDurRH     = 0.020; %R&H was 20 ms, but with our 120 Hz refresh this will end up at 16.66 ms 





