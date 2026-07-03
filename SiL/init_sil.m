%% Clean Start
% close all;
% bdclose all
% clear all;
% clc;

%% Use Simulink Project API to get the current project:
projectRoot = slproject.getCurrentProject().RootFolder;

%% Define airfield and aircraft
LOCATION_FLAG_TO = 7;
LOCATION_FLAG_LDG = 6;
AIR_START_FLAG = 0; %off
vehicleType = 1;

%% Simulation Environment
initLibrary();

%% Buses and parameters
ifrcg_codegen_path = '';
[~, Specs_Codegen, Specs_Internal]  = preparations(ifrcg_codegen_path);
Specs_Model = readSimulinkModelSpecs(model_path, Specs_Internal.model.model_specs_file); % read model specs file
Specs_Merged = mergeSpecs(Specs_Codegen, Specs_Model); % Merge CodeGen and Model Specs in one universal specification file
PX4_Paths = getPX4Paths(Specs_Merged, Specs_Internal); % Get all relevant paths within the PX4 Source Code
work_dir = setWorkingDirectory(Specs_Merged); % Set working directory (creates it if necessary)
defineCodeGenInternalBuses(Specs_Merged, Specs_Internal, BUS_NAME_SEPARATOR); % Call function to create CodeGen internal buses

% defineBuses(fullfile(projectRoot,'common','msg'));
% [defaultConsts,~]=initParametersAndConstants(struct([]),defineConstants(vehicle),'default');

%% Mission
defaultWP.flightplan = [4, 0, 0;-300, -200, -60;-300, -1200, -60;150, -600, -60;-100, -200, -60;zeros(16,3)];

%% Simulation time
t_end = 250;

if vehicle.landed == 1
    disp(['Vehicle: ',vehicle.name,', Location: ',location_name,' Ground']);
%elseif vehicle.airborne == 1
%    disp(['Vehicle: ',vehicle.name,', Location: ',location_name,' Air']);
else
    disp(['Vehicle: ',vehicle.name,', Location: ',location_name,' Air']);
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