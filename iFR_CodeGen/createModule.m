function createModule(path, varargin)
%createModule - Creates a module in the PX4 firmware
%The function creates a new PX4 firmware module with necessary files for
%simulink code generation
%
% Syntax:  createModule()
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
% Author: Niklas Pauli <niklas.pauli@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% Juni 2021; Last revision: 21.06.2021
%
% Original Author: Pascal Groﬂ <pascal.gross@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% April 2019; Last revision: 04.04.2019

%% Get paths to directories
scriptPath = mfilename('fullpath');
[filepath, ~, ~] = fileparts(scriptPath);
addpath(fullfile(filepath, 'helper_functions'));

if ~exist('path', 'var')
    moduleBaseDir = loadFromConfigOrUi({'src', 'modules'});
else
    moduleBaseDir = fullfile(path, 'src', 'modules');
end
skeletonDir = fullfile(filepath, 'skeleton');
controller_modelsDir = fullfile(filepath, '..', 'common');

if ~exist(moduleBaseDir, 'dir')
    error('Module base directory not found.')
end

if ~exist(skeletonDir, 'dir')
    error('Skeleton directory not found.')
end

while ~exist(controller_modelsDir, 'dir')
    disp('Simulink_controllers directory not found.')
    disp('go to simulink folder')
    moduleBaseDir = fullfile(uigetdir);
end

%% Read Prefix
prefix_file = fopen(fullfile(filepath, 'Prefix.txt'),'rt');
prefix = fscanf(prefix_file,'%s');
fclose(prefix_file);

%% Select Controller Model

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

% User Selection
fprintf('Found the following controllers:\n')
size_NameList = size(NameList,2);
for i = 1:size_NameList
    fprintf('%d. %s \n',i,NameList{i});
end

selected_controller = 0;
while selected_controller < 1 || selected_controller > size_NameList
    prompt = 'Controller selection (enter number):';
    selected_controller = input(prompt);
    if selected_controller < 1 || selected_controller > size_NameList
        fprintf('Error: Input is outside range.\n')
    end
end

% Get Module Name
module_name = NameList{selected_controller};
module_name = strcat(prefix,module_name);
module_name_sc = toSnakeCase(module_name);
module_name_usc = upper(module_name_sc);
module_name_ucc = toUpperCamelCase(module_name);
module_name_unique = num2str(now(), '%.20f'); % unique parameter suffix
module_name_unique = module_name_unique(end-5:end);

% Check if controller already exists
moduleDir = fullfile(moduleBaseDir, module_name_sc);
req_delete_prev_folder = false;
if exist(moduleDir, 'dir')
    choice = '';
    while 1
        choice = lower(input('Module directory already exists. Overwrite? [y|N]: ', 's'));
        
        if strcmp(choice, '')
            choice = 'n';
        end
        
        if strcmp(choice, 'y')  || strcmp(choice, 'n')
            req_delete_prev_folder = true;
            break;
        end
    end
    
    if strcmp(choice, 'n')
        disp('Aborting. Not overwriting module directory.')
        return
    end
end

% Remove Previously Created Module Directory
if req_delete_prev_folder
    disp('Removing old module directory.')
    rmdir(moduleDir, 's')
end

% Create Module Directory
disp('- Creating module directory')
if ~mkdir(moduleDir)
    error('Failed to create module directory');
end

% Copy Skeleton Files
disp('- Copying skeleton')
skeletonFiles = dir(skeletonDir);
for i=1:length(skeletonFiles)
    if ~strcmp(skeletonFiles(i).name, '.') && ~strcmp(skeletonFiles(i).name, '..')
        sourceFile = fullfile(skeletonDir, skeletonFiles(i).name);
        targetFile = fullfile(moduleDir, skeletonFiles(i).name);
        targetFile = strrep(targetFile, '%%module_name_sc%%', module_name_sc);
        targetFile = strrep(targetFile, '%%module_name_usc%%', module_name_usc);
        targetFile = strrep(targetFile, '%%module_name_ucc%%', module_name_ucc);
        targetFile = strrep(targetFile, '%%module_name_unique%%', module_name_unique);
        copyfile(sourceFile, targetFile)
        
        
        [~, ~, ext] = fileparts(targetFile);
        % Modify content of C/C++ files to match module name
        if strcmp(ext, '.cpp') || strcmp(ext, '.hpp') || strcmp(ext, '.c') ...
            || strcmp(ext, '.h') || strcmp(ext, '.txt') || strcmp(ext, '.m')
            strrepInFile(targetFile, '%%module_name_sc%%', module_name_sc);
            strrepInFile(targetFile, '%%module_name_usc%%', module_name_usc);
            strrepInFile(targetFile, '%%module_name_ucc%%', module_name_ucc);
            strrepInFile(targetFile, '%%module_name_unique%%', module_name_unique);
        end
        % Modify content of Kconfig to match module name
        if strcmp(skeletonFiles(i).name, 'Kconfig')
            strrepInFile(targetFile, '%%module_name_sc%%', module_name_sc);
            strrepInFile(targetFile, '%%module_name_usc%%', module_name_usc);
            strrepInFile(targetFile, '%%module_name_ucc%%', module_name_ucc);
            strrepInFile(targetFile, '%%module_name_unique%%', module_name_unique);
        end
    end
end

% Copy Prefixfile
prefix_source = fullfile(filepath, 'Prefix.txt');
prefix_target = fullfile(moduleDir, 'Prefix.txt');
copyfile(prefix_source, prefix_target)

disp('Done Creating Module.')

end

function strrepInFile(file, old, new)
f = fopen(file,'rt');
X = fread(f);
fclose(f);

X = strrep(char(X.'), old, new);

f = fopen(file, 'wt');
fwrite(f, X);
fclose(f);
end