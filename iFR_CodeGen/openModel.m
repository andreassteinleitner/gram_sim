function [constants, defaultPara, parameterDefinition, parameterConnectionBody] = openModel(varargin)
% openModel - Opens a SIMULINK-model within the simulink_controllers from from
% which ifr-codegen creates PX4 Firmware modules
%
% Prerequisites: a simulink model in the simulink_controllers folder should exist
%
% Syntax:  openModule()
%
% Inputs:
%    module_name - (optional) the name of the new module as string!!!
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Modified for Use with PX4 Firmware v1.13.2
% Author: Niklas Pauli <niklas.pauli@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% January 2023; Last revision: 13.02.2023
%
% Author: Niklas Pauli niklas.pauli@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% February 2021; Last revision: 21.06.2021

% Clean Start
restoredefaultpath;
bdclose('all');
clearvars -except varargin

%% Get paths to directories

% Add matlab functions to path
scriptPath = mfilename('fullpath');
[filepath, ~, ~] = fileparts(scriptPath);
addpath(fullfile(filepath, 'helper_functions'));
addpath(fullfile(filepath, '..', 'common', 'helper_functions')); %defineBuses, parseBus, initParam
if ~(exist(fullfile(filepath, 'helper_functions'), 'dir') && exist(fullfile(filepath, '..', 'common', 'helper_functions'), 'dir'))
    error('Important directories not found.')
end
%addpath(fullfile(filepath, '..', 'Library'));
%addpath(fullfile(filepath, '..', 'common'));

controller_modelsDir = fullfile(filepath, '..', 'common');
msgDir = fullfile(controller_modelsDir, 'msg');

if ~exist(controller_modelsDir, 'dir')
    error('simulink_controllers directory not found.')
end

% % Get all modules with a "ifr_" prefix" PX4 modules folder
% FileList = dir(fullfile(moduleBaseDir, '*'));
% NameList = {FileList.name};
% isFolderlist = [FileList.isdir];
% named_ifr = ~contains(NameList, 'ifr_');
% NameList(~isFolderlist | named_ifr) = []; 

% Get all controllers in simulink_controllers directory
% Folders named "Archive" and "Future_Work" are automatically neglected
FileList = dir(fullfile(controller_modelsDir, '*'));
NameList = {FileList.name};
isFolderlist = [FileList.isdir];
namedArchive = contains(NameList, 'Archive');
namedFutureWork = contains(NameList, 'Future_Work');
namedMsg = contains(NameList, 'msg');
namedHelperFunctions = contains(NameList, 'helper_functions');
namedLoggerTopics = contains(NameList, 'logger_topics');
nonrelevantFolders = namedArchive | namedFutureWork | namedMsg | namedHelperFunctions | namedLoggerTopics;
hasDot   = contains(NameList, '.');
NameList(~isFolderlist | hasDot | nonrelevantFolders) = []; 

% Checking if model_name was given
if nargin > 0
    
    module_name = varargin{1};  
    input_correct = contains(NameList, module_name);
    
    % Check if entered module name exists
    if ~input_correct
       disp('Aborting. Module with such a name does not exist.');
       disp('Check spelling and simulink_controllers folder.')
       return
    end
    
else % Automatically Search for ifr_controllers in PX4 modules folder
    
    % Ask for user selection
    fprintf('Found the following Model folders modules:\n')
    size_NameList = size(NameList,2);
    for i = 1:size_NameList
        fprintf('%d. %s \n',i,NameList{i});
    end
    selected_module = 0;
    while selected_module < 1 || selected_module > size_NameList
        prompt = 'Module selection (enter number):';
        selected_module = input(prompt);
        if selected_module < 1 || selected_module > size_NameList
            fprintf('Error: Input is outside range.\n')
        end
    end
    
    module_name = NameList{selected_module};
   
end

% Check if corresponding controller exists
model_name = module_name;
model_dir = fullfile(controller_modelsDir, model_name);
model_path = [fullfile(model_dir,model_name), '.slx'];


% Corresponding Firmware Wrapper
model_name_wrapper = join([model_name,'_wrapper_firmware']);
wrapper_path = [fullfile(model_dir,model_name_wrapper), '.slx'];
wrapper_flag = isfile(wrapper_path);

%% Opening Simulationmodel

% Adding model folder to path
addpath(genpath(model_dir));

%initialize constants
[constants, defaultPara, parameterDefinition, parameterConnectionBody]=initParametersAndConstants(defineParameters(), defineConstants(), module_name);
assignin('base','constants',constants);

%initialize buses
defineBuses(msgDir);

% Opening Model
disp('Opening simulink model ...')

if  wrapper_flag
    open_system(wrapper_path);
    % set model params
    set_param(model_name_wrapper,'Solver','ode2','StopTime','inf');
    l = namelengthmax; % Maximum identifier length
    set_param(model_name_wrapper, 'MaxIdLength', l);
else
    open_system(model_path);
    % set model params
    set_param(model_name,'Solver','ode2','StopTime','inf');
    l = namelengthmax; % Maximum identifier length
    set_param(model_name, 'MaxIdLength', l);
end
    
% Setting Path of Generated Code and Temporary Files
Simulink.fileGenControl('set',...
    'CacheFolder', fullfile(model_dir,'cache'),...
    'CodeGenFolder', fullfile(model_dir,'code'),...
    'createDir', true)

end
