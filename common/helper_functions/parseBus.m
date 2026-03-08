function [bus, varargout]=parseBus(varargin)
    if nargin==1
        filename=varargin{:};
    elseif nargin==2
        messageFolder=varargin{1};
        busName=varargin{2};
        filename=findBusBase(messageFolder, busName);
    end
    messageDefinition=fileread(filename);
    typesAndNames=textscan(messageDefinition, '%s%s', 'commentStyle', '#');
    bus=struct('name', 'is_valid', 'type', 'boolean', 'dimension', 1, 'isConstant', false, 'value', nan);
    for i=1:numel(typesAndNames{1})
        if strcmp(typesAndNames{1}{i}, '=')
            bus(end).isConstant=true;
            bus(end).value=str2double(typesAndNames{2}{i});
        else
            dimension=str2double(extractBetween(typesAndNames{1}{i}, '[', ']'));
            if isempty(dimension)
                dimension=1;
            else
                typesAndNames{1}{i}=eraseBetween(typesAndNames{1}{i}, '[', ']', 'Boundaries', 'inclusive');
            end
            type=strrep(strrep(strrep(typesAndNames{1}{i}, 'float32', 'single'), 'float64', 'double'), 'bool', 'boolean');
            member=struct('name', typesAndNames{2}{i}, 'type', type, 'dimension', dimension, 'isConstant', false, 'value', nan);
            equalSignIndex=find(member.name=='=');
            if ~isempty(equalSignIndex)
                member.isConstant=true;
                member.value=str2double(member.name(equalSignIndex+1:end));
                member.name=member.name(1:equalSignIndex-1);
            end
            bus=[bus; member];
        end
    end
    if nargout>1
        aliases=obtainAliases(messageDefinition);
        baseName=filename(find(filename==filesep, 1, 'last')+1:end-4);
          
        % base name must always be the first alias
        baseNamePosition=find(strcmp(aliases, baseName));
        if isempty(baseNamePosition) % base name is not yet an alias => add
            aliases=[baseName, aliases];
        elseif baseNamePosition~=1 % base name is not the first alias => move
            aliases=[baseName, aliases(1:baseNamePosition-1), aliases(baseNamePosition+1:end)];
        end
        
        % append "_bus" to avoid duplicate global variable names in PX4 Firmware during Compilation
        for j=1:numel(aliases)
            aliases{j} = strcat(aliases{j},'_bus');
        end
        
        % Output
        varargout{1}=aliases;
    end
end

function aliases=obtainAliases(text)
    lines=splitlines(text);
    aliases={};
    for l=1:numel(lines)
        i=strfind(lines{l}, '# TOPICS ');
        if ~isempty(i)
            aliases=[aliases, strsplit(lines{l}(i+9:end), ' ')];
        end
    end
end

function filename=findBusBase(messageFolder, busName)
    filename=fullfile(messageFolder, [busName, '.msg']);
    if ~isfile(filename) % bus name is an alias, we must find its origin
        messageList=dir(fullfile(messageFolder, '*.msg'));
        for thisMessage=messageList'
            filename=fullfile(messageFolder, thisMessage.name);
            aliases=obtainAliases(fileread(filename));
            if any(strcmp(aliases, busName))
                return
            end
        end
        error(['Definition of bus ', busName, ' could not be found!'])
    end
end