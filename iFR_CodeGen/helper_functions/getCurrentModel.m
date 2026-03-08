function [model_name, model_name_wrapper, model_dir] = getCurrentModel(moduleName,prefix)
% shortened modulname
name = erase(moduleName,prefix);

% modeldirectory
scriptPath = mfilename('fullpath');
[filepath, ~, ~] = fileparts(scriptPath);
model_dir = fullfile(filepath, '..', '..', 'common', name);
addpath(model_dir);

name_wrapper = join([name,'_wrapper_firmware']);
%model name
if exist([name '.slx'], 'file')
    model_name = name;
else
    error('Aborting. Model with such a name does not exist in controllermodel.')
end
% model wrapper name
if exist([name_wrapper '.slx'], 'file')
    model_name_wrapper = name_wrapper;
else
    model_name_wrapper = [];
    disp('Warning: Corresponding model wrapper not found. Continuing anyway.')
end