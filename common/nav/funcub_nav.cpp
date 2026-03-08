/**
 * iFR GNC - simulink - PX4 interface
 * Institut fuer Flugmechanik und Flugregelung
 * Copyright 2018 Universitaet Stuttgart.
 *
 * @author Lorenz Schmitt <lorenz.schmitt@ifr.uni-stuttgart.de>
 * @author Pascal Groß <pascal.gross@ifr.uni-stuttgart.de>
 */

#include <drivers/drv_hrt.h>
#include <px4_tasks.h>
#include <px4_time.h>
#include <errno.h>

extern "C" {
    #include "tasl_px4_nav_ert_rtw/tasl_px4_nav.h"
}
#include "tasl_px4_nav.h"

TaslPx4Nav::TaslPx4Nav():
        mLaunchTime(getHiResTime()),
        mActuatorArmed(orb_subscribe(ORB_ID(actuator_armed))),
        mSensorGyro(orb_subscribe(ORB_ID(sensor_gyro))),
        mSensorAccel(orb_subscribe(ORB_ID(sensor_accel))),
        mSensorBaro(orb_subscribe(ORB_ID(sensor_baro))),
        mVehicleMagnetometer(orb_subscribe(ORB_ID(vehicle_magnetometer))),
        mVehicleGpsPosition(orb_subscribe(ORB_ID(vehicle_gps_position))),
        mDistanceSensor(orb_subscribe(ORB_ID(distance_sensor))),
        mVehicleStatus(orb_subscribe(ORB_ID(vehicle_status))),
        mAdcReport(orb_subscribe(ORB_ID(adc_report))),
        mAirspeed(orb_subscribe(ORB_ID(airspeed))),
        mVehicleLocalPosition(orb_advertise(ORB_ID(vehicle_local_position), &mVehicleLocalPositionData)),
        mVehicleAttitude(orb_advertise(ORB_ID(vehicle_attitude), &mVehicleAttitudeData)),
        mNavigationHeight(orb_advertise(ORB_ID(navigation_height), &mNavigationHeightData)),
        mSensorsValid(orb_advertise(ORB_ID(sensors_valid), &mSensorsValidData)),
        mNavigationBaro(orb_advertise(ORB_ID(navigation_baro), &mNavigationBaroData)),
        mNavigationState(orb_advertise(ORB_ID(navigation_state), &mNavigationStateData)),
        mNavigationLidar(orb_advertise(ORB_ID(navigation_lidar), &mNavigationLidarData)),
        mNavigationMag(orb_advertise(ORB_ID(navigation_mag), &mNavigationMagData)),
        mAirdata(orb_advertise(ORB_ID(airdata), &mAirdataData)),
        mParametersAreInitialized(false),
        mParameterUpdate(orb_subscribe(ORB_ID(parameter_update))) {
    mPollingList[0].fd=mParameterUpdate;
    mPollingList[1].fd=mActuatorArmed;
    mPollingList[2].fd=mSensorGyro;
    mPollingList[3].fd=mSensorAccel;
    mPollingList[4].fd=mSensorBaro;
    mPollingList[5].fd=mVehicleMagnetometer;
    mPollingList[6].fd=mVehicleGpsPosition;
    mPollingList[7].fd=mDistanceSensor;
    mPollingList[8].fd=mVehicleStatus;
    mPollingList[9].fd=mAdcReport;
    mPollingList[10].fd=mAirspeed;
    for (auto & entry: mPollingList) entry.events=POLLIN;
    connectParameters();
}

TaslPx4Nav::~TaslPx4Nav() {
    orb_unsubscribe(mParameterUpdate);
    orb_unsubscribe(mActuatorArmed);
    orb_unsubscribe(mSensorGyro);
    orb_unsubscribe(mSensorAccel);
    orb_unsubscribe(mSensorBaro);
    orb_unsubscribe(mVehicleMagnetometer);
    orb_unsubscribe(mVehicleGpsPosition);
    orb_unsubscribe(mDistanceSensor);
    orb_unsubscribe(mVehicleStatus);
    orb_unsubscribe(mAdcReport);
    orb_unsubscribe(mAirspeed);
    orb_unadvertise(mVehicleLocalPosition);
    orb_unadvertise(mVehicleAttitude);
    orb_unadvertise(mNavigationHeight);
    orb_unadvertise(mSensorsValid);
    orb_unadvertise(mNavigationBaro);
    orb_unadvertise(mNavigationState);
    orb_unadvertise(mNavigationLidar);
    orb_unadvertise(mNavigationMag);
    orb_unadvertise(mAirdata);
}

void TaslPx4Nav::run() {
    double stepSize(0.01);
    tasl_px4_nav_initialize();

    while (!should_exit()) {
        double currentTime(getHiResTime());
        
        int pollingResult(px4_poll(mPollingList, 10+1, 1000));
        if (pollingResult>0) copyTopics();
        tasl_px4_nav_U.clock=float(currentTime-mLaunchTime);
        tasl_px4_nav_step();
        publishTopics();

        double timeToBeWaited=stepSize-(getHiResTime()-currentTime)-0.001; // no idea why the 0.001 offset is necessary
        if (timeToBeWaited>0) system_usleep(uint32_t(timeToBeWaited*1e6));
    }
}

int TaslPx4Nav::task_spawn(int argc, char *argv[]) {
    _task_id=px4_task_spawn_cmd("tasl_px4_nav", SCHED_DEFAULT, SCHED_PRIORITY_DEFAULT, 14000, (px4_main_t)&run_trampoline, (char *const *)argv);
    
    if (_task_id<0) {
        _task_id=-1;
        return -errno;
    }
    else return 0;
}

TaslPx4Nav * TaslPx4Nav::instantiate(int argc, char *argv[]) {
    return new TaslPx4Nav();
}

int TaslPx4Nav::print_usage(const char *reason) {
    if (reason) PX4_WARN("%s\n", reason);
    PRINT_MODULE_DESCRIPTION("tasl_px4_nav runs simulink generated GNC code.");
    PRINT_MODULE_USAGE_COMMAND_DESCR("start", "start module thread");
    PRINT_MODULE_USAGE_COMMAND_DESCR("stop", "stop module thread");
    PRINT_MODULE_USAGE_COMMAND_DESCR("status", "return module thread state");
    PRINT_MODULE_USAGE_NAME("tasl_px4_nav", "system");
    return 0;
}

int TaslPx4Nav::custom_command(int argc, char *argv[]) {
    return print_usage("unknown command");
}

double TaslPx4Nav::getHiResTime() {
    hrt_abstime timeInMicroseconds=hrt_absolute_time();
    return 1e-6*double(timeInMicroseconds);
}

void TaslPx4Nav::connectParameters() {
    int j=0;
    mParameters[j].name=param_find("NAV_MAG_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaMag;
    mParameters[j].name=param_find("NAV_GPS_HPOS_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaGpsPosXy;
    mParameters[j].name=param_find("NAV_GPS_VPOS_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaGpsPosZ;
    mParameters[j].name=param_find("NAV_GPS_HVEL_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaGpsVelXy;
    mParameters[j].name=param_find("NAV_GPS_VVEL_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaGpsVelZ;
    mParameters[j].name=param_find("NAV_ACC_UPDT_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaAccelerationUpdate;
    mParameters[j].name=param_find("NAV_BARO_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaBaro;
    mParameters[j].name=param_find("NAV_GYRO_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaGyro;
    mParameters[j].name=param_find("NAV_ACC_STD");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.sigmaAcc;
    mParameters[j].name=param_find("NAV_GPS_TIMEOUT");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.gpsTimeout;
    mParameters[j].name=param_find("NAV_FLOW_TIMEOUT");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.losRateDistanceTimeout;
    mParameters[j].name=param_find("NAV_SMOOTHING");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.biasSmoothingGain;
    mParameters[j].name=param_find("NAV_GPS_THRESH");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.gpsAccuracyThreshold;
    mParameters[j].name=param_find("NAV_REF_HEIGHT");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.referenceHeight;
    mParameters[j].name=param_find("NAV_DYN_H_DETERM");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.dynRefHeight;
    mParameters[j].name=param_find("NAV_GPS_BUFFER_T");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.gpsBufferTime;
    mParameters[j].name=param_find("NAV_AERO_FIL_OME");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.aeroFilCOfreq;
    mParameters[j].name=param_find("NAV_AERO_FIL_ON");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.aeroFiltActive;
    mParameters[j].name=param_find("NAV_Z_ALPHA");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.Zalpha;
    mParameters[j].name=param_find("NAV_Y_BETA");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.Ybeta;
    mParameters[j].name=param_find("NAV_ALPHA_CONV");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.alphaConv;
    mParameters[j].name=param_find("NAV_BETA_CONV");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.betaConv;
    mParameters[j].name=param_find("NAV_ALPHA_OFF");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.alphaOff;
    mParameters[j].name=param_find("NAV_BETA_OFF");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.betaOff;
    mParameters[j].name=param_find("NAV_VANES_VALID");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.vanesValid;
    mParameters[j].name=param_find("NAV_ADC_CHSWITCH");
    mParameters[j++].value=&tasl_px4_nav_U.parameters.channelSwitch;
}

void TaslPx4Nav::copyTopics() {
    bool newParametersAvailable(true);
    if (mParametersAreInitialized) orb_check(mParameterUpdate, &newParametersAvailable);
    if (newParametersAvailable) {
        parameter_update_s data;
        orb_copy(ORB_ID(parameter_update), mParameterUpdate, &data); // necessary because orb_check checks against last orb_copy		
		for (auto & param: mParameters) param_get(param.name, param.value);
        mParametersAreInitialized=true;
    }
    
    if (mPollingList[1].revents & POLLIN) {
        tasl_px4_nav_U.armed.is_valid=true;
        actuator_armed_s data;
        orb_copy(ORB_ID(actuator_armed), mActuatorArmed, &data);
        tasl_px4_nav_U.armed.armed_time_ms=data.armed_time_ms;
        tasl_px4_nav_U.armed.armed=data.armed;
        tasl_px4_nav_U.armed.prearmed=data.prearmed;
        tasl_px4_nav_U.armed.ready_to_arm=data.ready_to_arm;
        tasl_px4_nav_U.armed.lockdown=data.lockdown;
        tasl_px4_nav_U.armed.manual_lockdown=data.manual_lockdown;
        tasl_px4_nav_U.armed.force_failsafe=data.force_failsafe;
        tasl_px4_nav_U.armed.in_esc_calibration_mode=data.in_esc_calibration_mode;
        tasl_px4_nav_U.armed.soft_stop=data.soft_stop;
    }
    else tasl_px4_nav_U.armed.is_valid=false;
    
    if (mPollingList[2].revents & POLLIN) {
        tasl_px4_nav_U.gyro.is_valid=true;
        sensor_gyro_s data;
        orb_copy(ORB_ID(sensor_gyro), mSensorGyro, &data);
        tasl_px4_nav_U.gyro.device_id=data.device_id;
        tasl_px4_nav_U.gyro.error_count=static_cast<double>(data.error_count);
        tasl_px4_nav_U.gyro.x=data.x;
        tasl_px4_nav_U.gyro.y=data.y;
        tasl_px4_nav_U.gyro.z=data.z;
        tasl_px4_nav_U.gyro.integral_dt=data.integral_dt;
        tasl_px4_nav_U.gyro.x_integral=data.x_integral;
        tasl_px4_nav_U.gyro.y_integral=data.y_integral;
        tasl_px4_nav_U.gyro.z_integral=data.z_integral;
        tasl_px4_nav_U.gyro.temperature=data.temperature;
        tasl_px4_nav_U.gyro.scaling=data.scaling;
        tasl_px4_nav_U.gyro.x_raw=data.x_raw;
        tasl_px4_nav_U.gyro.y_raw=data.y_raw;
        tasl_px4_nav_U.gyro.z_raw=data.z_raw;
    }
    else tasl_px4_nav_U.gyro.is_valid=false;
    
    if (mPollingList[3].revents & POLLIN) {
        tasl_px4_nav_U.accel.is_valid=true;
        sensor_accel_s data;
        orb_copy(ORB_ID(sensor_accel), mSensorAccel, &data);
        tasl_px4_nav_U.accel.device_id=data.device_id;
        tasl_px4_nav_U.accel.error_count=static_cast<double>(data.error_count);
        tasl_px4_nav_U.accel.x=data.x;
        tasl_px4_nav_U.accel.y=data.y;
        tasl_px4_nav_U.accel.z=data.z;
        tasl_px4_nav_U.accel.integral_dt=data.integral_dt;
        tasl_px4_nav_U.accel.x_integral=data.x_integral;
        tasl_px4_nav_U.accel.y_integral=data.y_integral;
        tasl_px4_nav_U.accel.z_integral=data.z_integral;
        tasl_px4_nav_U.accel.temperature=data.temperature;
        tasl_px4_nav_U.accel.scaling=data.scaling;
        tasl_px4_nav_U.accel.x_raw=data.x_raw;
        tasl_px4_nav_U.accel.y_raw=data.y_raw;
        tasl_px4_nav_U.accel.z_raw=data.z_raw;
    }
    else tasl_px4_nav_U.accel.is_valid=false;
    
    if (mPollingList[4].revents & POLLIN) {
        tasl_px4_nav_U.baro.is_valid=true;
        sensor_baro_s data;
        orb_copy(ORB_ID(sensor_baro), mSensorBaro, &data);
        tasl_px4_nav_U.baro.device_id=data.device_id;
        tasl_px4_nav_U.baro.error_count=static_cast<double>(data.error_count);
        tasl_px4_nav_U.baro.pressure=data.pressure;
        tasl_px4_nav_U.baro.temperature=data.temperature;
    }
    else tasl_px4_nav_U.baro.is_valid=false;
    
    if (mPollingList[5].revents & POLLIN) {
        tasl_px4_nav_U.mag.is_valid=true;
        vehicle_magnetometer_s data;
        orb_copy(ORB_ID(vehicle_magnetometer), mVehicleMagnetometer, &data);
        tasl_px4_nav_U.mag.magnetometer_ga[0]=data.magnetometer_ga[0];
        tasl_px4_nav_U.mag.magnetometer_ga[1]=data.magnetometer_ga[1];
        tasl_px4_nav_U.mag.magnetometer_ga[2]=data.magnetometer_ga[2];
    }
    else tasl_px4_nav_U.mag.is_valid=false;
    
    if (mPollingList[6].revents & POLLIN) {
        tasl_px4_nav_U.gps.is_valid=true;
        vehicle_gps_position_s data;
        orb_copy(ORB_ID(vehicle_gps_position), mVehicleGpsPosition, &data);
        tasl_px4_nav_U.gps.lat=data.lat;
        tasl_px4_nav_U.gps.lon=data.lon;
        tasl_px4_nav_U.gps.alt=data.alt;
        tasl_px4_nav_U.gps.alt_ellipsoid=data.alt_ellipsoid;
        tasl_px4_nav_U.gps.s_variance_m_s=data.s_variance_m_s;
        tasl_px4_nav_U.gps.c_variance_rad=data.c_variance_rad;
        tasl_px4_nav_U.gps.fix_type=data.fix_type;
        tasl_px4_nav_U.gps.eph=data.eph;
        tasl_px4_nav_U.gps.epv=data.epv;
        tasl_px4_nav_U.gps.hdop=data.hdop;
        tasl_px4_nav_U.gps.vdop=data.vdop;
        tasl_px4_nav_U.gps.noise_per_ms=data.noise_per_ms;
        tasl_px4_nav_U.gps.jamming_indicator=data.jamming_indicator;
        tasl_px4_nav_U.gps.vel_m_s=data.vel_m_s;
        tasl_px4_nav_U.gps.vel_n_m_s=data.vel_n_m_s;
        tasl_px4_nav_U.gps.vel_e_m_s=data.vel_e_m_s;
        tasl_px4_nav_U.gps.vel_d_m_s=data.vel_d_m_s;
        tasl_px4_nav_U.gps.cog_rad=data.cog_rad;
        tasl_px4_nav_U.gps.vel_ned_valid=data.vel_ned_valid;
        tasl_px4_nav_U.gps.timestamp_time_relative=data.timestamp_time_relative;
        tasl_px4_nav_U.gps.time_utc_usec=static_cast<double>(data.time_utc_usec);
        tasl_px4_nav_U.gps.satellites_used=data.satellites_used;
        tasl_px4_nav_U.gps.heading=data.heading;
        tasl_px4_nav_U.gps.heading_offset=data.heading_offset;
    }
    else tasl_px4_nav_U.gps.is_valid=false;
    
    if (mPollingList[7].revents & POLLIN) {
        tasl_px4_nav_U.lidar.is_valid=true;
        distance_sensor_s data;
        orb_copy(ORB_ID(distance_sensor), mDistanceSensor, &data);
        tasl_px4_nav_U.lidar.min_distance=data.min_distance;
        tasl_px4_nav_U.lidar.max_distance=data.max_distance;
        tasl_px4_nav_U.lidar.current_distance=data.current_distance;
        tasl_px4_nav_U.lidar.variance=data.variance;
        tasl_px4_nav_U.lidar.signal_quality=data.signal_quality;
        tasl_px4_nav_U.lidar.type=data.type;
        tasl_px4_nav_U.lidar.MAV_DISTANCE_SENSOR_LASER=data.MAV_DISTANCE_SENSOR_LASER;
        tasl_px4_nav_U.lidar.MAV_DISTANCE_SENSOR_ULTRASOUND=data.MAV_DISTANCE_SENSOR_ULTRASOUND;
        tasl_px4_nav_U.lidar.MAV_DISTANCE_SENSOR_INFRARED=data.MAV_DISTANCE_SENSOR_INFRARED;
        tasl_px4_nav_U.lidar.MAV_DISTANCE_SENSOR_RADAR=data.MAV_DISTANCE_SENSOR_RADAR;
        tasl_px4_nav_U.lidar.id=data.id;
        tasl_px4_nav_U.lidar.orientation=data.orientation;
        tasl_px4_nav_U.lidar.ROTATION_DOWNWARD_FACING=data.ROTATION_DOWNWARD_FACING;
        tasl_px4_nav_U.lidar.ROTATION_UPWARD_FACING=data.ROTATION_UPWARD_FACING;
        tasl_px4_nav_U.lidar.ROTATION_BACKWARD_FACING=data.ROTATION_BACKWARD_FACING;
        tasl_px4_nav_U.lidar.ROTATION_FORWARD_FACING=data.ROTATION_FORWARD_FACING;
        tasl_px4_nav_U.lidar.ROTATION_LEFT_FACING=data.ROTATION_LEFT_FACING;
        tasl_px4_nav_U.lidar.ROTATION_RIGHT_FACING=data.ROTATION_RIGHT_FACING;
    }
    else tasl_px4_nav_U.lidar.is_valid=false;
    
    if (mPollingList[8].revents & POLLIN) {
        tasl_px4_nav_U.status.is_valid=true;
        vehicle_status_s data;
        orb_copy(ORB_ID(vehicle_status), mVehicleStatus, &data);
        tasl_px4_nav_U.status.ARMING_STATE_INIT=data.ARMING_STATE_INIT;
        tasl_px4_nav_U.status.ARMING_STATE_STANDBY=data.ARMING_STATE_STANDBY;
        tasl_px4_nav_U.status.ARMING_STATE_ARMED=data.ARMING_STATE_ARMED;
        tasl_px4_nav_U.status.ARMING_STATE_STANDBY_ERROR=data.ARMING_STATE_STANDBY_ERROR;
        tasl_px4_nav_U.status.ARMING_STATE_REBOOT=data.ARMING_STATE_REBOOT;
        tasl_px4_nav_U.status.ARMING_STATE_IN_AIR_RESTORE=data.ARMING_STATE_IN_AIR_RESTORE;
        tasl_px4_nav_U.status.ARMING_STATE_MAX=data.ARMING_STATE_MAX;
        tasl_px4_nav_U.status.FAILURE_NONE=data.FAILURE_NONE;
        tasl_px4_nav_U.status.FAILURE_ROLL=data.FAILURE_ROLL;
        tasl_px4_nav_U.status.FAILURE_PITCH=data.FAILURE_PITCH;
        tasl_px4_nav_U.status.FAILURE_ALT=data.FAILURE_ALT;
        tasl_px4_nav_U.status.HIL_STATE_OFF=data.HIL_STATE_OFF;
        tasl_px4_nav_U.status.HIL_STATE_ON=data.HIL_STATE_ON;
        tasl_px4_nav_U.status.NAVIGATION_STATE_MANUAL=data.NAVIGATION_STATE_MANUAL;
        tasl_px4_nav_U.status.NAVIGATION_STATE_ALTCTL=data.NAVIGATION_STATE_ALTCTL;
        tasl_px4_nav_U.status.NAVIGATION_STATE_POSCTL=data.NAVIGATION_STATE_POSCTL;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_MISSION=data.NAVIGATION_STATE_AUTO_MISSION;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_LOITER=data.NAVIGATION_STATE_AUTO_LOITER;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_RTL=data.NAVIGATION_STATE_AUTO_RTL;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_RCRECOVER=data.NAVIGATION_STATE_AUTO_RCRECOVER;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_RTGS=data.NAVIGATION_STATE_AUTO_RTGS;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_LANDENGFAIL=data.NAVIGATION_STATE_AUTO_LANDENGFAIL;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_LANDGPSFAIL=data.NAVIGATION_STATE_AUTO_LANDGPSFAIL;
        tasl_px4_nav_U.status.NAVIGATION_STATE_ACRO=data.NAVIGATION_STATE_ACRO;
        tasl_px4_nav_U.status.NAVIGATION_STATE_UNUSED=data.NAVIGATION_STATE_UNUSED;
        tasl_px4_nav_U.status.NAVIGATION_STATE_DESCEND=data.NAVIGATION_STATE_DESCEND;
        tasl_px4_nav_U.status.NAVIGATION_STATE_TERMINATION=data.NAVIGATION_STATE_TERMINATION;
        tasl_px4_nav_U.status.NAVIGATION_STATE_OFFBOARD=data.NAVIGATION_STATE_OFFBOARD;
        tasl_px4_nav_U.status.NAVIGATION_STATE_STAB=data.NAVIGATION_STATE_STAB;
        tasl_px4_nav_U.status.NAVIGATION_STATE_RATTITUDE=data.NAVIGATION_STATE_RATTITUDE;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_TAKEOFF=data.NAVIGATION_STATE_AUTO_TAKEOFF;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_LAND=data.NAVIGATION_STATE_AUTO_LAND;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_FOLLOW_TARGET=data.NAVIGATION_STATE_AUTO_FOLLOW_TARGET;
        tasl_px4_nav_U.status.NAVIGATION_STATE_AUTO_PRECLAND=data.NAVIGATION_STATE_AUTO_PRECLAND;
        tasl_px4_nav_U.status.NAVIGATION_STATE_ORBIT=data.NAVIGATION_STATE_ORBIT;
        tasl_px4_nav_U.status.NAVIGATION_STATE_MAX=data.NAVIGATION_STATE_MAX;
        tasl_px4_nav_U.status.RC_IN_MODE_DEFAULT=data.RC_IN_MODE_DEFAULT;
        tasl_px4_nav_U.status.RC_IN_MODE_OFF=data.RC_IN_MODE_OFF;
        tasl_px4_nav_U.status.RC_IN_MODE_GENERATED=data.RC_IN_MODE_GENERATED;
        tasl_px4_nav_U.status.nav_state=data.nav_state;
        tasl_px4_nav_U.status.arming_state=data.arming_state;
        tasl_px4_nav_U.status.hil_state=data.hil_state;
        tasl_px4_nav_U.status.failsafe=data.failsafe;
        tasl_px4_nav_U.status.system_type=data.system_type;
        tasl_px4_nav_U.status.system_id=data.system_id;
        tasl_px4_nav_U.status.component_id=data.component_id;
        tasl_px4_nav_U.status.is_rotary_wing=data.is_rotary_wing;
        tasl_px4_nav_U.status.is_vtol=data.is_vtol;
        tasl_px4_nav_U.status.vtol_fw_permanent_stab=data.vtol_fw_permanent_stab;
        tasl_px4_nav_U.status.in_transition_mode=data.in_transition_mode;
        tasl_px4_nav_U.status.in_transition_to_fw=data.in_transition_to_fw;
        tasl_px4_nav_U.status.rc_signal_lost=data.rc_signal_lost;
        tasl_px4_nav_U.status.rc_input_mode=data.rc_input_mode;
        tasl_px4_nav_U.status.data_link_lost=data.data_link_lost;
        tasl_px4_nav_U.status.data_link_lost_counter=data.data_link_lost_counter;
        tasl_px4_nav_U.status.high_latency_data_link_lost=data.high_latency_data_link_lost;
        tasl_px4_nav_U.status.engine_failure=data.engine_failure;
        tasl_px4_nav_U.status.mission_failure=data.mission_failure;
        tasl_px4_nav_U.status.failure_detector_status=data.failure_detector_status;
        tasl_px4_nav_U.status.onboard_control_sensors_present=data.onboard_control_sensors_present;
        tasl_px4_nav_U.status.onboard_control_sensors_enabled=data.onboard_control_sensors_enabled;
        tasl_px4_nav_U.status.onboard_control_sensors_health=data.onboard_control_sensors_health;
    }
    else tasl_px4_nav_U.status.is_valid=false;
    
    if (mPollingList[9].revents & POLLIN) {
        tasl_px4_nav_U.adcReport.is_valid=true;
        adc_report_s data;
        orb_copy(ORB_ID(adc_report), mAdcReport, &data);
        tasl_px4_nav_U.adcReport.channel_id[0]=data.channel_id[0];
        tasl_px4_nav_U.adcReport.channel_id[1]=data.channel_id[1];
        tasl_px4_nav_U.adcReport.channel_id[2]=data.channel_id[2];
        tasl_px4_nav_U.adcReport.channel_id[3]=data.channel_id[3];
        tasl_px4_nav_U.adcReport.channel_id[4]=data.channel_id[4];
        tasl_px4_nav_U.adcReport.channel_id[5]=data.channel_id[5];
        tasl_px4_nav_U.adcReport.channel_id[6]=data.channel_id[6];
        tasl_px4_nav_U.adcReport.channel_id[7]=data.channel_id[7];
        tasl_px4_nav_U.adcReport.channel_id[8]=data.channel_id[8];
        tasl_px4_nav_U.adcReport.channel_id[9]=data.channel_id[9];
        tasl_px4_nav_U.adcReport.channel_id[10]=data.channel_id[10];
        tasl_px4_nav_U.adcReport.channel_id[11]=data.channel_id[11];
        tasl_px4_nav_U.adcReport.channel_value[0]=data.channel_value[0];
        tasl_px4_nav_U.adcReport.channel_value[1]=data.channel_value[1];
        tasl_px4_nav_U.adcReport.channel_value[2]=data.channel_value[2];
        tasl_px4_nav_U.adcReport.channel_value[3]=data.channel_value[3];
        tasl_px4_nav_U.adcReport.channel_value[4]=data.channel_value[4];
        tasl_px4_nav_U.adcReport.channel_value[5]=data.channel_value[5];
        tasl_px4_nav_U.adcReport.channel_value[6]=data.channel_value[6];
        tasl_px4_nav_U.adcReport.channel_value[7]=data.channel_value[7];
        tasl_px4_nav_U.adcReport.channel_value[8]=data.channel_value[8];
        tasl_px4_nav_U.adcReport.channel_value[9]=data.channel_value[9];
        tasl_px4_nav_U.adcReport.channel_value[10]=data.channel_value[10];
        tasl_px4_nav_U.adcReport.channel_value[11]=data.channel_value[11];
    }
    else tasl_px4_nav_U.adcReport.is_valid=false;
    
    if (mPollingList[10].revents & POLLIN) {
        tasl_px4_nav_U.air_speed.is_valid=true;
        airspeed_s data;
        orb_copy(ORB_ID(airspeed), mAirspeed, &data);
        tasl_px4_nav_U.air_speed.indicated_airspeed_m_s=data.indicated_airspeed_m_s;
        tasl_px4_nav_U.air_speed.true_airspeed_m_s=data.true_airspeed_m_s;
        tasl_px4_nav_U.air_speed.air_temperature_celsius=data.air_temperature_celsius;
        tasl_px4_nav_U.air_speed.confidence=data.confidence;
    }
    else tasl_px4_nav_U.air_speed.is_valid=false;
}

void TaslPx4Nav::publishTopics() {
    mVehicleLocalPositionData.timestamp=hrt_absolute_time();
    mVehicleLocalPositionData.xy_valid=tasl_px4_nav_Y.vehicle_pos.xy_valid;
    mVehicleLocalPositionData.z_valid=tasl_px4_nav_Y.vehicle_pos.z_valid;
    mVehicleLocalPositionData.v_xy_valid=tasl_px4_nav_Y.vehicle_pos.v_xy_valid;
    mVehicleLocalPositionData.v_z_valid=tasl_px4_nav_Y.vehicle_pos.v_z_valid;
    mVehicleLocalPositionData.x=tasl_px4_nav_Y.vehicle_pos.x;
    mVehicleLocalPositionData.y=tasl_px4_nav_Y.vehicle_pos.y;
    mVehicleLocalPositionData.z=tasl_px4_nav_Y.vehicle_pos.z;
    mVehicleLocalPositionData.delta_xy[0]=tasl_px4_nav_Y.vehicle_pos.delta_xy[0];
    mVehicleLocalPositionData.delta_xy[1]=tasl_px4_nav_Y.vehicle_pos.delta_xy[1];
    mVehicleLocalPositionData.xy_reset_counter=tasl_px4_nav_Y.vehicle_pos.xy_reset_counter;
    mVehicleLocalPositionData.delta_z=tasl_px4_nav_Y.vehicle_pos.delta_z;
    mVehicleLocalPositionData.z_reset_counter=tasl_px4_nav_Y.vehicle_pos.z_reset_counter;
    mVehicleLocalPositionData.vx=tasl_px4_nav_Y.vehicle_pos.vx;
    mVehicleLocalPositionData.vy=tasl_px4_nav_Y.vehicle_pos.vy;
    mVehicleLocalPositionData.vz=tasl_px4_nav_Y.vehicle_pos.vz;
    mVehicleLocalPositionData.z_deriv=tasl_px4_nav_Y.vehicle_pos.z_deriv;
    mVehicleLocalPositionData.delta_vxy[0]=tasl_px4_nav_Y.vehicle_pos.delta_vxy[0];
    mVehicleLocalPositionData.delta_vxy[1]=tasl_px4_nav_Y.vehicle_pos.delta_vxy[1];
    mVehicleLocalPositionData.vxy_reset_counter=tasl_px4_nav_Y.vehicle_pos.vxy_reset_counter;
    mVehicleLocalPositionData.delta_vz=tasl_px4_nav_Y.vehicle_pos.delta_vz;
    mVehicleLocalPositionData.vz_reset_counter=tasl_px4_nav_Y.vehicle_pos.vz_reset_counter;
    mVehicleLocalPositionData.ax=tasl_px4_nav_Y.vehicle_pos.ax;
    mVehicleLocalPositionData.ay=tasl_px4_nav_Y.vehicle_pos.ay;
    mVehicleLocalPositionData.az=tasl_px4_nav_Y.vehicle_pos.az;
    mVehicleLocalPositionData.yaw=tasl_px4_nav_Y.vehicle_pos.yaw;
    mVehicleLocalPositionData.xy_global=tasl_px4_nav_Y.vehicle_pos.xy_global;
    mVehicleLocalPositionData.z_global=tasl_px4_nav_Y.vehicle_pos.z_global;
    mVehicleLocalPositionData.ref_timestamp=static_cast<uint64_t>(tasl_px4_nav_Y.vehicle_pos.ref_timestamp);
    mVehicleLocalPositionData.ref_lat=tasl_px4_nav_Y.vehicle_pos.ref_lat;
    mVehicleLocalPositionData.ref_lon=tasl_px4_nav_Y.vehicle_pos.ref_lon;
    mVehicleLocalPositionData.ref_alt=tasl_px4_nav_Y.vehicle_pos.ref_alt;
    mVehicleLocalPositionData.dist_bottom=tasl_px4_nav_Y.vehicle_pos.dist_bottom;
    mVehicleLocalPositionData.dist_bottom_rate=tasl_px4_nav_Y.vehicle_pos.dist_bottom_rate;
    mVehicleLocalPositionData.dist_bottom_valid=tasl_px4_nav_Y.vehicle_pos.dist_bottom_valid;
    mVehicleLocalPositionData.eph=tasl_px4_nav_Y.vehicle_pos.eph;
    mVehicleLocalPositionData.epv=tasl_px4_nav_Y.vehicle_pos.epv;
    mVehicleLocalPositionData.evh=tasl_px4_nav_Y.vehicle_pos.evh;
    mVehicleLocalPositionData.evv=tasl_px4_nav_Y.vehicle_pos.evv;
    mVehicleLocalPositionData.vxy_max=tasl_px4_nav_Y.vehicle_pos.vxy_max;
    mVehicleLocalPositionData.vz_max=tasl_px4_nav_Y.vehicle_pos.vz_max;
    mVehicleLocalPositionData.hagl_min=tasl_px4_nav_Y.vehicle_pos.hagl_min;
    mVehicleLocalPositionData.hagl_max=tasl_px4_nav_Y.vehicle_pos.hagl_max;
    orb_publish(ORB_ID(vehicle_local_position), mVehicleLocalPosition, &mVehicleLocalPositionData);
    mVehicleAttitudeData.timestamp=hrt_absolute_time();
    mVehicleAttitudeData.rollspeed=tasl_px4_nav_Y.vehicle_att.rollspeed;
    mVehicleAttitudeData.pitchspeed=tasl_px4_nav_Y.vehicle_att.pitchspeed;
    mVehicleAttitudeData.yawspeed=tasl_px4_nav_Y.vehicle_att.yawspeed;
    mVehicleAttitudeData.q[0]=tasl_px4_nav_Y.vehicle_att.q[0];
    mVehicleAttitudeData.q[1]=tasl_px4_nav_Y.vehicle_att.q[1];
    mVehicleAttitudeData.q[2]=tasl_px4_nav_Y.vehicle_att.q[2];
    mVehicleAttitudeData.q[3]=tasl_px4_nav_Y.vehicle_att.q[3];
    mVehicleAttitudeData.delta_q_reset[0]=tasl_px4_nav_Y.vehicle_att.delta_q_reset[0];
    mVehicleAttitudeData.delta_q_reset[1]=tasl_px4_nav_Y.vehicle_att.delta_q_reset[1];
    mVehicleAttitudeData.delta_q_reset[2]=tasl_px4_nav_Y.vehicle_att.delta_q_reset[2];
    mVehicleAttitudeData.delta_q_reset[3]=tasl_px4_nav_Y.vehicle_att.delta_q_reset[3];
    mVehicleAttitudeData.quat_reset_counter=tasl_px4_nav_Y.vehicle_att.quat_reset_counter;
    orb_publish(ORB_ID(vehicle_attitude), mVehicleAttitude, &mVehicleAttitudeData);
    mNavigationHeightData.timestamp=hrt_absolute_time();
    mNavigationHeightData.baro_height=tasl_px4_nav_Y.navigationHeight.baro_height;
    mNavigationHeightData.gps_height=tasl_px4_nav_Y.navigationHeight.gps_height;
    mNavigationHeightData.lidar_height=tasl_px4_nav_Y.navigationHeight.lidar_height;
    mNavigationHeightData.height_estimation=tasl_px4_nav_Y.navigationHeight.height_estimation;
    mNavigationHeightData.height_relative=tasl_px4_nav_Y.navigationHeight.height_relative;
    orb_publish(ORB_ID(navigation_height), mNavigationHeight, &mNavigationHeightData);
    mSensorsValidData.timestamp=hrt_absolute_time();
    mSensorsValidData.lidar=tasl_px4_nav_Y.sensorsValid.lidar;
    mSensorsValidData.mag=tasl_px4_nav_Y.sensorsValid.mag;
    mSensorsValidData.gps=tasl_px4_nav_Y.sensorsValid.gps;
    mSensorsValidData.baro=tasl_px4_nav_Y.sensorsValid.baro;
    orb_publish(ORB_ID(sensors_valid), mSensorsValid, &mSensorsValidData);
    mNavigationBaroData.timestamp=hrt_absolute_time();
    mNavigationBaroData.pressure_height=tasl_px4_nav_Y.navigationBaro.pressure_height;
    mNavigationBaroData.initial_position_constant=tasl_px4_nav_Y.navigationBaro.initial_position_constant;
    mNavigationBaroData.actual_baro_height=tasl_px4_nav_Y.navigationBaro.actual_baro_height;
    mNavigationBaroData.reference_height=tasl_px4_nav_Y.navigationBaro.reference_height;
    mNavigationBaroData.loop_identifier=tasl_px4_nav_Y.navigationBaro.loop_identifier;
    mNavigationBaroData.preprocessor_height=tasl_px4_nav_Y.navigationBaro.preprocessor_height;
    orb_publish(ORB_ID(navigation_baro), mNavigationBaro, &mNavigationBaroData);
    mNavigationStateData.timestamp=hrt_absolute_time();
    mNavigationStateData.position[0]=tasl_px4_nav_Y.navigationoutput.position[0];
    mNavigationStateData.position[1]=tasl_px4_nav_Y.navigationoutput.position[1];
    mNavigationStateData.position[2]=tasl_px4_nav_Y.navigationoutput.position[2];
    mNavigationStateData.velocity[0]=tasl_px4_nav_Y.navigationoutput.velocity[0];
    mNavigationStateData.velocity[1]=tasl_px4_nav_Y.navigationoutput.velocity[1];
    mNavigationStateData.velocity[2]=tasl_px4_nav_Y.navigationoutput.velocity[2];
    mNavigationStateData.attitude[0]=tasl_px4_nav_Y.navigationoutput.attitude[0];
    mNavigationStateData.attitude[1]=tasl_px4_nav_Y.navigationoutput.attitude[1];
    mNavigationStateData.attitude[2]=tasl_px4_nav_Y.navigationoutput.attitude[2];
    mNavigationStateData.rates[0]=tasl_px4_nav_Y.navigationoutput.rates[0];
    mNavigationStateData.rates[1]=tasl_px4_nav_Y.navigationoutput.rates[1];
    mNavigationStateData.rates[2]=tasl_px4_nav_Y.navigationoutput.rates[2];
    orb_publish(ORB_ID(navigation_state), mNavigationState, &mNavigationStateData);
    mNavigationLidarData.timestamp=hrt_absolute_time();
    mNavigationLidarData.input_distance=tasl_px4_nav_Y.navigationlidar.input_distance;
    mNavigationLidarData.input_valid=tasl_px4_nav_Y.navigationlidar.input_valid;
    mNavigationLidarData.h_g=tasl_px4_nav_Y.navigationlidar.h_g;
    mNavigationLidarData.finite_hg=tasl_px4_nav_Y.navigationlidar.finite_hg;
    mNavigationLidarData.orientation_valid=tasl_px4_nav_Y.navigationlidar.orientation_valid;
    mNavigationLidarData.measurement_valid=tasl_px4_nav_Y.navigationlidar.measurement_valid;
    mNavigationLidarData.time_diff=tasl_px4_nav_Y.navigationlidar.time_diff;
    mNavigationLidarData.datapoints_valid=tasl_px4_nav_Y.navigationlidar.datapoints_valid;
    mNavigationLidarData.h_g_est=tasl_px4_nav_Y.navigationlidar.h_g_est;
    mNavigationLidarData.h_g_dot=tasl_px4_nav_Y.navigationlidar.h_g_dot;
    mNavigationLidarData.est_valid=tasl_px4_nav_Y.navigationlidar.est_valid;
    orb_publish(ORB_ID(navigation_lidar), mNavigationLidar, &mNavigationLidarData);
    mNavigationMagData.timestamp=hrt_absolute_time();
    mNavigationMagData.state[0]=tasl_px4_nav_Y.navigationMag.state[0];
    mNavigationMagData.state[1]=tasl_px4_nav_Y.navigationMag.state[1];
    mNavigationMagData.state[2]=tasl_px4_nav_Y.navigationMag.state[2];
    mNavigationMagData.state[3]=tasl_px4_nav_Y.navigationMag.state[3];
    mNavigationMagData.state[4]=tasl_px4_nav_Y.navigationMag.state[4];
    mNavigationMagData.state[5]=tasl_px4_nav_Y.navigationMag.state[5];
    mNavigationMagData.state[6]=tasl_px4_nav_Y.navigationMag.state[6];
    mNavigationMagData.state[7]=tasl_px4_nav_Y.navigationMag.state[7];
    mNavigationMagData.state[8]=tasl_px4_nav_Y.navigationMag.state[8];
    mNavigationMagData.state[9]=tasl_px4_nav_Y.navigationMag.state[9];
    mNavigationMagData.meas[0]=tasl_px4_nav_Y.navigationMag.meas[0];
    mNavigationMagData.meas[1]=tasl_px4_nav_Y.navigationMag.meas[1];
    mNavigationMagData.meas[2]=tasl_px4_nav_Y.navigationMag.meas[2];
    mNavigationMagData.t[0]=tasl_px4_nav_Y.navigationMag.t[0];
    mNavigationMagData.t[1]=tasl_px4_nav_Y.navigationMag.t[1];
    mNavigationMagData.t[2]=tasl_px4_nav_Y.navigationMag.t[2];
    mNavigationMagData.t[3]=tasl_px4_nav_Y.navigationMag.t[3];
    mNavigationMagData.t[4]=tasl_px4_nav_Y.navigationMag.t[4];
    mNavigationMagData.t[5]=tasl_px4_nav_Y.navigationMag.t[5];
    mNavigationMagData.t[6]=tasl_px4_nav_Y.navigationMag.t[6];
    mNavigationMagData.t[7]=tasl_px4_nav_Y.navigationMag.t[7];
    mNavigationMagData.t[8]=tasl_px4_nav_Y.navigationMag.t[8];
    mNavigationMagData.ref[0]=tasl_px4_nav_Y.navigationMag.ref[0];
    mNavigationMagData.ref[1]=tasl_px4_nav_Y.navigationMag.ref[1];
    mNavigationMagData.ref[2]=tasl_px4_nav_Y.navigationMag.ref[2];
    mNavigationMagData.residual=tasl_px4_nav_Y.navigationMag.residual;
    mNavigationMagData.h[0]=tasl_px4_nav_Y.navigationMag.h[0];
    mNavigationMagData.h[1]=tasl_px4_nav_Y.navigationMag.h[1];
    mNavigationMagData.h[2]=tasl_px4_nav_Y.navigationMag.h[2];
    mNavigationMagData.h[3]=tasl_px4_nav_Y.navigationMag.h[3];
    mNavigationMagData.h[4]=tasl_px4_nav_Y.navigationMag.h[4];
    mNavigationMagData.h[5]=tasl_px4_nav_Y.navigationMag.h[5];
    mNavigationMagData.h[6]=tasl_px4_nav_Y.navigationMag.h[6];
    mNavigationMagData.h[7]=tasl_px4_nav_Y.navigationMag.h[7];
    mNavigationMagData.h[8]=tasl_px4_nav_Y.navigationMag.h[8];
    mNavigationMagData.r=tasl_px4_nav_Y.navigationMag.r;
    mNavigationMagData.gibbs_state[0]=tasl_px4_nav_Y.navigationMag.gibbs_state[0];
    mNavigationMagData.gibbs_state[1]=tasl_px4_nav_Y.navigationMag.gibbs_state[1];
    mNavigationMagData.gibbs_state[2]=tasl_px4_nav_Y.navigationMag.gibbs_state[2];
    mNavigationMagData.gibbs_state[3]=tasl_px4_nav_Y.navigationMag.gibbs_state[3];
    mNavigationMagData.gibbs_state[4]=tasl_px4_nav_Y.navigationMag.gibbs_state[4];
    mNavigationMagData.gibbs_state[5]=tasl_px4_nav_Y.navigationMag.gibbs_state[5];
    mNavigationMagData.gibbs_state[6]=tasl_px4_nav_Y.navigationMag.gibbs_state[6];
    mNavigationMagData.gibbs_state[7]=tasl_px4_nav_Y.navigationMag.gibbs_state[7];
    mNavigationMagData.gibbs_state[8]=tasl_px4_nav_Y.navigationMag.gibbs_state[8];
    mNavigationMagData.attitude[0]=tasl_px4_nav_Y.navigationMag.attitude[0];
    mNavigationMagData.attitude[1]=tasl_px4_nav_Y.navigationMag.attitude[1];
    mNavigationMagData.attitude[2]=tasl_px4_nav_Y.navigationMag.attitude[2];
    orb_publish(ORB_ID(navigation_mag), mNavigationMag, &mNavigationMagData);
    mAirdataData.timestamp=hrt_absolute_time();
    mAirdataData.airspeed=tasl_px4_nav_Y.air_data.airspeed;
    mAirdataData.alpha_meas=tasl_px4_nav_Y.air_data.alpha_meas;
    mAirdataData.beta_meas=tasl_px4_nav_Y.air_data.beta_meas;
    mAirdataData.alpha_fil=tasl_px4_nav_Y.air_data.alpha_fil;
    mAirdataData.beta_fil=tasl_px4_nav_Y.air_data.beta_fil;
    mAirdataData.alpha_out=tasl_px4_nav_Y.air_data.alpha_out;
    mAirdataData.beta_out=tasl_px4_nav_Y.air_data.beta_out;
    mAirdataData.alpha_est=tasl_px4_nav_Y.air_data.alpha_est;
    mAirdataData.beta_est=tasl_px4_nav_Y.air_data.beta_est;
    mAirdataData.wind_vec[0]=tasl_px4_nav_Y.air_data.wind_vec[0];
    mAirdataData.wind_vec[1]=tasl_px4_nav_Y.air_data.wind_vec[1];
    mAirdataData.wind_vec[2]=tasl_px4_nav_Y.air_data.wind_vec[2];
    orb_publish(ORB_ID(airdata), mAirdata, &mAirdataData);
}
