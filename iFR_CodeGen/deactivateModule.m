function deactivateModule(path, varargin)
% deactivateModule - deactivates a module in the PX4 firmware
% The function deactivates an existing self created PX4 firmware module so it
% 1) is removed from the list of modules, which are actually built
% 2) is removed from the list of modules which automatically start when Pixhawk boots up
%
% Syntax:  deactivateModule()
%
% Inputs: none
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Written for Use with PX4 Firmware v1.13.2
% Author: Niklas Pauli <niklas.pauli@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% January 2023; Last revision: 13.02.2023

%% Preparation

% Add helper functions to path
filepath = pwd; % get path to current folder
addpath(fullfile(filepath, 'helper_functions'));

if ~exist('path', 'var')
    moduleBaseDir = loadFromConfigOrUi({'src', 'modules'});
else
    moduleBaseDir = fullfile(path,'src','modules');
end

if ~exist(moduleBaseDir, 'dir')
    error('Module base directory not found.')
end

% Read Prefix
prefix_file = fopen(fullfile(filepath, 'Prefix.txt'),'rt');
prefix = fscanf(prefix_file,'%s');
fclose(prefix_file);

% Read Standard Boards
standard_boards_file = fileread('Standard_Boards.txt');
standard_boards = splitlines(standard_boards_file);

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
    disp(['Could not find any own modules with prefix' prefix ' in modules folder --> aborting'])
    return
end

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

%% User selection: Removing module from which board

moduleDir = fullfile(moduleBaseDir, module_name_sc);
remove_module_from_board = false;
use_standard_boards = true;
board_selection = 0;
selected_board = 0;
if exist(moduleDir, 'dir')
    while 1
        choice = lower(input(['Do you want to remove ' module_name ' from a board? [y|N]: '], 's'));
        
        if strcmp(choice, 'n')
            disp('Not removing module from a board')
            break;
            
        elseif strcmp(choice, 'y')
                
            remove_module_from_board = true;
            
            disp('Options for board selection:')
            disp('1) Remove module from all boards')
            disp('2) Select board from list of standard boards')
            disp('3) Select board from list with all boards')
            
            while 1
                
                board_selection = input('Choose board selection with corresponding numer.');
                
                switch board_selection
                    
                    case 1
                        break;
                    case 2
                        break
                    case 3
                        break
                    otherwise
                        disp('Selected number is unknown. Try again.')
                        
                end

            end
            
            break
        end
    end
    
    % get list of relevan tboards
    if board_selection
        
        % Get list with all relevant boards
        if ~exist('path', 'var')
            boardsDir = loadFromConfigOrUi({'boards'});
        else
            boardsDir = fullfile(path, 'boards');
        end
        px4_boards = dir(fullfile(boardsDir, '**', 'default.px4board'));
        
        % Reduce list if necessary
        if board_selection == 2
            relevant_boards(length(standard_boards)).name = standard_boards(i); % stores all relevant boards
            num_found_boards = 0; % counts number of found boards
            for i=1:length(standard_boards)
                for j=1:length(px4_boards)
                    if contains(px4_boards(j).folder,standard_boards(i)')
                        relevant_boards(i).folder = px4_boards(j).folder;
                        relevant_boards(i).name = px4_boards(j).name;
                        num_found_boards = num_found_boards +1;
                        break
                    end
                end
            end
            % Check if all boards in standard board list have been found
            if (num_found_boards ~= length(standard_boards))

                disp('Warning: did not find all specified standard boards')
                % Reduce size 
                for i=length(standard_boards):-1:num_found_boards+1
                    relevant_boards(i) = [];
                end

            end
        elseif board_selection == 1 || board_selection == 3
            relevant_boards(length(px4_boards)).name = standard_boards(i); % stores all relevant boards
            for i=1:length(px4_boards)
                relevant_boards(i).folder = px4_boards(i).folder;
                relevant_boards(i).name = px4_boards(i).name;
            end
        end
        
        if (~isempty(relevant_boards)  && board_selection ~= 1)

            % Displaying all relevant boards
            disp('Select the board you want to remove the module from')
            start = strfind(relevant_boards(1).folder, 'boards') + 7; %reduces length of paths shown in list below
            for i=1:length(relevant_boards)
                disp([num2str(i) ') ' fullfile(relevant_boards(i).folder(start:end), relevant_boards(i).name)])
            end

            % User Input for Selection
            disp('Type "0" for not removing the module from a board right now.')
            while 1
                selected_board = input('Which board do you want to remove the module from?');

                if (selected_board > 0 && selected_board <= length(relevant_boards))
                    disp(['Selected Board: ' fullfile(relevant_boards(selected_board).folder(start:end), relevant_boards(selected_board).name)])
                    break;
                elseif selected_board == 0
                    disp('User selection: NO board will be updated.')
                    break;
                else
                    disp('Wrong Input Try Again')
                end
            end
        end
        
    end
    
    
end

%% Updating Boards
% remove module from selected board(s)
board_updated = false;

% Removing module from single board
if selected_board > 0 
    boardFile=fullfile(relevant_boards(selected_board).folder, relevant_boards(selected_board).name);      
    sourceText=fileread(boardFile);
    sourceLines=splitlines(sourceText);
    fileChanged = false;
    % go through all lines of board file
    for j=1:length(sourceLines)
        line = strtrim(sourceLines(j));
        % look for module
        if contains(line, ['CONFIG_MODULES_' module_name_usc '=y'])
            start = strfind(relevant_boards(1).folder, 'boards') + 7; %reduces length of paths shown in list below
            disp(['Found ', module_name, ' in ', fullfile(relevant_boards(selected_board).folder(start:end), relevant_boards(selected_board).name), ' --> removing'])
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
        board_updated = true;
    end
% removing from all boards  
elseif board_selection == 1
    
    for i=1:length(relevant_boards)
        boardFile=fullfile(relevant_boards(i).folder, relevant_boards(i).name); 
        sourceText=fileread(boardFile);
        sourceLines=strsplit(sourceText, '\n');
        fileChanged = false;
        % go through all lines of board file
        for j=1:length(sourceLines)
            line = strtrim(sourceLines(j));
            % look for module
            if contains(line, ['CONFIG_MODULES_' module_name_usc '=y'])
                start = strfind(relevant_boards(1).folder, 'boards') + 7; %reduces length of paths shown in list below
                disp(['Found ', module_name, ' in ', fullfile(relevant_boards(i).folder(start:end), relevant_boards(i).name), ' --> removing'])
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
            board_updated = true;
        end
    end
end

if ~board_updated
    disp('NO board updated.')
end

%% User selection: autostart module

start_module = false;
num_veh_types_to_update = 1;
if exist(moduleDir, 'dir')
    while 1
        choice = lower(input(['Do you want to remove ' module_name ' from auto-start list? [y|N]: '], 's'));
        
        if strcmp(choice, 'n')
            disp('Not removing module from auto-start list')
            break;
            
        elseif strcmp(choice, 'y')
                
            start_module = true;
            
            disp('List of vehicle types:')
            disp('1) Fixed-Wing')
            disp('2) Multi-Copter')
            disp('3) Rover (UGV)')
            disp('4) VTOL')
            disp('5) Airship')
            disp('6) UUV')
            disp('7) Generic')
            
            while 1
                selected_vehicle_type = input('Select vehicle type to remove from with corresponding numer. Type "0" to select all.');
                
                if (1 <= selected_vehicle_type) && (selected_vehicle_type <= 7)
                    break;
                elseif selected_vehicle_type == 0
                    num_veh_types_to_update = 7;
                    break
                else
                    disp('Selected number is unknown. Try again.')
                end
            
            end
            
            break
        end
    end
end

%% Updating ROMFS (= automatically start module)

vehicle_updated = false;

if start_module
    
    % get folder with relevant files
    if ~exist('path', 'var')
        appsDir_path = loadFromConfigOrUi({'ROMFS', 'px4fmu_common', 'init.d'});
    else
        appsDir_path = fullfile(path, 'ROMFS','px4fmu_common','init.d');
    end

    % differentiate between different boards
    switch selected_vehicle_type

        case 1
            disp('Selected vehicle type: Fixed-Wing')
            apps_file_list(1).name = fullfile(appsDir_path,'rc.fw_apps');
            
        case 2
            disp('Selected vehicle type: Multi-Copter')
            apps_file_list(1).name = fullfile(appsDir_path,'rc.mc_apps');
        
        case 3
            disp('Selected vehicle type: Rover (UGV)')
            apps_file_list(1).name = fullfile(appsDir_path,'rc.rover_apps');
            
        case 4
            disp('Selected vehicle type: VTOL')
            apps_file_list(1).name = fullfile(appsDir_path,'rc.vtol_apps');
            
        case 5
            disp('Selected vehicle type: Airship')
            apps_file_list(1).name = fullfile(appsDir_path,'rc.airship_apps');
            
        case 6
            disp('Selected vehicle type: UUV')
            apps_file_list(1).name = fullfile(appsDir_path,'rc.uuv_apps');
            
        case 7
            disp('Selected vehicle type: Generic')
            apps_file_list(1).name = fullfile(appsDir_path,'rc.vehicle_setup');
            
        case 0
            disp('Selected vehicle type: All Vehicle Types')
            apps_file_list(1).name = fullfile(appsDir_path,'rc.fw_apps');
            apps_file_list(2).name = fullfile(appsDir_path,'rc.mc_apps');
            apps_file_list(3).name = fullfile(appsDir_path,'rc.rover_apps');
            apps_file_list(4).name = fullfile(appsDir_path,'rc.vtol_apps');
            apps_file_list(5).name = fullfile(appsDir_path,'rc.airship_apps');
            apps_file_list(6).name = fullfile(appsDir_path,'rc.uuv_apps');
            apps_file_list(7).name = fullfile(appsDir_path,'rc.vehicle_setup');

        otherwise
            disp('Selected vehicle type is unknown --> aborting')
            return
    end
    
    % Update files
    for i=1:num_veh_types_to_update

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
            vehicle_updated = true;
        end
        
    end
    
end

if ~vehicle_updated
    disp('NO vehicle updated.')
end

%% Finalisation
disp(['Done Deactivating ' module_name '.'])

end