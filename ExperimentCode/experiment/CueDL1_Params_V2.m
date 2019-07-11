function params = CueDL1_Params_V2
% params for version 2: 
% Same as Version 1 with slight changes: 

params = CueDL1_Params;

%changes
params.nFreebieTrials           = 5; 
params.freebieIntensity         = params.gabor.maxTilt; %fix "feebie" intensity at max tilt (25deg)


