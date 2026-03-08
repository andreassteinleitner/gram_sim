function [const]=constants()
    %% constants
    const.stepSize=struct('default', 0.01, 'unit', 's', 'description', 'sampling interval'); % default value, will be overwritten by solver step-size given in Model Configuration Parameters
    % const.example_vector=struct('default', [48.7501*pi/180; 9.1053*pi/180; 508.917], 'type', 'double', 'description', 'default initial position (LLA)');
end