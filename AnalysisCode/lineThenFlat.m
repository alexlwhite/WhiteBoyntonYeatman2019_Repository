function y = lineThenFlat(params, x)

a = params(1); %slope
b = params(2); %y-intercept
x0 = params(3); %inflection point 

y = zeros(size(x)); 
y(x<=x0) = a*x(x<=x0)+b; 
y(x>x0)  = a*x0+b; 

