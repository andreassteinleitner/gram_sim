function generateCode_V3(moduleName,model_name,model_name_wrapper,wrapper_flag,stacksize,messageFolder,workDirmodelpath,moduleDir)
% generateCode: 
%   Opens a SIMULINK-model from the controllermodel-Submodul from
%   which simulink-codegen creates PX4 Firmware modules.
%
% Prerequisites: will be called by generateModule.m 
%
% Syntax:  generateCode_V3()
%
% Inputs:
%    moduleName = name of modul as in firmware/scr/modules
%    model_name = name of simulink model in module folder
%    model_name_wrapper = name of corresponding wrapper (simulink model)
%    wrapper_flag = 0 = wrapper does exist #TODO remove, check empty(model_name_wrapper) instead ?
%    stacksize = supposed stacksize of firmware module
%
% Other m-files required: parseBus, initParametersAndConstants,
%                         defineParameters, defineConstants
% Other C-Files: template_CMakeLists.txt, %%module_name_sc%%_main.cppp, 
%                simulink_interface_cloze.cpp, simulink_interface_cloze.h 
% Subfunctions: removeDuplicateLines, strrepIndent, camelCase
%               obtainBaseName, indent, publishingCode, copyingCode,             
% MAT-files required: none
%
% Modified for Use with PX4 Firmware v1.13.2
% Author: Niklas Pauli <niklas.pauli@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% January 2023; Last revision: 13.02.2023
%
% Modified by: Niklas Pauli niklas.pauli@ifr.uni-stuttgart.de>
% University of Stuttgart, Institute of Flight Mechanics and Control
% February 2020; Last revision: 19.02.2020
%
% Original author: unknown


    % open model
    disp('- Loading model')
    if ~wrapper_flag
        model=load_system(model_name_wrapper);
    else
        model=load_system(model_name);
    end
    stepSize=evalin('base', get_param(model, 'FixedStep'));
    
    % defining parameters and constants
    disp('- Defining parameters and constants')
    % [constants, defaultPara, parameterDefinition, parameterConnectionBody, numberOfParameters]=initParametersAndConstants(defineParameters(), defineConstants());
    % [constants, defaultPara, parameterDefinition, parameterConnectionBody]=initParametersAndConstants(defineParameters(), defineConstants());
    [constants, defaultPara, parameterDefinition, parameterConnectionBody, numberOfParameters]=initParametersAndConstants(defineParameters(), defineConstants(), model_name);
    assignin('base','constants',constants);
    
    % Getting Bus Names
    disp('- Getting bus names')
    %messageFolder=fullfile('..', '..', '..', 'msg');
    variables=evalin('base', 'whos');
    busNames={variables(strcmp({variables.class}, 'Simulink.Bus')).name};
    
    % prepare generation of simulink_interface header and source
    disp('- Preparations...')
    [includeTopicHeaders, preparePollingList, declareTopicMembers, initializeTopicMembers,...
        terminateTopicMembers, copyTopics, publishTopics]=deal([]);
    inportsHandle=find_system(model, 'searchDepth', 1, 'BlockType', 'Inport');   
    inportNames=strrep(get_param(inportsHandle, 'Name'), ' ', ''); % simulink coder removes white spaces in port names
    inportDataTypes=get_param(inportsHandle, 'OutDataTypeStr');
    toBeConnected=find(contains(inportDataTypes, 'Bus: ') & ~contains(inportDataTypes, 'parameterBus'));
    inportNames=inportNames(toBeConnected);
    inportDataTypes=erase(inportDataTypes(toBeConnected), 'Bus: ');
        
    if size(toBeConnected,1) > 1  
        if numel(inportDataTypes)~=numel(unique(inportDataTypes))
            error('Duplicate inport bus types not allowed!')
        end 
    end
    
    
    %inportNames=inportNames(toBeConnected);
    %inportDataTypes=erase(inportDataTypes(toBeConnected), 'Bus: ');
%     if size(toBeConnected,1)==1
%         inportNames=inportNames(1,1);
%         inportDataTypes=erase(inportDataTypes(1,1), 'Bus: ');
%     else
%         inportNames=inportNames(toBeConnected);
%         inportDataTypes=erase(inportDataTypes(toBeConnected), 'Bus: ');
%     end
    

    for i=1:numel(inportNames)
        if any(strcmp(busNames, inportNames{i}))
            error(['Name clash for inport ''', inportNames{i}, ''': Top-level model ports must not have same name as buses.'])
        end
        busName=inportDataTypes{i};
        if strcmp(busName(end-3:end), '_bus')
            busName_red = busName(1:end-4); % Cut "_bus" Postfix
        else
            busName_red = busName;
        end
        busName_import = regexprep(busName_red, '_\d+$', ''); % Cut "_%i" Postfix
        includeTopicHeaders=[includeTopicHeaders, '#include <uORB/topics/', busName_import, '.h>', newline];
        preparePollingList=[preparePollingList, 'mPollingList[', num2str(i), '].fd=', camelCase(['m_', busName_red]), ';', newline];
        memberName=camelCase(['m_', busName]);
        memberName_red = camelCase(['m_', busName_red]); % Cut "_bus" Postfix
        declareTopicMembers=[declareTopicMembers, 'int ', memberName_red, ';', newline];
        initializeTopicMembers=[initializeTopicMembers, memberName_red, '(orb_subscribe(ORB_ID(', busName_red, '))),', newline];
        if ~wrapper_flag
            copyTopics=[copyTopics, copyingCode(num2str(i), [model_name_wrapper, '_U.', inportNames{i}], messageFolder, busName_red, memberName_red)];
        else
           copyTopics=[copyTopics, copyingCode(num2str(i), [model_name, '_U.', inportNames{i}], messageFolder, busName_red, memberName_red)];
        end
        
        terminateTopicMembers=[terminateTopicMembers, 'orb_unsubscribe(', memberName_red, ');', newline];
    end

    outportsHandle=find_system(model, 'SearchDepth', 1, 'BlockType', 'Outport');
    outportNames=strrep(get_param(outportsHandle, 'Name'), ' ', ''); % simulink coder removes white spaces in port names
    %outportNames=get_param(outportsHandle, 'Name');
    outportDataTypes=get_param(outportsHandle, 'OutDataTypeStr');   
    toBeConnected=find(contains(outportDataTypes, 'Bus: '));
    %outportNames=strrep(outportNames(toBeConnected), ' ', ''); % simulink coder removes white spaces in port names
    %outportNames=outportNames(toBeConnected);
    %outportDataTypes=erase(outportDataTypes(toBeConnected), 'Bus: ');
%     if size(toBeConnected,1)==1
%         outportNames=outportNames(1,1);
%         outportDataTypes=erase(outportDataTypes(1,1), 'Bus: ');
%     else
%         outportNames=outportNames(toBeConnected);
%         outportDataTypes=erase(outportDataTypes(toBeConnected), 'Bus: ');
%     end
    if size(toBeConnected,1) > 1
        outportNames=outportNames(toBeConnected);
        outportDataTypes=erase(outportDataTypes(toBeConnected), 'Bus: ');
        if numel(outportDataTypes)~=numel(unique(outportDataTypes))
            error('Duplicate outport bus types not allowed!')
        end
    else
        outportDataTypes=erase(outportDataTypes, 'Bus: ');
        outportDataTypes = {outportDataTypes};
        outportNames = {outportNames};
    end
    
    for i=1:numel(outportNames)
        if any(strcmp(busNames, outportNames{i}))
            error(['Name clash for outport ''', outportNames{i}, ''': Top-level model ports must not have same name as buses.'])
        end
        busName=outportDataTypes{i};
        if strcmp(busName(end-3:end), '_bus')
            busName_red = busName(1:end-4); % Cut "_bus" Postfix
        else
            busName_red = busName;
        end
        includeTopicHeaders=[includeTopicHeaders, '#include <uORB/topics/', obtainBaseName(messageFolder, busName_red), '.h>', newline];
        memberName=camelCase(['m_', busName]);
        memberName_red = camelCase(['m_', busName_red]); % Cut "_bus" Postfix
        declareTopicMembers=[declareTopicMembers, obtainBaseName(messageFolder, busName_red), '_s ', memberName_red, 'Data;', newline, 'orb_advert_t ', memberName_red, ';', newline];
        initializeTopicMembers=[initializeTopicMembers, memberName_red, '(orb_advertise(ORB_ID(', busName_red, '), &', memberName_red, 'Data)),', newline];
        if ~wrapper_flag
            publishTopics=[publishTopics, publishingCode([model_name_wrapper, '_Y.', outportNames{i}], busName_red, parseBus(messageFolder, busName_red), memberName_red)];
        else
            publishTopics=[publishTopics, publishingCode([model_name, '_Y.', outportNames{i}], busName_red, parseBus(messageFolder, busName_red), memberName_red)];
        end
        
        terminateTopicMembers=[terminateTopicMembers, 'orb_unadvertise(', memberName_red, ');', newline];
    end
    includeTopicHeaders=removeDuplicateLines(includeTopicHeaders);
    
    % set name variables
    module_name_sc = toSnakeCase(moduleName);
    module_name_usc = upper(module_name_sc);
    module_name_ucc = toUpperCamelCase(moduleName);
    
    
    disp('- Generate simulink_interface header')
    % generate simulink_interface header
    sourceText=fileread('simulink_interface_cloze.h'); 
    sourceText=strrep(sourceText, '%%module_name_sc%%', module_name_sc);
    sourceText=strrep(sourceText, '%%module_name_usc%%', module_name_usc);
    sourceText=strrep(sourceText, '%%module_name_ucc%%', module_name_ucc);
    sourceText=strrep(sourceText, '/*number of inputs*/', num2str(numel(inportNames)));
    sourceText=strrep(sourceText, '/*number of parameters*/', num2str(numberOfParameters));
    sourceText=strrepIndent(sourceText, '// include topic headers', includeTopicHeaders);
    sourceText=strrepIndent(sourceText, '// declare topic members', declareTopicMembers);

    %headerFile=fopen([workDirmodelpath,module_name_sc '.h'], 'w');
    headerFile=fopen(fullfile(workDirmodelpath, [module_name_sc '.h']), 'w');
    fprintf(headerFile, '%s', sourceText);
    fclose(headerFile);
    copyfile(fullfile(workDirmodelpath, [module_name_sc '.h']), fullfile(moduleDir, [module_name_sc '.h']));
    
    % generate simulink_interface source
    disp('- Generate simulink_interface source')
    sourceText=fileread('simulink_interface_cloze.cpp');  
    if ~wrapper_flag
        sourceText=strrep(sourceText, '%%module_name_wo_ifr%%', model_name_wrapper);
    else
        sourceText=strrep(sourceText, '%%module_name_wo_ifr%%', model_name);
    end
    sourceText=strrep(sourceText, '%%stacksize%%', stacksize);
    sourceText=strrep(sourceText, '%%module_name_sc%%', module_name_sc);
    sourceText=strrep(sourceText, '%%module_name_usc%%', module_name_usc);
    sourceText=strrep(sourceText, '%%module_name_ucc%%', module_name_ucc);
    sourceText=strrep(sourceText, '/*number of inputs*/', num2str(numel(inportNames)));
    sourceText=strrep(sourceText, '/*step size*/', num2str(stepSize));
    sourceText=strrepIndent(sourceText, '// initialize topic members', initializeTopicMembers);
    sourceText=strrepIndent(sourceText, '// prepare polling list', preparePollingList);
    if ~wrapper_flag
        sourceText=strrepIndent(sourceText, '// connect parameters function body', strrep(parameterConnectionBody, '%%model_name%%', model_name_wrapper));
    else
        sourceText=strrepIndent(sourceText, '// connect parameters function body', strrep(parameterConnectionBody, '%%model_name%%', model_name));
    end
    
    sourceText=strrepIndent(sourceText, '// copy topics', copyTopics);
    sourceText=strrepIndent(sourceText, '// publish topics', publishTopics);
    sourceText=strrepIndent(sourceText, '// terminate topic members', terminateTopicMembers);

    %sourceFile=fopen([module_name_sc '.cpp'], 'w');
    sourceFile=fopen(fullfile(workDirmodelpath, [module_name_sc '.cpp']), 'w');
    fprintf(sourceFile, '%s', sourceText);
    fclose(sourceFile);
    copyfile(fullfile(workDirmodelpath, [module_name_sc '.cpp']), fullfile(moduleDir, [module_name_sc '.cpp']));
    
    % generate simulink_interface_params source
    disp('- Generate simulink_interface_params source')
    %sourceFile=fopen([module_name_sc '_params.c'], 'w');
    sourceFile=fopen(fullfile(workDirmodelpath, [module_name_sc '_params.c']), 'w');
    fprintf(sourceFile, '%s', parameterDefinition);
    fclose(sourceFile);
    copyfile(fullfile(workDirmodelpath, [module_name_sc '_params.c']), fullfile(moduleDir, [module_name_sc '_params.c']));

    % Real Time Workshop Build
    disp('- Real Time Workshop Build')
    rtwbuild(model);
    disp(' ')
    disp(' ')
    disp(' ')
    
    % Remove old "generatedCode" folder
    if exist(fullfile(moduleDir,'generatedCode'), 'dir')
        rmdir(fullfile(moduleDir,'generatedCode'), 's');
    end

    % Copying files from Code Generation
    disp('- Copying files from Code Generation')
    copyCodeGenFilesV3(fullfile(moduleDir,'generatedCode'),workDirmodelpath);
    
    % Updating CMakeLists.txt
    disp('Updating CMakeLists.txt')
    
    sourceText=fileread('template_CMakeLists.txt');
    generated_code_folder_relative = 'generatedCode';
    generated_code_folder = fullfile(moduleDir,generated_code_folder_relative);
    code_gen_files = dir(generated_code_folder);
    counter = 1;
    for j = 1:length(code_gen_files)
        f = code_gen_files(j);
        if f.isdir; continue; end
        fn = [generated_code_folder_relative, '/' f.name];
        if fn(end) == 'c'
            generatedSourceFiles{counter} = fn;
            counter = counter +1;
        end
    end

    generatedSourceFiles = sprintf('%s\n', generatedSourceFiles{:});
    sourceText=strrepIndent(sourceText, '# code generated source files', generatedSourceFiles);
    sourceText=strrep(sourceText, '%%module_name_sc%%', module_name_sc);
    sourceText=strrep(sourceText, '%%module_name_usc%%', module_name_usc);
    sourceText=strrep(sourceText, '%%module_name_ucc%%', module_name_ucc);
    %sourceFile=fopen(['CMakeLists.txt'], 'w');
    sourceFile=fopen(fullfile(workDirmodelpath, 'CMakeLists.txt'), 'w');
    %sourceFile=fopen([module_name_sc '.cpp'], 'w');
    fprintf(sourceFile, '%s', sourceText);
    fclose(sourceFile);
    copyfile(fullfile(workDirmodelpath, 'CMakeLists.txt'), fullfile(moduleDir, 'CMakeLists.txt'));
end

function newName=camelCase(nameWithUnderscores)
    isUnderscore=nameWithUnderscores=='_';
    isUnderscoreIndex=find(isUnderscore);
    nameWithUnderscores(isUnderscoreIndex+1)=upper(nameWithUnderscores(isUnderscoreIndex+1));
    newName=nameWithUnderscores(~isUnderscore);
    newName(1)=lower(newName(1));
end

function text=strrepIndent(text, pattern, substitute)
    if isempty(substitute)
        return
    end
    
    if (substitute(end)==newline)
        substitute=substitute(1:end-1);
    end
    indentEnd=strfind(text, pattern)-1;
    indentBegin=find(text(1:indentEnd)==newline, 1, 'last')+1;
    indentation=text(indentBegin:indentEnd);
    text=strrep(text, pattern, strrep(substitute, newline, [newline, indentation]));
end

function out=copyingCode(pollingListIndex, structName, messageFolder, busName, memberName)
    out=[newline, 'if (mPollingList[', pollingListIndex, '].revents & POLLIN) {', newline];
    out=[out, indent(1), structName, '.is_valid=true;', newline,...
              indent(1), obtainBaseName(messageFolder, busName), '_s data;', newline,...
              indent(1), 'orb_copy(ORB_ID(', busName, '), ', memberName, ', &data);', newline];
    busFields=parseBus(messageFolder, busName);
    
    % ignore timestamp inside simulink (except for vehicle_local_poosition and vehicle_local_position : changed for Aerobotics --> fake bus name
    %if (~strcmp(busName,'vehicle_gps_position') && ~strcmp(busName,'vehicle_local_position'))
    if (~strcmp(busName,'fake___bus___name') && ~strcmp(busName,'fake___bus___name2'))
        for j=2:numel(busFields) % start from 2 to discard artificially added is_valid field
            if ~strcmp(busFields(j).name, 'timestamp')
                if contains(busFields(j).type, '64')
                    if busFields(j).dimension==1
                        out=[out, indent(1), structName, '.', busFields(j).name, '=static_cast<double>(data.', busFields(j).name, ');', newline];
                    else
                        for k=0:busFields(j).dimension-1
                            out=[out, indent(1), structName, '.', busFields(j).name, '[', num2str(k), ']=static_cast<double>(data.', busFields(j).name, '[', num2str(k), ']);', newline];
                        end
                    end
                else
                    if busFields(j).dimension==1
                        out=[out, indent(1), structName, '.', busFields(j).name, '=data.', busFields(j).name, ';', newline];
                    else
                        for k=0:busFields(j).dimension-1
                            out=[out, indent(1), structName, '.', busFields(j).name, '[', num2str(k), ']=data.', busFields(j).name, '[', num2str(k), '];', newline];
                        end
                    end
                end
            end
        end
    else
        for j=2:numel(busFields) % start from 2 to discard artificially added is_valid field
            %if ~strcmp(busFields(j).name, 'timestamp')
                if contains(busFields(j).type, '64')
                    if busFields(j).dimension==1
                        out=[out, indent(1), structName, '.', busFields(j).name, '=static_cast<double>(data.', busFields(j).name, ');', newline];
                    else
                        for k=0:busFields(j).dimension-1
                            out=[out, indent(1), structName, '.', busFields(j).name, '[', num2str(k), ']=static_cast<double>(data.', busFields(j).name, '[', num2str(k), ']);', newline];
                        end
                    end
                else
                    if busFields(j).dimension==1
                        out=[out, indent(1), structName, '.', busFields(j).name, '=data.', busFields(j).name, ';', newline];
                    else
                        for k=0:busFields(j).dimension-1
                            out=[out, indent(1), structName, '.', busFields(j).name, '[', num2str(k), ']=data.', busFields(j).name, '[', num2str(k), '];', newline];
                        end
                    end
                end
            %end
        end
    end
    out=[out, '}', newline, 'else ', structName, '.is_valid=false;', newline];
end

function out=publishingCode(structName, busName, busFields, memberName)
    out=newline;
    for j=2:numel(busFields) % start from 2 to discard artificially added is_valid field
        if ~busFields(j).isConstant
            if strcmp(busFields(j).name, 'timestamp')
                out=[memberName, 'Data.timestamp=hrt_absolute_time();', newline];
            elseif contains(busFields(j).type, 'int64')
                if busFields(j).dimension==1
                    out=[out, memberName, 'Data.', busFields(j).name, '=static_cast<', busFields(j).type, '_t>(', structName, '.', busFields(j).name, ');', newline];
                else
                    for k=0:busFields(j).dimension-1
                        out=[out, memberName, 'Data.', busFields(j).name, '[', num2str(k), ']=static_cast<', busFields(j).type, '_t>(', structName, '.', busFields(j).name, '[', num2str(k), ')];', newline];
                    end
                end
            else
                if busFields(j).dimension==1
                    out=[out, memberName, 'Data.', busFields(j).name, '=', structName, '.', busFields(j).name, ';', newline];
                else
                    for k=0:busFields(j).dimension-1
                        out=[out, memberName, 'Data.', busFields(j).name, '[', num2str(k), ']=', structName, '.', busFields(j).name, '[', num2str(k), '];', newline];
                    end
                end
            end
        end
    end
    out=[out, 'orb_publish(ORB_ID(', busName, '), ', memberName, ', &', memberName, 'Data);', newline];
end

function space=indent(layer)
    space=repmat(' ', 1, 4*layer);
end

function base=obtainBaseName(messageFolder, busName)
    [~, aliases]=parseBus(messageFolder, busName);
    base=aliases{1};
    base = base(1:end-4); % Cut "_bus" Postfix
    base = regexprep(base, '_\d+$', ''); % Cut "_%i" Postfix
end

function withoutDuplicates=removeDuplicateLines(withDuplicates)
    if isempty(withDuplicates)
        withoutDuplicates = withDuplicates;
    else
        uniqueLines=unique(splitlines(withDuplicates));
        withoutDuplicates=sprintf('%s\n', uniqueLines{:});
    end
end
