try
    projectRoot = slproject.getCurrentProject().RootFolder;
catch %iFR Codegen does not open simulink project
    projectRoot = fullfile(pwd,'..');
end
addpath(fullfile(projectRoot,'common','helper_functions'))
defineBuses(fullfile(projectRoot,'common','msg'));

if ~exist('gncParams','var') || ~exist('gncConsts','var')
    gncParams = defineParameters_gnc();
    gncConsts = defineConstants_gnc(vehicle);
    [gncConsts, gncPara]=initParametersAndConstants(gncParams,gncConsts,'gnc');
end
