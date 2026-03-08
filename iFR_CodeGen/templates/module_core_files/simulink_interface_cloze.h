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

#ifndef IFR_%%module_name_usc%%_H
#define IFR_%%module_name_usc%%_H

#include <px4_platform_common/module.h>
#include <px4_platform_common/posix.h>
#include <parameters/param.h>
#include <uORB/topics/parameter_update.h>
#include <uORB/Subscription.hpp>
#include <uORB/uORB.h>
// include topic headers

struct %%module_name_ucc%%: ModuleBase<%%module_name_ucc%%> {
    %%module_name_ucc%%();
    ~%%module_name_ucc%%() override;
    /** @see ModuleBase::run() */
    void run() override;
    /** @see ModuleBase */
    static int task_spawn(int argc, char *argv[]);
    /** @see ModuleBase */
    static %%module_name_ucc%% *instantiate(int argc, char *argv[]);
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

    // declare topic members
    bool mParametersAreInitialized;
    int mParameterUpdate;
	struct ParameterPair {
		param_t name;
		float* value;
	};
    ParameterPair mParameters[/*number of parameters*/];
    px4_pollfd_struct_t mPollingList[/*number of inputs*/+1];
};

#endif
