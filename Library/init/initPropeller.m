function propeller = initPropeller(vehicle)

switch vehicle.type
    case 1
        propeller.radius    = 22/2*0.0254;                                     % propeller radius (-> 22'' = 0.5588 m)
        propeller.blades    = 2;                                         % number of propeller blades
        propeller.pitch     = atan(12*0.0254/(2*pi*propeller.radius));        % pitch angle at propeller tip (-> 12'' = 0.305 m)
        propeller.chord     = 0.04;                                      % mean chord of the propeller blades 3....4 cm
        mass                = 0.10;
        propeller.J         = 2*(propeller.radius/2)^2*mass/2; % Steiner's law: mass*lever^2
        propeller.delta     = [0.0087, -0.012, 0.4];    %??            % coefficients proposed by Bailey (A simplified theoretical method..., p. 9) for NACA23012 airfoil for 2e6 < Re < 8e6
        propeller.if        = -3*pi/180;                              % installation angle elevation
        propeller.af        = 0;                                      % installation angle azimuth
        propeller.pos       = [0.5;0;0];                %??          % installation position
    case {2,3,4}
        propeller.radius    = 0.55/2;                                     % propeller radius (-> 18'' = 0.455 m)
        propeller.blades    = 2;                                         % number of propeller blades
        propeller.pitch     = atan(0.3/(2*pi*propeller.radius));        % pitch angle at propeller tip (-> 7'' = 0.18 m)
        propeller.chord     = 0.03;                                      % mean chord of the propeller blades
        mass                = 0.03;
        propeller.J         = 2*(propeller.radius/2)^2*mass/2; % Steiner's law: mass*lever^2
        propeller.delta     = [0.0087, -0.012, 0.4];                     % coefficients proposed by Bailey (A simplified theoretical method..., p. 9) for NACA23012 airfoil for 2e6 < Re < 8e6
        propeller.if        = 0;                                         % installation angle elevation
        propeller.af        = 0;                                         % installation angle azimuth
        propeller.pos       = [0.1;0;0.01];                              % installation position
        propeller.foldSpeed = 50*pi/180;
end