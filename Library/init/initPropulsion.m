function propulsion = initPropulsion()
propulsion.r         = [0;0;0]; %engine position from CG
propulsion.inci      = 0 * pi/180; %engine installation angle [rad]
propulsion.power_max = 620; %W
propulsion.stat_thr  = 1; %N
end