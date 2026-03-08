function engine = initEngine(vehicle)

switch vehicle.type
    case 1
        Umax         = 12*4.2;                  % max voltage
        RPMperV      = 185;                 % rpm over voltage
    
        engine.eff   = 0.9;                 % engine electrical efficiency
        Pmax         = 37*95;      %??  % max power U*I
        engine.R     = 8*5*10^-3;            % internal resistance [ohm]
    
        syms ke kf
        OmegaMax  = RPMperV*Umax*2*pi/60;
        I         = (Umax-ke*OmegaMax)/engine.R;
        Meng      = ke*engine.eff*I;
        Pow       = Meng*OmegaMax;
        [kf,ke]   =solve([Pmax;OmegaMax]==[Pow;Meng/kf],[kf,ke]);
    
        engine.ke      = double(ke(2));                          % electrical torque constant [V s / rad]
        engine.kf      = double(kf(2));                          % viscous friction [Nm s / rad]
        engine.J       =  5*10^-5;                             % rotor inertia [kg m^2]
        %engine.Omega0  =  35000*pi/180; % full throttle
        engine.Omega0  =  0*pi/180;
        engine.Imax    =  100;
        engine.type    =  2;
    case {2,3,4}
        Umax         = 25;                  % max voltage
        RPMperV      = 800;                 % rpm over voltage
    
        engine.eff   = 0.9;                 % engine electrical efficiency
        Pmax         = 1200;                % max power
        engine.R     = 66*10^-3;            % internal resistance [ohm]
    
        syms ke kf
        OmegaMax  = RPMperV*Umax*2*pi/60;   
        I         = (Umax-ke*OmegaMax)/engine.R;
        Meng      = ke*engine.eff*I;
        Pow       = Meng*OmegaMax;
        [kf,ke]   =solve([Pmax;OmegaMax]==[Pow;Meng/kf],[kf,ke]);
    
        engine.ke      = double(ke(2));                          % electrical torque constant [V s / rad]
        engine.kf      = double(kf(2));                          % viscous friction [Nm s / rad]
        engine.J       =  0.8*10^-5;                             % rotor inertia [kg m^2]
    %     engine.Omega0  =  40000*pi/180;
        engine.Omega0  =  0*pi/180;
        engine.Imax    =  50;
end