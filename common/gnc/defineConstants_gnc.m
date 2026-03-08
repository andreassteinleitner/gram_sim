function const =defineConstants_gnc(varargin)
    if nargin < 1
        step = 0.01;
        J = [0.2139,0,-0.0015;0,0.2251,0;-0.0015,0,0.4362];
        m = 4.2;
        S = 0.468;
        b = 2.41;
        chord=0.245;
        fuselage = 10;
    else
        step = varargin{1}.sampletime;
        J = varargin{1}.J;
        m = varargin{1}.m;
        S = varargin{1}.S;
        b = varargin{1}.b;
        chord=varargin{1}.chord;
        fuselage = varargin{1}.fuselage;
    end

    const.g                   = struct('default', single(9.80884), 'unit', 'm/s^2', 'description', 'gravitational acceleration in Stuttgart');
    const.rho                 = struct('default', single(1.225), 'unit', 'kg/m^3', 'description', 'Air density in Stuttgart');
    const.vehicle_m           = struct('default', m, 'unit', 'm/s^2', 'description', 'gravitational acceleration in Stuttgart');
    const.vehicle_J           = struct('default', J, 'unit', 'm/s^2', 'description', 'Vehicle inertia matrix');   
    const.stepSize            = struct('default', step, 'unit', 's', 'description', 'sampling interval'); % default value, will be overwritten by solver step-size given in Model Configuration Parameters
    const.vehicle_S           = struct('default', S, 'unit', 'm^2', 'description', 'Wing area');
    const.vehicle_b           = struct('default', b, 'unit', 'm', 'description', 'Wing span');
    const.vehicle_c           = struct('default', chord, 'unit', 'm', 'description', 'Aerodynamic chord');
    const.vehicle_fuselage_cs = struct('default', fuselage, 'unit', 'm^2', 'description', 'Lateral fuselage cross section');
    
end