function [const]=defineConstants_nav(varargin)
% const.example_vector=struct('default', [48.7501*pi/180; 9.1053*pi/180; 508.917], 'type', 'double', 'description', 'default initial position (LLA)');
if nargin < 1
    sampletime = 0.01;
    position0 = [48.6340;9.4321;353.3382];
    vehicle_height = 0.3382;
    ground_height = position0(3)-vehicle_height;
    air_start = 0;
else
    vehicle = varargin{1};
    sampletime = vehicle.sampletime;
    position0 = vehicle.pos0;
    ground_height = vehicle.ground_height;
    air_start = ~vehicle.landed;
end

const.stepSize           = struct('default', sampletime, 'unit', 's', 'description', 'sampling interval'); % default value, will be overwritten by solver step-size given in Model Configuration Parameters

const.atmosphereKappa    =struct('default', 1.235, 'description', 'heat capacity ratio for computing height from pressure');
const.temperatureGradient=struct('default', 0.0065, 'description', 'termperature gradient for computing height from pressure');
const.referenceTemperature=struct('default', 288.15, 'description', 'reference temperature for computing height from pressure');
const.referencePressure  = struct('default', 1.01325e5, 'description', 'reference pressure for computing height from pressure');
const.initialPositionLla = struct('default', [position0(1); position0(2); ground_height], 'type', 'double', 'description', 'default initial position (LLA)');
const.initialBaroReading =struct('default', position0(3) - ground_height, 'description', 'reference height for initial baro reading in simulation');
wgs84                    = load('WGS84mag.mat');
wgs84CoeffDescription    = 'Gauss coefficient for WGS 84 magnetic field model';
const.g0                 = struct('default', wgs84.g0, 'type', 'double', 'description', wgs84CoeffDescription);
const.h0                 = struct('default', wgs84.h0, 'type', 'double', 'description', wgs84CoeffDescription);
const.dg                 = struct('default', wgs84.dg, 'type', 'double', 'description', wgs84CoeffDescription);
const.dh                 = struct('default', wgs84.dh, 'type', 'double', 'description', wgs84CoeffDescription);
const.g                  = struct('default', single(9.80884), 'unit', 'm/s^2', 'description', 'gravitational acceleration in Stuttgart');

const.gpsDelay           = struct('default', 0.18, 'unit', 's', 'description', 'GPS time delay ');
const.magDelay           = struct('default', 0.0, 'unit', 's', 'description', 'magnetometer time delay');
const.opticalFlowDelay   = struct('default', 0.035, 'unit', 's', 'description', 'optical flow time delay');
const.filterDelay        = struct('default', max([const.gpsDelay.default, const.magDelay.default, const.opticalFlowDelay.default]), 'unit', 's', 'description', 'resulting filter delay');
const.minCalibrationTime = struct('default', 2, 'unit', 's', 'description', 'lower bound for the calibration timespan');
%minCalibrationTime > max(defaultConsts.forcesSuppressedTime)!!

const.lidarMinRange      = struct('default', 0.001, 'unit', 'm', 'description', 'minimum value of lidar measurement');
const.lidarMaxRange      = struct('default', 30, 'unit', 'm', 'description', 'maximum range of lidar measurement');

const.airStart           = struct('default', air_start, 'description', 'Simulation initialized in air');

const.Zalpha             = struct('default', -155.1208, 'unit', 'm/s^2', 'description', 'Aerodynamic coefficient');
const.Ybeta              = struct('default', -9.0732, 'unit', 'm/s^2', 'description', 'Aerodynamic coefficient');

end
