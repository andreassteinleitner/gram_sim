px4_add_module(
	MODULE modules__tasl_px4_nav
	MAIN tasl_px4_nav
	STACK_MAIN 2500
	STACK_MAX 4000
	COMPILE_FLAGS -Wno-unused-variable -Wno-double-promotion -Wno-float-equal
	SRCS
		tasl_px4_nav_ert_rtw/const_params.c
		tasl_px4_nav_ert_rtw/navigation_filter.c
		tasl_px4_nav_ert_rtw/norm_LcYPheyz.c
		tasl_px4_nav_ert_rtw/normalize_AVrRBFGe.c
		tasl_px4_nav_ert_rtw/normalize_vPX96U5O.c
		tasl_px4_nav_ert_rtw/tasl_px4_nav.c
		tasl_px4_nav_ert_rtw/tasl_px4_nav_data.c
		tasl_px4_nav_ert_rtw/xgetrf_R1bc2LZg.c
		tasl_px4_nav_main.cpp
		tasl_px4_nav.cpp
	DEPENDS
	)