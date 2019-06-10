% function y = jcurve(params, x)
% A j-shaped function, developed by Alex L. White for fitting RT data as a
% function of age. 
% 
% y = s*(a1*exp(-x*b1) + a2*exp(x*b2));
% 
% 
% Inputs: 
% - params: a 1x4 vector of parameters [a1 a2 b1 b2 s]
% - x: input value 
% 
% Outputs
% - y: output value 
% 
% By Alex L. White, 2019, at the University of Washington 
function y = jcurve(params, x)

a1 = params(1); 
a2 = params(2); 
b1 = params(3); 
b2 = params(4);
s = params(5);

y = s*(a1*exp(-x*b1) + a2*exp(x*b2));
