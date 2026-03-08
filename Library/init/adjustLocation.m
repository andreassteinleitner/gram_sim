function vehicle = adjustLocation(vehicle,ldg_rnwy,afmaPara)
    gpa     = afmaPara.atol.GPA.Data*pi/180;
    l_final = afmaPara.rnwy.finalLength.Data;
    l_base  = afmaPara.rnwy.baseLength.Data;
    appr_angle = afmaPara.rnwy.patternAngle.Data*pi/180;
    hdg_ldg = ldg_rnwy(2)*pi/180;
    ldg_pos = ldg_rnwy(3:5);
    
    rotated_projection = [[cos(appr_angle) -sin(appr_angle);sin(appr_angle) cos(appr_angle)] * [cos(hdg_ldg);sin(hdg_ldg)];-tan(gpa)]';
    offset = (l_final*[cos(hdg_ldg),sin(hdg_ldg),-tan(gpa)] + 2*l_base * rotated_projection)./convert2cartesian(ldg_pos)';
    
    vehicle.pos0 = double((ldg_pos-offset).*[1e-7,1e-7,1e-3]);
    vehicle.ori0 = double([0,0,hdg_ldg+appr_angle]);
end

function llh2ned = convert2cartesian(refPos)
    semiMajorAxis=single(6378137);
    eccentricity=single(8.1819190842622e-2);
    posScaleFactor=single([1e-7*pi/180; 1e-7*pi/180; 1e-3]);
    R0=semiMajorAxis/sqrt(1-eccentricity^2*sin(posScaleFactor(1)*single(refPos(1)))^2);
    llh2ned = [(1-eccentricity^2)/semiMajorAxis^2*R0^3+posScaleFactor(3)*single(refPos(3)); (R0+posScaleFactor(3)*single(refPos(3)))*cos(posScaleFactor(1)*single(refPos(1))); -1].*posScaleFactor;
end