function [t,y] = ode_E(f,h,tspan,y0)

t = tspan(1):h:tspan(end);
nSteps = length(t);
dim = length(y0);

y = zeros(dim,nSteps);
y(:,1) = y0;


for i = 2:nSteps
    y(:,i) = y(:,i-1) + h*f(t(i-1),y(:,i-1));
end

t = t';
y = y';

end