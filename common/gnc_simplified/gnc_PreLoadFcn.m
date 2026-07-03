try
    projectRoot = slproject.getCurrentProject().RootFolder;
catch %iFR Codegen does not open simulink project
    projectRoot = fullfile(pwd,'..');
end
addpath(fullfile(projectRoot,'common','helper_functions'))
defineBuses(fullfile(projectRoot,'common','msg'));

if ~exist('gncParams','var') || ~exist('gncConsts','var')
    gncParams = defineParameters_gnc();
    if exist('vehicle','var')
        gncConsts = defineConstants_gnc(vehicle);
    else
        gncConsts = defineConstants_gnc();
    end
    [gncConsts, gncPara]=initParametersAndConstants(gncParams,gncConsts,'gnc');
end

stepsize_ctrl = evalin('base', get_param(bdroot, 'FixedStep'));