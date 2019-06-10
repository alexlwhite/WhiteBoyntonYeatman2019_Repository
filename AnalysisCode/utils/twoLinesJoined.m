% function y = twoLinesJoined(params, x)
% A  piecewise linear function , developed by Alex L. White for fitting thresholds as a
% function of age. 
% 
% This function assumes that y varies as a function of x in two linear segments that may 
% have different slopes, and meet at an inflection point x0. 
% 
% 
% Inputs: 
% - params: a 1x4 vector of parameters [a1 b1 x0 a2]. 
%  a1=slope of the first section, b1=y-intercept of the first section,
%  x0=inflection point, a2=slope of the second section 
% - x: input value 
% 
% Outputs
% - y: output value 
% 
% By Alex L. White, 2019, at the University of Washington 

function y = twoLinesJoined(params, x)

a1 = params(1); %slope for line 1
b1 = params(2); %y-intercept line 1
x0 = params(3); %inflection point 
a2 = params(4); %slope for line 2

y = zeros(size(x)); 
y(x<=x0) = a1*x(x<=x0)+b1; 

%solve for y-intercept of line 2, given slope a2 and value at intercept x0
interceptY = a1*x0+b1;
%y=ax+b
b2 = interceptY - a2*x0;

y(x>x0)  = a2*x(x>x0)+b2; 

