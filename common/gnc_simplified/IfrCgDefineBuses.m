function [] = IfrCgDefineBuses(prefix)

% IFR CodeGen for PX4
% University of Stuttgart, Institute of Flight Mechanics and Control

% Author: Niklas Pauli niklas.pauli@ifr.uni-stuttgart.de>
% Date: April 2026

%% Description
% The function IfrCgDefineBuses() will be automatically called by the IFR Code, when a model is opened or a module is
% generated. The function offers the possibility to define Simulink-Bus-Objects (short: "buses") for the user. These buses 
% can be freely used within the Simulink model and may improve its internal structure.
% 
% The names of the buses will automatically have the prefix, which has been specified for buses in the IFR CodeGen. The user 
% can adjust the prefix with the corresponding specification file(s) (see README).
% Besides that, user is free to choose the name of the buses (! only the name in the cell array counts and NOT the name of the 
% field of the bus defintion structure). Be aware that all bus names will be transformed PascalCase automatically. 
%
% The user can also define a Bus-Object that has another Bus-Object as one of its element. There are two possibilities, how
% the referenced bus is defined by itself:
% 1) The Bus-Object is define within this function:
%    The user has to use the keyword "Bus_IFRCG:" for the type of the element followed by the EXACT (bus-)name used in the 
%    definition of the referenced bus. Only by doing this the selected prefic is added correctly (see example).
% 2) The Bus-Object is define outside of this function:
%    The user has to use the standard keyword "Bus:" for the type of the element followed by the EXACT (bus-)name used in the 
%    definition of the referenced bus. The user has also to make sure that the definition of the referenced bus is also
%    loaded when the model is openened. For example by using the "execute_before" specification for the model.
%
% Important:
% After defining a new Bus-Object it has to be added to the Cell Array "Bus_Definitions", which collects all Bus-Object
% defintions and passes them to the function to create the actual Bus-Objects.
%
% General Info about "buses" in Matlab/Simulink:
%   Every Bus resp. Bus-Object contains the following fields:
%       - Description = Bus description e.g. ''(default)
%       - Elements = Elements of bus: more info see below, default = empty array
%       - DataScope = Data type definition mode in generated code 'Auto' (default) | 'Exported' | 'Imported'
%       - HeaderFile = C header file used with data type definition '' (default) | character vector | string scalar
%       - Alignment — Data alignment boundary -1 (default) | integer
%       - PreserveElementDimensions — Specification to preserve dimensions of multidimensional bus elements 'false' (default) | 'true'
%
%   The Bus-Elemente themselves contain the following fields:
%       - Name = character vector e.g. 'a'(default)
%       - Complexity = Numeric Type of element ('real'(default)|'complex')
%       - Dimension = Dimension of element e.g. 1(default) or [3,3]
%       - DataType = Data type of element e.g. 'double'(default) or 'Bus: Sinusoidal'
%       - Min = Minimum value of element [](default) or scalar value
%       - Max = Maximum value of element [](default) or scalar value
%       - DimensionsMode = Specify hwo to handle size of element 'Fixed'(default) | 'Variable'
%       - Unit = Physical Unit for expressing element e.g. ''(default)
%       - Description = Bus element description e.g. ''(default)
%
%   The definitions of the Bus-Objects and Bus-Elements are given as a "Cell Array" for a better readability.
%   They are converted to actual buses with the function Simulink.Bus.cellToObject(), which expects the following order of
%   fields:
%
%       Bus-Object:
%       1. Bus name
%       2. Header file
%       3. Description
%       4. Data scope
%       5. Alignment
%       6. Preserve Element Dimensions
%       7. Elements
%
%       Bus-Element:
%       1. Element name
%       2. Dimensions
%       3. Data type
%       4. Sample time (optional) — If you specify a sample time, specify an inherited sample time (-1). A noninherited sample time causes an error during model compilation. For more information, see Simulink.BusElement objects no longer support the SampleTime property.
%       5. Complexity
%       6. Sampling mode (entfernt aus Bus Element, aber immer noch benötigt für Simulink.Bus.cellToObject())
%          The elements field arrays or cell arrays can also contain this information:
%       7. Dimensions mode
%       8. Minimum
%       9. Maximum
%       10. Units
%       11. Description
%
%   References:
%       - https://de.mathworks.com/help/simulink/ug/create-bus-objects-programmatically.html
%       - https://de.mathworks.com/help/simulink/slref/simulink.bus.celltoobject.html
%       - https://de.mathworks.com/help/simulink/slref/simulink.buselement.html
%       - https://de.mathworks.com/help/simulink/slref/simulink.bus.html

%% Bus-Definitions

    % Cell Array with all Bus definition
    guidance_cmd={...
        {'guidance_cmd', '', 'Results of guidance calculation', {...
            {'roll_lim', 1, 'single', 'real', 'Sample', 'Fixed', [], [], '', ''},...
            {'act_cmd', 6, 'single', 'real', 'Sample', 'Fixed', [], [], '', ''},...
            {'rte_cmd', 3, 'single', 'real', 'Sample', 'Fixed', [], [], '', ''},...
            {'att_cmd', 5, 'single', 'real', 'Sample', 'Fixed', [], [], '', ''},...
            {'trk_cmd', 3, 'single', 'real', 'Sample', 'Fixed', [], [], '', ''}...
        }}
    };

    % Cell Array with all Bus definition
    Bus_Definitions = {guidance_cmd};
     

%% Generating Bus-Objects

% call IFR CodeGen function which also deals with the prefix
createModelBusObject(Bus_Definitions, prefix)

end 