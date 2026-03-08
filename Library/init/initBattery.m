function battery = initBattery(vehicle)

switch vehicle.type
    case 1 % TASL
        s = 10;
        Ah = 15;
        battery.Vfull = s*4.2;
        battery.Vnom  = s*3.7;
        battery.Vempt = s*3.25;
        battery.Qfull = Ah*3600;
        battery.Qnom  = 0.95 * battery.Qfull;
        battery.Qempt = 0.2  * battery.Qnom;
        battery.B     = 3/battery.Qempt;
    case {2,3,4}% Maja, Funcub XL, Funcub NG    
        battery.Vfull = 16.8;
        battery.Vnom  = 14.8;
        battery.Vempt = 13.0;
        battery.Qfull = 13.2*3600;
        battery.Qnom  = 12.2*3600;
        battery.Qempt = battery.Qnom*0.2;
        battery.B     = 3/battery.Qempt;
        s=3.3;
end

syms K A
V0 = battery.Vfull-A;
[K,A]=solve([battery.Vnom;battery.Vempt]==[V0+K*(battery.Qfull-battery.Qnom)/battery.Qnom+A*exp(-battery.B*(battery.Qfull-battery.Qnom));...
    V0+K*(battery.Qfull-battery.Qempt)/battery.Qempt+A*exp(-battery.B*(battery.Qfull-battery.Qempt))],[K,A]);
battery.K = double(K);
battery.A = double(A);
battery.R     = 3*s*10^-3;


%% plot battery SOC vs voltage
%     V0 = battery.Vfull-A;
%     charge = linspace(battery.Qnom*0.02,battery.Qfull,100);
%     plot(charge/3600,V0+battery.K*(battery.Qfull-charge)./charge+battery.A*exp(-battery.B*(battery.Qfull-charge)))
%     hold on
%     plot(battery.Qfull*[1,1]/3600,[0,battery.Vfull],'k:')
%     plot(battery.Qnom*[1,1]/3600,[0,battery.Vnom],'k:')
%     plot(battery.Qempt*[1,1]/3600,[0,battery.Vempt],'k:')
%     hold off
%     set(gca, 'xdir','reverse')
%     xlabel('Q [Ah]')
%     ylabel('U [V]')