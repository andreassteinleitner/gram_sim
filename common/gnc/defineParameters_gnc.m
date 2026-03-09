function [params]=defineParameters_gnc(varargin)
%% parameters
%% name field must be upper case
%% name field must not exceed 12 letters
%% field min is optional
%% field max is optional

if nargin==2
    vehicle = varargin{1};
    ATOL_coeffs = varargin{2};
else
    vehicle.ori0 = [0,0.1372,0];
    ATOL_coeffs = [300, -112, 486344990, 94250890, 353000, 300, -53, 486324320, 94285610, 351000, 0, -3, 250, 250, -3, 60, 15, 7, 15, 23, 17, 0, 0, 15];
    disp('WARNING: Automatic adoption of ATOL_coeffs from SiL/HiL failed.')
end

%% general parameters
params.trim_switch = struct('default', 0, 'description', 'Set autopilot into trim mode', 'name', 'G_TRIM_SWITCH', 'group','IFR_GNC');

params.controller_selector = struct('default', 0, 'description', 'Select contoller type, (0) INDI, (1) MODAL', 'name', 'G_CONTROL_SEL', 'group','IFR_GNC');
params.imu_filt_ang_acc = struct('default', 1, 'description', 'Decide if IMU filter module should be used for angular accelerations (1) or not (0)', 'name', 'IMU_FIL_DRTE', 'group','IFR_GNC');

%% ATOL parameters
params.h_fake       = struct('default', 0, 'description', 'Perform fake landing at defined altitude', 'min', 0, 'name', 'A_FAK_ALT', 'group','IFR_GNC');
params.h_loiter     = struct('default', 50, 'description', 'Loiter height above ground', 'min', 0, 'name', 'A_HLOITER', 'group','IFR_GNC');

%% Saturations
params.limit.gammaMin          = struct('default', -12, 'description', 'Minimum gamma commanding', 'name', 'L_GAMMA_MIN', 'group','IFR_GNC');
params.limit.gammaMax          = struct('default', 12, 'description', 'Maximum gamma commanding', 'name', 'L_GAMMA_MAX', 'group','IFR_GNC');
params.limit.vel_max           = struct('default', 50, 'description', 'Maximum velocity', 'unit', 'm/s', 'name', 'L_V_MAX', 'group','IFR_GNC');
params.limit.vel_min           = struct('default',15, 'description', 'Minimum velocity', 'name', 'L_VEL_MIN', 'group','IFR_GNC');
params.limit.nzMax             = struct('default', 4, 'description', 'Maximum load factor', 'name', 'L_NZ_MAX', 'group','IFR_GNC');
params.limit.gr_lim            = struct('default', 0.6, 'description', 'Limit for commanded ground turn rate', 'name', 'L_GR_MAX', 'group','IFR_GNC');
params.limit.alpha_max         = struct('default', 15, 'description', 'Aerodynamic attitude', 'name', 'L_ALPHA_MAX_0', 'group','IFR_GNC');
params.limit.theta_max         = struct('default', 18, 'description', 'Theta limit', 'name', 'L_THETA_MAX', 'group','IFR_GNC');
params.limit.beta_max          = struct('default', 25, 'description', 'Limit for commanded sideslip angle', 'name', 'L_BETA_MAX', 'group','IFR_GNC');
params.limit.phi_max           = struct('default', 30, 'description', 'Limit for commanded roll angle', 'name', 'L_PHI_MAX', 'group','IFR_GNC');
params.limit.p_lim             = struct('default', 1, 'description', 'Limit for commanded roll rate', 'name', 'L_P_MAX', 'group','IFR_GNC');
params.limit.q_lim             = struct('default', 0.7, 'description', 'Limit for commanded pitch rate', 'name', 'L_Q_MAX', 'group','IFR_GNC');
params.limit.r_lim             = struct('default', 0.3, 'description', 'Limit for commanded yaw rate', 'name', 'L_R_MAX', 'group','IFR_GNC');
params.limit.act_lim           = struct('default', 1.0, 'description', 'Limit for actuator commands', 'name', 'L_ACT_MAX', 'group','IFR_GNC');
params.limit.flap_max           = struct('default', 90, 'description', 'Maximum flap deflection', 'name', 'L_FLP_MAX', 'group','IFR_GNC');

%% Guidance
params.guidance.K_H         = struct('default', 1, 'description', 'gain for horizontal path tracking', 'name', 'GU_K_H', 'group','IFR_GNC');
params.guidance.K_V         = struct('default', 1, 'description', 'gain for vertical path tracking', 'name', 'GU_K_V', 'group','IFR_GNC');
params.guidance.WP          = struct('default', -0.6, 'description', 'proportional gain for vertical waypoint tracking', 'name', 'GU_WP', 'group','IFR_GNC');
params.guidance.v_cmd       = struct('default', 60, 'description', 'set-point velocity', 'unit', 'm/s', 'name', 'GU_V_CMD', 'min', 12, 'group','IFR_GNC');
params.guidance.gamma_cmd   = struct('default', 0, 'description', 'set-point gamma', 'unit', 'deg', 'name', 'GU_GAMMA_CMD', 'group','IFR_GNC');
params.guidance.chi_cmd     = struct('default', 0, 'description', 'set-point chi', 'unit', 'deg', 'name', 'GU_CHI_CMD', 'group','IFR_GNC');
params.guidance.psi_cmd     = struct('default', 0, 'description', 'set-point psi', 'unit', 'deg', 'name', 'GU_PSI_CMD', 'group','IFR_GNC');

%% Controller gains
TSP = 3; %time separation principle
k_p     = 12;
k_q     = 12;
k_r     = 8;
k_a     = k_q/TSP;%alpha
k_t     = k_q/TSP;%theta
k_b     = k_r/TSP;%beta
k_psi   = k_r/TSP;
k_m     = k_p/TSP;%mu
k_ga_p  = k_a/TSP;
k_chi_p = 1/3;%k_m/TSP;
k_v     = 0.9;
k_y     = k_chi_p/TSP;
k_z     = k_ga_p/TSP;
k_v_clb = k_ga_p/TSP;
k_ga_thr= k_v/TSP;

params.indi.K_POS_Y     = struct('default', k_y, 'description', 'Indi position lateral offset gain', 'name', 'I_K_POS_Y', 'group','IFR_GNC');
params.indi.K_POS_Z     = struct('default', k_z, 'description', 'Indi position vertical offset gain', 'name', 'I_K_POS_Z', 'group','IFR_GNC');
params.indi.K_TRK_GAMMA = struct('default', k_ga_p, 'description', 'Indi track gamma gain', 'name', 'I_K_TRK_GAM', 'group','IFR_GNC');
params.indi.K_TRK_GAMMAD= struct('default', 0, 'description', 'Indi track gamma derivative gain', 'name', 'I_K_TRK_GAMD', 'group','IFR_GNC');
params.indi.K_TRK_GAMMAI= struct('default', 0, 'description', 'Indi track gamma integral gain', 'name', 'I_K_TRK_GAMI', 'group','IFR_GNC');
params.indi.K_TRK_CHI   = struct('default', k_chi_p, 'description', 'Indi track chi gain', 'name', 'I_K_TRK_CHI', 'group','IFR_GNC');
params.indi.K_TRK_CHID  = struct('default', 0, 'description', 'Indi track chi derivative gain', 'name', 'I_K_TRK_CHID', 'group','IFR_GNC');
params.indi.K_TRK_V_CLB = struct('default', k_v_clb, 'description', 'Indi track V gain', 'name', 'I_K_TRK_V_CLB', 'group','IFR_GNC');
params.indi.K_TRK_GA_CLB= struct('default', k_ga_thr, 'description', 'Indi track V gain', 'name', 'I_K_TRK_GAM_T', 'group','IFR_GNC');
params.indi.K_TRK_V     = struct('default', k_v, 'description', 'Indi track V gain', 'name', 'I_K_TRK_V', 'group','IFR_GNC');
params.indi.K_ATT_ALPHA = struct('default', k_a, 'description', 'Indi attitude alpha gain', 'name', 'I_K_ATT_ALP', 'group','IFR_GNC');
params.indi.K_ATT_THETA = struct('default', k_t, 'description', 'Indi attitude theta gain', 'name', 'I_K_ATT_THE', 'group','IFR_GNC');
params.indi.K_ATT_BETA  = struct('default', k_b, 'description', 'Indi attitude beta gain', 'name', 'I_K_ATT_BET', 'group','IFR_GNC');
params.indi.K_ATT_PSI   = struct('default', k_psi, 'description', 'Indi attitude psi gain', 'name', 'I_K_ATT_PSI', 'group','IFR_GNC');
params.indi.K_ATT_PHI   = struct('default', k_m, 'description', 'Indi attitude phi gain', 'name', 'I_K_ATT_PHI', 'group','IFR_GNC');
params.indi.K_RTE_P     = struct('default', k_p, 'description', 'Indi rate p gain', 'name', 'I_K_RATE_P', 'group','IFR_GNC');
params.indi.K_RTE_Q     = struct('default', k_q, 'description', 'Indi rate q gain', 'name', 'I_K_RATE_Q', 'group','IFR_GNC');
params.indi.K_RTE_R     = struct('default', k_r, 'description', 'Indi rate r gain', 'name', 'I_K_RATE_R', 'group','IFR_GNC');
params.indi.K_RTE_PSI_DD= struct('default', 1.2, 'description', 'NDI brkae controller P-gain', 'name', 'I_K_TW_KP', 'group','IFR_GNC');

params.indi.psi_enabled= struct('default', 1, 'description', 'Disable psi measurement on ground', 'name', 'I_PSI_ACTIVE', 'group','IFR_GNC');
params.indi.oswald      = struct('default', 0.7, 'description', 'Oswald factor B matrix', 'name', 'I_OSWALD_B', 'group','IFR_GNC');
params.indi.cl0         = struct('default', 0.6, 'description', 'Zero lift coefficient', 'name', 'I_CL0', 'group','IFR_GNC');

%% Effectiveness
params.indi.EFF_XI_L   = struct('default', -0.1759, 'description', 'Indi effectivity aileron to roll', 'name', 'I_EFF_XI_L', 'group','IFR_GNC');
params.indi.EFF_XI_N   = struct('default', 0.0051, 'description', 'Indi effectivity aileron to yaw', 'name', 'I_EFF_XI_N', 'group','IFR_GNC');
params.indi.EFF_ETA_M  = struct('default', -1.8705, 'description', 'Indi effectivity elevator to pitch', 'name', 'I_EFF_ETA_M', 'group','IFR_GNC');
params.indi.EFF_ZETA_L = struct('default', 0.0078, 'description', 'Indi effectivity rudder to roll', 'name', 'I_EFF_ZETA_L', 'group','IFR_GNC');
params.indi.EFF_ZETA_N = struct('default', -0.0938, 'description', 'Indi effectivity rudder to yaw', 'name', 'I_EFF_ZETA_N', 'group','IFR_GNC');
params.indi.EFF_DELTA  = struct('default', 150, 'description', 'Indi effectivity thrust to accel', 'name', 'I_EFF_DELTA', 'group','IFR_GNC');

%% Inertia
params.indi.inertia_xx = struct('default', 1.4707, 'description', 'Inertia xx', 'name', 'I_INERT_XX', 'group','IFR_GNC');
params.indi.inertia_xy = struct('default', 0, 'description', 'Inertia xy', 'name', 'I_INERT_XY', 'group','IFR_GNC');
params.indi.inertia_yy = struct('default', 26.924, 'description', 'Inertia yy', 'name', 'I_INERT_YY', 'group','IFR_GNC');
params.indi.inertia_yz = struct('default', 0, 'description', 'Inertia yz', 'name', 'I_INERT_YZ', 'group','IFR_GNC');
params.indi.inertia_zz = struct('default', 27.748, 'description', 'Inertia zz', 'name', 'I_INERT_ZZ', 'group','IFR_GNC');
params.indi.inertia_xz = struct('default', 0.545, 'description', 'Inertia xz', 'name', 'I_INERT_XZ', 'group','IFR_GNC');

%% Modal
params.lonCruise.K_ALPHA_ETA=struct('default', 0, 'description', 'short period alpha', 'unit', 'Gs', 'name', 'CR_K_A_ETA', 'group','IFR_GNC');
params.lonCruise.K_Q_ETA=struct('default', -30, 'description', 'short period damper', 'unit', 'Gs', 'name', 'CR_K_Q_ETA', 'group','IFR_GNC');
params.lonCruise.K_V_ETA=struct('default', 0, 'description', 'pyhgoid damper (increase for increased damping)', 'unit', 'Gs', 'name', 'CR_K_V_ETA', 'group','IFR_GNC');
params.lonCruise.K_GAMMA_ETA=struct('default', -240, 'description', 'phygoid spring (increase gain for faster response)', 'unit', 'Gs', 'name', 'CR_K_Y_ETA', 'group','IFR_GNC');
params.lonCruise.I_V_ETA=struct('default', 0, 'description', 'Integrator always 0', 'unit', 'Gs', 'name', 'CR_I_V_ETA', 'group','IFR_GNC');
params.lonCruise.I_GAMMA_ETA=struct('default', -30, 'description', 'integrator gain (approx. 0.2*K_gamma_eta)', 'unit', 'Gs', 'name', 'CR_I_Y_ETA', 'group','IFR_GNC');
params.lonCruise.K_ALPHA_DELTA=struct('default', 0, 'description', 'always 0', 'unit', 'Gs', 'name', 'CR_K_A_DELTA', 'group','IFR_GNC');
params.lonCruise.K_Q_DELTA=struct('default', 0, 'description', 'always 0', 'unit', 'Gs', 'name', 'CR_K_Q_DELTA', 'group','IFR_GNC');
params.lonCruise.K_V_DELTA=struct('default', 45, 'description', 'delta thrust for speed deviation', 'unit', 'Gs', 'name', 'CR_K_V_DELTA', 'group','IFR_GNC');
params.lonCruise.K_GAMMA_DELTA=struct('default',0, 'description', 'Gain for increase in thrust for given delta gamma', 'unit', 'Gs', 'name', 'CR_K_Y_DELTA', 'group','IFR_GNC');
params.lonCruise.I_V_DELTA=struct('default', 15, 'description', 'integrator for V deviation', 'unit', 'Gs', 'name', 'CR_I_V_DELTA', 'group','IFR_GNC');
params.lonCruise.I_GAMMA_DELTA=struct('default', 0, 'description', 'always 0', 'unit', 'Gs', 'name', 'CR_I_Y_DELTA', 'group','IFR_GNC');
params.lonCruise.K_TURN=struct('default', -12, 'description', 'gain for turn coordination', 'unit', 'Gs', 'name', 'CR_K_TURN', 'group','IFR_GNC');
params.latCruise.K_R_XI=struct('default', 0, 'description', 'always 0 - r cannot be controlled by flying wing', 'unit', 'Gs', 'name', 'CR_K_R_XI', 'group','IFR_GNC');
params.latCruise.K_BETA_XI=struct('default', 0, 'description', 'always 0 - no control in beta', 'unit', 'Gs', 'name', 'CR_K_BETA_XI', 'group','IFR_GNC');
params.latCruise.K_P_XI=struct('default',   20, 'description', 'damping in roll about x-axis', 'unit', 'Gs', 'name', 'CR_K_P_XI', 'group','IFR_GNC');
params.latCruise.K_PHI_XI=struct('default', 450, 'description', 'gain for rolling motion (spring)', 'unit', 'Gs', 'name', 'CR_K_PHI_XI', 'group','IFR_GNC');
params.latCruise.I_BETA_XI=struct('default', 0, 'description', 'integrator for side slip deviation', 'unit', 'Gs', 'name', 'CR_I_BETA_XI', 'group','IFR_GNC');
params.latCruise.I_PHI_XI=struct('default', 0.1, 'description', 'integrator for roll deviation', 'unit', 'Gs', 'name', 'CR_I_PHI_XI', 'group','IFR_GNC');
params.latCruise.K_R_ZETA=struct('default', 0, 'description', 'always 0 - r cannot be controlled by flying wing', 'unit', 'Gs', 'name', 'CR_K_R_ZTA', 'group','IFR_GNC');
params.latCruise.K_BETA_ZETA=struct('default', -10, 'description', 'always 0 - no control in beta', 'unit', 'Gs', 'name', 'CR_K_B_ZTA', 'group','IFR_GNC');
params.latCruise.K_P_ZETA=struct('default', 0, 'description', 'damping in roll about x-axis', 'unit', 'Gs', 'name', 'CR_K_P_ZTA', 'group','IFR_GNC');
params.latCruise.K_PHI_ZETA=struct('default', 0, 'description', 'gain for rolling motion (spring)', 'unit', 'Gs', 'name', 'CR_K_PHI_ZTA', 'group','IFR_GNC');
params.latCruise.I_BETA_ZETA=struct('default', 0, 'description', 'integrator for side slip deviation', 'unit', 'Gs', 'name', 'CR_I_BTA_ZTA', 'group','IFR_GNC');
params.latCruise.I_PHI_ZETA=struct('default', 0, 'description', 'integrator for roll deviation', 'unit', 'Gs', 'name', 'CR_I_PHI_ZTA', 'group','IFR_GNC');
params.latCruise.P_CHI=struct('default', 0.05, 'description', 'gain for path azimuth deviation', 'unit', 'Gs', 'name', 'CR_K_PCHI', 'group','IFR_GNC');
params.lonCruise.mainGain=struct('default', 100, 'description', 'Overall controller gain', 'unit', 'Gs', 'name', 'CR_MAINGAIN', 'group','IFR_GNC');

%% Signs
params.controlsigns.ail = struct('default', 1, 'description', 'Sign of control command aileron', 'name', 'SIGN_AIL', 'group','IFR_GNC');
params.controlsigns.ele = struct('default', 1, 'description', 'Sign of control command elevator', 'name', 'SIGN_ELE', 'group','IFR_GNC');
params.controlsigns.rud = struct('default', 1, 'description', 'Sign of control command rudder', 'name', 'SIGN_RUD', 'group','IFR_GNC');
params.controlsigns.thr = struct('default', 1, 'description', 'Sign of control command thrust', 'name', 'SIGN_THR', 'group','IFR_GNC');

%% PIC - CIC interaction
params.authority.chan1 = struct('default', 1, 'description', 'Ctrl author. ch.1: 0->PIC, 1->CIC', 'name', 'AUTHOR_1', 'group','IFR_GNC');  %Percentage of considered control command wrt manual command on channel 1
params.authority.chan2 = struct('default', 1, 'description', 'Ctrl author. ch.2: 0->PIC, 1->CIC', 'name', 'AUTHOR_2', 'group','IFR_GNC');  %Percentage of considered control command wrt manual command on channel 2
params.authority.chan3 = struct('default', 1, 'description', 'Ctrl author. ch.3: 0->PIC, 1->CIC', 'name', 'AUTHOR_3', 'group','IFR_GNC');  %Percentage of considered control command wrt manual command on channel 3
params.authority.chan4 = struct('default', 0, 'description', 'Ctrl author. ch.4: 0->PIC, 1->CIC', 'name', 'AUTHOR_4', 'group','IFR_GNC');  %Percentage of considered control command wrt manual command on channel 4

end