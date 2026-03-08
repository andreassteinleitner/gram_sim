function addPx4BusCreator(bus)
    msgFolder = fullfile(pwd, '..', 'common', 'msg');
    if ~exist(msgFolder, 'dir')
        error('Message folder not found.')
    end
    if isstring(bus)
        busName=bus;
    else
        busName=inputname(1);
    end
    
    busName_red = busName(1:end-4); % Cut "_bus" Postfix
    busDefinition=parseBus(msgFolder, busName_red);
    % ignore timestamp inside simulink
    busDefinition=busDefinition(~strcmp({busDefinition.name}, 'timestamp'));
    
    subsystemHandle=add_block('simulink/Commonly Used Blocks/Subsystem', [gcs, '/', inputname(1), '_creator'], 'MakeNameUnique', 'on');
    subsystemPath=getfullname(subsystemHandle);
    creatorHandle=add_block('simulink/Commonly Used Blocks/Bus Creator', [subsystemPath, '/Bus Creator']);
    busType=['Bus: ', busName];
    set_param(creatorHandle, 'OutDataTypeStr', busType, 'Inputs', num2str(numel(busDefinition)), 'InheritFromInputs', 'off');
    creatorPort=get_param(creatorHandle, 'PortHandles');
    
    delete_line(subsystemPath, 'In1/1', 'Out1/1')
    delete_block([subsystemPath, '/In1'])
    outportHandle=getSimulinkBlockHandle([subsystemPath, '/Out1']);
    set_param(outportHandle, 'OutDataTypeStr', busType, 'Name', busName);
    outportPort=get_param(outportHandle, 'PortHandles');
    for i=1:numel(busDefinition)
        signal=busDefinition(i);
        if strcmp(signal.name, 'is_valid')
            signalHandle=add_block('simulink/Commonly Used Blocks/Constant', [subsystemPath, '/', signal.name]);
            set_param(signalHandle, 'OutDataTypeStr', 'boolean', 'Value', 'true');
        elseif signal.isConstant
            signalHandle=add_block('simulink/Commonly Used Blocks/Constant', [subsystemPath, '/', signal.name]);
            set_param(signalHandle, 'OutDataTypeStr', signal.type, 'Value', num2str(signal.value));
        else
            signalHandle=add_block('simulink/Commonly Used Blocks/In1', [subsystemPath, '/', signal.name]);
            if contains(signal.type, 'int64')
                set_param(signalHandle, 'OutDataTypeStr', 'double', 'PortDimensions', num2str(signal.dimension));
            else
                set_param(signalHandle, 'OutDataTypeStr', signal.type, 'PortDimensions', num2str(signal.dimension));
            end
        end
        signalPort=get_param(signalHandle, 'PortHandles');
        add_line(subsystemPath, signalPort.Outport(1), creatorPort.Inport(i));
    end
    add_line(subsystemPath, creatorPort.Outport(1), outportPort.Inport(1));
end