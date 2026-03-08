% copyMessages - Copies the custom message folder to the PX4 firmware
%
% Syntax:  copyMessages()
%
% Inputs: none
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Written for Use with PX4 Firmware v1.13.2
% Author: 
% University of Stuttgart, Institute of Flight Mechanics and Control
% October 2025;

disp("Start copying msg topics")

filepath = pwd; % get path to current folder
addpath(fullfile(filepath, 'helper_functions')); % add folder with helper functions to path

basepath = fullfile(filepath, '..');
if ~exist(basepath, 'dir')
    error('Codegen files in wrong directory.')
end

msgBaseDir = fullfile(basepath, "common", "msg");
if ~exist(msgBaseDir, 'dir')
    warning("Nothing to copy: 'msg' folder does not exist")
    return
end

if ~exist('wslBasePath', 'var')
    msgWslBaseDir = loadFromConfigOrUi({'msg'});
else
    msgWslBaseDir = fullfile(wslBasePath, 'msg');
end

workDirpath = 'C:\PX4_Firmware_IFR_CodeGen\msg\';
if ~exist(workDirpath, 'dir')
    mkdir(workDirpath);
end
rmdir(workDirpath, 's')
disp("### Copy files to working directory.")
copyfile(msgBaseDir, workDirpath)

disp("### Clear msg folder in wsl.")
rmdir(msgWslBaseDir, 's')

disp("### Copy files from working directory to wsl.")
copyfile(workDirpath, msgWslBaseDir)