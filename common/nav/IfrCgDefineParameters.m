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
    
params.use_acc   = struct('default', 1, 'type','single', 'description', 'Decide if IMU filter module should be used for accel. (1) or not (0)', 'name', 'IMU_FIL_ACC', 'group','IFR_NAV');
params.use_rte   = struct('default', 1, 'type','single', 'description', 'Decide if IMU filter module should be used for ang vel. (1) or not (0)', 'name', 'IMU_FIL_RTE', 'group','IFR_NAV');

params.sigmaMag=struct('default', 0.115, 'type','single', 'description', 'magnetic field measurement standard deviation', 'name', 'MAG_STD', 'group','IFR_NAV');
params.sigmaGpsPosXy=struct('default', 1.5, 'type','single', 'description', 'GPS horizontal (x-y-axis) position standard deviation', 'unit', 'm', 'name', 'GPS_HPOS_STD', 'group','IFR_NAV');
params.sigmaGpsPosZ=struct('default', 4, 'type','single', 'description', 'GPS vertical (z-axis) position standard deviation', 'unit', 'm', 'name', 'GPS_VPOS_STD', 'group','IFR_NAV');
params.sigmaGpsVelXy=struct('default', 0.06, 'type','single', 'description', 'GPS horizontal (x-y-axis) velocity standard deviation', 'unit', 'm/s', 'name', 'GPS_HVEL_STD', 'group','IFR_NAV');
params.sigmaGpsVelZ=struct('default', 0.09, 'type','single', 'description', 'GPS vertical (z-axis) velocity standard deviation', 'unit', 'm/s', 'name', 'GPS_VVEL_STD', 'group','IFR_NAV');
params.sigmaAccelerationUpdate=struct('default', 0.1, 'type','single', 'description', 'Update of acceleration-based attitude correction standard deviation', 'unit', 'm/s^2', 'name', 'ACC_UPDT_STD', 'group','IFR_NAV');
params.sigmaBaro=struct('default', 0.23, 'type','single', 'description', 'barometric height standard deviation', 'unit', 'm', 'name', 'BARO_STD', 'group','IFR_NAV');
params.sigmaGyro=struct('default', 0.045, 'type','single', 'description', 'gyroscope standard deviation', 'unit', 'rad', 'name', 'GYRO_STD', 'group','IFR_NAV');
params.sigmaAcc=struct('default', 0.013, 'type','single', 'description', 'acceleration standard deviation', 'unit', 'm/s^2', 'name', 'ACC_STD', 'group','IFR_NAV');
params.gpsTimeout=struct('default', 5, 'type','single', 'description', 'time after which GPS is considered unavailable', 'unit', 's', 'name', 'GPS_TIMEOUT', 'group','IFR_NAV');
params.losRateDistanceTimeout=struct('default', 0.5, 'type','single', 'description', 'Max time after detection of comms loss or exceeding distance limit', 'unit', 's', 'name', 'L_RT_D_TOUT', 'group','IFR_NAV');
params.biasSmoothingGain=struct('default', 0.005, 'type','single', 'description', 'weight of current measurement in recursive bias determination', 'min', 0.005, 'max', 0.5, 'name', 'SMOOTHING', 'group','IFR_NAV');
params.gpsAccuracyThreshold=struct('default', 20, 'type','single', 'description', 'only use GPS measurements with this horizontal accuracy or better', 'min', 0.5, 'max', 30, 'unit', 'm', 'name', 'GPS_THRESH', 'group','IFR_NAV');

params.referenceHeight = struct('default', 392, 'type','single', 'description', 'Reference height of ground for Baro', 'name', 'REF_HEIGHT', 'group','IFR_NAV');
params.dynRefHeight = struct('default', 1, 'type','single', 'description', 'Determine reference height dynamically', 'name', 'DYN_H_DETERM', 'group','IFR_NAV');

params.gpsBufferTime = struct('default', 4, 'max', 40, 'type','single', 'description', 'Time period for gps reference averaging', 'name', 'GPS_BUFFER_T', 'group','IFR_NAV');

params.aeroFilCOfreq = struct('default', 0.5, 'type','single', 'unit', '1/s', 'description', 'Cut-off frequency for aerodynamic angle measurement filter', 'name', 'AERO_FIL_OME', 'group','IFR_NAV');
params.aeroFiltActive= struct('default', 1, 'type','single', 'unit', '', 'description', 'Filter switch', 'name', 'AERO_FIL_ON', 'group','IFR_NAV');
params.Zalpha        = struct('default', -155.1208, 'type','single', 'unit', 'm/s^2', 'description', 'Aerodynamic coefficient', 'name', 'Z_ALPHA', 'group','IFR_NAV');
params.Ybeta         = struct('default', -9.0732, 'type','single', 'unit', 'm/s^2', 'description', 'Aerodynamic coefficient', 'name', 'Y_BETA', 'group','IFR_NAV');
params.alphaConv     = struct('default', 1.9428, 'type','single', 'description', 'Conversion from voltage to alpha', 'name', 'ALPHA_CONV', 'group','IFR_NAV');
params.betaConv      = struct('default', 2.3954, 'type','single', 'description', 'Conversion from voltage to beta', 'name', 'BETA_CONV', 'group','IFR_NAV');
params.alphaOff      = struct('default', -3.5651, 'type','single', 'description', 'Offset from voltage to alpha', 'name', 'ALPHA_OFF', 'group','IFR_NAV');
params.betaOff       = struct('default', -2.8122, 'type','single', 'description', 'Offset from voltage to beta', 'name', 'BETA_OFF', 'group','IFR_NAV');
params.channelSwitch = struct('default', 0, 'type','single', 'description', 'ADC channels are switched', 'name', 'ADC_CHSWITCH', 'group','IFR_NAV');

params.lidar_offset = struct('default', 0, 'type','single', 'description', 'Offset on lidar measurement', 'name', 'LIDAR_OFF', 'group','IFR_NAV');

params.pix_roll = struct('default', pi, 'type','single', 'description', 'X axis orientation of pixhawk mount', 'name', 'PIX_ROLL', 'group','IFR_NAV');
params.pix_pitch = struct('default', deg2rad(0), 'type','single', 'description', 'Y axis orientation of pixhawk mount', 'name', 'PIX_PITCH', 'group','IFR_NAV');
params.pix_yaw = struct('default', deg2rad(0), 'type','single', 'description', 'Z axis orientation of pixhawk mount', 'name', 'PIX_YAW', 'group','IFR_NAV');

params.xi_max = struct('default', 11, 'type','single', 'description', 'xi_max', 'name', 'XI_MAX', 'group','IFR_NAV');
params.eta_max = struct('default', 13, 'type','single', 'description', 'eta_max', 'name', 'ETA_MAX', 'group','IFR_NAV');
params.zeta_max = struct('default', 21, 'type','single', 'description', 'zeta_max', 'name', 'ZETA_MAX', 'group','IFR_NAV');
params.lidar_enabled = struct('default', 1, 'type','single', 'description', 'lidar_enabled', 'name', 'LIDAR_ENABLED', 'group','IFR_NAV');
params.chiVel = struct('default', 2, 'type','single', 'description', 'chiVel', 'name', 'CHI_VEL', 'group','IFR_NAV');
params.VaDisabled = struct('default', 0, 'type','single', 'description', 'Va (Airspeed-sensor) Disabled', 'name', 'VA_DISABLED', 'group','IFR_NAV');

%% Signs
params.ail = struct('default', 1, 'type','single', 'description', 'Sign of control command aileron', 'name', 'RC_AIL', 'group','IFR_NAV');
params.ele = struct('default', 1, 'type','single', 'description', 'Sign of control command elevator', 'name', 'RC_ELE', 'group','IFR_NAV');
params.rud = struct('default', 1, 'type','single', 'description', 'Sign of control command rudder', 'name', 'RC_RUD', 'group','IFR_NAV');
params.thr = struct('default', 1, 'type','single', 'description', 'Sign of control command thrust', 'name', 'RC_THR', 'group','IFR_NAV');

end