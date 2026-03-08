function sensors = initSensors(vehicle)
%% Sensor Parameters

sensors.IMU.timestep = 0.01;
%IMU lever arm with respect to airplane cg
sensors.IMU.sensor_position=[0;0;0];
%rotation of IMU w.r.t aircraftframe with mounting uncertainty of sigma=2°
sensors.IMU.phi_sensor   = 180*pi/180 ;
sensors.IMU.theta_sensor = 90*pi/180;
sensors.IMU.psi_sensor   = 180*pi/180;
sensors.IMU.b_sensorRM=[cos(sensors.IMU.theta_sensor)*cos(sensors.IMU.psi_sensor)                                                       cos(sensors.IMU.theta_sensor)*sin(sensors.IMU.psi_sensor)                                                   -sin(sensors.IMU.theta_sensor);
    -cos(sensors.IMU.phi_sensor)*sin(sensors.IMU.psi_sensor)+sin(sensors.IMU.phi_sensor)*sin(sensors.IMU.theta_sensor)*cos(sensors.IMU.psi_sensor)      cos(sensors.IMU.phi_sensor)*cos(sensors.IMU.psi_sensor)+sin(sensors.IMU.phi_sensor)*sin(sensors.IMU.theta_sensor)*sin(sensors.IMU.psi_sensor)   sin(sensors.IMU.phi_sensor)*cos(sensors.IMU.theta_sensor)
    sin(sensors.IMU.phi_sensor)*sin(sensors.IMU.psi_sensor)+cos(sensors.IMU.phi_sensor)*sin(sensors.IMU.theta_sensor)*cos(sensors.IMU.psi_sensor)       -sin(sensors.IMU.phi_sensor)*cos(sensors.IMU.psi_sensor)+cos(sensors.IMU.phi_sensor)*sin(sensors.IMU.theta_sensor)*sin(sensors.IMU.psi_sensor)  cos(sensors.IMU.phi_sensor)*cos(sensors.IMU.theta_sensor)];
%Gyro parameters (ADIS16407)
sensors.IMU.g_axis_mis= randn(1)*0.5*0.05*pi/180;              %axis-to-axis misalignment [rad]
sensors.IMU.g_initial_bias = [0 0 0]*pi/180; %3*randn(3,1)*pi/180;              %inital bias [rad/s]
sensors.IMU.g_inrun_bias=0.007*pi/180;                         %standart deviation of in-run bias stability [rad/s]
sensors.IMU.g_noise=0.045*pi/180;%0.8*pi/180;                                %standart deviation output noise [rad/s] rms
sensors.IMU.g_range=300*pi/180;                                %dynamic range [rad/s]
sensors.IMU.g_qstep=0.05;                                      %Sensitivity [deg/s/LSB]
%Transformation matrix for axis-to-axis misalignment of gyros
sensors.IMU.g_coord_comp1=-1/3*sqrt(-2*sqrt(-2*(cos(pi/2+sensors.IMU.g_axis_mis))^2+cos(pi/2+sensors.IMU.g_axis_mis)+1)+cos(pi/2+sensors.IMU.g_axis_mis)+2);
sensors.IMU.g_coord_comp2=sqrt(1-2*sensors.IMU.g_coord_comp1^2);
sensors.IMU.g_coord_ex=[sensors.IMU.g_coord_comp2; sensors.IMU.g_coord_comp1;sensors.IMU.g_coord_comp1];
sensors.IMU.g_coord_ey=[sensors.IMU.g_coord_comp1;sensors.IMU.g_coord_comp2;sensors.IMU.g_coord_comp1];
sensors.IMU.g_coord_ez=[sensors.IMU.g_coord_comp1;sensors.IMU.g_coord_comp1;sensors.IMU.g_coord_comp2];
sensors.IMU.g_coord_TM=inv([sensors.IMU.g_coord_ex sensors.IMU.g_coord_ey sensors.IMU.g_coord_ez]);
%Acc parameters (ADIS16407)
sensors.IMU.acc_axis_mis= randn(1)*0.5*0.2*pi/180;             %axis-to-axis misalignment [rad]
sensors.IMU.acc_initial_bias = [0 0 0]; %5/1000*randn(3,1)*9.81;         %inital bias [m/s^2]
sensors.IMU.acc_inrun_bias=0.2*9.81/1000;                      %standart deviation of in-run bias stability [m/s^2]
sensors.IMU.acc_noise=0.013;%0.009*9.81;                              %standart deviation of output noise [m/s^2] rms
sensors.IMU.acc_range=18*9.81;                                 %dynamic range [m/s^2]
sensors.IMU.acc_qstep=3.33e-3;                                 %Sensitivity [g/LSB]
%Transformation matrix for axis-to-axis misalignment of accelerometers
sensors.IMU.acc_coord_comp1=-1/3*sqrt(-2*sqrt(-2*(cos(pi/2+sensors.IMU.acc_axis_mis))^2+cos(pi/2+sensors.IMU.acc_axis_mis)+1)+cos(pi/2+sensors.IMU.acc_axis_mis)+2);
sensors.IMU.acc_coord_comp2=sqrt(1-2*sensors.IMU.acc_coord_comp1^2);
sensors.IMU.acc_coord_ex=[sensors.IMU.acc_coord_comp2; sensors.IMU.acc_coord_comp1;sensors.IMU.acc_coord_comp1];
sensors.IMU.acc_coord_ey=[sensors.IMU.acc_coord_comp1;sensors.IMU.acc_coord_comp2;sensors.IMU.acc_coord_comp1];
sensors.IMU.acc_coord_ez=[sensors.IMU.acc_coord_comp1;sensors.IMU.acc_coord_comp1;sensors.IMU.acc_coord_comp2];
sensors.IMU.acc_coord_TM=inv([sensors.IMU.acc_coord_ex sensors.IMU.acc_coord_ey sensors.IMU.acc_coord_ez]);
%position of IMU w.r.t acc sensor frame
sensors.IMU.inclined_sensor_position= sensors.IMU.acc_coord_TM*sensors.IMU.b_sensorRM*sensors.IMU.sensor_position;

% gps sensor model
sensors.gps.R = 6378137;
sensors.gps.sigmaPos = [1.5 1.5 4];
sensors.gps.sigmaVel = [0.06 0.06 0.09];
sensors.gps.timestep = 0.2;
sensors.gps.freq = sensors.gps.timestep/(1/100);

% Mag sensor model
sensors.mag.sigma = 0.115; %unit milligauss
sensors.mag.reference = magnet(vehicle.pos0,2021); %unit milligauss
sensors.mag.freq = 1;

% Air Data sensor model
sensors.airData.sigmaHCA = 0.06; % not req. mBar
sensors.airData.sigmaAdis = 0.027; % ambient pressure mBar
sensors.airData.sigmaDiff = 0.0012; % diff pressure mBar
sensors.airData.freq = 1;

%Lidar sensor model
load('lidarErrorPDF.mat');
sensors.lidar.sigma = 0.015;
sensors.lidar.maxRange = 30;
sensors.lidar.minRange = 0.1;
sensors.lidar.pdf = pd;
sensors.lidar.freq = 4;
end

function magRefNED = magnet(llh, year)  % Outputs - magnetic field strength in local tangential coordinates % Br B in radial direction % Bt B in theta direction % Bp B in phi direction
wgs84 = load('WGS84mag.mat');
days = round(max(single(year-2000), single(0))*365.25);
lat = pi/2-llh(1)*pi/180;
lon = llh(2)*pi/180;
a = 6371200;
r = a+llh(3);
% Checks to see if located at either pole to avoid singularities
if (lat>single(-pi*1e-7) && lat<single(pi*1e-7))
    lat=single(pi*1e-7);
elseif(lat<single(pi*(1+1e-7)) && lat>single(pi*(1-1e-7)))
    lat=single(pi*(1-1e-7));
end

N=13;
g = wgs84.g0 + wgs84.dg*days/365.25;
h = wgs84.h0 + wgs84.dh*days/365.25;

[Br, Bt, Bp, dP11, dP10, P20, dP20]=deal(single(0));
[P10, P11]=deal(single(1));
[cosLat, sinLat]=deal(cos(lat), sin(lat));
for m=0:N
    for n=1:N
        if m<=n
            % Calculate Legendre polynomials and derivatives recursively
            if n==m
                P2 = sinLat*P11;
                dP2 = sinLat*dP11 + cosLat*P11;
                P11=P2; P10=P11; P20=single(0); dP11=dP2; dP10=dP11; dP20=single(0);
            elseif n==1
                P2 = cosLat*P10;
                dP2 = cosLat*dP10 - sinLat*P10;
                P20=P10; P10=P2; dP20=dP10; dP10=dP2;
            else
                K = ((n-1)^2-m^2)/((2*n-1)*(2*n-3));
                P2 = cosLat*P10 - K*P20;
                dP2 = cosLat*dP10 - sinLat*P10 - K*dP20;
                P20=P10; P10=P2; dP20=dP10; dP10=dP2;
            end
            Br = Br + (a/r)^(n+2)*(n+1)*((g(n,m+1)*cos(m*lon) + h(n,m+1)*sin(m*lon))*P2);
            Bt = Bt + (a/r)^(n+2)*((g(n,m+1)*cos(m*lon) + h(n,m+1)*sin(m*lon))*dP2);
            Bp = Bp + (a/r)^(n+2)*(m*(-g(n,m+1)*sin(m*lon) + h(n,m+1)*cos(m*lon))* P2);
        end
    end
end
magRefSphere = [Br;-Bt;-Bp/sinLat];
e = 0*pi/180;
magRefNED = [-sin(e),-cos(e),0;0,0,1;-cos(e),sin(e),0]*magRefSphere*10^-2;
end
