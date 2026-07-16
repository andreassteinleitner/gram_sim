function [vehicle,AIR_START_FLAG] = initVehicleLocation(vehicleType,AIR_START_FLAG)

%% vehicle
vehicleStruct = vehicleOptions();
if vehicleType == -1
    string = 'Choose Vehicle:\n';
    for k = 1:length(vehicleStruct)
        string = [string num2str(k) ' - ' vehicleStruct{k}.name '\n'];
    end
    vehicleType = input(string);
end

%% location selection
locationStruct = locationOptions();
LOCATION_FLAG_TO = 7;
LOCATION_FLAG_LDG = 6;
location_TO = locationStruct{LOCATION_FLAG_TO};
location_LDG = locationStruct{LOCATION_FLAG_LDG};

if AIR_START_FLAG == -1
    string = 'Start from:\n0 - Ground\n1 - Air\n';
    AIR_START_FLAG = input(string);
end

%% init vehicle
vehicle = vehicleStruct{vehicleType};

initialPitch = 0;%tan((vehicle.gear.right_pos(3)-vehicle.gear.aux_pos(3))/(vehicle.gear.right_pos(1)-vehicle.gear.aux_pos(1))); %deg
HaG = 0.2;%[0,0,1]*(angle2rotation(0, initialPitch, 0)*(vehicle.gear.right_pos));
HaG = HaG+0.2;
if exist('AIR_START_FLAG','var') && AIR_START_FLAG == 1  %Air start
    % vehicle.ctrlStartTime = 2;
    vehicle.landed = 0;
    vehicle.pos0 = location_TO.groundPos + [0 0 100];
    vehicle.vel0 = [50 0 0];
    vehicle.ori0 = [0,0,0]*pi/180;
    vehicle.omega0 = [0;0;0];
else %Ground start
    % vehicle.ctrlStartTime = 10;
    vehicle.landed = 1;
    vehicle.pos0 = location_TO.groundPos + [0 0 HaG];
    vehicle.vel0 = [0,0,0];
    vehicle.ori0 = [0,initialPitch,location_TO.groundHeading*pi/180]; %rad
    vehicle.omega0 = [0;0;0];
end
vehicle.ground_height = location_TO.groundPos(3);

end

function locationStruct = locationOptions()
locationStruct{1}.name          = 'Bangalore Jakkur Airfield 080';
locationStruct{1}.groundPos     = [13.07761808,77.60182142,926];
locationStruct{1}.groundHeading = 80;
locationStruct{1}.altRwyEnd     = 906;
locationStruct{1}.rwyLenth      = 500;
locationStruct{1}.airport       = 1;

locationStruct{2}.name          = 'Bangalore Jakkur Airfield 260';
locationStruct{2}.groundPos     = [13.07761808,77.60182142,906];
locationStruct{2}.groundHeading = 260;
locationStruct{2}.altRwyEnd     = 926;
locationStruct{2}.rwyLenth      = 500;
locationStruct{2}.airport       = 1;

locationStruct{3}.name          = 'Ihinger Hof Airfield 116';
locationStruct{3}.groundPos     = [48.741038,8.917853,490];
locationStruct{3}.groundHeading = 116;
locationStruct{3}.altRwyEnd     = 488;
locationStruct{3}.rwyLenth      = 350;
locationStruct{3}.airport       = 2;

locationStruct{4}.name          = 'Ihinger Hof Airfield 296';
locationStruct{4}.groundPos     = [48.739543,8.922462,488];
locationStruct{4}.groundHeading = 296;
locationStruct{4}.altRwyEnd     = 490;
locationStruct{4}.rwyLenth      = 350;
locationStruct{4}.airport       = 2;

locationStruct{5}.name          = 'Hahnweide Airfield 127';
locationStruct{5}.groundPos     = [48.633751, 9.425991, 353];
locationStruct{5}.groundHeading = 127;
locationStruct{5}.altRwyEnd     = 351;
locationStruct{5}.rwyLenth      = 600;
locationStruct{5}.airport       = 3;

locationStruct{6}.name          = 'Hahnweide Airfield 307';
locationStruct{6}.groundPos     = [48.632432,9.428561,351];
locationStruct{6}.groundHeading = 307;
locationStruct{6}.altRwyEnd     = 353; %353
locationStruct{6}.rwyLenth      = 300;
locationStruct{6}.airport       = 3;

locationStruct{7}.name          = 'Hahnweide Airfield 248';
locationStruct{7}.groundPos     = [48.634499, 9.425089, 353]; %353
locationStruct{7}.groundHeading = 248;
locationStruct{7}.altRwyEnd     = 348; %348
locationStruct{7}.rwyLenth      = 300;
locationStruct{7}.airport       = 3;

locationStruct{8}.name          = 'Hahnweide Airfield 068';
locationStruct{8}.groundPos     = [48.63488, 9.421272, 348];
locationStruct{8}.groundHeading = 068;
locationStruct{8}.altRwyEnd     = 353;
locationStruct{8}.rwyLenth      = 300;
locationStruct{8}.airport       = 3;

locationStruct{9}.name          = 'Equatorial Afrika';
locationStruct{9}.groundPos     = [4.76510881,-2.06634516,50];
locationStruct{9}.groundHeading = 0;
locationStruct{9}.altRwyEnd     = 50;
locationStruct{9}.rwyLenth      = 300;
locationStruct{9}.airport       = 4;
end

function vehicleStruct = vehicleOptions()
vehicleStruct{1}.type = 1;
vehicleStruct{1}.name = 'Gram80';
vehicleStruct{1}.m = 34.3;
vehicleStruct{1}.J = [1.4707 0 0.545; 0 26.924 0;0.545 0 27.748];
vehicleStruct{1}.cg = [1.545 ; 0; 0.094];
vehicleStruct{1}.S = 0.816;
vehicleStruct{1}.b = 1.8;
vehicleStruct{1}.chord = 0.435;
vehicleStruct{1}.fuselage = 10; %Lateral fuselage cross section

refLengthScaled = 0.2;

vehicleStruct{1}.gear.right_pos  = vehicleStruct{1}.cg + [0.05; 0.15; refLengthScaled];
vehicleStruct{1}.gear.left_pos   = vehicleStruct{1}.cg + [0.05; -0.15; refLengthScaled];
vehicleStruct{1}.gear.aux_pos   = vehicleStruct{1}.cg + [-0.5; 0; 0.5*refLengthScaled];

vehicleStruct{1}.gear.main_stiff = 0.4*vehicleStruct{1}.m*9.81/0.04;  %PartOfMassToCarry * g * springDeflectionOnGround
vehicleStruct{1}.gear.aux_stiff = 0.2*vehicleStruct{1}.m*9.81/0.02;  %PartOfMassToCarry * g * springDeflectionOnGround
vehicleStruct{1}.gear.main_damp  = 5*vehicleStruct{1}.m;                 % N/(m/s)
vehicleStruct{1}.gear.aux_damp  = 2*vehicleStruct{1}.m;                 % N/(m/s)

% Gram40
vehicleStruct{2}.type = 2;
vehicleStruct{2}.name = 'Gram40';
vehicleStruct{2}.m = 3.6;
vehicleStruct{2}.J = [0.04 0 0; 0 0.63 0;0 0 0.63];
vehicleStruct{2}.cg = [1.545 ; 0; 0.094];
vehicleStruct{2}.S = 0.25;
vehicleStruct{2}.b = 0.9;
vehicleStruct{2}.chord = 0.23;
vehicleStruct{2}.fuselage = 10; %Lateral fuselage cross section

refLengthScaled = 0.2;

vehicleStruct{2}.gear.right_pos  = vehicleStruct{2}.cg + [0.05; 0.15; refLengthScaled];
vehicleStruct{2}.gear.left_pos   = vehicleStruct{2}.cg + [0.05; -0.15; refLengthScaled];
vehicleStruct{2}.gear.aux_pos   = vehicleStruct{2}.cg + [-0.5; 0; 0.5*refLengthScaled];

vehicleStruct{2}.gear.main_stiff = 0.4*vehicleStruct{2}.m*9.81/0.04;  %PartOfMassToCarry * g * springDeflectionOnGround
vehicleStruct{2}.gear.aux_stiff = 0.2*vehicleStruct{2}.m*9.81/0.02;  %PartOfMassToCarry * g * springDeflectionOnGround
vehicleStruct{2}.gear.main_damp  = 5*vehicleStruct{2}.m;                 % N/(m/s)
vehicleStruct{2}.gear.aux_damp  = 2*vehicleStruct{2}.m;                 % N/(m/s)

% FunCub XL
vehicleStruct{3}.type = 3;
vehicleStruct{3}.name = 'funcubXL';
vehicleStruct{3}.m = 4;
vehicleStruct{3}.J = [0.14145 0 0.01045; 0 0.11240 0;0.01045 0 0.23326];
vehicleStruct{3}.cg = [0.079 ; 0; -0.083];
vehicleStruct{3}.S = 0.4165; %assuming trapezoidal
vehicleStruct{3}.b = 1.7;
vehicleStruct{3}.chord = 0.26;
vehicleStruct{3}.fuselage = 10; %Lateral fuselage cross section

refLengthScaled = 0.2;

vehicleStruct{3}.gear.right_pos  = vehicleStruct{3}.cg + [0.17; 0.18; refLengthScaled];
vehicleStruct{3}.gear.left_pos   = vehicleStruct{3}.cg + [0.17; -0.18; refLengthScaled];
vehicleStruct{3}.gear.aux_pos   = vehicleStruct{3}.cg + [-0.5; 0; refLengthScaled];

vehicleStruct{3}.gear.main_stiff = 0.2*vehicleStruct{3}.m*9.81/0.02;  %PartOfMassToCarry * g * springDeflectionOnGround
vehicleStruct{3}.gear.aux_stiff = 0.4*vehicleStruct{3}.m*9.81/0.04;  %PartOfMassToCarry * g * springDeflectionOnGround
vehicleStruct{3}.gear.main_damp  = 2*vehicleStruct{3}.m;                 % N/(m/s)
vehicleStruct{3}.gear.aux_damp  = 5*vehicleStruct{3}.m ;                 % N/(m/s)

end

