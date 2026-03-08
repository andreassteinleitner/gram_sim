function servo = initServos()
scaling = 1.0;
servo.T = [0.06;0.06;0.06;0.06;0.06;0.06]; %ail,ele,rud,thr,nw,flp

twLim = 20;
flpLim = 90;
servo.pwmToAngle = scaling*pi/180*[11,13,21,twLim,flpLim];
servo.ailLim = servo.pwmToAngle(1)*[1,-1];
servo.eleLim = servo.pwmToAngle(2)*[1,-1];
servo.rudLim = servo.pwmToAngle(3)*[1,-1];
servo.deltLim = scaling*[1,-1];
servo.nwLim = servo.pwmToAngle(4)*[1,-1];
servo.flpLim = servo.pwmToAngle(5)*[1,0];
end