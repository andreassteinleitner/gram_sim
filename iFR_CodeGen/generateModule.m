% generateModule - Generates source code for a module in the PX4 firmware
% The function generates all necessary build files for an existing self
% created PX4 firmware module to allow compilation with the PX4 Fimrware.
%
% Syntax:  generateModule()
%
% Inputs: none
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Written for Use with PX4 Firmware v1.13.3
% Author: Andreas Steinleitner <andreas.steinleitner@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% Last revision: 04.02.2026

%% Clean Start
restoredefaultpath;
clearvars -except wslBasePath;

close all;
clear function;
clc;
bdclose('all');

%% Preparation

% Add necessary folders to path
filepath = pwd; % get path to current folder
basepath = fullfile(filepath, '..');
if ~exist(basepath, 'dir')
    error('Codegen files in wrong directory.')
end

addpath(fullfile(basepath, 'common', 'helper_functions')); % add folder with helper functions to path
addpath(fullfile(filepath, 'helper_functions')); % add folder with helper functions to path
addpath(fullfile(filepath, 'templates', 'module_core_files')); % add folder with templates for module core files to path

if ~exist('wslBasePath', 'var')
    disp('Base path not found')
    moduleBaseDir = loadFromConfigOrUi({'src', 'modules'});
else
    disp(['Base path: ',wslBasePath])
    moduleBaseDir = fullfile(wslBasePath, 'src', 'modules');
end

if ~exist(moduleBaseDir, 'dir')
    error('Module base directory not found.')
end

% Add working directory to path
workDirpath = 'C:\PX4_Firmware_IFR_CodeGen\generate_modules\';
if ~exist(workDirpath, 'dir')
    mkdir(workDirpath);
end

% Read Prefix
prefix_file = fopen(fullfile(filepath, 'Prefix.txt'),'rt');
prefix = fscanf(prefix_file,'%s');
fclose(prefix_file);

%% Selection

% Get all modules with the defined prefix from PX4 modules folder
FileList = dir(fullfile(moduleBaseDir, '*'));
NameList = {FileList.name};
isFolderlist = [FileList.isdir];
named_with_prefix = ~contains(NameList, prefix);
NameList(~isFolderlist | named_with_prefix) = [];

% Ask for user selection
fprintf('Found the following own modules:\n')
size_NameList = size(NameList,2);

if size_NameList < 1
    disp(['Could not find any own modules with prefix ' prefix ' in modules folder --> aborting'])
    return
end

for i = 1:size_NameList
    fprintf('%d. %s \n',i,NameList{i});
end
selected_module = -1;
if size_NameList > 9
    while selected_module < 0 || selected_module > size_NameList
        prompt = 'Module selection (enter number). Enter 0 to generate all modules.\n';
        selected_module = input(prompt);
        if selected_module < 0 || selected_module > size_NameList
            fprintf('Error: Input is outside range.\n')
        end
    end
else
    while selected_module < 0 || (selected_module > size_NameList && selected_module < 10) %single digit 
        prompt = 'Module selection: Enter one number or several numbers as consecutive digits. Enter 0 to generate all modules.\n';
        selected_module = input(prompt);
        digits = num2str(selected_module)-'0';
        if selected_module < 0 || (selected_module > size_NameList && selected_module < 10) %single digit 
            fprintf('Error: Input is outside range.\n')
        end
    end
end
if selected_module == 0
    module_vec = 1:size_NameList;
    fprintf('Generating all own modules.\n')
else
    if exist('digits',"var")
        module_vec = digits;
    else
        module_vec = selected_module;
    end
end

for module_ctr = 1:length(module_vec)
    selected_module = module_vec(module_ctr);
    module_name = NameList{selected_module};
    module_name_sc = toSnakeCase(module_name);
    module_name_usc = upper(module_name_sc);
    moduleDir = fullfile(moduleBaseDir, module_name_sc);

    %% Locate and move correct simulink model files
    disp(' ');
    disp('-----------------------------------------------------');
    disp(['Code generation for ',module_name,'!']);

    % get corresponding model
    [model_name, model_name_wrapper, model_base_dir]=getCurrentModel(module_name,prefix);
    wrapper_flag = isempty(model_name_wrapper);
    name_sim_wrapper = join([model_name,'_wrapper_simulation']);

    % copy files from controllermodel
    disp('- Copying model files')

    workDirmodelpath = fullfile(workDirpath, model_name);
    if ~exist(workDirmodelpath, 'dir')
        mkdir(workDirmodelpath);
    end

    modelFiles = dir(model_base_dir);
    for i=1:length(modelFiles)
        if ~strcmp(modelFiles(i).name, '.') && ~strcmp(modelFiles(i).name, '..') && ~contains(modelFiles(i).name, 'simulation')
            sourceFile = fullfile(model_base_dir, modelFiles(i).name);
            targetFile = fullfile(workDirmodelpath,modelFiles(i).name);
            copyfile(sourceFile, targetFile)
        end
    end

    % add to path
    addpath(genpath(workDirmodelpath));

    %% Get and adjust stacksize

    % Read Current Stacksize
    stacksize_file = fopen(fullfile(moduleDir, 'Stacksize.txt'),'rt');
    stacksize = fscanf(stacksize_file,'%s');
    fclose(stacksize_file);

    % ask to adjust stacksize
    if isscalar(module_vec)
        choice = '';
        adjust_stacksize = false;
        while 1
            choice = lower(input(['Current stacksize is: ', stacksize, '. Adjust? [y|N]: '], 's'));

            if strcmp(choice, '')
                choice = 'n';
            end

            if strcmp(choice, 'y')
                adjust_stacksize = true;
                break;
            elseif strcmp(choice, 'n')
                break;
            else
                disp('Invalide Input. Try again.')
            end
        end
    else
        adjust_stacksize = false;
    end

    % adjust stacksize if prompted to do so
    new_stacksize = 0;
    if adjust_stacksize
        while 1
            stacksize_input = input('Enter the new stacksize as a positive integer value. Abort entering "0" ');
            stacksize_input = int32(stacksize_input);

            % check if input is a number
            if isinteger(stacksize_input)

                % check if input value is positive
                if stacksize_input > 0

                    % Verifying new stacksize
                    disp(['New stacksize is: ', num2str(stacksize_input)]);
                    while 1
                        choice = lower(input('Correct? [y|N]: ', 's'));

                        if strcmp(choice, 'n')
                            disp('Discarded stacksize input. Try again. ')
                            break;
                        elseif strcmp(choice, 'y')
                            disp('Accepted new stacksize.')
                            new_stacksize = stacksize_input;
                            break;
                        else
                            disp('Invalide Input. Try again.')
                        end

                    end

                    if new_stacksize > 0
                        break;
                    end

                elseif stacksize_input == 0
                    disp('Aborting stacksize adjustment.')
                    break;
                else
                    disp('Stacksize Input is not positive. Try again')
                end
                % Input is not a number --> requesting new user input
            else
                disp('Stacksize Input is not an integer value. Try again')
            end

        end
    end

    % adjust value in stacksize settings file
    if new_stacksize > 0
        disp('Writing new stacksize in settings')
        stacksize_file=fopen(fullfile(moduleDir, 'Stacksize.txt'), 'w');
        fprintf(stacksize_file, '%s', num2str(new_stacksize));
        fclose(stacksize_file);
    end

    %% defining buses from message folder
    disp('- Defining busses')
    messageFolder = fullfile(basepath, 'common', 'msg');
    defineBuses(messageFolder);

    %% Setting Path of Generated Code and Temporary Files
    % necessary for building not in wsl
    Simulink.fileGenControl('set',...
        'CacheFolder', workDirmodelpath,...
        'CodeGenFolder', workDirmodelpath,...
        'createDir', true)

    %% Generate Code
    disp('############################')
    disp('- Starting Code Generation')
    generateCode_V3(module_name,model_name,model_name_wrapper,wrapper_flag,stacksize,messageFolder,workDirmodelpath,moduleDir)

    %% Finalisation

    % Closing system
    close_system(model_name_wrapper)

    disp(' ');
    disp('-----------------------------------------------------');
    disp('Code generation completed!');
    disp(datetime);
    disp(['Done Generating Module: ' module_name])
    disp('-----------------------------------------------------');
    disp(' ');
end

%% Copy msg folder to wslbasepath
copyMessages();
