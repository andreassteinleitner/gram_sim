function aerodynamic = initAero_old(vehicle)
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
    name = 'funcubXL_flaps';
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
%%%%%%%%% new %%%%%%%%%
if any(contains(fileList,'Flaps'))
    fileList = fileList(contains(fileList,'Flaps0'));
end
%%%%%%%%% new %%%%%%%%%

fun = @(s)~cellfun('isempty',strfind(fileList,s)); %finds string s in cell fileList

% Derivatives
% Elevator
derivativIdentifier={'VInf','CXq','CLq','Cmq','CYp','Clp','Cnp','CYr','Clr','Cnr','CXd','CZd','Cmd'};
derivativIdentifierMap={'VInf','CDq','CLq','Cmq','CYp','Clp','Cnp','CYr','Clr','Cnr','CDele','CLele','Cmele'};
eleFile = find(cell2mat(cellfun(fun,{'lev'},'Uni',0)));
indexEle = sortrows([cell2mat(cellfun(@(x)sscanf(x, '%f'), fileList(eleFile), 'uni', 0)),eleFile]);
indexEle = indexEle(:,2);
%arranges index such that the elevator angle is in ascending order

dataArray = zeros(length(indexEle),length(derivativIdentifier));
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
for jj = 1:length(derivativIdentifier)
    aerodynamic.derivatives.(derivativIdentifierMap{jj})=dataArray(:,jj);
end
aerodynamic.derivatives.vBounds = [min(aerodynamic.derivatives.VInf),max(aerodynamic.derivatives.VInf)];

% Rudder

derivativIdentifier={'CYd','Cld','Cnd'};
derivativIdentifierMap={'CYrud','Clrud','Cnrud'};
%data = fileread(['TrimCalc/0deg_Rudder.txt']);
out = cell2mat(cellfun(fun,{'0','udder'},'Uni',0));
indexRud = find(all(out,2));
if(length(indexRud)==1)
    data = fileread(['TrimCalc/', name, '/', fileList{indexRud}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value)*C_rud_mod;
    end
end

% Aileron
derivativIdentifier={'CYd','Cld','Cnd'};
%data = fileread(['TrimCalc/0deg_Aileron.txt']);
out = cell2mat(cellfun(fun,{'0','ileron'},'Uni',0));
indexAil = find(all(out,2));
if(length(indexAil)==1)
    derivativIdentifierMap={'CYail','Clail','Cnail'};
    data = fileread(['TrimCalc/', name, '/', fileList{indexAil}]);
    for jj = 1:length(derivativIdentifier)
        res  = regexp(data,[derivativIdentifier{jj} '\s*=\s*(?<value>-?\d*.\d*)'],'names');
        aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
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
            aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
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
        aerodynamic.derivatives.(derivativIdentifierMap{jj})=str2num(res.value);
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
%%%%%%%%% new %%%%%%%%%
if any(contains(folder_list,'Flaps'))
    folder_list = folder_list(contains(folder_list,'Flaps0'));
end
%%%%%%%%% new %%%%%%%%%

betaVec = [];
vVec = [];
alphaVec = [];
HVec = [];

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

alphaVec = -8:2:24;
betaVec  = sort(unique(betaVec));
vVec     = sort(unique(vVec));
HVec     = sort(unique(HVec));
HVecs=["0_5","1_0","1_5","2_5","7_5","100"];
dummy = zeros(length(alphaVec),length(betaVec),length(vVec));
dummyGE = zeros(length(alphaVec),length(betaVec),length(vVec),length(HVec));
aerodynamic.polar.alpha = dummy;
aerodynamic.polar.beta  = dummy;
aerodynamic.polar.V     = dummy;
aerodynamic.polar.CL    = dummy;
aerodynamic.polar.CD    = dummy;
aerodynamic.polar.CY    = dummy;
aerodynamic.polar.Cl    = dummy;
aerodynamic.polar.Cm    = dummy;
aerodynamic.polar.Cn    = dummy;
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
                    aerodynamic.polarGE.CL(ii,jj,kk,tt)    = dataGE(ind,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt)    = dataGE(ind,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt)    = dataGE(ind,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt)    = dataGE(ind,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt)    = dataGE(ind,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt)    = dataGE(ind,10);
                elseif breaker
                    aerodynamic.polarGE.CL(ii,jj,kk,tt)    = dataBodyGE(indBody,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt)    = dataBodyGE(indBody,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt)    = dataBodyGE(indBody,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt)    = dataBodyGE(indBody,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt)    = dataBodyGE(indBody,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt)    = dataBodyGE(indBody,10);
                else
                    aerodynamic.polarGE.CL(ii,jj,kk,tt)    = dataBodyGE(indBody,3)*CLmod;
                    aerodynamic.polarGE.CD(ii,jj,kk,tt)    = dataGE(ind,6)*CDmod;
                    aerodynamic.polarGE.CY(ii,jj,kk,tt)    = dataBodyGE(indBody,7);
                    aerodynamic.polarGE.Cl(ii,jj,kk,tt)    = dataBodyGE(indBody,8);
                    aerodynamic.polarGE.Cm(ii,jj,kk,tt)    = dataBodyGE(indBody,9)+Cm0;
                    aerodynamic.polarGE.Cn(ii,jj,kk,tt)    = dataBodyGE(indBody,10);
                end
            end
        end
    end
end
aerodynamic.polarGE.alphaBounds = pi/180*[min(alphaVec),max(alphaVec)];
aerodynamic.polarGE.betaBounds = pi/180*[min(betaVec),max(betaVec)];
aerodynamic.polarGE.vBounds = [min(vVec),max(vVec)];
[aerodynamic.polarGE.alpha,aerodynamic.polarGE.beta,aerodynamic.polarGE.V,aerodynamic.polarGE.H] = ndgrid(pi/180*alphaVec,pi/180*betaVec,vVec,HVec);

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
                aerodynamic.polar.CL(ii,jj,kk)    = data(ind,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk)    = data(ind,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk)    = data(ind,7);
                aerodynamic.polar.Cl(ii,jj,kk)    = data(ind,8);
                aerodynamic.polar.Cm(ii,jj,kk)    = data(ind,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk)    = data(ind,10);
            elseif breaker
                aerodynamic.polar.CL(ii,jj,kk)    = dataBody(indBody,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk)    = dataBody(indBody,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk)    = dataBody(indBody,7);
                aerodynamic.polar.Cl(ii,jj,kk)    = dataBody(indBody,8);
                aerodynamic.polar.Cm(ii,jj,kk)    = dataBody(indBody,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk)    = dataBody(indBody,10);
            else
                aerodynamic.polar.CL(ii,jj,kk)    = dataBody(indBody,3)*CLmod;
                aerodynamic.polar.CD(ii,jj,kk)    = data(ind,6)*CDmod;
                aerodynamic.polar.CY(ii,jj,kk)    = dataBody(indBody,7);
                aerodynamic.polar.Cl(ii,jj,kk)    = dataBody(indBody,8);
                aerodynamic.polar.Cm(ii,jj,kk)    = dataBody(indBody,9)+Cm0;
                aerodynamic.polar.Cn(ii,jj,kk)    = dataBody(indBody,10);
            end
        end
    end
end

aerodynamic.alpha0 = interp1(aerodynamic.polar.CL(:,1,1),aerodynamic.polar.alpha(:,1,1),0);

aerodynamic.polar.alphaBounds = pi/180*[min(alphaVec),max(alphaVec)];
aerodynamic.polar.betaBounds = pi/180*[min(betaVec),max(betaVec)];
aerodynamic.polar.vBounds = [min(vVec),max(vVec)];
[aerodynamic.polar.alpha,aerodynamic.polar.beta,aerodynamic.polar.V] = ndgrid(pi/180*alphaVec,pi/180*betaVec,vVec);

%     plot(aerodynamic.polar.alpha(:,1,3)*180/pi,aerodynamic.polar.CL(:,1,3))

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