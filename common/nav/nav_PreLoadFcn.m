try
    projectRoot = slproject.getCurrentProject().RootFolder;
catch %iFR Codegen does not open simulink project
    projectRoot = fullfile(pwd,'..');
end
addpath(fullfile(projectRoot,'common','helper_functions'))
%defineBuses(fullfile(projectRoot,'common','msg'));

if ~exist('navParams','var') || ~exist('navConsts','var')
    navParams = defineParameters_nav();
    if exist('vehicle','var')
        navConsts = defineConstants_nav(vehicle);
    else
        navConsts = defineConstants_nav();
    end
    [navConsts, navPara]=initParametersAndConstants(navParams,navConsts,'nav');
end

%[constants, ~, parameterDefinition, parameterConnectionBody]=initParametersAndConstants(defineParameters_nav(), defineConstants_nav(), 'nav');
stepsize_ctrl = evalin('base', get_param(bdroot, 'FixedStep'));