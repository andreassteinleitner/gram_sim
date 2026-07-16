%% Clean Start
close all;
bdclose all
clear all;
clc;

%% Use Simulink Project API to get the current project:
projectRoot = slproject.getCurrentProject().RootFolder;

%% Define airfield and aircraft
AIR_START_FLAG = 0; %off
vehicleType = 2; %(1) gram80, (2) gram40, (3) funcub

%% Simulation Environment
initLibrary();

%% Buses and parameters
defineBuses(fullfile(projectRoot,'common','msg'));
[defaultConsts,~]=initParametersAndConstants(struct([]),defineConstants(vehicle),'default');

%% Mission
defaultWP.flightplan = [4, 0, 0;-300, -200, -60;-300, -1200, -60;150, -600, -60;-100, -200, -60;zeros(16,3)];

%% Simulation time
t_end = 250;

if vehicle.landed == 1
    disp(['Vehicle: ',vehicle.name,' Ground']);
else
    disp(['Vehicle: ',vehicle.name,' Air']);
end

%% Open model
load_system('gnc')
load_system('nav')

open("SiL_gram.slx");

%% Setting Path of Generated Code and Temporary Files
Simulink.fileGenControl('set',...
    'CacheFolder', fullfile(projectRoot,'cache'),...
    'CodeGenFolder', fullfile(projectRoot,'code'),...
    'createDir', true)