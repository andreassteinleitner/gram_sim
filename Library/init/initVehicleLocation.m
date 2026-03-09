function [vehicle,location_name,to_rnwy,ldg_rnwy,rwyNoise,AIR_START_FLAG] = initVehicleLocation(LOCATION_FLAG_TO,LOCATION_FLAG_LDG,vehicleType,AIR_START_FLAG)

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
if LOCATION_FLAG_TO == -1
    string = 'Choose Start location:\n';
    for k = 1:length(locationStruct)
        string = [string num2str(k) ' - ' locationStruct{k}.name '\n'];
    end
    LOCATION_FLAG_TO = input(string);
    string = 'Start from:\n0 - Ground\n1 - Air\n';
    AIR_START_FLAG = input(string);
end
if LOCATION_FLAG_LDG == -1
    string = 'Choose Landing location:\n';
    for k = 1:length(locationStruct)
        if isequal(locationStruct{k}.airport,locationStruct{LOCATION_FLAG_TO}.airport)
            string = [string num2str(k) ' - ' locationStruct{k}.name '\n'];
        end
    end
    LOCATION_FLAG_LDG = input(string);
end

if AIR_START_FLAG == -1
    string = 'Start from:\n0 - Ground\n1 - Air\n';
    AIR_START_FLAG = input(string);
end
if ~isequal(locationStruct{LOCATION_FLAG_TO}.airport,locationStruct{LOCATION_FLAG_LDG}.airport)
    string = 'Please choose a landing site corresponding to the take-off airport:\n';
    for k = 1:length(locationStruct)
        if isequal(locationStruct{k}.airport,locationStruct{LOCATION_FLAG_TO}.airport)
            string = [string num2str(k) ' - ' locationStruct{k}.name '\n'];
        end
    end
    LOCATION_FLAG_LDG = input(string);
end

%% init location
location_TO = locationStruct{LOCATION_FLAG_TO};
location_LDG = locationStruct{LOCATION_FLAG_LDG};
location_name = location_TO.name;

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

%{
    % Plot landing gear
    for i=1:3
        plotMat(1,i) = vehicle.gear.right_pos(i);
        plotMat(2,i) = vehicle.gear.left_pos(i);
        plotMat(3,i) = vehicle.gear.aux_pos(i);
    end
    figure
    hold on
    plot3(plotMat(:,1),plotMat(:,2),plotMat(:,3),'*r')
    xlabel('x')
    ylabel('y')
    axis([-0.05,0.01,-0.01,0.01,0,0.2])
    view(3)
%}

% runway and ATOL
rwyTOLen = location_TO.rwyLenth;                            %1                  
rwyTOHdg = mod((location_TO.groundHeading+180),360)-180;    %2
rwyTOPos = location_TO.groundPos';                          %345
rwyLDGLen = location_LDG.rwyLenth;                          %6
rwyLDGHdg = mod((location_LDG.groundHeading+180),360)-180;  %7
rwyLDGPos = location_LDG.groundPos';                        %8910
patternCW = 0;                                              %11
GPA = -13;                                                   %12
baseLength = 400;                                           %13
finalLength = 500;                                          %14
hFlare = -15;                                                %15
wpRadius = 60;                                              %16
abortAngle = 4;                                             %17
V_TO_slow = 7;                                             %18
V_TO_fast = 15;                                             %19
V_TO_excess = 23;                                           %20
V_glide = 15;                                               %21
fake_alt = 0;                                               %22
abort_ldg = 0;                                              %23
climboutAngle = 6;                                              %24
rwyTOAltEnd = location_TO.altRwyEnd;
rwyLDGAltEnd = location_LDG.altRwyEnd;

% rnwy_coeffs = [rwyTOLen, rwyTOHdg, rwyTOPos(1)*10^7, rwyTOPos(2)*10^7, rwyTOPos(3)*10^3, rwyLDGLen, rwyLDGHdg, rwyLDGPos(1)*10^7, rwyLDGPos(2)*10^7, rwyLDGPos(3)*10^3, patternCW, GPA, baseLength, finalLength, hFlare, wpRadius, abortAngle, V_TO_slow, V_TO_fast, V_TO_excess, V_glide, fake_alt, abort_ldg, rwyTOAltEnd*10^3, rwyLDGAltEnd*10^3, climboutAngle];
to_rnwy = single([rwyTOLen, rwyTOHdg, rwyTOPos(1)*10^7, rwyTOPos(2)*10^7, rwyTOPos(3)*10^3, rwyTOAltEnd*10^3]);
ldg_rnwy = single([rwyLDGLen, rwyLDGHdg, rwyLDGPos(1)*10^7, rwyLDGPos(2)*10^7, rwyLDGPos(3)*10^3, rwyLDGAltEnd*10^3]);

%% calculate ground noise
a = (sind(rwyTOPos(1)/2-rwyLDGPos(1)/2))^2+cosd(rwyTOPos(1))*cosd(rwyLDGPos(1))*(sind(rwyTOPos(2)/2-rwyLDGPos(2)/2))^2;
c = 2*atan2(sqrt(a),sqrt(1-a));
d = 6371e3 * c; % distance between TO and LDG
flying_region = ceil(d + rwyTOLen + rwyLDGLen + finalLength);

x_dir = flying_region + 200;
y_dir = flying_region + 200;
amplitude = 1;

im = zeros(x_dir, y_dir);
[x_dir, y_dir] = size(im);
i = 3;
w = sqrt(x_dir*y_dir);
while w > 3
    i = i + 1;
    d = interp2(randn(ceil((x_dir-1)/(2^(i-1))+1),ceil((y_dir-1)/(2^(i-1))+1)), i-1, 'spline');
    im = im + i * d(1:x_dir, 1:y_dir);
    w = w - ceil(w/2 - 1);
end
rwyNoise = amplitude*((im - min(im(:))) / (max(im(:)) - min(im(:)))*2-1);
%figure; imagesc(im); colormap gray;
%figure; surf(im); axis equal;

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

% FunCub XL
vehicleStruct{2}.type = 2;
vehicleStruct{2}.name = 'funcubXL';
vehicleStruct{2}.m = 4;
vehicleStruct{2}.J = [0.14145 0 0.01045; 0 0.11240 0;0.01045 0 0.23326];
vehicleStruct{2}.cg = [0.079 ; 0; -0.083];
vehicleStruct{2}.S = 0.4165; %assuming trapezoidal
vehicleStruct{2}.b = 1.7;
vehicleStruct{2}.chord = 0.26;
vehicleStruct{2}.fuselage = 10; %Lateral fuselage cross section

refLengthScaled = 0.2;

vehicleStruct{2}.gear.right_pos  = vehicleStruct{2}.cg + [0.17; 0.18; refLengthScaled];
vehicleStruct{2}.gear.left_pos   = vehicleStruct{2}.cg + [0.17; -0.18; refLengthScaled];
vehicleStruct{2}.gear.aux_pos   = vehicleStruct{2}.cg + [-0.5; 0; refLengthScaled];

vehicleStruct{2}.gear.main_stiff = 0.2*vehicleStruct{2}.m*9.81/0.02;  %PartOfMassToCarry * g * springDeflectionOnGround
vehicleStruct{2}.gear.aux_stiff = 0.4*vehicleStruct{2}.m*9.81/0.04;  %PartOfMassToCarry * g * springDeflectionOnGround
vehicleStruct{2}.gear.main_damp  = 2*vehicleStruct{2}.m;                 % N/(m/s)
vehicleStruct{2}.gear.aux_damp  = 5*vehicleStruct{2}.m ;                 % N/(m/s)

end

function dcm = angle2rotation(phi,theta,psi)
t1 = [1 0 0;0 cos(phi) -sin(phi);0 sin(phi) cos(phi)];
t2 = [cos(theta) 0 sin(theta);0 1 0;-sin(theta) 0 cos(theta)];
t3 = [cos(psi) -sin(psi) 0;sin(psi) cos(psi) 0;0 0 1];
dcm = t1*t2*t3;
end
