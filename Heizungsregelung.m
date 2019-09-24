%% Set Parameters
% geometry 
    % room
    x = 4; % [m]
    y = 5;
    z = 3;

    Vol = x*y*z;
    ceilingA = x*y;
    floorA = ceilingA;
    
    % window
    nW = 2;         % number of windows
    windowA = 2 * nW;    % [m^2] for now
    % heater
    nH = 1;
    heaterA = 2 * nH;  % [m^2] for now
    % wall
    wallA = 2*x*z+2*y*z-nW*windowA;
% constants
    % general
    R = 287;   % [J/kgK]
    cp = 1009; % [J/kgK]
    p = 1e5;   % [Pa]
    
    % heat transfer coefficients
    kHeater = 10;
    kWall = 0.1;
    kWindow = 0.95;
    kCeiling = 0.2;
    
%environmental parameters
    % temperatures
    T_init = 280; 

    T_env = 283;
    T_heat = 320;
    T_soll = [290 295];
    
% Parameters C1 and C2 of the Heizkurve
    %Steepness
        C1 = 0.8;
    %Parallel Slide
        C2 = 1.6;
        
    
%% time discretisation
Days = 2;
delta_t = 60; %seconds
t0 = 0;
tend = Days*2*3600; % days in seconds

derivation_time = t0:delta_t:tend;

%% Import data from the Excel File (just the temperature as exercise of data extraction from .xlsx)
%the file has the first row as Timestamps and the second row as Temperatures
file_name = 'T_november_alone.xlsx'; 
opts = detectImportOptions(file_name);
%needed to format everything as double value while importing
opts = setvartype(opts, {'Uhrzeit','Temp'},'double'); 
%reads the whole table and keeps in memory, ist aber unnötig eigentlich
%T_data_readfile = readtable(file_name,opts, 'ReadRowNames', false); 
%in opts adds the limitation to read just columns with selected names
opts.SelectedVariableNames = 'Uhrzeit';

Timeprint_array_row = readtable(file_name,opts,'ReadVariableNames', false);

%% Conversion of the Time data to the classic format
Timeprint_array = table2array(Timeprint_array_row(1:47,1));
Timeprint_array_mmss = days(Timeprint_array);
Timeprint_array_mmss.Format = 'hh:mm:ss';
% Time = datetime(Timeprint_array,'ConvertFrom',);
%% Extraction of the temperature data from the table (datas from .txt)
T_file = fopen('Temp20191116.txt','r');
T_outside = fscanf(T_file, '%f');
fclose(T_file);
%% Interpolation of the Temperature data to create a function out of it
% Set up fittype and options.
ft = fittype( 'smoothingspline' );

% Finds a curve - smoothed spline- which is fitting to data and saves it in a cfit variable 
fitresultfunction_ext_temp = fit(Timeprint_array,T_outside, ft);
%% Heatflow
    H_Switch = 0;
    Ts = [T_heat T_env T_env T_env];
    k =  [kHeater kWall kWindow kCeiling];
    Areas = [heaterA wallA windowA floorA];

%% Declaration of the function handlers
%function handle to pick the instant ideal temperature of the heater
T_heater = @(T_inside,T_outside) Heizkurve(T_inside,T_outside,C1,C2);
%function handle to activate the heating surface %%TO DEPRECATE
factor = @(H_Switch) [H_Switch 1 1 1]; % for switching the heater on(1)/off(0) 
Q_room = @(T,H_Switch) factor(H_Switch).*Areas.*k.*(Ts-T);
T_change = @(t,T,H_Switch) R*T/(p*Vol*cp)*sum(Q_room(T,H_Switch));
%% calculate new Temperature

[derivation_time,T_inside] = ode_E_2(T_change,delta_t,[t0 tend],T_init,T_soll);

% convert seconds to hours
derivation_timeHours = derivation_time/3600;
plot(derivation_timeHours,T_inside)
axis([t0 derivation_timeHours(end) 273.15 max(T_inside)+10])
xlabel('t [h]'); ylabel('T[K]');
    
        
