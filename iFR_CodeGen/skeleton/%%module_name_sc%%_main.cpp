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

#include "%%module_name_sc%%.h"

extern "C" __EXPORT int %%module_name_sc%%_main(int argc, char *argv[]);

int %%module_name_sc%%_main(int argc, char *argv[]) {
    return %%module_name_ucc%%::main(argc, argv);
}
