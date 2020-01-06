
%------------------------%%%%%%%%%%%%%%%%%%--------------------------------
%                        %% CONTROL DECK %%
%------------------------%%%%%%%%%%%%%%%%%%--------------------------------

%------------------------- CONTROL SYSTEM ---------------------------------
% choose your control system
%   0: Heater turned off
%   1: 'Heizkurve'-Regulation
%   2: 'On/Off'-Regulation
    
    Controller = 0; 

% 'Heizkurve'-Control
    T_inside_theoretically = 295;   % Soll Temp for 'Heizkurve'-Regulation
    
    % Parameters to control the Heater-Temperature
    C1 = 0.8;           % Steepness
    C2 = 1;             % Parallel shift
    rootn = 1.1;        % Root value

% 'On/Off'-Control
    T_soll = [295 295]; % Soll Temp for 'On/Off'-Regulation
    T_heat = 320;       % Heater Temp
    
%-------------------------- TEMPERATURES ----------------------------------
% Define temperature of ROOM in Kelvin:  

    T_init = 280;   % initial temperature of the room 
   
% Define temperature of ENVIRONMENT.
% you can either define a constant temperature or, if measurements in Celsius 
% are available, hand over the .csv file. 
% Additionaly a sinusoidal temperature trend is implemented by using the 
% keyword 'sine'.
% Examples: T_env = 'T_january_alone.csv'
%           T_env = 'sine'
%           T_env = 280

    T_env = 'T_november_alone.csv';

%-------------------------- TIME CONTROL ----------------------------------
%while using the Heizkurve Regelung can only be used one day, because the
%function is just defined between the 00:00 and 24:00  boundary.
%IF WE NEED MORE DAYS, MUST BE PROGRAMMED A DISCRETIZED PROCESSING OF DATAS
%FOR EACH DAY, OR USE OF DATASETS COMING FROM MORE DAYS.
    Days = 1;
    delta_t = 60; %seconds
    t0 = 0;
    tend = Days*24*3600; % days in seconds
    
%----------------------------- ROOM ---------------------------------------    
% geometry 
    x = 4; % [m]
    y = 5; 
    z = 3; 
% Number of Windows and Heaters
    nW = 2;         % number of windows
    nH = 1;         % number of heaters
% heat transfer coefficients [W/(m^2*K)]
    kHeater = 10;
    kWall = 0.15;
    kWindow = 0.7;
    kCeiling = 0.16;    
%--------------------------- CONSTANTS ------------------------------------
% general
    R = 287;   % [J/kgK]
    cp = 1009; % [J/kgK]
    p = 1e5;   % [Pa]
 
%% Definition of Outside- and Heater-Temperature depending on Settings

if ischar(T_env)
    if strcmp(T_env, 'sine')
        outsideTemp = @(t) 273 + 10*sin(t/(300*2*pi));
    else
        try    
            [measuredTime, measuredTemp] = importData(T_env);
            outsideTemp = @(t) interp1(measuredTime, measuredTemp, t);
        catch % if there is no file (or wrong name), a constant temperature is set.
            outsideTemp = @(t) 273 + 0*t;
        end
    end
else
    outsideTemp = @(t) T_env + 0*t; % '+0*t' for plotting neatly.
end
    
% depending on the regulation-system the Heater Temperature is defined.
if Controller == 1 % 'Heizkurve'-Control
    T_heater = @(t) T_inside_theoretically + C1*nthroot((T_inside_theoretically-outsideTemp(t)),rootn)+C2;
    Ts = @(t) [T_heater(t) outsideTemp(t) outsideTemp(t) outsideTemp(t)];
else % other control-systems
    T_heater = T_heat;
    Ts = @(t) [T_heater outsideTemp(t) outsideTemp(t) outsideTemp(t)];
end

%% ----------------------%%%%%%%%%%%%%%%%%%--------------------------------
%                        %% Calculations %%
%------------------------%%%%%%%%%%%%%%%%%%--------------------------------
% Geometry    
    % Volume and Areas
    Vol = x*y*z;
    ceilingA = x*y;
    floorA = ceilingA;
    
    % window
    windowA = 2 * nW;    % [m^2] 
    % heater
    heaterA = 2 * nH;  % [m^2] for now
    % wall
    wallA = 2*x*z+2*y*z-nW*windowA;

% Heatflow
    % storing all relevant heatflows in a vector.
    k =  [kHeater kWall kWindow kCeiling];
    Areas = [heaterA wallA windowA floorA];
    factor = @(H_Switch) [H_Switch 1 1 1];
    
    Q_room = @(t,T,H_Switch) factor(H_Switch).*Areas.*k.*(Ts(t)-T);
    
    T_change = @(t,T,H_Switch) R*T/(p*Vol*cp)*sum(Q_room(t,T,H_Switch));
%% Derivation and calculation of the Temperature

%T_soll is just useful when in use with an on/off Regulator
[derivation_time,T_inside] = ode_E_Heizkurve(T_change,delta_t,[t0 tend],T_init,T_soll,Controller);

% convert seconds to hours
derivation_timeHours = derivation_time/3600;


%% ----------------------%%%%%%%%%%%%%%%%%%--------------------------------
%                        %%    PLOTS     %%
%------------------------%%%%%%%%%%%%%%%%%%--------------------------------
figure(1)
plot(derivation_timeHours,T_inside)
axis([t0 derivation_timeHours(end) min(T_inside)-10 max(T_inside)+10])
xlabel('t [h]'); ylabel('T[K]');


figure(2)
plot(derivation_timeHours,T_inside)
hold on
plot(derivation_timeHours,outsideTemp(derivation_time))
if Controller == 1
plot(derivation_timeHours,T_heater(derivation_time))
end
%plot([derivation_timeHours(1) derivation_timeHours(end)], [289 289],'--')
axis([t0 derivation_timeHours(end) 250 max(T_inside)+30])
xlabel('t [h]'); ylabel('T[K]');
%legend('T innen', 'T aussen', 'T vorlauf')
hold off
    
% Plot Heizkurve
figure(3)
TempRange = linspace(293,253,100);
Heizkurve =  T_inside_theoretically + C1*nthroot((T_inside_theoretically-TempRange),rootn)+C2;
plot(TempRange-273.15,Heizkurve-273.15)
xlabel('Umgebungstemperatur [°C]'); ylabel('Vorlauftemperatur [°C]');




