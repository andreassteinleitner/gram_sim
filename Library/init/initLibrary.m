%% Vehicle ridgid body data
if ~exist('AIR_START_FLAG')
    AIR_START_FLAG = -1;
end
if ~(exist('LOCATION_FLAG_TO','var') || exist('LOCATION_FLAG_LDG','var'))
    LOCATION_FLAG_TO = -1;
    LOCATION_FLAG_LDG = -1;
end
if ~exist('vehicleType')
    vehicleType = -1;
end
[vehicle,location_name,to_rnwy,ldg_rnwy,rwyNoise,AIR_START_FLAG] = initVehicleLocation(LOCATION_FLAG_TO,LOCATION_FLAG_LDG,vehicleType,AIR_START_FLAG);

%% Gear
%gear = initLandingGear();

%% Atmosphere
atmosphere = initAtmos();

%% Aerodynamic
aerodynamic = initAero_old(vehicle);

%% Battery
battery = initBattery(vehicle);

%% Engine
engine = initEngine(vehicle); %electric propulsion
propulsion = initPropulsion(); %combustion engine

%% Propeller
propeller = initPropeller(vehicle);

%% Servos
servo = initServos();

%% Sensors
sensors = initSensors(vehicle);

%% Buses
initBusDef(1); %SiL