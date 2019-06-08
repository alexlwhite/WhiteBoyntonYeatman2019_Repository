function y = jcurve(params, x)

a1 = params(1); 
a2 = params(2); 
b1 = params(3); 
b2 = params(4);
scale = params(5);

y = scale*(a1*exp(-x*b1) + a2*exp(x*b2));
