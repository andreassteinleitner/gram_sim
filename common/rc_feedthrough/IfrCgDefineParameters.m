%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                             %
% Copyright: iFR - Universität Stuttgart      %
%                                             %
% Autor:  Manuel Storrer, M.Sc.               %
% E-Mail: manuel.storrer@ifr.uni-stuttgart.de %
% Datum:  28.05.2026                          %
%                                             %
% Letztes Update: 28.05.2026                  %
%                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [parameters]=defineParameters()

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
    
%% Feedthrough

% Enable RC feedthrough
parameters.enable_motor_feedthrough = struct('name','IFR_ENBL_MOTORS',...
                                             'group','iFR Feedthrough',...
                                             'type','single',...
                                             'default',0,...
                                             'min',0,...
                                             'max',1,...
                                             'decimal',0,...
                                             'increment',1,...
                                             'description_short', 'Enable motor feedthrough',...
                                             'description_long', 'Enable the RC channel feedthrough corresponding to the motors. False corresponds to disarmed outputs. Motor channels are the channels 7 to 14.');

parameters.enable_servo_feedthrough = struct('name','IFR_ENBL_SERVOS',...
                                             'group','iFR Feedthrough',...
                                             'type','single',...
                                             'default',0,...
                                             'min',0,...
                                             'max',1,...
                                             'decimal',0,...
                                             'increment',1,...
                                             'description_short', 'Enable servo feedthrough',...
                                             'description_long', 'Enable the RC channel feedthrough corresponding to the servos. False corresponds to disarmed outputs. Servo channels are the channels 1 to 6 and 15 to 16.');

end