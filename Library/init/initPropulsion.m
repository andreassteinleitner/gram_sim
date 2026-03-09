function propulsion = initPropulsion(vehicle)
propulsion.r         = [0;0;0]; %engine position from CG
propulsion.inci      = 0 * pi/180; %engine installation angle [rad]
if vehicle.type == 2 %Funcub
    propulsion.power_max = 620; %W
    propulsion.bias = 1; %W
else
    propulsion.power_max = 5000; %W
    propulsion.bias = 10; %W
end
propulsion.stat_thr  = 10; %N
end