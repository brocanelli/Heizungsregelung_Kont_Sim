%% Set Parameters
% geometry 
    % room
    x = 5; % [m]
    y = 5;
    z = 3;

    Vol = x*y*z;
    wallA = x*z;
    floorA = x*y;
    
    % window
    nW = 2;         % number of windows
    windowA = 2;    % [m^2] for now
    % heater
    heaterA = 2;  % [m^2] for now
    
    Areas = [heaterA wallA windowA floorA];
    
% constants
    % general
    R = 287;   % [J/kgK]
    cp = 1009; % [J/kgK]
    p = 1e5;   % [Pa]
    
    % heat transfer coefficients
    kHeater = 5;
    kWall = 0.6;
    kWindow = 1;
    kCeiling = 0.8;
    
    

%% time discretisation
delta_t = 10;
t0 = 0;
tend = 10000;

time = t0:delta_t:tend;

%% Temperatures
T_init = 270; 

T_env = 270;
T_heat = 335;

heaterOn = true;

%% Heatflow
if heaterOn
    Ts = [T_heat T_env T_env T_env];
    k =  [kHeater kWall kWindow kCeiling];
    Areas = [heaterA wallA windowA floorA];
else
    Ts = [T_env T_env T_env];
    k =  [kWall kWindow kCeiling];
    Areas = [wallA windowA floorA];
end

Q_room = @(T) Areas.*k.*(Ts-T);
T_change = @(t,T) R*T/(p*Vol*cp)*sum(Q_room(T));
%% calculate new Temperature

[time,Temperature] = ode_E(T_change,delta_t,[t0 tend],T_init);

plot(time,Temperature)
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    