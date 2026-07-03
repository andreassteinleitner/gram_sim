%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                           %
% Copyright: iFR - Universität Stuttgart    %
%                                           %
% Autor:  Dipl.-Ing. Niklas Pauli           %
% E-Mail: Niklas.Pauli@ifr.uni-stuttgart.de %
% Datum:  07.03.2024                        %
%                                           %
% Letztes Update: 22.10.2024                %
%                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function params=IfrCgDefineParameters()

%% Beschreibung
% Die Funktion definiert die Parameter für den zugehörigen Algorithmus. Diese werden sowohl in der Simulation als
% auch über die IFR CodeGeneration für PX4 in der Firmware der Autopiloten genutzt.
% Die Parameter werden bewusst allgemein als ein Matlab-Struct angelegt. Daraus werden sie dann mit den entsprechenden 
% Parsern in die für den jeweiligen Einsatz passende Form gebracht.
% Für die Simulation und die IFR CodeGeneration für PX4 bedeutet das, dass sie aus dieser Defintion ein entsprechender
% Bus gebaut wird und auch ein Struct, der den Wert des Parameters enthält. Dadurch können in der Simulation auch
% mehrere unterschiedliche Parametersätze genutzt werden.
% Bei der IFR CodeGeneration für PX4 wird auch eine entsprechende Parameterdefintionsdatei erzeugt, wie sie durch die
% Firmware des Bordrechners benötigt wird.

%% Referenzen
% Das Schema zur Definition von PX4-Parametern findet sich unter 
% https://github.com/PX4/PX4-Autopilot/blob/main/validation/module_schema.yaml

%% Konventionen/Regeln

% Bei der Defintion der Parameter müssen folgende Konventionen eingehalten werden:
%   - Die Bezeichnung hat immer einen zweiteiligen Aufbau "parameter.bezeichnung
%       - hierbei ist "parameter" einfach die Ausgangsvariable des Gesamtfunktion und die "bezeichnung" kann frei 
%         gewählt werden (! "bezeichnung" muss für verschiedene Parameter aber auch verschieden sein).
%   - Das Struct selbst besteht aus einer Auswahl von Feldern mit festen Bezeichnungen. Davon sind manche zwingend zu
%     nutzen und manche nur in bestimmten Situationen von Relevanz (siehe unten). Die Reihenfolge der Felder ist
%     grundsätzlich nicht von Relevanz aber sollte aus Gründen der Übersichtlichkeit konsistent sein.
%   - Alle Felder, die nicht einen Wert oder Zahl enthalten werden als "Character Array" mit einfachen Anführungszeichen
%     also z.B. 'single' angegeben und nicht als String Array (haben doppelte Anführungszeichen). 
%   - Die Felder 'default', 'min', 'max', 'decimal' und 'increment' haben Zahlenwerte (z.B. 2.0) und diese werden auch
%     so ohne jegliche Anführungszeichen angegeben. Für boolesche-Parameter kann für den 'default'-Wert auch true oder
%     false angegeben werden.
%   - Für den Parameternamen gilt:
%       - Er wird als Feld 'name' angegeben und ist NICHT identisch zur "bezeichnung" (s.o.)
%       - Großschreibung ist Pflicht.
%       - Die Namen aller Parameter in einer Simulation oder in einer PX4-Firmware müssen unterschiedlich. Doppelte
%         Parameternamen sind nicht erlaubt, auch nicht in verschiedenen Algorithmen oder Gruppen.
%       - Die Anzahl Ziffern darf nicht größer als 16 sein, da dies das Limit von PX4 ist. Info: in der aktuellen
%         IFR-CodeGen für PX4 wird KEIN Präfix "IFR_" mehr automatisch den Namen vorangestellt.
%   - Über die Gruppen ist es möglich eine zusätzliche Aufteilung der Parameter innerhalb eines Moduls zu erhalten.
%       - Der Gruppenname wird im Feld 'group' angegeben.
%       - Momentan MUSS ein Gruppenname vergeben werden, da die Nutzung in der Simulation und iFR-CodeGeneration darauf
%         ausgelegt ist. Soll keine Aufteilung in einem Modul getroffen werden, so können alle Parameter der gleichen
%         Gruppe zugeordnet werden.
%       - Über den Gruppennamen werden auch die Parameter in PX4 gruppiert, was insbesonder bei der Nutzung der 
%         Bodenkontrollstationssoftware QGC von Vorteil ist.
%       - es ist möglich auch den gleichen Gruppennamen in verschiedenen Algorithmen bzw. Modulen zu nutzen. Dadurch
%         existiert die Möglichkeit Parameter von mehreren Algorithmen einer Gruppe zuzuordnen, wenn diese thematisch
%         zusammenfallen. Dies hat aber nur Auswirkungen innerhalb von PX4 bzw. bei der Nutzung von QGC. Für die in der
%         Simulation genutzen Matlab.Structs und Bus-Objekte erfolgt über die jeweiligen Algorithmen als oberer Ebene
%         eine Aufteilung.
%       - Der Gruppenname sollte möglichst kurz sein. 
%   - Folgende weitere Felder müssen angegeben werden:
%       - 'type' = Datentyp (erlaubt = 'single', 'int32', 'boolean')
%       - 'default' = Standardwert des Parameters (z.B. 1.0, für boolesche Parameter kann entweder true oder false oder
%                     auch 0 und 1 genutzt werden.
%       - eine "Beschreibung" bzw. 'description'. Für mehr Details siehe unten.
%   - Die weiteren Felder sind nur optional, aber sollten für eine saubere Darstellung in PX4 gesetzt werden
%       - 'unit' = Einheit des Parameters (für die erlaubten Einheitsbezeichnungen siehe Referenz oben).
%       - 'min' = Minimalwert des Parameters (nur bei Datenty 'single' und 'int32' von Relevanz)
%       - 'max' = Maximalwert des Parameters
%       - 'decimal' = Anzahl an Dezimalstellen des Parameters (nur für Datenty 'single' von Relevanz und auch nur 
%                     beachtet bei Eingabe in PX4 über QGC)
%       - 'increment' = Inkrement zur Veränderung des Parameterwerts (nur für Datenty 'single' von Relevanz und auch nur 
%                     beachtet bei Eingabe in PX4 über QGC)
%   - Bei der Beschreibung stehen 2 Möglichkeiten zur Verfügung. Allerdings muss eine davon umgesetzt sein.
%       - 1. Es wird ein Feld 'description' genutzt, das die Beschreibung des Parameters enthält. Diese darf eine Länge
%            von 70 Zeichen nicht überschreiten und wird in PX4 und auch für die Parameterbusse genutzt.
%       - 2. Es wird ein Feld 'description_short' genutzt, das eine KURZE Beschreibung des Parameters enthält. Diese 
%            darf eine Länge von 70 Zeichen nicht überschreiten. Es besteht dann die Möglichkeit auch eine zusätzliches 
%            Feld 'description_long' hinzuzufügen, das eine LANGE Beschreibung des Parameters enthält. Diese 
%            darf dann eine Länge von 200 Zeichen nicht überschreiten. Es kann aber auch auf das Feld 'description_long'
%            verzeichtet werden. In diesem Fall entspricht 'description_short' einer Nutzung von 'description'. Wenn ein
%            Feld 'description_long' vorhanden ist, wird dieses an entsprechender Stelle in PX4 aber auch für die
%            Beschreibung in den Parameterbussen genutzt.

%% Beispiel

% parameters.param1=struct('name','IFR_WP_PHI_TURN',...
%                          'group','IFR_WP_CTRL',...
%                          'type','single',...
%                          'default',45.0,...
%                          'unit','deg',...
%                          'min',0.0,...
%                          'max',90.0,...
%                          'decimal',1,...
%                          'increment',0.1,...
%                          'description_short','virtual allowed bank angle for switching condition',...
%                          'description_long','Algorithm switches to the next waypoint, if the aircraft is closer to the waypoint than the radius of a horzontal turn with this bank angle');

%% Parameterdefinitionen
    
params.trim_switch             = struct('default', 0, 'type','single', 'description', 'Set autopilot into trim mode', 'name', 'G_TRIM_SWITCH', 'group','IFR_GNC');

params.controller_selector     = struct('default', 0, 'type','single', 'description', 'Select contoller type, (0) INDI, (1) MODAL', 'name', 'G_CONTROL_SEL', 'group','IFR_GNC');
params.imu_filt_ang_acc        = struct('default', 1, 'type','single', 'description', 'Should IMU fil. module be used for ang. accel (1) or not (0)', 'name', 'IMU_FIL_DRTE', 'group','IFR_GNC');
params.trk_der_switch          = struct('default', 1, 'type','single', 'description', 'Trk derivs calculated from accel measures (1) or numeric diff (2-6)', 'name', 'G_TRK_DERIV', 'group','IFR_GNC');

%% ATOL parameters
params.h_fake                  = struct('default', 0, 'type','single', 'description', 'Perform fake landing at defined altitude', 'min', 0, 'name', 'A_FAK_ALT', 'group','IFR_GNC');
params.h_loiter                = struct('default', 50, 'type','single', 'description', 'Loiter height above ground', 'min', 0, 'name', 'A_HLOITER', 'group','IFR_GNC');

%% Saturations
params.gammaMin          = struct('default', -12, 'type','single', 'description', 'Minimum gamma commanding', 'name', 'L_GAMMA_MIN', 'group','IFR_GNC');
params.gammaMax          = struct('default', 12, 'type','single', 'description', 'Maximum gamma commanding', 'name', 'L_GAMMA_MAX', 'group','IFR_GNC');
params.vel_max           = struct('default', 50, 'type','single', 'description', 'Maximum velocity', 'unit', 'm/s', 'name', 'L_V_MAX', 'group','IFR_GNC');
params.vel_min           = struct('default',15, 'type','single', 'description', 'Minimum velocity', 'name', 'L_VEL_MIN', 'group','IFR_GNC');
params.nzMax             = struct('default', 4, 'type','single', 'description', 'Maximum load factor', 'name', 'L_NZ_MAX', 'group','IFR_GNC');
params.gr_lim            = struct('default', 0.6, 'type','single', 'description', 'Limit for commanded ground turn rate', 'name', 'L_GR_MAX', 'group','IFR_GNC');
params.alpha_max         = struct('default', 15, 'type','single', 'description', 'Aerodynamic attitude', 'name', 'L_ALPHA_MAX_0', 'group','IFR_GNC');
params.theta_max         = struct('default', 18, 'type','single', 'description', 'Theta limit', 'name', 'L_THETA_MAX', 'group','IFR_GNC');
params.beta_max          = struct('default', 25, 'type','single', 'description', 'Limit for commanded sideslip angle', 'name', 'L_BETA_MAX', 'group','IFR_GNC');
params.phi_max           = struct('default', 30, 'type','single', 'description', 'Limit for commanded roll angle', 'name', 'L_PHI_MAX', 'group','IFR_GNC');
params.p_lim             = struct('default', 1, 'type','single', 'description', 'Limit for commanded roll rate', 'name', 'L_P_MAX', 'group','IFR_GNC');
params.q_lim             = struct('default', 0.7, 'type','single', 'description', 'Limit for commanded pitch rate', 'name', 'L_Q_MAX', 'group','IFR_GNC');
params.r_lim             = struct('default', 0.3, 'type','single', 'description', 'Limit for commanded yaw rate', 'name', 'L_R_MAX', 'group','IFR_GNC');
params.act_lim           = struct('default', 1.0, 'type','single', 'description', 'Limit for actuator commands', 'name', 'L_ACT_MAX', 'group','IFR_GNC');
params.flap_max          = struct('default', 90, 'type','single', 'description', 'Maximum flap deflection', 'name', 'L_FLP_MAX', 'group','IFR_GNC');

%% NAV parameters
params.xi_max            = struct('default', 11, 'type','single', 'description', 'xi_max', 'name', 'XI_MAX_GNC', 'group','IFR_GNC');
params.eta_max           = struct('default', 13, 'type','single', 'description', 'eta_max', 'name', 'ETA_MAX_GNC', 'group','IFR_GNC');
params.zeta_max          = struct('default', 21, 'type','single', 'description', 'zeta_max', 'name', 'ZETA_MAX_GNC', 'group','IFR_GNC');
params.pix_roll          = struct('default', pi, 'type','single', 'description', 'X axis orientation of pixhawk mount', 'name', 'PIX_ROLL_GNC', 'group','IFR_GNC');
params.pix_pitch         = struct('default', deg2rad(0), 'type','single', 'description', 'Y axis orientation of pixhawk mount', 'name', 'PIX_PITCH_GNC', 'group','IFR_GNC');
params.pix_yaw           = struct('default', deg2rad(0), 'type','single', 'description', 'Z axis orientation of pixhawk mount', 'name', 'PIX_YAW_GNC', 'group','IFR_GNC');
params.use_acc           = struct('default', 1, 'type','single', 'description', 'Decide if IMU filter module should be used for accel. (1) or not (0)', 'name', 'IMUFACC_GNC', 'group','IFR_GNC');

%% Guidance
params.K_H         = struct('default', 1, 'type','single', 'description', 'gain for horizontal path tracking', 'name', 'GU_K_H', 'group','IFR_GNC');
params.K_V         = struct('default', 1, 'type','single', 'description', 'gain for vertical path tracking', 'name', 'GU_K_V', 'group','IFR_GNC');
params.WP          = struct('default', -0.6, 'type','single', 'description', 'proportional gain for vertical waypoint tracking', 'name', 'GU_WP', 'group','IFR_GNC');
params.v_cmd       = struct('default', 20, 'type','single', 'description', 'set-point velocity', 'unit', 'm/s', 'name', 'GU_V_CMD', 'min', 12, 'group','IFR_GNC');
params.gamma_cmd   = struct('default', 0, 'type','single', 'description', 'set-point gamma', 'unit', 'deg', 'name', 'GU_GAMMA_CMD', 'group','IFR_GNC');
params.chi_cmd     = struct('default', 0, 'type','single', 'description', 'set-point chi', 'unit', 'deg', 'name', 'GU_CHI_CMD', 'group','IFR_GNC');
params.psi_cmd     = struct('default', 0, 'type','single', 'description', 'set-point psi', 'unit', 'deg', 'name', 'GU_PSI_CMD', 'group','IFR_GNC');

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

params.K_POS_Y     = struct('default', k_y, 'type','single', 'description', 'Indi position lateral offset gain', 'name', 'I_K_POS_Y', 'group','IFR_GNC');
params.K_POS_Z     = struct('default', k_z, 'type','single', 'description', 'Indi position vertical offset gain', 'name', 'I_K_POS_Z', 'group','IFR_GNC');
params.K_TRK_GAMMA = struct('default', k_ga_p, 'type','single', 'description', 'Indi track gamma gain', 'name', 'I_K_TRK_GAM', 'group','IFR_GNC');
params.K_TRK_GAMMAD= struct('default', 0, 'type','single', 'description', 'Indi track gamma derivative gain', 'name', 'I_K_TRK_GAMD', 'group','IFR_GNC');
params.K_TRK_GAMMAI= struct('default', 0, 'type','single', 'description', 'Indi track gamma integral gain', 'name', 'I_K_TRK_GAMI', 'group','IFR_GNC');
params.K_TRK_CHI   = struct('default', k_chi_p, 'type','single', 'description', 'Indi track chi gain', 'name', 'I_K_TRK_CHI', 'group','IFR_GNC');
params.K_TRK_CHID  = struct('default', 0, 'type','single', 'description', 'Indi track chi derivative gain', 'name', 'I_K_TRK_CHID', 'group','IFR_GNC');
params.K_TRK_V_CLB = struct('default', k_v_clb, 'type','single', 'description', 'Indi track V gain', 'name', 'I_K_TRK_V_CLB', 'group','IFR_GNC');
params.K_TRK_GA_CLB= struct('default', k_ga_thr, 'type','single', 'description', 'Indi track V gain', 'name', 'I_K_TRK_GAM_T', 'group','IFR_GNC');
params.K_TRK_V     = struct('default', k_v, 'type','single', 'description', 'Indi track V gain', 'name', 'I_K_TRK_V', 'group','IFR_GNC');
params.K_ATT_ALPHA = struct('default', k_a, 'type','single', 'description', 'Indi attitude alpha gain', 'name', 'I_K_ATT_ALP', 'group','IFR_GNC');
params.K_ATT_THETA = struct('default', k_t, 'type','single', 'description', 'Indi attitude theta gain', 'name', 'I_K_ATT_THE', 'group','IFR_GNC');
params.K_ATT_BETA  = struct('default', k_b, 'type','single', 'description', 'Indi attitude beta gain', 'name', 'I_K_ATT_BET', 'group','IFR_GNC');
params.K_ATT_PSI   = struct('default', k_psi, 'type','single', 'description', 'Indi attitude psi gain', 'name', 'I_K_ATT_PSI', 'group','IFR_GNC');
params.K_ATT_PHI   = struct('default', k_m, 'type','single', 'description', 'Indi attitude phi gain', 'name', 'I_K_ATT_PHI', 'group','IFR_GNC');
params.K_RTE_P     = struct('default', k_p, 'type','single', 'description', 'Indi rate p gain', 'name', 'I_K_RATE_P', 'group','IFR_GNC');
params.K_RTE_Q     = struct('default', k_q, 'type','single', 'description', 'Indi rate q gain', 'name', 'I_K_RATE_Q', 'group','IFR_GNC');
params.K_RTE_R     = struct('default', k_r, 'type','single', 'description', 'Indi rate r gain', 'name', 'I_K_RATE_R', 'group','IFR_GNC');
params.K_RTE_PSI_DD= struct('default', 1.2, 'type','single', 'description', 'NDI brkae controller P-gain', 'name', 'I_K_TW_KP', 'group','IFR_GNC');
params.psi_enabled= struct('default', 1, 'type','single', 'description', 'Disable psi measurement on ground', 'name', 'I_PSI_ACTIVE', 'group','IFR_GNC');
params.oswald      = struct('default', 0.7, 'type','single', 'description', 'Oswald factor B matrix', 'name', 'I_OSWALD_B', 'group','IFR_GNC');
params.cl0         = struct('default', 0.6, 'type','single', 'description', 'Zero lift coefficient', 'name', 'I_CL0', 'group','IFR_GNC');

%% Effectiveness
params.EFF_XI_L   = struct('default', -0.1759, 'type','single', 'description', 'Indi effectivity aileron to roll', 'name', 'I_EFF_XI_L', 'group','IFR_GNC');
params.EFF_XI_N   = struct('default', 0.0051, 'type','single', 'description', 'Indi effectivity aileron to yaw', 'name', 'I_EFF_XI_N', 'group','IFR_GNC');
params.EFF_ETA_M  = struct('default', -1.8705, 'type','single', 'description', 'Indi effectivity elevator to pitch', 'name', 'I_EFF_ETA_M', 'group','IFR_GNC');
params.EFF_ZETA_L = struct('default', 0.0078, 'type','single', 'description', 'Indi effectivity rudder to roll', 'name', 'I_EFF_ZETA_L', 'group','IFR_GNC');
params.EFF_ZETA_N = struct('default', -0.0938, 'type','single', 'description', 'Indi effectivity rudder to yaw', 'name', 'I_EFF_ZETA_N', 'group','IFR_GNC');
params.EFF_DELTA  = struct('default', 150, 'type','single', 'description', 'Indi effectivity thrust to accel', 'name', 'I_EFF_DELTA', 'group','IFR_GNC');
% params.indi.EFF_DELTA  = struct('default', 14, 'description', 'Indi effectivity thrust to accel', 'name', 'I_EFF_DELTA', 'group','IFR_GNC');

%% Inertia
params.inertia_xx = struct('default', 1.4707, 'type','single', 'description', 'Inertia xx', 'name', 'I_INERT_XX', 'group','IFR_GNC');
params.inertia_xy = struct('default', 0, 'type','single', 'description', 'Inertia xy', 'name', 'I_INERT_XY', 'group','IFR_GNC');
params.inertia_yy = struct('default', 26.924, 'type','single', 'description', 'Inertia yy', 'name', 'I_INERT_YY', 'group','IFR_GNC');
params.inertia_yz = struct('default', 0, 'type','single', 'description', 'Inertia yz', 'name', 'I_INERT_YZ', 'group','IFR_GNC');
params.inertia_zz = struct('default', 27.748, 'type','single', 'description', 'Inertia zz', 'name', 'I_INERT_ZZ', 'group','IFR_GNC');
params.inertia_xz = struct('default', 0.545, 'type','single', 'description', 'Inertia xz', 'name', 'I_INERT_XZ', 'group','IFR_GNC');

% params.indi.inertia_xx = struct('default', 0.1414, 'description', 'Inertia xx', 'name', 'I_INERT_XX', 'group','IFR_GNC');
% params.indi.inertia_xy = struct('default', 0, 'description', 'Inertia xy', 'name', 'I_INERT_XY', 'group','IFR_GNC');
% params.indi.inertia_yy = struct('default', 0.1124, 'description', 'Inertia yy', 'name', 'I_INERT_YY', 'group','IFR_GNC');
% params.indi.inertia_yz = struct('default', 0, 'description', 'Inertia yz', 'name', 'I_INERT_YZ', 'group','IFR_GNC');
% params.indi.inertia_zz = struct('default', 0.2333, 'description', 'Inertia zz', 'name', 'I_INERT_ZZ', 'group','IFR_GNC');
% params.indi.inertia_xz = struct('default', 0.0104, 'description', 'Inertia xz', 'name', 'I_INERT_XZ', 'group','IFR_GNC');

%% Modal
params.K_ALPHA_ETA=struct('default', 0, 'type','single', 'description', 'short period alpha', 'name', 'CR_K_A_ETA', 'group','IFR_GNC');
params.K_Q_ETA=struct('default', -30, 'type','single', 'description', 'short period damper', 'name', 'CR_K_Q_ETA', 'group','IFR_GNC');
params.K_V_ETA=struct('default', 0, 'type','single', 'description', 'pyhgoid damper (increase for increased damping)', 'name', 'CR_K_V_ETA', 'group','IFR_GNC');
params.K_GAMMA_ETA=struct('default', -240, 'type','single', 'description', 'phygoid spring (increase gain for faster response)', 'name', 'CR_K_Y_ETA', 'group','IFR_GNC');
params.I_V_ETA=struct('default', 0, 'type','single', 'description', 'Integrator always 0', 'name', 'CR_I_V_ETA', 'group','IFR_GNC');
params.I_GAMMA_ETA=struct('default', -30, 'type','single', 'description', 'integrator gain (approx. 0.2*K_gamma_eta)', 'name', 'CR_I_Y_ETA', 'group','IFR_GNC');
params.K_ALPHA_DELTA=struct('default', 0, 'type','single', 'description', 'always 0', 'name', 'CR_K_A_DELTA', 'group','IFR_GNC');
params.K_Q_DELTA=struct('default', 0, 'type','single', 'description', 'always 0', 'name', 'CR_K_Q_DELTA', 'group','IFR_GNC');
params.K_V_DELTA=struct('default', 45, 'type','single', 'description', 'delta thrust for speed deviation', 'name', 'CR_K_V_DELTA', 'group','IFR_GNC');
params.K_GAMMA_DELTA=struct('default',0, 'type','single', 'description', 'Gain for increase in thrust for given delta gamma', 'name', 'CR_K_Y_DELTA', 'group','IFR_GNC');
params.I_V_DELTA=struct('default', 15, 'type','single', 'description', 'integrator for V deviation', 'name', 'CR_I_V_DELTA', 'group','IFR_GNC');
params.I_GAMMA_DELTA=struct('default', 0, 'type','single', 'description', 'always 0', 'name', 'CR_I_Y_DELTA', 'group','IFR_GNC');
params.K_TURN=struct('default', -12, 'type','single', 'description', 'gain for turn coordination', 'name', 'CR_K_TURN', 'group','IFR_GNC');
params.K_R_XI=struct('default', 0, 'type','single', 'description', 'always 0 - r cannot be controlled by flying wing', 'name', 'CR_K_R_XI', 'group','IFR_GNC');
params.K_BETA_XI=struct('default', 0, 'type','single', 'description', 'always 0 - no control in beta', 'name', 'CR_K_BETA_XI', 'group','IFR_GNC');
params.K_P_XI=struct('default',   20, 'type','single', 'description', 'damping in roll about x-axis', 'name', 'CR_K_P_XI', 'group','IFR_GNC');
params.K_PHI_XI=struct('default', 450, 'type','single', 'description', 'gain for rolling motion (spring)', 'name', 'CR_K_PHI_XI', 'group','IFR_GNC');
params.I_BETA_XI=struct('default', 0, 'type','single', 'description', 'integrator for side slip deviation', 'name', 'CR_I_BETA_XI', 'group','IFR_GNC');
params.I_PHI_XI=struct('default', 0.1, 'type','single', 'description', 'integrator for roll deviation', 'name', 'CR_I_PHI_XI', 'group','IFR_GNC');
params.K_R_ZETA=struct('default', 0, 'type','single', 'description', 'always 0 - r cannot be controlled by flying wing', 'name', 'CR_K_R_ZTA', 'group','IFR_GNC');
params.K_BETA_ZETA=struct('default', -10, 'type','single', 'description', 'always 0 - no control in beta', 'name', 'CR_K_B_ZTA', 'group','IFR_GNC');
params.K_P_ZETA=struct('default', 0, 'type','single', 'description', 'damping in roll about x-axis', 'name', 'CR_K_P_ZTA', 'group','IFR_GNC');
params.K_PHI_ZETA=struct('default', 0, 'type','single', 'description', 'gain for rolling motion (spring)', 'name', 'CR_K_PHI_ZTA', 'group','IFR_GNC');
params.I_BETA_ZETA=struct('default', 0, 'type','single', 'description', 'integrator for side slip deviation', 'name', 'CR_I_BTA_ZTA', 'group','IFR_GNC');
params.I_PHI_ZETA=struct('default', 0, 'type','single', 'description', 'integrator for roll deviation', 'name', 'CR_I_PHI_ZTA', 'group','IFR_GNC');
params.P_CHI=struct('default', 0.05, 'type','single', 'description', 'gain for path azimuth deviation', 'name', 'CR_K_PCHI', 'group','IFR_GNC');
params.mainGain=struct('default', 100, 'type','single', 'description', 'Overall controller gain', 'name', 'CR_MAINGAIN', 'group','IFR_GNC');

%% Signs
params.ail = struct('default', 1, 'type','single', 'description', 'Sign of control command aileron', 'name', 'SIGN_AIL', 'group','IFR_GNC');
params.ele = struct('default', 1, 'type','single', 'description', 'Sign of control command elevator', 'name', 'SIGN_ELE', 'group','IFR_GNC');
params.rud = struct('default', 1, 'type','single', 'description', 'Sign of control command rudder', 'name', 'SIGN_RUD', 'group','IFR_GNC');
params.thr = struct('default', 1, 'type','single', 'description', 'Sign of control command thrust', 'name', 'SIGN_THR', 'group','IFR_GNC');

%% PIC - CIC interaction
params.chan1 = struct('default', 1, 'type','single', 'description', 'Ctrl author. ch.1: 0->PIC, 1->CIC', 'name', 'AUTHOR_1', 'group','IFR_GNC');  %Percentage of considered control command wrt manual command on channel 1
params.chan2 = struct('default', 1, 'type','single', 'description', 'Ctrl author. ch.2: 0->PIC, 1->CIC', 'name', 'AUTHOR_2', 'group','IFR_GNC');  %Percentage of considered control command wrt manual command on channel 2
params.chan3 = struct('default', 1, 'type','single', 'description', 'Ctrl author. ch.3: 0->PIC, 1->CIC', 'name', 'AUTHOR_3', 'group','IFR_GNC');  %Percentage of considered control command wrt manual command on channel 3
params.chan4 = struct('default', 1, 'type','single', 'description', 'Ctrl author. ch.4: 0->PIC, 1->CIC', 'name', 'AUTHOR_4', 'group','IFR_GNC');  %Percentage of considered control command wrt manual command on channel 4

end