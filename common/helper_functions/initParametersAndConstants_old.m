% iFR GNC - simulink - PX4 interface
% Flight Mechanics and Controls Lab
% Created: 2018-07-09
% Copyright 2018 Stuttgart University.
%
% @author Johannes Stephan <johannes.stephan@ifr.uni-stuttgart.de>
% @author Lorenz Schmitt <lorenz.schmitt@ifr.uni-stuttgart.de>

function [constants, defaultPara, parameterDefinition, parameterConnectionBody]=initParametersAndConstants_old(params, consts, module_name)
%% generate default data
[constants,~] = generateDefaultConstants(consts,0);
[defaultPara,paraCount] = generateDefaultParameters(params,0);

%% generate bus objects
generateBusObjects(params, [module_name,'_parameter'])
generateBusObjects(consts, [module_name,'_constants'])

[parameterDefinition, parameterConnectionBody]=writeParaDef(params, 'parameters',paraCount);
parameterDefinition=['#include <px4_config.h>', newline, '#include <parameters/param.h>', newline, newline, parameterDefinition];

end

function [defaultPara,count] = generateDefaultParameters(data,count)
if isempty(data)
    defaultPara = struct([]);
else
    fields = fieldnames(data);
    for ii=1:numel(fields)
        field = fields{ii};
        locData = data.(field);
        locFields = fieldnames(locData);

        if isstruct(locData.(locFields{1}))
            [locResult,count] = generateDefaultParameters(locData,count);
            defaultPara.(field) = locResult;
        else
            if isfield(locData,'default') && ~isempty(locData.default)
                if isfield(locData,'type')
                    defaultPara.(field) = eval([locData.type, '(locData.default)']);
                else
                    defaultPara.(field) = timeseries(single(locData.default));
                end
                count = count + numel(locData.default);
            else
                error(['Missing data on default value for variable ' field])
            end
        end
    end
end
end

function [defaultPara,count] = generateDefaultConstants(data,count)
fields = fieldnames(data);
for ii=1:numel(fields)
    field = fields{ii};
    locData = data.(field);
    locFields = fieldnames(locData);

    if isstruct(locData.(locFields{1}))
        [locResult,count] = generateDefaultParameters(locData,count);
        defaultPara.(field) = locResult;
    else
        if isfield(locData,'default') && ~isempty(locData.default)
            if isfield(locData,'type')
                defaultPara.(field) = eval([locData.type, '(locData.default)']);
            else
                defaultPara.(field) = single(locData.default);
            end
            count = count + numel(locData.default);
        else
            error(['Missing data on default value for variable ' field])
        end
    end
end
end

function generateBusObjects(data,name)
busName = [name, 'Bus'];
eval([busName '=Simulink.Bus;']);
assignin('base',busName,eval(busName))
recursiveBusDef(data,eval(busName),busName);
end

function recursiveBusDef(data,bus,name)
fields = fieldnames(data);
for ii=1:numel(fields)
    field = fields{ii};
    locData = data.(field);
    locFields = fieldnames(locData);

    if isstruct(locData.(locFields{1}))
        busName = [field,'Bus'];
        eval([busName '=Simulink.Bus;']);
        assignin('base',busName,eval(busName))

        newElement=Simulink.BusElement;
        eval(['newElement.DataType= '' Bus: ' busName ' '';'])
        newElement.Name=field;
        bus.Elements(end+1)=newElement;
        assignin('base',name,bus)

        recursiveBusDef(locData,eval(busName),busName);
    else
        bus.Elements(end+1) = generateBusElements(locData,field);
        assignin('base',name,bus)
    end
end
end

function busData = generateBusElements(data,name)
busData = Simulink.BusElement;
busData.Name = name;
if isfield(data,'default') && ~isempty(data.default)
    dim = size(data.default);
else
    error(['Missing default value for variable ' name])
end
if isfield(data,'description') && ~isempty(data.description)
    busData.Description = data.description;
else
    warning(['Missing description on variable ' name])
end
busData.Dimensions = dim;
busData.DimensionsMode = 'Fixed';
if isfield(data,'type')
    busData.DataType = data.type;
else
    busData.DataType = 'single';
end
busData.SampleTime = -1;
busData.Complexity = 'real';

if isfield(data,'unit') && ~isempty(data.unit)
    busData.Unit = data.unit;
end
if isfield(data,'max') && ~isempty(data.max)
    busData.Max = data.max;
end
if isfield(data,'min') && ~isempty(data.min)
    busData.Min = data.min;
end
end

function [str_params, str_connect]=writeParaDef(data, name, paraCount)
[str_params, str_connect]=recursiveWriter(data, {name}, '', sprintf('mParameters.reserve(%i);\n', paraCount));
end

function [str_params, str_connect]=recursiveWriter(data, path, str_params, str_connect)
fields = fieldnames(data);
for ii=1:numel(fields)
    field = fields{ii};
    locData = data.(field);
    locFields = fieldnames(locData);

    if isstruct(locData.(locFields{1}))
        locPath = path;
        locPath{end+1} = field;
        [str_params,str_connect]=recursiveWriter(locData,locPath,str_params,str_connect);
    else

        dim = size(locData.default);

        for jj = 1:dim(1)*dim(2)
            name = field;
            if isfield(locData,'description') && ~isempty(locData.description)
                description = locData.description;
            else
                description = '';
            end

            varName = ['IFR_', locData.name];

            str_params = [str_params, newline, '/**', newline, ' * ', description, newline, ' *', newline];

            str_params=[str_params, ' * @group ifr', newline];
            additionalInfoNames={'min', 'max', 'unit', 'decimal'};
            for k=1:numel(additionalInfoNames)
                if isfield(locData, additionalInfoNames{k}) && ~isempty(locData.(additionalInfoNames{k}))
                    str_params=[str_params, ' * @', additionalInfoNames{k}, ' ', num2str(locData.(additionalInfoNames{k})), newline];
                end
            end

            str_params = [str_params, ' */', newline];
            str_params = [str_params, 'PARAM_DEFINE_FLOAT(', varName, ', ', num2str(locData.default(jj)), 'f);', newline];

            structName = '';
            for kk = 1:length(path)
                structName = [structName,path{kk},'.'];
            end

            if numel(locData.default)==1
                str_connect = [str_connect, sprintf('mParameters.push_back(std::make_pair(param_find("%s"), &ifr_gnc_U.%s%s));\n',varName,structName, name)];
            else
                str_connect = [str_connect, sprintf('mParameters.push_back(std::make_pair(param_find("%s"), &ifr_gnc_U.%s%s[%i]));\n',varName,structName, name, jj-1)];
            end

        end

    end
end
end
