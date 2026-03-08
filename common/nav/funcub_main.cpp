/**
 * iFR GNC - simulink - PX4 interface
 * Institut fuer Flugmechanik und Flugregelung
 * Copyright 2018 Universitaet Stuttgart.
 *
 * @author Lorenz Schmitt <lorenz.schmitt@ifr.uni-stuttgart.de>
 * @author Pascal Groß <pascal.gross@ifr.uni-stuttgart.de>
 */

#include "tasl_px4_nav.h"

extern "C" __EXPORT int tasl_px4_nav_main(int argc, char *argv[]);

int tasl_px4_nav_main(int argc, char *argv[]) {
    return TaslPx4Nav::main(argc, argv);
}
