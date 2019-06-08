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

