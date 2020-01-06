function [t,y] = ode_E_Heizkurve(f,h,tspan,y0,condition,controller)

t = tspan(1):h:tspan(end);
nSteps = length(t);
dim = length(y0);
on = 1;
y = zeros(dim,nSteps);
y(:,1) = y0;


for i = 2:nSteps
    if controller == 0
        on = 0;
    elseif controller == 2
        if y(1,i-1) > condition(2)
            on = 0;
        elseif y(1,i-1) < condition(1)
            on = 1;
        end
    end
    y(:,i) = y(:,i-1) + h*f(t(i-1),y(:,i-1),on);
    
end

t = t';
y = y';

end