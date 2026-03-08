function deleteModule(path, varargin)
% deleteModule - Deletes a module in the PX4 firmware
% The function deletes an existing PX4 firmware module with necessary files
% for simulink code generation
%
% Syntax:  deleteModule()
%
% Inputs:
%    module_name - (optional) the name of the module to be deleted
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
% Modified for Use with modified PX4 Firmware V2021
% Author: Niklas Groﬂ <niklas.pauli@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% Juni 2021; Last revision: 21.06.2021
% 
% Original Author: Pascal Groﬂ <pascal.gross@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% April 2019; Last revision: 04.04.2019

%% Preparation

% Add matlab functions to path
scriptPath = mfilename('fullpath');
[filepath, ~, ~] = fileparts(scriptPath);
addpath(fullfile(filepath, 'helper_functions'));

if ~exist('path', 'var')
    moduleBaseDir = loadFromConfigOrUi({'src', 'modules'});
else
    moduleBaseDir = fullfile(path, 'src','modules');
end

if ~exist(moduleBaseDir, 'dir')
    error('Module base directory not found.')
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
module_name_sc = toSnakeCase(module_name);
module_name_usc = upper(module_name_sc);

%% Choice for Deletion

moduleDir = fullfile(moduleBaseDir, module_name_sc);
if exist(moduleDir, 'dir')
    choice = '';
    while 1
        choice = lower(input(['Do you really want to completely remove ' module_name '? [y|N]: '], 's'));
        
        if strcmp(choice, '')
            choice = 'n';
        end
        
        if strcmp(choice, 'y')  || strcmp(choice, 'n')
            break;
        end
    end
    
    if strcmp(choice, 'n')
        disp('Aborting. Not deleting module.')
        return
    end
end

%% Updating Boards
% remove module from board(build module) and vehicle(auto-start)

% Get list with all relevant boards
boardsDir = fullfile(filepath, '..', '..', 'boards');
px4_boards = dir(fullfile(boardsDir, '**', 'default.px4board'));

for i=1:length(px4_boards)
    boardFile=fullfile(px4_boards(i).folder, px4_boards(i).name); 
    sourceText=fileread(boardFile);
    sourceLines=strsplit(sourceText, '\n');
    fileChanged = false;
    % go through all lines of board file
    for j=1:length(sourceLines)
        line = strtrim(sourceLines(j));
        % look for module
        if contains(line, ['CONFIG_MODULES_' module_name_usc '=y'])
            start = strfind(px4_boards(1).folder, 'boards') + 7; %reduces length of paths shown in list below
            disp(['Found ', module_name, ' in ', fullfile(px4_boards(i).folder(start:end), px4_boards(i).name), ' --> removing'])
            fileChanged = true;
            sourceLines = {sourceLines{1:j-1} sourceLines{j+1:end}};
            break;
        end
    end

    % write file changes
    if fileChanged
        sourceFile=fopen(boardFile, 'w');
        fprintf(sourceFile, '%s', strjoin(sourceLines, '\n'));
        fclose(sourceFile);
    end
end

% get folder with relevant files
if ~exist('path', 'var')
    appsDir_path = loadFromConfigOrUi({'ROMFS', 'px4fmu_common', 'init.d'});

else
    appsDir_path = fullfile(path,'ROMFS','px4fmu_common','init.d');
end

apps_file_list(1).name = fullfile(appsDir_path,'rc.fw_apps');
apps_file_list(2).name = fullfile(appsDir_path,'rc.mc_apps');
apps_file_list(3).name = fullfile(appsDir_path,'rc.rover_apps');
apps_file_list(4).name = fullfile(appsDir_path,'rc.vtol_apps');
apps_file_list(5).name = fullfile(appsDir_path,'rc.airship_apps');
apps_file_list(6).name = fullfile(appsDir_path,'rc.uuv_apps');
apps_file_list(7).name = fullfile(appsDir_path,'rc.vehicle_setup');

% Update files
for i=1:length(apps_file_list)

    sourceText=fileread(apps_file_list(i).name);
    sourceLines=splitlines(sourceText);
    fileChanged = false;
    % go through all line of board file
    for j=1:length(sourceLines)
        line = sourceLines(j);

        if contains(line, [module_name_sc ' start'])
            start = strfind(apps_file_list(i).name, 'init.d') + 7; %reduces length of paths shown in list below
            disp(['Found ', module_name, ' in ', apps_file_list(i).name(start:end), ' --> removing'])
            fileChanged = true;
            sourceLines = {sourceLines{1:j-1} sourceLines{j+1:end}};
            break;
        end

    end
    % write file changes
    if fileChanged
        sourceFile=fopen(apps_file_list(i).name, 'w');
        fprintf(sourceFile, '%s', strjoin(sourceLines, '\n'));
        fclose(sourceFile);
    end

end

%% Updating ROMFS
% remove module from list of modules, which are automatically started

%% Remove directory
disp('- Removing module directory')
recycle('on');
rmdir(moduleDir, 's')

%% Finalisation
disp(['Done Deleting ' module_name ' from Firmware'])

end