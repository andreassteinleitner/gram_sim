function aerodynamic = initAero(vehicle)
toExcel = 0;


if vehicle.type == 1 % TASL
    name = 'tasl';
    aerodynamic.chord = 0.306;
    aerodynamic.S = 1.415;
    aerodynamic.b = 4.658;
    Cm0 = -0.009;
    CnrDelta = 4;
    C_rud_mod = 1;
    alphaMax = 15;
    CLdeg    = 0.5;
    CDmod = 1.3;
    
elseif vehicle.type == 2 % MAJA
    name = 'maja';
    aerodynamic.chord = 0.245;
    aerodynamic.S = 0.468;
    aerodynamic.b = 2.41;
    Cm0 = 0.025;
    CnrDelta = 4;
    C_rud_mod = 1;
    alphaMax = 15;
    CLdeg    = 0.5;
    CDmod = 1;

elseif vehicle.type == 3 % FUNCUB XL
    name = 'funcubXL_flaps_mod';
    aerodynamic.chord = 0.26; %MAC=0.235
    aerodynamic.S = 0.4165; %assuming trapezoidal
    aerodynamic.b = 1.7;
    % what are those ?
     Cm0 = 0.025;
    CnrDelta = 4;
    C_rud_mod = 1;
    alphaMax = 10;
    CLdeg    = 0.5;
    CDmod = 1;
    
elseif vehicle.type == 4 % FUNCUB NG
    name ='funcubNG';
    aerodynamic.chord = 0.231;
    aerodynamic.S = 0.33;
    aerodynamic.b = 1.42;
    Cm0 = 0.025;
    CnrDelta = 4;
    C_rud_mod = 1;
    alphaMax = 15;
    CLdeg    = 0.5;
    CDmod = 1;
end

projectRoot = slproject.getCurrentProject().RootFolder;
fileList = {dir(fullfile(projectRoot,'Library','init',['TrimCalc/' name '/*.txt'])).name}';
fileList50 = {dir(fullfile(projectRoot,'Library','init',['TrimCalc/' name '/*.txt'])).name}';
fileList100 = {dir(fullfile(projectRoot,'Library','init',['TrimCalc/' name '/*.txt'])).name}';

%%%%%%%%% new %%%%%%%%%
if any(contains(fileList,'Flaps'))
    fileList = fileList(contains(fileList,'Flaps0'));
end

if any(contains(fileList50,'Flaps'))
    fileList50 = fileList50(contains(fileList50,'Flaps50'));
end

if any(contains(fileList100,'Flaps'))
    fileList100 = fileList100(contains(fileList100,'Flaps100'));
end

%%%%%%%%% new %%%%%%%%%

fun = @(s)~cellfun('isempty',strfind(fileList,s)); %finds string s in cell fileList
fun50 = @(s)~cellfun('isempty',strfind(fileList50,s)); %finds string s in cell fileList
fun100 = @(s)~cellfun('isempty',strfind(fileList100,s)); %finds string s in cell fileList

% Derivatives
% Elevator
derivativIdentifier={'VInf','CXq','CLq','Cmq','CYp','Clp','Cnp','CYr','Clr','Cnr','CXd','CZd','Cmd'};
derivativIdentifierMap={'VInf','CDq','CLq','Cmq','CYp','Clp','Cnp','CYr','Clr','Cnr','CDele','CLele','Cmele'};
eleFile = find(cell2mat(cellfun(fun,{'lev'},'Uni',0)));
eleFile50 = find(cell2mat(cellfun(fun50,{'lev'},'Uni',0)));
eleFile100 = find(cell2mat(cellfun(fun100,{'lev'},'Uni',0)));

indexEle = sortrows([cell2mat(cellfun(@(x)sscanf(x, '%f'), fileList(eleFile), 'uni', 0)),eleFile]);
indexEle = indexEle(:,2);

indexEle50 = sortrows([cell2mat(cellfun(@(x)sscanf(x, '%f'), fileList50(eleFile50), 'uni', 0)),eleFile50]);
indexEle50 = indexEle50(:,2);

indexEle100 = sortrows([cell2mat(cellfun(@(x)sscanf(x, '%f'), fileList100(eleFile100), 'uni', 0)),eleFile100]);
indexEle100 = indexEle100(:,2);
%arranges index such that the elevator angle is in ascending order

dataArray = zeros(length(indexEle),length(derivativIdentifier));
dataArray50 = zeros(length(indexEle50),length(derivativIdentifier));
dataArray100 = zeros(length(indexEle100),length(derivativIdentifier));

for ii = 1:length(indexEle)
    data = fileread(['TrimCalc/', name, '/', fileList{indexEle(ii)}]);
    %data = fileread(['TrimCalc/' fileList{ii}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        if  strcmp(derivativIdentifier{jj},'Cnr')
            dataArray(ii,jj)=str2num(res.value)*CnrDelta;
        else
            dataArray(ii,jj)=str2num(res.value);
        end
    end
end

for ii = 1:length(indexEle50)
    data = fileread(['TrimCalc/', name, '/', fileList50{indexEle50(ii)}]);
    %data = fileread(['TrimCalc/' fileList{ii}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        if  strcmp(derivativIdentifier{jj},'Cnr')
            dataArray50(ii,jj)=str2num(res.value)*CnrDelta;
        else
            dataArray50(ii,jj)=str2num(res.value);
        end
    end
end

for ii = 1:length(indexEle100)
    data = fileread(['TrimCalc/', name, '/', fileList100{indexEle100(ii)}]);
    %data = fileread(['TrimCalc/' fileList{ii}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        if  strcmp(derivativIdentifier{jj},'Cnr')
            dataArray100(ii,jj)=str2num(res.value)*CnrDelta;
        else
            dataArray100(ii,jj)=str2num(res.value);
        end
    end
end

for jj = 1:length(derivativIdentifier)
    
    d0 = size(dataArray, 1);
    d50 = size(dataArray50, 1);
    d100 = size(dataArray100, 1);
    maxLen = max([d0, d50, d100]);
    aerodynamic.derivatives.(derivativIdentifierMap{jj}) = zeros(maxLen, 3);
    arr(1:d0, 1) = dataArray(:,jj);
    arr(1:d50, 2) = dataArray50(:,jj);
    arr(1:d100, 3) = dataArray100(:,jj);
    aerodynamic.derivatives.(derivativIdentifierMap{jj})= arr;
    %aerodynamic.derivatives.(derivativIdentifierMap{jj})=[dataArray(:,jj), dataArray50(:,jj), dataArray100(:,jj)];
end
A = aerodynamic.derivatives.VInf;
%minVec = arrayfun(@(j) min(A(A(:,j) ~= 0, j)), 1:size(A,2));

aerodynamic.derivatives.vBounds = [arrayfun(@(j) min(A(A(:,j) ~= 0, j)), 1:size(A,2)); max(aerodynamic.derivatives.VInf)];
%aerodynamic.derivatives.vBounds = [min(aerodynamic.derivatives.VInf),max(aerodynamic.derivatives.VInf)];
%(aerodynamic.derivatives.VInf > 0)

aerodynamic.derivatives.valid_elements = sum(A~=0,1);

% Rudder

derivativIdentifier={'CYd','Cld','Cnd'};
derivativIdentifierMap={'CYrud','Clrud','Cnrud'};
%data = fileread(['TrimCalc/0deg_Rudder.txt']);
out = cell2mat(cellfun(fun,{'0','udder'},'Uni',0));
out50 = cell2mat(cellfun(fun50,{'0','udder'},'Uni',0));
out100 = cell2mat(cellfun(fun100,{'0','udder'},'Uni',0));

indexRud = find(all(out,2));
indexRud50 = find(all(out50,2));
indexRud100 = find(all(out100,2));
%aerodynamic.derivatives.(derivativIdentifierMap{jj}) = zeros(1, 3);

if(length(indexRud)==1)
    data = fileread(['TrimCalc/', name, '/', fileList{indexRud}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        
        ar2(1,1) = str2num(res.value)*C_rud_mod;
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1,1) = ar2(1,1);
        %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value)*C_rud_mod;
    end
end

if(length(indexRud50)==1)
    data = fileread(['TrimCalc/', name, '/', fileList50{indexRud50}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        ar2(1,2) = str2num(res.value)*C_rud_mod;
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1,2) = ar2(1, 2);
    end
end

if(length(indexRud100)==1)
    data = fileread(['TrimCalc/', name, '/', fileList100{indexRud100}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        ar2(1,3) = str2num(res.value)*C_rud_mod;
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1,3) = ar2(1, 3);
    end
end

% Aileron
derivativIdentifier={'CYd','Cld','Cnd'};
%data = fileread(['TrimCalc/0deg_Aileron.txt']);
out = cell2mat(cellfun(fun,{'0','ileron'},'Uni',0));
out50 = cell2mat(cellfun(fun50,{'0','ileron'},'Uni',0));
out100 = cell2mat(cellfun(fun100,{'0','ileron'},'Uni',0));

indexAil = find(all(out,2));
indexAil50 = find(all(out50,2));
indexAil100 = find(all(out100,2));

l0 = length(indexAil);
l50 = length(indexAil50);
l100 = length(indexAil100);

if(length(indexAil)==1)
    derivativIdentifierMap={'CYail','Clail','Cnail'};
    data = fileread(['TrimCalc/', name, '/', fileList{indexAil}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        ar3(1,1) = str2num(res.value);
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1,1) = ar3(1,1);
        %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
    end
elseif(length(indexAil)==2)
    out = cell2mat(cellfun(fun,{'0','ileron','In'},'Uni',0));
    indexAilIn = find(all(out,2));
    if ~isempty(indexAilIn)
        out = cell2mat(cellfun(fun,{'0','ileron','Out'},'Uni',0));
        indexAilOut = find(all(out,2));
        if ~isempty(indexAilOut)
            data = fileread(['TrimCalc/', name, '/', fileList{indexAilOut}]);
            derivativIdentifierMap={'CYailOut','ClailOut','CnailOut'};
        else
            disp('Error: Can''t find 0deg_aileronIn');
            return;
        end
        for jj = 1:length(derivativIdentifier)
            res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
            ar3(1:l0,1) = str2num(res.value);
            aerodynamic.derivatives.(derivativIdentifierMap{jj})(1:l0,1) = ar3(1:l0,1);
            %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
        end
        data = fileread(['TrimCalc/', name, '/', fileList{indexAilIn}]);
        derivativIdentifierMap={'CYailIn','ClailIn','CnailIn'};
    else %not Tasl Aero
        disp('Error: Can''t find 0deg_aileronIn');
        out = cell2mat(cellfun(fun,{'ileron','27'},'Uni',0)); %Egenius second aileron file
        notIndex = find(all(out,2));
        indexAil(find(indexAil==notIndex)) = [];
        data = fileread(['TrimCalc/', name, fileList{indexAil}]);
    end
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        ar3(1:l0,1) = str2num(res.value);
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1:l0,1) = ar3(1:l0,1);
        %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
    end
end

if(length(indexAil50)==1)
    derivativIdentifierMap={'CYail','Clail','Cnail'};
    data = fileread(['TrimCalc/', name, '/', fileList50{indexAil50}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        ar3(1,2) = str2num(res.value);
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1,2) = ar3(1, 2);
        %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
    end
elseif(length(indexAil50)==2)
    out50 = cell2mat(cellfun(fun50,{'0','ileron','In'},'Uni',0));
    indexAilIn = find(all(out50,2));
    if ~isempty(indexAilIn)
        out50 = cell2mat(cellfun(fun50,{'0','ileron','Out'},'Uni',0));
        indexAilOut = find(all(out50,2));
        if ~isempty(indexAilOut)
            data = fileread(['TrimCalc/', name, '/', fileList{indexAilOut}]);
            derivativIdentifierMap={'CYailOut','ClailOut','CnailOut'};
        else
            disp('Error: Can''t find 0deg_aileronIn');
            return;
        end
        for jj = 1:length(derivativIdentifier)
            res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
            ar3(1:l50,2) = str2num(res.value);
            aerodynamic.derivatives.(derivativIdentifierMap{jj})(1:l50,2) = ar3(1:l50,2);
            %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
        end
        data = fileread(['TrimCalc/', name, '/', fileList{indexAilIn}]);
        derivativIdentifierMap={'CYailIn','ClailIn','CnailIn'};
    else %not Tasl Aero
        disp('Error: Can''t find 0deg_aileronIn');
        out50 = cell2mat(cellfun(fun50,{'ileron','27'},'Uni',0)); %Egenius second aileron file
        notIndex = find(all(out50,2));
        indexAil50(find(indexAil50==notIndex)) = [];
        data = fileread(['TrimCalc/', name, fileList{indexAil50}]);
    end
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        ar3(1:l50,2) = str2num(res.value);
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1:l50,2) = ar3(1:l50,2);
        %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
    end
end

if(length(indexAil100)==1)
    derivativIdentifierMap={'CYail','Clail','Cnail'};
    data = fileread(['TrimCalc/', name, '/', fileList100{indexAil100}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        ar3(1,3) = str2num(res.value);
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1,3) = ar3(1, 3);
        %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
    end
elseif(length(indexAil100)==2)
    out100 = cell2mat(cellfun(fun100,{'0','ileron','In'},'Uni',0));
    indexAilIn = find(all(out100,2));
    if ~isempty(indexAilIn)
        out100 = cell2mat(cellfun(fun100,{'0','ileron','Out'},'Uni',0));
        indexAilOut = find(all(ou100t,2));
        if ~isempty(indexAilOut)
            data = fileread(['TrimCalc/', name, '/', fileList{indexAilOut}]);
            derivativIdentifierMap={'CYailOut','ClailOut','CnailOut'};
        else
            disp('Error: Can''t find 0deg_aileronIn');
            return;
        end
        for jj = 1:length(derivativIdentifier)
            res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
            ar3(1:l100,3) = str2num(res.value);
            aerodynamic.derivatives.(derivativIdentifierMap{jj})(1:l100,3) = ar3(1:l100,3);
            %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
        end
        data = fileread(['TrimCalc/', name, '/', fileList{indexAilIn}]);
        derivativIdentifierMap={'CYailIn','ClailIn','CnailIn'};
    else %not Tasl Aero
        disp('Error: Can''t find 0deg_aileronIn');
        out100 = cell2mat(cellfun(fun100,{'ileron','27'},'Uni',0)); %Egenius second aileron file
        notIndex = find(all(out100,2));
        indexAil100(find(indexAil100==notIndex)) = [];
        data = fileread(['TrimCalc/', name, fileList{indexAil100}]);
    end
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        ar3(1:l100,3) = str2num(res.value);
        aerodynamic.derivatives.(derivativIdentifierMap{jj})(1:l100,3) = ar3(1:l100,3);
        %aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
    end
end
%if ~isfield(aerodynamic.derivatives,'CYailIn') %not Tasl
%    aerodynamic.derivatives.CYailOut = 2*aerodynamic.derivatives.CYailOut/3;
%    aerodynamic.derivatives.ClailOut = 2*aerodynamic.derivatives.ClailOut/3;
%    aerodynamic.derivatives.CnailOut = 2*aerodynamic.derivatives.CnailOut/3;
%    aerodynamic.derivatives.CYailIn = aerodynamic.derivatives.CYailOut / 2;
%    aerodynamic.derivatives.ClailIn = aerodynamic.derivatives.ClailOut / 2;
%    aerodynamic.derivatives.CnailIn = aerodynamic.derivatives.CnailOut / 2;
%end

% Polar
folder_list = {dir(fullfile(projectRoot,'Library','init',['Polars/', name, '/*.txt'])).name}';
folder_list50 = {dir(fullfile(projectRoot,'Library','init',['Polars/', name, '/*.txt'])).name}';
folder_list100 = {dir(fullfile(projectRoot,'Library','init',['Polars/', name, '/*.txt'])).name}';
%%%%%%%%% new %%%%%%%%%
if any(contains(folder_list,'Flaps'))
    folder_list = folder_list(contains(folder_list,'Flaps0'));
end

if any(contains(folder_list50,'Flaps'))
    folder_list50 = folder_list50(contains(folder_list50,'Flaps50'));
end

if any(contains(folder_list100,'Flaps'))
    folder_list100 = folder_list100(contains(folder_list100,'Flaps100'));
end
%%%%%%%%% new %%%%%%%%%

betaVec = [];
vVec = [];
alphaVec = [];
flapVec = [];
HVec = [];

betaVec50 = [];
vVec50 = [];
alphaVec50 = [];
HVec50 = [];

betaVec100 = [];
vVec100 = [];
alphaVec100 = [];
HVec100 = [];

for ii = 1:length(folder_list)
    
    file     = folder_list{ii};
    data     = fileread(['Polars/', name, '/', file]);
    withBody = contains(data,'with Body');
    
    if contains(file,'gr_')
        H = file(length(file)-6:length(file)-4);
        inGE = 1;
    else
        inGE = 0;
    end
    
    %file    = folder_list{ii};
    %data    = fileread([mainFolderPolar, file]);
    res     = regexp(data,'Freestream speed\s*:\s*(?<value>-?\d*.\d*)','names');
    V       = str2num(res.value);
    vVec    = [vVec,V];
    
    fidi    = fopen(['Polars/', name, '/', file],'rt');
    D       = textscan(fidi, repmat('%f',1,13), 'Delimiter',' ', 'MultipleDelimsAsOne',true, 'HeaderLines',8, 'CollectOutput',true);
    fclose(fidi);
    
    res     = D{1};
    beta    = res(1,2);
    betaVec = [betaVec,beta];
    
    alpha   = res(:,1);
    alphaVec = [alphaVec,alpha'];
    
    if inGE
        if withBody
            poldataBodyGE.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        else
            poldataGE.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        end
        H=string(H(1))+"."+string(H(3));
        H=str2double(H);
        HVec=[HVec,H];
    else
        if withBody
            poldataBody.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        else
            poldata.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        end
    end
end

for ii = 1:length(folder_list50)
    
    file     = folder_list50{ii};
    data     = fileread(['Polars/', name, '/', file]);
    withBody = contains(data,'with Body');
    
    if contains(file,'gr_')
        H = file(length(file)-6:length(file)-4);
        inGE = 1;
    else
        inGE = 0;
    end
    
    %file    = folder_list{ii};
    %data    = fileread([mainFolderPolar, file]);
    res     = regexp(data,'Freestream speed\s*:\s*(?<value>-?\d*.\d*)','names');
    V       = str2num(res.value);
    vVec50    = [vVec50,V];
    
    fidi    = fopen(['Polars/', name, '/', file],'rt');
    D       = textscan(fidi, repmat('%f',1,13), 'Delimiter',' ', 'MultipleDelimsAsOne',true, 'HeaderLines',8, 'CollectOutput',true);
    fclose(fidi);
    
    res     = D{1};
    beta    = res(1,2);
    betaVec50 = [betaVec50,beta];
    
    alpha   = res(:,1);
    alphaVec50 = [alphaVec50,alpha'];
    
    if inGE
        if withBody
            poldataBodyGE50.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        else
            poldataGE50.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        end
        H=string(H(1))+"."+string(H(3));
        H=str2double(H);
        HVec50=[HVec50,H];
    else
        if withBody
            poldataBody50.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        else
            poldata50.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        end
    end
end

for ii = 1:length(folder_list100)
    
    file     = folder_list100{ii};
    data     = fileread(['Polars/', name, '/', file]);
    withBody = contains(data,'with Body');
    
    if contains(file,'gr_')
        H = file(length(file)-6:length(file)-4);
        inGE = 1;
    else
        inGE = 0;
    end
    
    %file    = folder_list{ii};
    %data    = fileread([mainFolderPolar, file]);
    res     = regexp(data,'Freestream speed\s*:\s*(?<value>-?\d*.\d*)','names');
    V       = str2num(res.value);
    vVec100    = [vVec100,V];
    
    fidi    = fopen(['Polars/', name, '/', file],'rt');
    D       = textscan(fidi, repmat('%f',1,13), 'Delimiter',' ', 'MultipleDelimsAsOne',true, 'HeaderLines',8, 'CollectOutput',true);
    fclose(fidi);
    
    res     = D{1};
    beta    = res(1,2);
    betaVec100 = [betaVec100,beta];
    
    alpha   = res(:,1);
    alphaVec100 = [alphaVec100,alpha'];
    
    if inGE
        if withBody
            poldataBodyGE100.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        else
            poldataGE100.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        end
        H=string(H(1))+"."+string(H(3));
        H=str2double(H);
        HVec100=[HVec100,H];
    else
        if withBody
            poldataBody100.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        else
            poldata100.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]) = res;
        end
    end
end

alphaVec = -8:2:24;
alphaVec50 = -8:2:24;
alphaVec100 = -8:2:24;
betaVec  = sort(unique(betaVec));
betaVec50  = sort(unique(betaVec50));
betaVec100  = sort(unique(betaVec100));
vVec     = sort(unique(vVec));
vVec50     = sort(unique(vVec50));
vVec100     = sort(unique(vVec100));
flapVec = [1,2,3];
HVec     = sort(unique(HVec));
HVec50     = sort(unique(HVec50));
HVec100     = sort(unique(HVec100));
HVecs=["0_5","1_0","1_5","2_5","7_5","100"];
HVecs50=["0_5","1_0","1_5","2_5","7_5","100"];
HVecs100=["0_5","1_0","1_5","2_5","7_5","100"];
dummy = zeros(length(alphaVec),length(betaVec),length(vVec),length(flapVec));
dummyGE = zeros(length(alphaVec),length(betaVec),length(vVec),length(HVec),length(flapVec));
aerodynamic.polar.flap = dummy;
aerodynamic.polar.alpha = dummy;
aerodynamic.polar.beta  = dummy;
aerodynamic.polar.V     = dummy;
aerodynamic.polar.CL    = dummy;
aerodynamic.polar.CD    = dummy;
aerodynamic.polar.CY    = dummy;
aerodynamic.polar.Cl    = dummy;
aerodynamic.polar.Cm    = dummy;
aerodynamic.polar.Cn    = dummy;
aerodynamic.polarGE.flap = dummyGE;
aerodynamic.polarGE.alpha = dummyGE;
aerodynamic.polarGE.beta  = dummyGE;
aerodynamic.polarGE.V     = dummyGE;
aerodynamic.polarGE.CL    = dummyGE;
aerodynamic.polarGE.CD    = dummyGE;
aerodynamic.polarGE.CY    = dummyGE;
aerodynamic.polarGE.Cl    = dummyGE;
aerodynamic.polarGE.Cm    = dummyGE;
aerodynamic.polarGE.Cn    = dummyGE;

for tt = 1:length(HVec)
    H = HVecs(tt);
    for jj = 1:length(betaVec)
        beta = betaVec(jj);
        for kk = 1:length(vVec)
            V = vVec(kk);
            if exist('poldataBodyGE','var')
                dataBodyGE = poldataBodyGE.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
                breakerBody = 0;
            else
                dataBodyGE = 0;
                breakerBody = 1;
            end
            if exist('poldataGE','var')
                dataGE = poldataGE.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
                breaker = 0;
            else
                dataBodyGE = 0;
                breaker = 1;
            end
            for ii = 1:length(alphaVec)
                alpha = alphaVec(ii);
                if sum(dataBodyGE(:,1)==alpha)==0 && ~breakerBody
                    dataBodyGE = [dataBodyGE;alpha,interp1(dataBodyGE(:,1),dataBodyGE(:,2:end),alpha,'linear','extrap')];
                end
                if sum(dataGE(:,1)==alpha)==0 && ~breaker
                    dataGE = [dataGE;alpha,interp1(dataGE(:,1),dataGE(:,2:end),alpha,'linear','extrap')];
                end
                indBody = dataBodyGE(:,1)==alpha;
                ind = dataGE(:,1)==alpha;
                
                if alpha > alphaMax
                    CLmod = 1-CLdeg*(alpha-alphaMax)/(max(alphaVec)-alphaMax);
                else
                    CLmod = 1;
                end
                
                if breakerBody
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,1)    = dataGE(ind,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,1)    = dataGE(ind,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,1)    = dataGE(ind,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,1)    = dataGE(ind,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,1)    = dataGE(ind,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,1)    = dataGE(ind,10);
                elseif breaker
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,1)    = dataBodyGE(indBody,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,1)    = dataBodyGE(indBody,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,1)    = dataBodyGE(indBody,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,1)    = dataBodyGE(indBody,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,1)    = dataBodyGE(indBody,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,1)    = dataBodyGE(indBody,10);
                else
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,1)    = dataBodyGE(indBody,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,1)    = dataGE(ind,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,1)    = dataBodyGE(indBody,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,1)    = dataBodyGE(indBody,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,1)    = dataBodyGE(indBody,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,1)    = dataBodyGE(indBody,10);
                end
            end
        end
    end
end

for tt = 1:length(HVec50)
    H = HVecs50(tt);
    for jj = 1:length(betaVec50)
        beta = betaVec50(jj);
        for kk = 1:length(vVec50)
            V = vVec50(kk);
            if exist('poldataBodyGE','var')
                dataBodyGE = poldataBodyGE50.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
                breakerBody = 0;
            else
                dataBodyGE = 0;
                breakerBody = 1;
            end
            if exist('poldataGE','var')
                dataGE = poldataGE50.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
                breaker = 0;
            else
                dataBodyGE = 0;
                breaker = 1;
            end
            for ii = 1:length(alphaVec50)
                alpha = alphaVec50(ii);
                if sum(dataBodyGE(:,1)==alpha)==0 && ~breakerBody
                    dataBodyGE = [dataBodyGE;alpha,interp1(dataBodyGE(:,1),dataBodyGE(:,2:end),alpha,'linear','extrap')];
                end
                if sum(dataGE(:,1)==alpha)==0 && ~breaker
                    dataGE = [dataGE;alpha,interp1(dataGE(:,1),dataGE(:,2:end),alpha,'linear','extrap')];
                end
                indBody = dataBodyGE(:,1)==alpha;
                ind = dataGE(:,1)==alpha;
                
                if alpha > alphaMax
                    CLmod = 1-CLdeg*(alpha-alphaMax)/(max(alphaVec50)-alphaMax);
                else
                    CLmod = 1;
                end
                
                if breakerBody
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,2)    = dataGE(ind,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,2)    = dataGE(ind,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,2)    = dataGE(ind,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,2)    = dataGE(ind,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,2)    = dataGE(ind,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,2)    = dataGE(ind,10);
                elseif breaker
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,2)    = dataBodyGE(indBody,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,2)    = dataBodyGE(indBody,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,2)    = dataBodyGE(indBody,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,2)    = dataBodyGE(indBody,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,2)    = dataBodyGE(indBody,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,2)    = dataBodyGE(indBody,10);
                else
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,2)    = dataBodyGE(indBody,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,2)    = dataGE(ind,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,2)    = dataBodyGE(indBody,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,2)    = dataBodyGE(indBody,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,2)    = dataBodyGE(indBody,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,2)    = dataBodyGE(indBody,10);
                end
            end
        end
    end
end

for tt = 1:length(HVec100)
    H = HVecs100(tt);
    for jj = 1:length(betaVec100)
        beta = betaVec100(jj);
        for kk = 1:length(vVec100)
            V = vVec100(kk);
            if exist('poldataBodyGE','var')
                dataBodyGE = poldataBodyGE100.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
                breakerBody = 0;
            else
                dataBodyGE = 0;
                breakerBody = 1;
            end
            if exist('poldataGE','var')
                dataGE = poldataGE100.(['H' num2str(H)]).(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
                breaker = 0;
            else
                dataBodyGE = 0;
                breaker = 1;
            end
            for ii = 1:length(alphaVec100)
                alpha = alphaVec100(ii);
                if sum(dataBodyGE(:,1)==alpha)==0 && ~breakerBody
                    dataBodyGE = [dataBodyGE;alpha,interp1(dataBodyGE(:,1),dataBodyGE(:,2:end),alpha,'linear','extrap')];
                end
                if sum(dataGE(:,1)==alpha)==0 && ~breaker
                    dataGE = [dataGE;alpha,interp1(dataGE(:,1),dataGE(:,2:end),alpha,'linear','extrap')];
                end
                indBody = dataBodyGE(:,1)==alpha;
                ind = dataGE(:,1)==alpha;
                
                if alpha > alphaMax
                    CLmod = 1-CLdeg*(alpha-alphaMax)/(max(alphaVec100)-alphaMax);
                else
                    CLmod = 1;
                end
                
                if breakerBody
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,3)    = dataGE(ind,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,3)    = dataGE(ind,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,3)    = dataGE(ind,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,3)    = dataGE(ind,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,3)    = dataGE(ind,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,3)    = dataGE(ind,10);
                elseif breaker
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,3)    = dataBodyGE(indBody,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,3)    = dataBodyGE(indBody,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,3)    = dataBodyGE(indBody,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,3)    = dataBodyGE(indBody,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,3)    = dataBodyGE(indBody,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,3)    = dataBodyGE(indBody,10);
                else
                    aerodynamic.polarGE.CL(ii,jj,kk,tt,3)    = dataBodyGE(indBody,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt,3)    = dataGE(ind,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt,3)    = dataBodyGE(indBody,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt,3)    = dataBodyGE(indBody,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt,3)    = dataBodyGE(indBody,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt,3)    = dataBodyGE(indBody,10);
                end
            end
        end
    end
end
a_GE_Bounds0 = pi/180*[min(alphaVec);max(alphaVec)];
a_GE_Bounds50 = pi/180*[min(alphaVec50);max(alphaVec50)];
a_GE_Bounds100 = pi/180*[min(alphaVec100);max(alphaVec100)];
aerodynamic.polarGE.alphaBounds = [a_GE_Bounds0 a_GE_Bounds50 a_GE_Bounds100];
b_GE_Bounds0 =  pi/180*[min(betaVec);max(betaVec)];
b_GE_Bounds50 =  pi/180*[min(betaVec50);max(betaVec50)];
b_GE_Bounds100 =  pi/180*[min(betaVec100);max(betaVec100)];
aerodynamic.polarGE.betaBounds = [b_GE_Bounds0 b_GE_Bounds50 b_GE_Bounds100];
v_GE_Bounds0 =  [min(vVec);max(vVec)];
v_GE_Bounds50 =  [min(vVec50);max(vVec50)];
v_GE_Bounds100 =  [min(vVec100);max(vVec100)];
aerodynamic.polarGE.vBounds = [v_GE_Bounds0 v_GE_Bounds50 v_GE_Bounds100];
[aerodynamic.polarGE.alpha,aerodynamic.polarGE.beta,aerodynamic.polarGE.V,aerodynamic.polarGE.H,aerodynamic.polarGE.flap] = ndgrid(pi/180*alphaVec,pi/180*betaVec,vVec,HVec,flapVec);

for jj = 1:length(betaVec)
    beta = betaVec(jj);
    for kk = 1:length(vVec)
        V = vVec(kk);
        if exist('poldataBody','var')
            dataBody = poldataBody.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
            breakerBody = 0;
        else
            dataBody = 0;
            breakerBody = 1;
        end
        if exist('poldata','var')
            data = poldata.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
            breaker = 0;
        else
            dataBody = 0;
            breaker = 1;
        end
        for ii = 1:length(alphaVec)
            alpha = alphaVec(ii);
            if sum(dataBody(:,1)==alpha)==0 && ~breakerBody
                dataBody = [dataBody;alpha,interp1(dataBody(:,1),dataBody(:,2:end),alpha,'linear','extrap')];
            end
            if sum(data(:,1)==alpha)==0 && ~breaker
                data = [data;alpha,interp1(data(:,1),data(:,2:end),alpha,'linear','extrap')];
            end
            indBody = dataBody(:,1)==alpha;
            ind = data(:,1)==alpha;
            
            if alpha > alphaMax
                CLmod = 1-CLdeg*(alpha-alphaMax)/(max(alphaVec)-alphaMax);
            else
                CLmod = 1;
            end
            if breakerBody
                aerodynamic.polar.CL(ii,jj,kk,1)    = data(ind,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,1)    = data(ind,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,1)    = data(ind,7);
                aerodynamic.polar.Cl(ii,jj,kk,1)    = data(ind,8);
                aerodynamic.polar.Cm(ii,jj,kk,1)    = data(ind,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,1)    = data(ind,10);
            elseif breaker
                aerodynamic.polar.CL(ii,jj,kk,1)    = dataBody(indBody,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,1)    = dataBody(indBody,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,1)    = dataBody(indBody,7);
                aerodynamic.polar.Cl(ii,jj,kk,1)    = dataBody(indBody,8);
                aerodynamic.polar.Cm(ii,jj,kk,1)    = dataBody(indBody,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,1)    = dataBody(indBody,10);
            else
                aerodynamic.polar.CL(ii,jj,kk,1)    = dataBody(indBody,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,1)    = data(ind,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,1)    = dataBody(indBody,7);
                aerodynamic.polar.Cl(ii,jj,kk,1)    = dataBody(indBody,8);
                aerodynamic.polar.Cm(ii,jj,kk,1)    = dataBody(indBody,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,1)    = dataBody(indBody,10);
            end
        end
    end
end

for jj = 1:length(betaVec50)
    beta = betaVec50(jj);
    for kk = 1:length(vVec50)
        V = vVec50(kk);
        if exist('poldataBody','var')
            dataBody = poldataBody50.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
            breakerBody = 0;
        else
            dataBody = 0;
            breakerBody = 1;
        end
        if exist('poldata','var')
            data = poldata50.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
            breaker = 0;
        else
            dataBody = 0;
            breaker = 1;
        end
        for ii = 1:length(alphaVec50)
            alpha = alphaVec50(ii);
            if sum(dataBody(:,1)==alpha)==0 && ~breakerBody
                dataBody = [dataBody;alpha,interp1(dataBody(:,1),dataBody(:,2:end),alpha,'linear','extrap')];
            end
            if sum(data(:,1)==alpha)==0 && ~breaker
                data = [data;alpha,interp1(data(:,1),data(:,2:end),alpha,'linear','extrap')];
            end
            indBody = dataBody(:,1)==alpha;
            ind = data(:,1)==alpha;
            
            if alpha > alphaMax
                CLmod = 1-CLdeg*(alpha-alphaMax)/(max(alphaVec50)-alphaMax);
            else
                CLmod = 1;
            end
            if breakerBody
                aerodynamic.polar.CL(ii,jj,kk,2)    = data(ind,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,2)    = data(ind,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,2)    = data(ind,7);
                aerodynamic.polar.Cl(ii,jj,kk,2)    = data(ind,8);
                aerodynamic.polar.Cm(ii,jj,kk,2)    = data(ind,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,2)    = data(ind,10);
            elseif breaker
                aerodynamic.polar.CL(ii,jj,kk,2)    = dataBody(indBody,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,2)    = dataBody(indBody,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,2)    = dataBody(indBody,7);
                aerodynamic.polar.Cl(ii,jj,kk,2)    = dataBody(indBody,8);
                aerodynamic.polar.Cm(ii,jj,kk,2)    = dataBody(indBody,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,2)    = dataBody(indBody,10);
            else
                aerodynamic.polar.CL(ii,jj,kk,2)    = dataBody(indBody,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,2)    = data(ind,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,2)    = dataBody(indBody,7);
                aerodynamic.polar.Cl(ii,jj,kk,2)    = dataBody(indBody,8);
                aerodynamic.polar.Cm(ii,jj,kk,2)    = dataBody(indBody,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,2)    = dataBody(indBody,10);
            end
        end
    end
end

for jj = 1:length(betaVec100)
    beta = betaVec100(jj);
    for kk = 1:length(vVec100)
        V = vVec100(kk);
        if exist('poldataBody','var')
            dataBody = poldataBody100.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
            breakerBody = 0;
        else
            dataBody = 0;
            breakerBody = 1;
        end
        if exist('poldata','var')
            data = poldata100.(['V' num2str(round(V))]).(['Beta' num2str(round(beta))]);
            breaker = 0;
        else
            dataBody = 0;
            breaker = 1;
        end
        for ii = 1:length(alphaVec100)
            alpha = alphaVec100(ii);
            if sum(dataBody(:,1)==alpha)==0 && ~breakerBody
                dataBody = [dataBody;alpha,interp1(dataBody(:,1),dataBody(:,2:end),alpha,'linear','extrap')];
            end
            if sum(data(:,1)==alpha)==0 && ~breaker
                data = [data;alpha,interp1(data(:,1),data(:,2:end),alpha,'linear','extrap')];
            end
            indBody = dataBody(:,1)==alpha;
            ind = data(:,1)==alpha;
            
            if alpha > alphaMax
                CLmod = 1-CLdeg*(alpha-alphaMax)/(max(alphaVec100)-alphaMax);
            else
                CLmod = 1;
            end
            if breakerBody
                aerodynamic.polar.CL(ii,jj,kk,3)    = data(ind,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,3)    = data(ind,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,3)    = data(ind,7);
                aerodynamic.polar.Cl(ii,jj,kk,3)    = data(ind,8);
                aerodynamic.polar.Cm(ii,jj,kk,3)    = data(ind,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,3)    = data(ind,10);
            elseif breaker
                aerodynamic.polar.CL(ii,jj,kk,3)    = dataBody(indBody,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,3)    = dataBody(indBody,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,3)    = dataBody(indBody,7);
                aerodynamic.polar.Cl(ii,jj,kk,3)    = dataBody(indBody,8);
                aerodynamic.polar.Cm(ii,jj,kk,3)    = dataBody(indBody,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,3)    = dataBody(indBody,10);
            else
                aerodynamic.polar.CL(ii,jj,kk,3)    = dataBody(indBody,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk,3)    = data(ind,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk,3)    = dataBody(indBody,7);
                aerodynamic.polar.Cl(ii,jj,kk,3)    = dataBody(indBody,8);
                aerodynamic.polar.Cm(ii,jj,kk,3)    = dataBody(indBody,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk,3)    = dataBody(indBody,10);
            end
        end
    end
end
aerodynamic.alpha0 = interp1(aerodynamic.polar.CL(:,1,1),aerodynamic.polar.alpha(:,1,1),0);
aBounds0 = pi/180*[min(alphaVec); max(alphaVec)];
aBounds50 = pi/180*[min(alphaVec50); max(alphaVec50)];
aBounds100 =pi/180*[min(alphaVec100); max(alphaVec100)];
aerodynamic.polar.alphaBounds = [aBounds0 aBounds50 aBounds100];
bBounds0 = pi/180*[min(betaVec);max(betaVec)];
bBounds50 = pi/180*[min(betaVec50);max(betaVec50)];
bBounds100 = pi/180*[min(betaVec100);max(betaVec100)];
aerodynamic.polar.betaBounds = [bBounds0 bBounds50 bBounds100];
vBounds0 = [min(vVec);max(vVec)];
vBounds50 = [min(vVec50);max(vVec50)];
vBounds100 = [min(vVec100);max(vVec100)];
aerodynamic.polar.vBounds = [vBounds0 vBounds50 vBounds100];
[aerodynamic.polar.alpha,aerodynamic.polar.beta,aerodynamic.polar.V,aerodynamic.polar.flap] = ndgrid(pi/180*alphaVec,pi/180*betaVec,vVec,flapVec);

if toExcel
    fields = fieldnames(aerodynamic.derivatives);
    aeroMat=zeros(length(fields),max(structfun(@length,aerodynamic.derivatives)));
    for i=1:length(fields)
        aeroMat(i,1:length(getfield(aerodynamic.derivatives,fields{i}))) = getfield(aerodynamic.derivatives,fields{i});
    end
    T = rows2vars(array2table(aeroMat','VariableNames',fields));
    writetable(T,'aero_derivatives_tasl.xlsx');
end
end