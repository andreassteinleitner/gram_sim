function [pos,vel,att,errVar,sensors_valid]=estimateVehicleState(para,imu,opFlow,sonar,baro,mag,gps,geoRef,startFilter,navConsts)
persistent state covariance filterIsRunning timing
if isempty(state)
    state=[zeros(6, 1, 'single'); 1; zeros(3, 1, 'single')];
    covariance=diag(single([25, 25, 25, 4, 4, 4, 0.1, 0.1, 0.1]));
    filterIsRunning=false;
    timing=struct('sinceGps', para.gpsTimeout, 'sinceLosRate', para.losRateDistanceTimeout,...
        'sinceSonar', para.sonarTimeout, 'lastTime', imu.time-navConsts.stepSize);
end

stepSize=imu.time-timing.lastTime;
timing.lastTime=imu.time;

if gps.isValid
    if timing.sinceGps>=para.gpsTimeout && filterIsRunning
        [state, covariance]=resetUsingGps(para, state, covariance, gps);
        gps.isValid=false;
    end
    timing.sinceGps=single(0);
else
    timing.sinceGps=timing.sinceGps+stepSize;
end

if opFlow.isValid
    timing.sinceLosRate=single(0);
else
    timing.sinceLosRate=timing.sinceLosRate+stepSize;
end

if sonar.isValid
    timing.sinceSonar=single(0);
else
    timing.sinceSonar=timing.sinceSonar+stepSize;
end

if ~filterIsRunning
    if startFilter
        state(7:10)=initQuat(mag.magneticField, imu.acceleration);
        covariance(7:9, 7:9)=diag(single([0.1,0.1,0.1]));
        % next time GPS is available, horizontal position and velocity
        % shall be set to measurement rather than being updated
        [timing.sinceGps, timing.sinceLosRate, filterIsRunning]=deal(para.gpsTimeout, para.losRateDistanceTimeout, true);
    end
    [pos, vel, att, errVar]=deal(state(1:3), state(4:6), state(7:10), diag(covariance));
else
    if timing.sinceGps<para.gpsTimeout
        [pos, vel, att, errVar, state, covariance]=runFilter(para, state, covariance, 1:9,...
            imu, stepSize, mag, gps, baro, opFlow, sonar, geoRef);
    elseif timing.sinceLosRate<para.losRateDistanceTimeout && timing.sinceSonar<para.sonarTimeout
        [pos, vel, att, errVar, state, covariance]=runFilter(para, state, covariance, 3:9,...
            imu, stepSize, mag, gps, baro, opFlow, sonar, geoRef);
    else
        [pos, vel, att, errVar, state, covariance]=runFilter(para, state, covariance, [3, 6:9],...
            imu, stepSize, mag, gps, baro, opFlow, sonar, geoRef);
    end
end
sensors_valid = [mag.isValid;gps.isValid;baro.isValid;opFlow.isValid;sonar.isValid];
end

function [position, velocity, attitude, errorVariances, state, covariance]=runFilter(parameters, state, covariance, subStateIndices, imu, stepSize,...
    mag, gps, baro, opticalFlow, sonar, geodeticReference)
[state, covariance]=update(parameters, state, covariance, subStateIndices, mag, gps, baro, opticalFlow, sonar, imu.acceleration, geodeticReference.gravity, geodeticReference.earth_magnetic_field);
[position, velocity, attitude, errorVariances]=deal(state(1:3), state(4:6), state(7:10), diag(covariance));
[state, covariance]=predict(parameters, state, covariance, subStateIndices, imu, stepSize, geodeticReference.gravity);
end

function [state, covariance]=predict(parameters, state, covariance, iSub, imu, stepSize, g)
[v, q]=deal(state(4:6), state(7:10));

I=eye(3, 'single');
O=zeros(3, 'single');

bodyToGeo=quatToMat(q)';
stateIncrement=[stepSize*v+0.5*stepSize^2*(bodyToGeo*imu.acceleration+g);...
    stepSize*(bodyToGeo*imu.acceleration+g);...
    0.5*stepSize*[0, -imu.rate'; imu.rate, -skew(imu.rate)]*q];
F=[I, stepSize*I, -0.5*stepSize^2*bodyToGeo*skew(imu.acceleration);...
    O,          I,       -stepSize*bodyToGeo*skew(imu.acceleration);...
    O,          O,                        I-stepSize*skew(imu.rate)];
GQImuGT=[0.25*stepSize^4*parameters.sigmaAcc^2*I, 0.5*stepSize^3*parameters.sigmaAcc^2*I,                                         O;...
    0.5*stepSize^3*parameters.sigmaAcc^2*I,     stepSize^2*parameters.sigmaAcc^2*I,                                         O;...
    O,                                            O, stepSize^2*parameters.sigmaGyro^2*I];

covariance(iSub, iSub)=F(iSub, iSub)*covariance(iSub, iSub)*F(iSub, iSub)'+GQImuGT(iSub, iSub);
state([iSub, end])=state([iSub, end])+stateIncrement([iSub, end]);
state(7:10)=normalize(state(7:10));
end

function [state, covariance]=update(parameters, state, covariance, iSub, mag, gps, baro, opticalFlow, sonar, acc, g, magRef)
geoToBody=quatToMat(state(7:10));
bodyToGeo=geoToBody';
gibbsState=[state(1:6); zeros(3, 1, 'single')]; % expected attitude error (gibbs vector) is zero

if mag.isValid
    [residual, H, R]=magMeasurementModel(parameters, mag.magneticField, bodyToGeo, magRef);
    [gibbsState(iSub), covariance(iSub, iSub)]=performKalmanUpdate(gibbsState(iSub), covariance(iSub, iSub), residual, H(:, iSub), R);
end
if gps.isValid
    [residual, H, R]=gpsMeasurementModel(parameters, gps.position, gps.velocity, gibbsState(1:3), gibbsState(4:6));
    [gibbsState(iSub), covariance(iSub, iSub)]=performKalmanUpdate(gibbsState(iSub), covariance(iSub, iSub), residual, H(:, iSub), R);
elseif numel(iSub)<numel(gibbsState)-2 % only use acceleration update if neither GPS nor LOS rate are available
    [residual, H, R]=accMeasurementModel(parameters, acc, geoToBody, g);
    [gibbsState(iSub), covariance(iSub, iSub)]=performKalmanUpdate(gibbsState(iSub), covariance(iSub, iSub), residual, H(:, iSub), R);
    gibbsState(4:5)=0.995*gibbsState(4:5); % velocity estimate is likely to be far off, hence it is damped
end
if baro.isValid% && (sonar.distance>0.5 || sonar.distance==0) % ground effect renders baro useless below 0.5 meters above ground
    [residual, H, R]=baroMeasurementModel(parameters, baro.height, -gibbsState(3));
    [gibbsState(iSub), covariance(iSub, iSub)]=performKalmanUpdate(gibbsState(iSub), covariance(iSub, iSub), residual, H(:, iSub), R);
end
if opticalFlow.isValid && sonar.isValid && numel(iSub)<numel(gibbsState) % only use optical flow velocity update when gps is not available
    [residual, H, R]=losRateDistanceMeasurementModel(parameters, opticalFlow.losRate, sonar.distance, geoToBody, gibbsState(4:6));
    [gibbsState(iSub), covariance(iSub, iSub)]=performKalmanUpdate(gibbsState(iSub), covariance(iSub, iSub), residual, H(:, iSub), R);
end
state=[gibbsState(1:6); normalize(quaternionProduct(state(7:10), [2; gibbsState(7:9)]))];
end

function [residual, measurementMatrix, measurementCovariance]=magMeasurementModel(parameters, mag, bodyToGeo, magGeoRef)
magGeo=bodyToGeo*mag;
measurementMatrix=[zeros(1, 6, 'single'), bodyToGeo(3, :)];
normProduct=norm(magGeoRef(1:2))*norm(magGeo(1:2));
denominator=normProduct+magGeoRef(1:2)'*magGeo(1:2);
epsilon=single(1e-3);
sigmaMag=single(1e-4)*parameters.sigmaMag; % unit should be T but is Gs
if denominator>epsilon*normProduct
    residual=2*(magGeo(1)*magGeoRef(2)-magGeo(2)*magGeoRef(1))/denominator;
    measurementCovariance=(2*norm(magGeo(1:2))*sigmaMag/denominator)^2;
else % error is close to 180 deg, circumventing singularity...
    residual=2*sqrt(2/epsilon-1);
    measurementCovariance=(2*sigmaMag/(epsilon*norm(magGeoRef(1:2))))^2;
end
end

function [residual, measurementMatrix, measurementCovariance]=gpsMeasurementModel(parameters, gpsPos, gpsVel, pos, vel)
residual=[gpsPos-pos; gpsVel-vel];
measurementMatrix=[eye(6, 'single'), zeros(6, 3, 'single')];
measurementCovariance=diag([parameters.sigmaGpsPosXy([1; 1]); parameters.sigmaGpsPosZ;...
    parameters.sigmaGpsVelXy([1; 1]); parameters.sigmaGpsVelZ].^2);
end

function [residual, measurementMatrix, measurementCovariance]=baroMeasurementModel(parameters, baroHeight, height)
residual=baroHeight-height;
measurementMatrix=[zeros(1, 2, 'single'), -1, zeros(1, 6, 'single')];
measurementCovariance=parameters.sigmaBaro^2;
end

function [residual, measurementMatrix, measurementCovariance]=accMeasurementModel(parameters, acc, geoToBody, g)
residual=acc+geoToBody*g;
measurementMatrix=[zeros(3, 6, 'single'), -skew(geoToBody*g)];
measurementCovariance=parameters.sigmaAccelerationUpdate^2*eye(3, 'single');
end

function [residual, measurementMatrix, measurementCovariance]=losRateDistanceMeasurementModel(parameters, losRate, distance, geoToBody, velocity)
residual=losRate+1/distance*geoToBody(1:2, :)*velocity;
measurementMatrix=-1/distance*[zeros(2, 3, 'single'), geoToBody(1:2, :), [eye(2, 'single'), zeros(2, 1, 'single')]*skew(geoToBody*velocity)];
measurementCovariance=parameters.sigmaLosRate^2*eye(2, 'single');
end

function [state, covariance]=performKalmanUpdate(state, covariance, residual, H, R)
S=H*covariance*H'+R;
K=covariance*H'/S;
state=state+K*residual;
covariance=covariance-K*H*covariance;
end

function [state, covariance]=resetUsingGps(parameters, state, covariance, gps)
state(1:2)=gps.position(1:2);
covariance(1:2, 1:2)=parameters.sigmaGpsPosXy.^2*eye(2, 'single');
[covariance(1:2, 3:end), covariance(3:end, 1:2)]=deal(single(0));
state(4:6)=gps.velocity;
covariance(4:6, 4:6)=diag([parameters.sigmaGpsVelXy([1; 1]); parameters.sigmaGpsVelZ].^2);
[covariance(4:6, [1:3, 7:end]), covariance([1:3, 7:end], 4:6)]=deal(single(0));
end

function q=initQuat(magMeas, accMeas)
% geodetic axes in body frame using Gram-Schmidt process
basisZ=-normalize(accMeas);
basisX=normalize(magMeas-(magMeas'*basisZ)*basisZ);
q=matToQuat([basisX, cross(basisZ, basisX), basisZ]);
end

function n=normalize(v)
n=v./repmat(sqrt(sum(v.^2)), size(v, 1), 1);
end

function s=skew(v)
s=[     0, -v(3),  v(2);...
    v(3),     0, -v(1);...
    -v(2),  v(1),     0];
end

function prod=quaternionProduct(q, p)
[q0, qVec, p0, pVec]=deal(q(1), q(2:4), p(1), p(2:4));
prod=[q0*p0-qVec'*pVec; q0*pVec+p0*qVec+cross(qVec, pVec)];
end

function mat=quatToMat(quat)
[q0, q1, q2, q3]=deal(quat(1), quat(2), quat(3), quat(4));
mat=[1-2*(q2^2+q3^2), 2*(q1*q2+q3*q0), 2*(q1*q3-q2*q0); ...
    2*(q1*q2-q3*q0), 1-2*(q1^2+q3^2), 2*(q2*q3+q1*q0); ...
    2*(q1*q3+q2*q0), 2*(q2*q3-q1*q0), 1-2*(q1^2+q2^2)];
end

function quat=matToQuat(mat)
quat=zeros(4, 1, 'single');
tr=trace(mat);
if (tr>0)
    quat=[1+tr; mat(2, 3)-mat(3, 2); mat(3, 1)-mat(1, 3); mat(1, 2)-mat(2, 1)];
else
    [~, iMaxD]=max(diag(mat));
    switch iMaxD
        case 1, quat=[mat(2, 3)-mat(3, 2); 1+mat(1, 1)-mat(2, 2)-mat(3, 3); mat(1, 2)+mat(2, 1); mat(3, 1)+mat(1, 3)];
        case 2, quat=[mat(3, 1)-mat(1, 3); mat(1, 2)+mat(2, 1); 1-mat(1, 1)+mat(2, 2)-mat(3, 3); mat(2, 3)+mat(3, 2)];
        case 3, quat=[mat(1, 2)-mat(2, 1); mat(3, 1)+mat(1, 3); mat(2, 3)+mat(3, 2); 1-mat(1, 1)-mat(2, 2)+mat(3, 3)];
    end
end
quat=normalize(quat);
end