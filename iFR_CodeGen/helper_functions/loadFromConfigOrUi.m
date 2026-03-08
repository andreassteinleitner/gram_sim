function [moduleBaseDir] = loadFromConfigOrUi(goto, configFile)
    if nargin < 2 || isempty(configFile)
        configFile = 'config.mat';
    end
    if nargin < 1 || isempty(goto)
        goto = [''];
    end

    if isfile(configFile)
        loadedConfig = load(configFile);
        if isfield(loadedConfig, 'config') && isfield(loadedConfig.config, 'wslBasePath')
            moduleBaseDir = fullfile(loadedConfig.config.wslBasePath, goto{:});
            fprintf('Using path from config: %s \n', moduleBaseDir);
        end
    else
        disp(['go to: ' strjoin(goto, '/')])
        moduleBaseDir = fullfile(uigetdir);
    end
end