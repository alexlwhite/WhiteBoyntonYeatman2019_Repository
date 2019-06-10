% function y = lineThenFlat(params, x)
% A  piecewise linear function , developed by Alex L. White for fitting thresholds as a
% function of age. 
% 
% This function assumes that y varies as a function of x with a linear
% slope up until an inflection point x0, after which there is no more
% change in y. 
% 
% 
% Inputs: 
% - params: a 1x4 vector of parameters [a b x0]. 
%  a=slope, b=y-intercept, x0=inflection point 
% - x: input value 
% 
% Outputs
% - y: output value 
% 
% By Alex L. White, 2019, at the University of Washington 

function y = lineThenFlat(params, x)

a = params(1); %slope
b = params(2); %y-intercept
x0 = params(3); %inflection point 

y = zeros(size(x)); 
y(x<=x0) = a*x(x<=x0)+b; 
y(x>x0)  = a*x0+b; 

