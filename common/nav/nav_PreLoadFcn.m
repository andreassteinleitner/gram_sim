try
    projectRoot = slproject.getCurrentProject().RootFolder;
catch %iFR Codegen does not open simulink project
    projectRoot = fullfile(pwd,'..');
end
addpath(fullfile(projectRoot,'common','helper_functions'))
defineBuses(fullfile(projectRoot,'common','msg'));

if ~exist('navParams','var') || ~exist('navConsts','var')
    navParams = defineParameters_nav();
    navConsts = defineConstants_nav(vehicle);
    [navConsts, navPara]=initParametersAndConstants(navParams,navConsts,'nav');
end

%[constants, ~, parameterDefinition, parameterConnectionBody]=initParametersAndConstants(defineParameters_nav(), defineConstants_nav(), 'nav');
