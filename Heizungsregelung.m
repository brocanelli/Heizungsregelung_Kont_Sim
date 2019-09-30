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
    % T_heat is set to 1 because is automatically changed from the
    % Heizkurve regulation system.
    %THE USE OF ANOTHER REGULATION SYSTEM REQUIRES ADDITION OF A LOOP TO
    %FIND OUT IF THE HEIZKURVE REGELUNG IS ACTIVE
    T_heat = 1; %otherwise 320 circa
    T_soll = [290 295];
    
    %% Heatflow
    H_Switch = 0; %TO MODIFY AND FIND AN APPROPRIATE USE ONCE THERE'S JUST 
                  %ONE PROGRAM FOR BOTH THE REGULATORS
    Ts = [T_heat T_env T_env T_env];
    k =  [kHeater kWall kWindow kCeiling];
    Areas = [heaterA wallA windowA floorA];
    
% Parameters C1, C2 and root value of the Heizkurve
    %Steepness
        C1 = 0.8;
    %Parallel Slide
        C2 = 1.6;
    %Root value
        rootn = 0.9;
        
    
%% time discretisation

%while using the Heizkurve Regelung can only be used one day, because the
%function is just defined between the 00:00 and 24:00  boundary.
%IF WE NEED MORE DAYS, MUST BE PROGRAMMED A DISCRETIZED PROCESSING OF DATAS
%FOR EACH DAY, OR USE OF DATASETS COMING FROM MORE DAYS.
Days = 1;
delta_t = 60; %seconds
t0 = 0;
tend = Days*24*3600; % days in seconds

derivation_time = t0:delta_t:tend;

%% Import data from the Excel File (just the time as exercise of data extraction from .xlsx)
%the file has the first row as Timestamps and the second row as
%Temperatures
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

%% Conversion of the Time data to a second format, which is usable in the derivation process

Timeprint_array_seconds = Timeprint_array.*24*3600;

%% Extraction of the temperature data from the table (datas from .txt)
T_file = fopen('Temp20191116.txt','r');
T_outside_array = fscanf(T_file, '%f');
fclose(T_file);
% Degrees to Kelvin
T_outside_array = T_outside_array + 273.15;
%% Interpolation of the Temperature data to create a function out of it
% Set up fittype and options.
    ft = fittype( 'smoothingspline' );

% Finds a curve - smoothed spline- which is fitting to data and saves it in a cfit variable 
    fitresultfunction_ext_temp = fit(Timeprint_array_seconds,T_outside_array, ft);

%% Declaration of the function handlers
% the external temperature for each time(t) is calculated as multiplication
% of the external temperature function * time

% function handle to pick the instant ideal temperature of the heater
    T_heater = @(t,T_inside) T_inside + C1*nthroot((T_inside-fitresultfunction_ext_temp(t)),rootn)+C2;
    
% function handle to modify the factor which regulates the temperature 
% of the heating surface
    factor = @(t,T,H_regulation) [T_heater(t,T) 1 1 1];

% with the use of the "Regelung durch Heizkurve", is no more needed the feedback
% coming from the loop in ODE_E solver(H_regulation), which checks if the 
% temperature is within the wished range. It is anyway kept for the future
% creation of a program which easily switches between the two regulators.
    Q_room = @(t,T,H_regulation) Areas.*k.*((Ts.*factor(t,T,H_regulation))-(fitresultfunction_ext_temp(t)));
    
    T_change = @(t,T,H_regulation) R*T/(p*Vol*cp)*sum(Q_room(t,T,H_regulation));
%% Derivation and calculation of the Temperature

%T_soll is just useful when in use with an on/off Regulator
[derivation_time,T_inside] = ode_E_Heizkurve(T_change,delta_t,[t0 tend],T_init,T_soll);

% convert seconds to hours
derivation_timeHours = derivation_time/3600;
plot(derivation_timeHours,T_inside)
axis([t0 derivation_timeHours(end) 273.15 max(T_inside)+10])
xlabel('t [h]'); ylabel('T[K]');
    
        
