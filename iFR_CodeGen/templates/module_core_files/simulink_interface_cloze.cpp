/**
 * iFR GNC - simulink - PX4 interface
 * Institut fuer Flugmechanik und Flugregelung
 * Copyright 2023 Universitaet Stuttgart.
 *
 * Modified in 2023 for PX4 Firmware v1.13.2 by:
 * @author Niklas Pauli <niklas.pauli@ifr.uni-stuttgart.de>
 * Original authors:
 * @author Lorenz Schmitt <lorenz.schmitt@ifr.uni-stuttgart.de>
 * @author Pascal Groß <pascal.gross@ifr.uni-stuttgart.de>
 */

#include <drivers/drv_hrt.h>
#include <px4_platform_common/tasks.h>
#include <px4_platform_common/time.h>
#include <errno.h>
//additional headers
#include <poll.h>
#include <px4_platform_common/px4_config.h>



extern "C" {
    #include "generatedCode/%%module_name_wo_ifr%%.h"
}
#include "%%module_name_sc%%.h"

%%module_name_ucc%%::%%module_name_ucc%%():
        mLaunchTime(getHiResTime()),
        // initialize topic members
        mParametersAreInitialized(false),
        mParameterUpdate(orb_subscribe(ORB_ID(parameter_update))) {
    mPollingList[0].fd=mParameterUpdate;
    // prepare polling list
    for (auto & entry: mPollingList) entry.events=POLLIN;
    connectParameters();
}

%%module_name_ucc%%::~%%module_name_ucc%%() {
    orb_unsubscribe(mParameterUpdate);
    // terminate topic members
}

void %%module_name_ucc%%::run() {
    double stepSize(/*step size*/);
    %%module_name_wo_ifr%%_initialize();

    while (!should_exit()) {
        double currentTime(getHiResTime());
        
        int pollingResult(px4_poll(mPollingList, /*number of inputs*/+1, 1000));
        if (pollingResult>0) copyTopics();
        %%module_name_wo_ifr%%_U.clock=float(currentTime-mLaunchTime);
        %%module_name_wo_ifr%%_step();
        publishTopics();

        double timeToBeWaited=stepSize-(getHiResTime()-currentTime)-0.001; // no idea why the 0.001 offset is necessary
        if (timeToBeWaited>0) system_usleep(uint32_t(timeToBeWaited*1e6));
    }
}

int %%module_name_ucc%%::task_spawn(int argc, char *argv[]) {
    _task_id=px4_task_spawn_cmd("%%module_name_sc%%", SCHED_DEFAULT, SCHED_PRIORITY_DEFAULT, %%stacksize%%, (px4_main_t)&run_trampoline, (char *const *)argv);
    
    if (_task_id<0) {
        _task_id=-1;
        return -errno;
    }
    else return 0;
}

%%module_name_ucc%% * %%module_name_ucc%%::instantiate(int argc, char *argv[]) {
    return new %%module_name_ucc%%();
}

int %%module_name_ucc%%::print_usage(const char *reason) {
    if (reason) PX4_WARN("%s\n", reason);
    PRINT_MODULE_DESCRIPTION("%%module_name_sc%% runs simulink generated GNC code.");
    PRINT_MODULE_USAGE_COMMAND_DESCR("start", "start module thread");
    PRINT_MODULE_USAGE_COMMAND_DESCR("stop", "stop module thread");
    PRINT_MODULE_USAGE_COMMAND_DESCR("status", "return module thread state");
    PRINT_MODULE_USAGE_NAME("%%module_name_sc%%", "system");
    return 0;
}

int %%module_name_ucc%%::custom_command(int argc, char *argv[]) {
    return print_usage("unknown command");
}

double %%module_name_ucc%%::getHiResTime() {
    hrt_abstime timeInMicroseconds=hrt_absolute_time();
    return 1e-6*double(timeInMicroseconds);
}

void %%module_name_ucc%%::connectParameters() {
    // connect parameters function body
}

void %%module_name_ucc%%::copyTopics() {
    bool newParametersAvailable(true);
    if (mParametersAreInitialized) orb_check(mParameterUpdate, &newParametersAvailable);
    if (newParametersAvailable) {
        parameter_update_s data;
        orb_copy(ORB_ID(parameter_update), mParameterUpdate, &data); // necessary because orb_check checks against last orb_copy		
		for (auto & param: mParameters) param_get(param.name, param.value);
        mParametersAreInitialized=true;
    }
    // copy topics
}

void %%module_name_ucc%%::publishTopics() {
    // publish topics
}
