function const =defineConstants_gnc(varargin)
    if nargin < 1
        %J = [1.4707 0 0.545; 0 26.924 0;0.545 0 27.748];
        m = 34.3;
        S = 0.816;
        b = 1.8;
        chord=0.435;
        fuselage = 10;
    else
        %J = varargin{1}.J;
        m = varargin{1}.m;
        S = varargin{1}.S;
        b = varargin{1}.b;
        chord=varargin{1}.chord;
        fuselage = varargin{1}.fuselage;
    end

    const.g                   = struct('default', single(9.80884), 'unit', 'm/s^2', 'description', 'gravitational acceleration in Stuttgart');
    const.rho                 = struct('default', single(1.225), 'unit', 'kg/m^3', 'description', 'Air density in Stuttgart');
    const.vehicle_m           = struct('default', m, 'unit', 'm/s^2', 'description', 'gravitational acceleration in Stuttgart');
    %const.vehicle_J           = struct('default', J, 'unit', 'm/s^2', 'description', 'Vehicle inertia matrix');   
    const.stepSize            = struct('default', 0.01, 'unit', 's', 'description', 'sampling interval'); % default value, will be overwritten by solver step-size given in Model Configuration Parameters
    const.vehicle_S           = struct('default', S, 'unit', 'm^2', 'description', 'Wing area');
    const.vehicle_b           = struct('default', b, 'unit', 'm', 'description', 'Wing span');
    const.vehicle_c           = struct('default', chord, 'unit', 'm', 'description', 'Aerodynamic chord');
    const.vehicle_fuselage_cs = struct('default', fuselage, 'unit', 'm^2', 'description', 'Lateral fuselage cross section');
    
end