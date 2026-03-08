#include <px4_config.h>
#include <parameters/param.h>


/**
 * magnetic field measurement standard deviation
 *
 * @group ifr
 * @unit Gs
 */
PARAM_DEFINE_FLOAT(NAV_MAG_STD, 0.115f);

/**
 * GPS horizontal position standard deviation
 *
 * @group ifr
 * @unit m
 */
PARAM_DEFINE_FLOAT(NAV_GPS_HPOS_STD, 1.5f);

/**
 * GPS vertical position standard deviation
 *
 * @group ifr
 * @unit m
 */
PARAM_DEFINE_FLOAT(NAV_GPS_VPOS_STD, 4f);

/**
 * GPS horizontal velocity standard deviation
 *
 * @group ifr
 * @unit m/s
 */
PARAM_DEFINE_FLOAT(NAV_GPS_HVEL_STD, 0.06f);

/**
 * GPS vertical velocity standard deviation
 *
 * @group ifr
 * @unit m/s
 */
PARAM_DEFINE_FLOAT(NAV_GPS_VVEL_STD, 0.09f);

/**
 * acceleration-based attitude correction standard deviation
 *
 * @group ifr
 * @unit m/s^2
 */
PARAM_DEFINE_FLOAT(NAV_ACC_UPDT_STD, 0.1f);

/**
 * barometric height standard deviation
 *
 * @group ifr
 * @unit m
 */
PARAM_DEFINE_FLOAT(NAV_BARO_STD, 0.23f);

/**
 * gyroscope standard deviation
 *
 * @group ifr
 * @unit rad
 */
PARAM_DEFINE_FLOAT(NAV_GYRO_STD, 0.045f);

/**
 * acceleration standard deviation
 *
 * @group ifr
 * @unit m/s^2
 */
PARAM_DEFINE_FLOAT(NAV_ACC_STD, 0.013f);

/**
 * time after which GPS is considered unavailable
 *
 * @group ifr
 * @unit s
 */
PARAM_DEFINE_FLOAT(NAV_GPS_TIMEOUT, 5f);

/**
 * time after which optical flow is considered unavailable
 *
 * @group ifr
 * @unit s
 */
PARAM_DEFINE_FLOAT(NAV_FLOW_TIMEOUT, 0.5f);

/**
 * weight of current measurement in recursive bias determination
 *
 * @group ifr
 * @min 0.005
 * @max 0.5
 */
PARAM_DEFINE_FLOAT(NAV_SMOOTHING, 0.1f);

/**
 * only use GPS measurements with this horizontal accuracy or better
 *
 * @group ifr
 * @min 0.5
 * @max 30
 * @unit m
 */
PARAM_DEFINE_FLOAT(NAV_GPS_THRESH, 20f);

/**
 * Reference height of ground for Baro
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_REF_HEIGHT, 435f);

/**
 * Determine reference height dynamically
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_DYN_H_DETERM, 1f);

/**
 * Time period for gps reference averaging
 *
 * @group ifr
 * @max 40
 */
PARAM_DEFINE_FLOAT(NAV_GPS_BUFFER_T, 4f);

/**
 * Cut-off frequency for aerodynamic angle measurement filter
 *
 * @group ifr
 * @unit 1/s
 */
PARAM_DEFINE_FLOAT(NAV_AERO_FIL_OME, 0.5f);

/**
 * Filter switch
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_AERO_FIL_ON, 1f);

/**
 * Aerodynamic coefficient
 *
 * @group ifr
 * @unit m/s^2
 */
PARAM_DEFINE_FLOAT(NAV_Z_ALPHA, -155.1208f);

/**
 * Aerodynamic coefficient
 *
 * @group ifr
 * @unit m/s^2
 */
PARAM_DEFINE_FLOAT(NAV_Y_BETA, -9.0732f);

/**
 * Conversion from voltage to alpha
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_ALPHA_CONV, 1.9428f);

/**
 * Conversion from voltage to beta
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_BETA_CONV, 2.3954f);

/**
 * Offset from voltage to alpha
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_ALPHA_OFF, -3.5651f);

/**
 * Offset from voltage to beta
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_BETA_OFF, -2.8122f);

/**
 * Wind vanes data is valid
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_VANES_VALID, 1f);

/**
 * ADC channels are switched
 *
 * @group ifr
 */
PARAM_DEFINE_FLOAT(NAV_ADC_CHSWITCH, 0f);
