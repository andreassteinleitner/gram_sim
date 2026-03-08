function const = defineConstants(vehicle)
% const.example_vector=struct('default', [48.7501*pi/180; 9.1053*pi/180; 508.917], 'type', 'double', 'description', 'default initial position (LLA)');

position0 = vehicle.pos0;
ground_height = vehicle.ground_height;

%% constants
const.atmosphereKappa     = struct('default', 1.235, 'description', 'heat capacity ratio for computing height from pressure');
const.temperatureGradient = struct('default', 0.0065, 'description', 'termperature gradient for computing height from pressure');
const.referenceTemperature= struct('default', 288.15, 'description', 'reference temperature for computing height from pressure');
const.referencePressure   = struct('default', 1.01325e5, 'description', 'reference pressure for computing height from pressure');
const.initialPositionLla  = struct('default', [position0(1); position0(2); ground_height], 'type', 'double', 'description', 'default initial position (LLA)');
const.forcesSuppressedTime= struct('default', 1.9, 'type', 'double', 'description', 'Time after start without forces to initialise pixhawk estimation in equilibrium state');
%forcesSuppressedTime < navConsts.minCalibrationTime!!
const.startTakeOff        = struct('default', 7, 'type', 'double', 'description', 'Time at which take-off is initiated by RC emulator');
const.startLanding        = struct('default', 40, 'type', 'double', 'description', 'Time at which landing is initiated by RC emulator');
const.groundStart         = struct('default', vehicle.landed, 'type', 'double', 'description', 'Simulation initialisation on ground');
const.sensorsReal         = struct('default', 0, 'type', 'double', 'description', 'Sensor validity emulated from real conditions');

const.gpsDelay           = struct('default', 0.18, 'unit', 's', 'description', 'GPS time delay ');
const.lidarMaxRange      = struct('default', 35, 'unit', 'm', 'description', 'Range for valid lidar measurements');

wgs84                    = load('WGS84mag.mat');
wgs84CoeffDescription    = 'Gauss coefficient for WGS 84 magnetic field model';
const.g0                 = struct('default', wgs84.g0, 'type', 'double', 'description', wgs84CoeffDescription);
const.h0                 = struct('default', wgs84.h0, 'type', 'double', 'description', wgs84CoeffDescription);
const.dg                 = struct('default', wgs84.dg, 'type', 'double', 'description', wgs84CoeffDescription);
const.dh                 = struct('default', wgs84.dh, 'type', 'double', 'description', wgs84CoeffDescription);
const.g                  = struct('default', single(9.80884), 'unit', 'm/s^2', 'description', 'gravitational acceleration in Stuttgart');

const.wind_type          = struct('default', 1, 'description', 'Use random von Karman wind model (1) or sine-wave head and tail wind model (2)');
const.wind_start         = struct('default', 0, 'description', 'Start time for wind activation');
const.wind_augment       = struct('default', 0, 'description', 'If wind model 2 is selected, wind can be augmented additionally with scaling factor');

end