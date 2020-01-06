function [Q_room] = Q_flow(t,T,H_regulation,f,k,Areas,T_heat,T_ext_fun)
%This function is managing the handler relative to the heat flow
%calculation

%Temperatures
Ts = [T_heat T_ext_fun(t) T_ext_fun(t) T_ext_fun(t)];

Q_room = Areas.*k.*(Ts.*f(t,H_regulation)-T);
end

