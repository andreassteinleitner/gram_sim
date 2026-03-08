function [params]=defineParameters_nav(varargin)
%% parameters
%% name field must be upper case
%% name field must not exceed 12 letters
%% field min is optional
%% field max is optional

if nargin==1
    refHeight = varargin{1}.ground_height;
else
    refHeight = 392; %Ihinger Hof
    disp('WARNING: Prompting vehicle status at initialization failed. State estimation initialized on ground.')
end

%% navigation params
params.imu_filt.use_acc   = struct('default', 1, 'description', 'Decide if IMU filter module should be used for accelerations (1) or not (0)', 'name', 'IMU_FIL_ACC', 'group','IFR_NAV');
params.imu_filt.use_rte   = struct('default', 1, 'description', 'Decide if IMU filter module should be used for angular velocities (1) or not (0)', 'name', 'IMU_FIL_RTE', 'group','IFR_NAV');

params.sigmaMag=struct('default', 0.115, 'description', 'magnetic field measurement standard deviation', 'name', 'MAG_STD', 'group','IFR_NAV');
params.sigmaGpsPosXy=struct('default', 1.5, 'description', 'GPS horizontal (x-y-axis) position standard deviation', 'unit', 'm', 'name', 'GPS_HPOS_STD', 'group','IFR_NAV');
params.sigmaGpsPosZ=struct('default', 4, 'description', 'GPS vertical (z-axis) position standard deviation', 'unit', 'm', 'name', 'GPS_VPOS_STD', 'group','IFR_NAV');
params.sigmaGpsVelXy=struct('default', 0.06, 'description', 'GPS horizontal (x-y-axis) velocity standard deviation', 'unit', 'm/s', 'name', 'GPS_HVEL_STD', 'group','IFR_NAV');
params.sigmaGpsVelZ=struct('default', 0.09, 'description', 'GPS vertical (z-axis) velocity standard deviation', 'unit', 'm/s', 'name', 'GPS_VVEL_STD', 'group','IFR_NAV');
params.sigmaAccelerationUpdate=struct('default', 0.1, 'description', 'Update of acceleration-based attitude correction standard deviation', 'unit', 'm/s^2', 'name', 'ACC_UPDT_STD', 'group','IFR_NAV');
params.sigmaBaro=struct('default', 0.23, 'description', 'barometric height standard deviation', 'unit', 'm', 'name', 'BARO_STD', 'group','IFR_NAV');
params.sigmaGyro=struct('default', 0.045, 'description', 'gyroscope standard deviation', 'unit', 'rad', 'name', 'GYRO_STD', 'group','IFR_NAV');
params.sigmaAcc=struct('default', 0.013, 'description', 'acceleration standard deviation', 'unit', 'm/s^2', 'name', 'ACC_STD', 'group','IFR_NAV');
params.gpsTimeout=struct('default', 5, 'description', 'time after which GPS is considered unavailable', 'unit', 's', 'name', 'GPS_TIMEOUT', 'group','IFR_NAV');
params.losRateDistanceTimeout=struct('default', 0.5, 'description', 'Max time after detection of communication loss or exceeding distance limit', 'unit', 's', 'name', 'L_RT_D_TOUT', 'group','IFR_NAV');
params.biasSmoothingGain=struct('default', 0.005, 'description', 'weight of current measurement in recursive bias determination', 'min', 0.005, 'max', 0.5, 'name', 'SMOOTHING', 'group','IFR_NAV');
params.gpsAccuracyThreshold=struct('default', 20, 'description', 'only use GPS measurements with this horizontal accuracy or better', 'min', 0.5, 'max', 30, 'unit', 'm', 'name', 'GPS_THRESH', 'group','IFR_NAV');

params.referenceHeight = struct('default', refHeight, 'description', 'Reference height of ground for Baro', 'name', 'REF_HEIGHT', 'group','IFR_NAV');
params.dynRefHeight = struct('default', 1, 'description', 'Determine reference height dynamically', 'name', 'DYN_H_DETERM', 'group','IFR_NAV');

params.gpsBufferTime = struct('default', 4, 'max', 40, 'description', 'Time period for gps reference averaging', 'name', 'GPS_BUFFER_T', 'group','IFR_NAV');

params.aeroFilCOfreq = struct('default', 0.5, 'unit', '1/s', 'description', 'Cut-off frequency for aerodynamic angle measurement filter', 'name', 'AERO_FIL_OME', 'group','IFR_NAV');
params.aeroFiltActive= struct('default', 1, 'unit', '', 'description', 'Filter switch', 'name', 'AERO_FIL_ON', 'group','IFR_NAV');
params.Zalpha        = struct('default', -155.1208, 'unit', 'm/s^2', 'description', 'Aerodynamic coefficient', 'name', 'Z_ALPHA', 'group','IFR_NAV');
params.Ybeta         = struct('default', -9.0732, 'unit', 'm/s^2', 'description', 'Aerodynamic coefficient', 'name', 'Y_BETA', 'group','IFR_NAV');
params.alphaConv     = struct('default', 1.9428, 'description', 'Conversion from voltage to alpha', 'name', 'ALPHA_CONV', 'group','IFR_NAV');
params.betaConv      = struct('default', 2.3954, 'description', 'Conversion from voltage to beta', 'name', 'BETA_CONV', 'group','IFR_NAV');
params.alphaOff      = struct('default', -3.5651, 'description', 'Offset from voltage to alpha', 'name', 'ALPHA_OFF', 'group','IFR_NAV');
params.betaOff       = struct('default', -2.8122, 'description', 'Offset from voltage to beta', 'name', 'BETA_OFF', 'group','IFR_NAV');
params.channelSwitch = struct('default', 0, 'description', 'ADC channels are switched', 'name', 'ADC_CHSWITCH', 'group','IFR_NAV');

params.lidar_offset = struct('default', 0, 'description', 'Offset on lidar measurement', 'name', 'LIDAR_OFF', 'group','IFR_NAV');

params.pix_roll = struct('default', pi, 'description', 'X axis orientation of pixhawk mount', 'name', 'PIX_ROLL', 'group','IFR_NAV');
params.pix_pitch = struct('default', deg2rad(0), 'description', 'Y axis orientation of pixhawk mount', 'name', 'PIX_PITCH', 'group','IFR_NAV');
params.pix_yaw = struct('default', deg2rad(0), 'description', 'Z axis orientation of pixhawk mount', 'name', 'PIX_YAW', 'group','IFR_NAV');

params.xi_max = struct('default', 11, 'description', 'xi_max', 'name', 'XI_MAX', 'group','IFR_NAV');
params.eta_max = struct('default', 13, 'description', 'eta_max', 'name', 'ETA_MAX', 'group','IFR_NAV');
params.zeta_max = struct('default', 21, 'description', 'zeta_max', 'name', 'ZETA_MAX', 'group','IFR_NAV');
params.lidar_enabled = struct('default', 1, 'description', 'lidar_enabled', 'name', 'LIDAR_ENABLED', 'group','IFR_NAV');
params.chiVel = struct('default', 2, 'description', 'chiVel', 'name', 'CHI_VEL', 'group','IFR_NAV');
params.VaDisabled = struct('default', 0, 'description', 'Va (Airspeed-sensor) Disabled', 'name', 'VA_DISABLED', 'group','IFR_NAV');

%% Signs
params.rcsigns.ail = struct('default', 1, 'description', 'Sign of control command aileron', 'name', 'RC_AIL', 'group','IFR_NAV');
params.rcsigns.ele = struct('default', 1, 'description', 'Sign of control command elevator', 'name', 'RC_ELE', 'group','IFR_NAV');
params.rcsigns.rud = struct('default', 1, 'description', 'Sign of control command rudder', 'name', 'RC_RUD', 'group','IFR_NAV');
params.rcsigns.thr = struct('default', 1, 'description', 'Sign of control command thrust', 'name', 'RC_THR', 'group','IFR_NAV');

end
