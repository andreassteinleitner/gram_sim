/**
 * iFR GNC - simulink - PX4 interface
 * Institut fuer Flugmechanik und Flugregelung
 * Copyright 2018 Universitaet Stuttgart.
 *
 * @author Lorenz Schmitt <lorenz.schmitt@ifr.uni-stuttgart.de>
 * @author Pascal Groß <pascal.gross@ifr.uni-stuttgart.de>
 */

#ifndef IFR_TASL_PX4_NAV_H
#define IFR_TASL_PX4_NAV_H

#include <px4_module.h>
#include <px4_posix.h>
#include <uORB/topics/parameter_update.h>

#include <uORB/topics/actuator_armed.h>
#include <uORB/topics/adc_report.h>
#include <uORB/topics/airdata.h>
#include <uORB/topics/airspeed.h>
#include <uORB/topics/distance_sensor.h>
#include <uORB/topics/navigation_baro.h>
#include <uORB/topics/navigation_height.h>
#include <uORB/topics/navigation_lidar.h>
#include <uORB/topics/navigation_mag.h>
#include <uORB/topics/navigation_state.h>
#include <uORB/topics/sensor_accel.h>
#include <uORB/topics/sensor_baro.h>
#include <uORB/topics/sensor_gyro.h>
#include <uORB/topics/sensors_valid.h>
#include <uORB/topics/vehicle_attitude.h>
#include <uORB/topics/vehicle_gps_position.h>
#include <uORB/topics/vehicle_local_position.h>
#include <uORB/topics/vehicle_magnetometer.h>
#include <uORB/topics/vehicle_status.h>

struct TaslPx4Nav: ModuleBase<TaslPx4Nav> {
    TaslPx4Nav();
    ~TaslPx4Nav() override;
    /** @see ModuleBase::run() */
    void run() override;
    /** @see ModuleBase */
    static int task_spawn(int argc, char *argv[]);
    /** @see ModuleBase */
    static TaslPx4Nav *instantiate(int argc, char *argv[]);
    /** @see ModuleBase */
    static int print_usage(const char *reason = nullptr);
    /** @see ModuleBase */
    static int custom_command(int argc, char *argv[]);

private:
    double getHiResTime();
    double mLaunchTime;

    void connectParameters();
    void copyTopics();
    void publishTopics();

    int mActuatorArmed;
    int mSensorGyro;
    int mSensorAccel;
    int mSensorBaro;
    int mVehicleMagnetometer;
    int mVehicleGpsPosition;
    int mDistanceSensor;
    int mVehicleStatus;
    int mAdcReport;
    int mAirspeed;
    vehicle_local_position_s mVehicleLocalPositionData;
    orb_advert_t mVehicleLocalPosition;
    vehicle_attitude_s mVehicleAttitudeData;
    orb_advert_t mVehicleAttitude;
    navigation_height_s mNavigationHeightData;
    orb_advert_t mNavigationHeight;
    sensors_valid_s mSensorsValidData;
    orb_advert_t mSensorsValid;
    navigation_baro_s mNavigationBaroData;
    orb_advert_t mNavigationBaro;
    navigation_state_s mNavigationStateData;
    orb_advert_t mNavigationState;
    navigation_lidar_s mNavigationLidarData;
    orb_advert_t mNavigationLidar;
    navigation_mag_s mNavigationMagData;
    orb_advert_t mNavigationMag;
    airdata_s mAirdataData;
    orb_advert_t mAirdata;
    bool mParametersAreInitialized;
    int mParameterUpdate;
	struct ParameterPair {
		param_t name;
		float* value;
	};
    ParameterPair mParameters[26];
    px4_pollfd_struct_t mPollingList[10+1];
};

#endif
