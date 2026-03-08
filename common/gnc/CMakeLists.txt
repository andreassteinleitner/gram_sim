px4_add_module(
	MODULE modules__tasl_px4_gnc
	MAIN tasl_px4_gnc
	STACK_MAIN 2500
	STACK_MAX 4000
	COMPILE_FLAGS -Wno-unused-variable -Wno-double-promotion -Wno-float-equal
	SRCS
		tasl_px4_gnc_ert_rtw/const_params.c
		tasl_px4_gnc_ert_rtw/guid_ctrl.c
		tasl_px4_gnc_ert_rtw/guid_ctrl_data.c
		tasl_px4_gnc_ert_rtw/inv_Q5siBjH0.c
		tasl_px4_gnc_ert_rtw/mod_vkoic04f.c
		tasl_px4_gnc_ert_rtw/mod_y1cbMvKo.c
		tasl_px4_gnc_ert_rtw/mode_selector.c
		tasl_px4_gnc_ert_rtw/norm_LcYPheyz.c
		tasl_px4_gnc_ert_rtw/norm_p2xetJcK.c
		tasl_px4_gnc_ert_rtw/rtGetInf.c
		tasl_px4_gnc_ert_rtw/rtGetNaN.c
		tasl_px4_gnc_ert_rtw/rt_atan2f_snf.c
		tasl_px4_gnc_ert_rtw/rt_invf3x3_snf.c
		tasl_px4_gnc_ert_rtw/rt_nonfinite.c
		tasl_px4_gnc_ert_rtw/rt_powf_snf.c
		tasl_px4_gnc_ert_rtw/tasl_px4_gnc.c
		tasl_px4_gnc_main.cpp
		tasl_px4_gnc.cpp
	DEPENDS
	)