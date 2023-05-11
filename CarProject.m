


function CarProject()
    clear;
    clc;
   
    close all hidden;
    
    %mass
    mc      = 0.5;        % to be used for car
    mg      = 0.033;     % to be used for left and right gimbal
    md      = 0.112;      % to be used for left and right disk
    
    %geometry 
    w = 0.2;        %width of car
    h = 0.01;        %height of car
    l = 0.2;          %length of car
    r = 0.03;        %radius, disk and gimbal
    t = 0.06;        %height up the tower to cm of gimbals

    % Spin rate of disks
    prescribed = 1000;
    
    %Gravity
    g = 9.81;
    
    %Factor to turn off and on the disks
    fd1 = 1;
    fd2 = 0;
    
	T1 =  +0.1 * fd1;
    T2 =  -0.1 * fd2;
        %When to turn off motors (factor is between 0 and 1)
        %For example: to stop motor 3 at half time, factor3 = 0.5
    factor1 = 1;
    factor2 = 1;
    
	%TIME VARIABLES
    runtime = 0.2;
    dt = 0.0001;
    steps = runtime/dt;


    
%---------------------------------------------------------------------------
    % See document for mass moment of inertia matrix for a cuboid
    Jc1 = mc * (h^2 + w^2)/ 12;  
    Jc2 = mc * (h^2 + l^2)/ 12 ;  
    Jc3 = mc * (l^2 + w^2)/ 12 ;
  

    %Set the moment of inertia matrix for gimbal, hollow sphere
    Jg1 = 2 * mg * r^2  / 3;
    Jg2 = 2 * mg * r^2  / 3;
    Jg3 = 2 * mg * r^2  / 3;


    %Set the moment of inertia matrix for gyro which initially face in 3-direction
    Jd1 = md * (r * r) / 4;
    Jd2 = md * (r * r) / 4;
    Jd3 = md * (r * r) / 2;
    
    %Prescribed Gyro spin rates: this code is written so we have the disk
    %spinning ALL THE TIME (we can turn off the motors of precession, but
    %the disks spin)
    prescribedL =  -prescribed * fd1;  
    prescribedR = prescribed * fd2;  

    %crate the diagonal mass matrix
    mv = [mc mc mc Jc1 Jc2 Jc3 mg mg mg Jg1 Jg2 Jg3 mg mg mg Jg1 Jg2 Jg3 md md md Jd1 Jd2 Jd3 md md md Jd1 Jd2 Jd3];
    M = diag(mv);
  


  
    %Get to the CM of the first link: the car
    sc  = [l/2; 0; 0];
    %Get to the CM of the LEFT gimbal
    sLg = [0;  w/2; t];
    %Get to the CM of the RIGHT gimbal
    sRg = [0; -w/2; t];

    %crate the space for D and zero all elements
    %There is wasted space here and wasted initialization
    %Optimization will not have much of an impact, anyway.
    D = zeros(30, 30);
    
    %INITIAL Car rotation matrix and rotation matrix rate
    R1          = eye(3);
    R1d         = zeros(3,3); 
    
    %The spin rates are constant and the C is, too; so we can build this
    %now. THIS IS A MASSIVE WASTE OF MEMORY SPACE, BUT NOT THAT MUCH
    %TO WORRY ABOUT
    
    Cx = zeros(30, 2);
    e3 = [0; 0; 1];
    Cx(22:24, 1:1) = e3;
    Cx(28:30, 2:2) = e3;
    Cr = Cx * [prescribedL; prescribedR];
 

        
    %create a data structure to pass around named variables
    physics.g       = g;
    physics.sLg     = sLg;
    physics.sRg     = sRg;
    physics.sc      = sc;
    physics.M       = M;
    physics.R1      = R1;
    physics.R1d     = R1d;
    physics.Cr      = Cr;
    physics.pL      = prescribedL;
    physics.pR      = prescribedR;
    physics.mc      = mc;
    physics.mg      = mg;
    physics.md      = md;
    physics.Jc2     = Jc2;
    physics.dt      = dt;   



    %When to turn off motors (factor is between 0 and 1)
	%For example: to stop motor 3 at half time, factor3 = 0.5
    T1stop = runtime * factor1;
    T2stop = runtime * factor2;

    %create a data structure for all motor information
    motors.T1 = T1;
    motors.T2 = T2;
    motors.T1stop = T1stop;
    motors.T2stop = T2stop;
    
    %Initialize q and qd for the RK    
    qd	= [0;           0;          0;          0;          0];
    q	= [0;           0;          0;           -0/4;          0/4];

%--------------------------
    
    % For every time step, we will store some redundant information
    % We can always go back later and undo the redundancy. 
    % I prefer it so we can think about coding vs. math
    
    %These arrays are to extract data for plotting graphs and for webGL.
    %They are of no use in the RK (so you can skip them on the first pass).
    %They will be as long as the number of time steps.
    %The first one holds the time values (though, in theory, we do not need it).
    %WITH REGARD TO R: THERE ARE EASIER WAYS TO RECAPTURE THIS AFTER ALL IS
    %COMLPETED, BUT WE ARE GOING AFTER CLARITY, NOT PROCESS OR STORAGE OPTIMIZATION
        steps = int64(steps); %Got an error here that it wasnt an integer
        Tarray   = zeros(steps,1);
        R11      = zeros(steps,1);
        R12      = zeros(steps,1);
        R13      = zeros(steps,1);
        R21      = zeros(steps,1);
        R22      = zeros(steps,1);
        R23      = zeros(steps,1);
        R31      = zeros(steps,1);
        R32      = zeros(steps,1);
        R33      = zeros(steps,1);
        pitch   = zeros(steps,1); 
        yaw     = zeros(steps,1); 
        roll    = zeros(steps,1);
    
    % Thie following information is to SAVE data for current and previous time steps.
    % This is used in the algorithm, to acquire the data for the current
    % times step from the previous.
    % IT IS IMPORTANT TO NOTE THAT the FIRST THREE LINES OF QTIME ARE
    % MEANINGLESS SINCE WE DO NOT INTEGRATE OMEGA1 since that only integrates
    % the coordinate and NOT the direction.  WE MUST USE RODRIGUEZ
        index = 1; % index = 1 holds the initial conditions.
        Qtime = zeros(steps, 5);
        Qtime(index ,1)       =     q(1);  % car omega o1 integrated (USELESS)   
        Qtime(index ,2)       =     q(2);  % car omgea o2 integrated (USELESS)   
        Qtime(index ,3)       =     q(3);  % car omega o3 integrated (USELESS)   
        Qtime(index ,4)       =     q(4);  % car LeftGimball
        Qtime(index ,5)       =     q(5);  % car RightGimball
    
    %This second one holds the anglular rates (dots) for all time
    %The first three rows of Qd are NOT meaningless
        Qdtime = zeros(steps, 5);
        Qdtime(index ,1)      =     qd(1);  % car o1
        Qdtime(index ,2)      =     qd(2);  % car o1
        Qdtime(index ,3)      =     qd(3);  % car o1
        Qdtime(index ,4)       =    qd(4);  % car LeftGimball
        Qdtime(index ,5)       =    qd(5);  % car RightGimball

    
    % initialize the time
    t = 0;   
    
for i = 2:steps
 
    
        q(1)    = Qtime(i-1 ,1) ;  % no meaning
        q(2)    = Qtime(i-1 ,2) ;  % no meaning
        q(3)    = Qtime(i-1 ,3) ;  % no meaning
        q(4)    = Qtime(i-1 ,4) ;
        q(5)    = Qtime(i-1 ,5) ;
    
        qd(1)   = Qdtime(i-1 ,1) ;
        qd(2)   = Qdtime(i-1 ,2) ;
        qd(3)   = Qdtime(i-1 ,3) ;
        qd(4)   = Qdtime(i-1 ,4) ;
        qd(5)   = Qdtime(i-1 ,5) ;
    

        % In accordance with RK, we first predict...
        % Note that the prediction is ALWAYS and ONLY the value from the previous
        % time step.  Here we use "i minus 1" as im1
                qdim1 = qd;
                qim1  = q;  % remember: first three rows are meaningless
                Rim1  = physics.R1;
                Rim1d = physics.R1d;
            
              
% Warning: we might be inclined to insist that "Previous R1 and R1dot are in the
% physics structure. Well, read it carefully: to re-use the get_K function, we must reset
% the predictions to R and Rdot, so this is not the the time to modify the
% physics data structure, yet.
             
            k1 = dt * get_K(t,      Rim1, Rim1d, qim1, qdim1, physics, motors);
                qdp  = qdim1 + k1/2; 
                R1p  = Rim1*Rodriguez( qdp, dt/2);
                R1dp = R1p * skew(qdp(1), qdp(2), qdp(3));
                qp   = qim1 + qdp * dt/2;  
                
            k2 = dt * get_K(t + dt/2, R1p, R1dp, qp, qdp, physics, motors);           
                qdp  = qdim1 + k2/2;  
                R1p  = Rim1*Rodriguez(qdp, dt/2);
                R1dp = R1p * skew(qdp(1), qdp(2), qdp(3));
                qp   = qim1 +  qdp * dt/2;     
                
            k3 = dt * get_K(t + dt/2, R1p, R1dp, qp, qdp, physics, motors);
                qdp  = qdim1 + k3/2;  
                R1p  = Rim1*Rodriguez(qdp, dt/2);
                R1dp = R1p * skew(qdp(1), qdp(2), qdp(3));
                qp   = qim1 +  qdp * dt/2;     

            k4 = dt * get_K(t + dt,  R1p, R1dp, qp,qdp, physics, motors);
                qdp = qdim1 + (k1 + 2*k2 + 2*k3 + k4)/6;
                qp   = qim1 + qdp * dt;
        
            %Use Rodriguez to the the Rotation from the rates.
            R1   = Rim1*Rodriguez(qdp, dt);
            R1d  = R1 * skew(qdp(1), qdp(2), qdp(3));

            physics.R1 = R1;
            physics.R1d = R1d;
        
        %Store for current time
        Qtime(i ,1)       =     qp(1); %Useless
        Qtime(i ,2)       =     qp(2); %Useless
        Qtime(i ,3)       =     qp(3); %Useless
        Qtime(i ,4)       =     qp(4);
        Qtime(i ,5)       =     qp(5);
 
        %Store for current time
        Qdtime(i ,1)       =     qdp(1);
        Qdtime(i ,2)       =     qdp(2);
        Qdtime(i ,3)       =     qdp(3);
        Qdtime(i ,4)       =     qdp(4);
        Qdtime(i ,5)       =     qdp(5);
       
        %Store for plotting: we do NOT need omega1 for plotting
        %We need the rotation matrix
        Tarray(i)  	= t;
        R11(i)      = physics.R1(1,1);
        R12(i)      = physics.R1(1,2);
        R13(i)      = physics.R1(1,3);
        R21(i)      = physics.R1(2,1);
        R22(i)      = physics.R1(2,2);
        R23(i)      = physics.R1(2,3);
        R31(i)      = physics.R1(3,1);
        R32(i)      = physics.R1(3,2);
        R33(i)      = physics.R1(3,3); 
      
       % physics.R1
        pitch(i)   = acos(R11(i));
        roll(i)    = acos(R21(i));
        yaw(i)     = acos(R31(i));
   
        t = t + dt;
   
     

end


%------------ THIS WRITES THE FILES FOR THREE.js ----------

%---------------- GYRO ------------------
if fd1 == 1 && fd2 == 1
    fileID = fopen('R1_both.js','w');
    fprintf(fileID,'function R1_both(){\n');
elseif fd1 == 1 && fd2 == 0
    fileID = fopen('R1_M1.js','w');
    fprintf(fileID,'function R1_M1(){\n');
elseif fd1 == 0 && fd2 == 1
    fileID = fopen('R1_M2.js','w');
    fprintf(fileID,'function R1_M2(){\n');
elseif fd1 == 0 && fd2 == 0
    fileID = fopen('R1_M0.js','w');
    fprintf(fileID,'function R1_M0(){\n');
end

    fprintf(fileID,'var R1 = [\n');
    for i = 1:steps
    fprintf(fileID,'[%12.8f, %12.8f, %12.8f, %12.8f, %12.8f, %12.8f, %12.8f, %12.8f, %12.8f],\n',R11(i), R12(i), R13(i), R21(i),R22(i),R23(i),R31(i),R32(i),R33(i));
    end
    fprintf(fileID,'];\n');
    fprintf(fileID,'return R1;\n}\n');
    fclose(fileID);
    
    
%----------------- gimbal ------------------------

if fd1 == 1 && fd2 == 1
    fileID = fopen('gim_both.js','w');
    fprintf(fileID, 'function gim_both() {\n', 'w');
elseif fd1 == 1 && fd2 == 0
    fileID = fopen('gim_M1.js','w');
    fprintf(fileID, 'function gim_M1() {\n', 'w');
elseif fd1 == 0 && fd2 == 1
    fileID = fopen('gim_M2.js','w');
    fprintf(fileID, 'function gim_M2() {\n', 'w');
elseif fd1 == 0 && fd2 == 0
    fileID = fopen('gim_M0.js','w');
    fprintf(fileID, 'function gim_M0() {\n', 'w');
end

    fprintf(fileID,'var gimbal = [\n');

    for i = 1:steps
        fprintf(fileID, '[%12.8f, %12.8f],\n', Qtime(i,4), Qtime(i,5));
    end

    fprintf(fileID,'];\n');
    fprintf(fileID,'return gimbal;\n}\n');
    fclose(fileID);

%---------omega 2 (Pitch Angular Velocity) -----------    
    if fd1 == 1 && fd2 == 1
    fileID = fopen('o2_both.js','w');
    fprintf(fileID,'function o2_both(){\n');
    elseif fd1 == 1 && fd2 == 0
    fileID = fopen('o2_M1.js','w');
    fprintf(fileID,'function o2_M1(){\n');
    elseif fd1 == 0 && fd2 == 1
    fileID = fopen('o2_M2.js','w');
    fprintf(fileID,'function o2_M2(){\n');
    end

    fprintf(fileID,'var o2 = [\n');
    for i = 1:steps
    fprintf(fileID, '[%12.8f],\n',Qdtime(i,2));
    end

    fprintf(fileID,'];\n');
    fprintf(fileID,'return o2;\n}\n');
    fclose(fileID);
    %---------omega 3 (Yaw Angular Velocity) -----------    
    if fd1 == 1 && fd2 == 1
    fileID = fopen('o3_both.js','w');
    fprintf(fileID,'function o3_both(){\n');
    elseif fd1 == 1 && fd2 == 0
    fileID = fopen('o3_M1.js','w');
    fprintf(fileID,'function o3_M1(){\n');
    elseif fd1 == 0 && fd2 == 1
    fileID = fopen('o3_M2.js','w');
    fprintf(fileID,'function o3_M2(){\n');
    end
    fprintf(fileID,'var o3 = [\n');
    for i = 1:steps
    fprintf(fileID, '[%12.8f],\n',Qdtime(i,3));
    end
    fprintf(fileID,'];\n');
    fprintf(fileID,'return o3;\n}\n');
    fclose(fileID);
    
   







fileID = fopen('Gyrosensordata.txt', 'r');
formatSpec = '%f';
G = fscanf(fileID, formatSpec);
fclose(fileID);
Qdtime(:,2);

runtime_gyro = 2;
Tarray_gyro = linspace(0, runtime_gyro, length(G));
%G = G(470:530);



figure('Position',[100 100 800 400])
sgtitle('Pitch Angular Velocity','FontSize',20)
subplot(1,2,1);
plot(Tarray, Qdtime(:,2),'LineWidth',1.5);
title('Simulation','FontSize',14);
xlabel('Time [s]');
ylabel('Radians/second [rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax1 = gca; % Get the current axes for the first subplot
ax1.XAxis.FontSize = 14; % Set the font size of the x-axis label for the first subplot
ax1.YAxis.FontSize = 14; % Set the font size of the y-axis label for the first subplot
ax1.Title.FontSize = 14; % Set the font size of the title for the first subplot
subplot(1,2,2);
plot(Tarray_gyro(1:201), G(550:750),'LineWidth',1.5);
title('Gyro-sensor - Adafruit lsm9ds1','FontSize',14);
xlabel('Time [s]');
ylabel('Radians/second [rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax2 = gca; % Get the current axes for the second subplot
ax2.XAxis.FontSize = 14; % Set the font size of the x-axis label for the second subplot
ax2.YAxis.FontSize = 14; % Set the font size of the y-axis label for the second subplot
ax2.Title.FontSize = 14; % Set the font size of the title for the second subplot
set(gca,'xlim',[0 0.4])
set(gcf,'Color','w')


%This is for plotting different cases
if fd1 == 1 && fd2 == 1
    both_pitch = Qdtime(:,2);
    both_yaw = Qdtime(:,3);
    both_roll = Qdtime(:,1);
    save('case1p.mat', 'both_pitch');
    save('case1y.mat', 'both_yaw');
    save('case1r.mat', 'both_roll');
elseif fd1 == 1 && fd2 == 0
    motor1_pitch = Qdtime(:,2);
    motor1_yaw = Qdtime(:,3);
    motor1_roll = Qdtime(:,1);
    save('case2p.mat', 'motor1_pitch');
    save('case2y.mat', 'motor1_yaw');
    save('case2r.mat', 'motor1_roll');
elseif fd1 == 0 && fd2 == 1
    motor2_pitch = Qdtime(:,2);
    motor2_yaw = Qdtime(:,3);
    motor2_roll = Qdtime(:,1);
    save('case3p.mat', 'motor2_pitch');
    save('case3y.mat', 'motor2_yaw');
    save('case3r.mat', 'motor2_roll');
end


load('case1p.mat', 'both_pitch');
load('case1y.mat', 'both_yaw');
load('case1r.mat', 'both_roll');
load('case2p.mat', 'motor1_pitch');
load('case2y.mat', 'motor1_yaw');
load('case2r.mat', 'motor1_roll');
load('case3p.mat', 'motor2_pitch');
load('case3y.mat', 'motor2_yaw');
load('case3r.mat', 'motor2_roll');
% 
% %------------- CASE 1 --------------
% figure('Position',[100 100 800 400])
% sgtitle('Case 1:','FontSize',20)
% subplot(1,2,1);
% plot(Tarray, both_pitch,'LineWidth',1.5);
% title('Pitch','FontSize',14);
% xlabel('Time [s]');
% ylabel('Radians/second [rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax1 = gca; % Get the current axes for the first subplot
% ax1.XAxis.FontSize = 14; % Set the font size of the x-axis label for the first subplot
% ax1.YAxis.FontSize = 14; % Set the font size of the y-axis label for the first subplot
% ax1.Title.FontSize = 14; % Set the font size of the title for the first subplot
% ylim([min(both_pitch) max(both_pitch)]); % Set y-axis limits to be the same for both subplots
% subplot(1,2,2);
% plot(Tarray, both_yaw,'LineWidth',1.5);
% title('Yaw','FontSize',14);
% xlabel('Time [s]');
% ylabel('Radians/second [rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax2 = gca; % Get the current axes for the second subplot
% ax2.XAxis.FontSize = 14; % Set the font size of the x-axis label for the second subplot
% ax2.YAxis.FontSize = 14; % Set the font size of the y-axis label for the second subplot
% ax2.Title.FontSize = 14; % Set the font size of the title for the second subplot
% set(gca,'ylim',[-7 6])
% set(gcf,'Color','w')
% 
% 
% %--------------------- CASE 2 ----------------------
% figure('Position',[100 100 800 400])
% sgtitle('Case 2:','FontSize',20)
% subplot(1,2,1);
% plot(Tarray, motor1_pitch,'LineWidth',1.5);
% title('Pitch','FontSize',14);
% xlabel('Time [s]');
% ylabel('Radians/second [rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax1 = gca; % Get the current axes for the first subplot
% ax1.XAxis.FontSize = 14; % Set the font size of the x-axis label for the first subplot
% ax1.YAxis.FontSize = 14; % Set the font size of the y-axis label for the first subplot
% ax1.Title.FontSize = 14; % Set the font size of the title for the first subplot
% ylim([min(motor1_pitch) max(motor1_pitch)]); % Set y-axis limits to be the same for both subplots
% subplot(1,2,2);
% plot(Tarray, motor1_yaw,'LineWidth',1.5);
% title('Yaw','FontSize',14);
% xlabel('Time [s]');
% ylabel('Radians/second [rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax2 = gca; % Get the current axes for the second subplot
% ax2.XAxis.FontSize = 14; % Set the font size of the x-axis label for the second subplot
% ax2.YAxis.FontSize = 14; % Set the font size of the y-axis label for the second subplot
% ax2.Title.FontSize = 14; % Set the font size of the title for the second subplot
% 
% %------------------ CASE 3 ---------------------
% figure('Position',[100 100 800 400])
% sgtitle('Case 3:','FontSize',20)
% subplot(1,2,1);
% plot(Tarray, motor2_yaw,'LineWidth',1.5);
% title('Pitch','FontSize',14);
% xlabel('Time [s]');
% ylabel('Radians/second [rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax1 = gca; % Get the current axes for the first subplot
% ax1.XAxis.FontSize = 14; % Set the font size of the x-axis label for the first subplot
% ax1.YAxis.FontSize = 14; % Set the font size of the y-axis label for the first subplot
% ax1.Title.FontSize = 14; % Set the font size of the title for the first subplot
% ylim([min(Qdtime(:,2)) max(Qdtime(:,2))]); % Set y-axis limits to be the same for both subplots
% subplot(1,2,2);
% plot(Tarray, motor1_yaw,'LineWidth',1.5);
% title('Yaw','FontSize',14);
% xlabel('Time [s]');
% ylabel('Radians/second [rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax2 = gca; % Get the current axes for the second subplot
% ax2.XAxis.FontSize = 14; % Set the font size of the x-axis label for the second subplot
% ax2.YAxis.FontSize = 14; % Set the font size of the y-axis label for the second subplot
% ax2.Title.FontSize = 14; % Set the font size of the title for the second subplot
% set(gca,'ylim',[-7 6])
% set(gcf,'Color','w')
% 


% figure('Position',[100 100 800 400])
% sgtitle('Pitch & Yaw Angular Velocities','FontSize',15)
% subplot(3,2,1);
% plot(Tarray, both_pitch,'LineWidth',1.5);
% title('Case 1: Pitch','FontSize',14);
% xlabel('[s]');
% ylabel('[rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax1 = gca; % Get the current axes for the first subplot
% ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
% ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
% ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
% ylim([min(both_pitch) max(both_pitch)]); % Set y-axis limits to be the same for both subplots
% subplot(3,2,2);
% plot(Tarray, both_yaw,'LineWidth',1.5);
% title('Case 1: Yaw','FontSize',14);
% xlabel('[s]');
% ylabel('[rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax2 = gca; % Get the current axes for the second subplot
% ax2.XAxis.FontSize = 9; % Set the font size of the x-axis label for the second subplot
% ax2.YAxis.FontSize = 9; % Set the font size of the y-axis label for the second subplot
% ax2.Title.FontSize = 9; % Set the font size of the title for the second subplot
% set(gca,'ylim',[-7 6])
% set(gcf,'Color','w')
% 
% 
% subplot(3,2,3);
% plot(Tarray(1:length(motor1_pitch)), motor1_pitch,'LineWidth',1.5);
% title('Case 2: Pitch','FontSize',14);
% xlabel('[s]');
% ylabel('[rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax1 = gca; % Get the current axes for the first subplot
% ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
% ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
% ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
% ylim([min(motor1_pitch) max(motor1_pitch)]); % Set y-axis limits to be the same for both subplots
% 
% 
% subplot(3,2,4);
% plot(Tarray(1:length(motor1_pitch)), motor1_yaw,'LineWidth',1.5);
% title('Case 2: Yaw','FontSize',12);
% xlabel('[s]');
% ylabel('[rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax1 = gca; % Get the current axes for the first subplot
% ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
% ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
% ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
% ylim([min(motor1_yaw) max(motor1_yaw)]); % Set y-axis limits to be the same for both subplots
% 
% 
% subplot(3,2,5);
% plot(Tarray(1:length(motor1_pitch)), motor2_pitch,'LineWidth',1.5);
% title('Case 3: Pitch','FontSize',14);
% xlabel('[s]');
% ylabel('[rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax1 = gca; % Get the current axes for the first subplot
% ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
% ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
% ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
% ylim([min(motor2_pitch) max(motor2_pitch)]); % Set y-axis limits to be the same for both subplots
% 
% subplot(3,2,6);
% plot(Tarray(1:length(motor1_pitch)), motor2_yaw,'LineWidth',1.5);
% title('Case 3: Yaw','FontSize',14);
% xlabel('[s]');
% ylabel('[rad/s]');
% set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
% ax1 = gca; % Get the current axes for the first subplot
% ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
% ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
% ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
% ylim([min(motor2_yaw) max(motor2_yaw)]); % Set y-axis limits to be the same for both subplots
% 
% 




figure('Position',[100 100 1000 600])
sgtitle('Pitch, Yaw & Roll Angular Velocities','FontSize',15)
subplot(3,3,1);
plot(Tarray, both_pitch,'LineWidth',1.5);
title('Case 1: Pitch','FontSize',14);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax1 = gca; % Get the current axes for the first subplot
ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
ylim([min(both_pitch) max(both_pitch)]); % Set y-axis limits to be the same for both subplots
subplot(3,3,2);
plot(Tarray, both_yaw,'LineWidth',1.5);
title('Case 1: Yaw','FontSize',14);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax2 = gca; % Get the current axes for the second subplot
ax2.XAxis.FontSize = 9; % Set the font size of the x-axis label for the second subplot
ax2.YAxis.FontSize = 9; % Set the font size of the y-axis label for the second subplot
ax2.Title.FontSize = 9; % Set the font size of the title for the second subplot
set(gca,'ylim',[-7 6])
set(gcf,'Color','w')
subplot(3,3,3);
plot(Tarray, both_roll,'LineWidth',1.5);
title('Case 1: Roll','FontSize',14);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax2 = gca; % Get the current axes for the second subplot
ax2.XAxis.FontSize = 9; % Set the font size of the x-axis label for the second subplot
ax2.YAxis.FontSize = 9; % Set the font size of the y-axis label for the second subplot
ax2.Title.FontSize = 9; % Set the font size of the title for the second subplot
set(gca,'ylim',[-7 6])
set(gcf,'Color','w')



subplot(3,3,4);
plot(Tarray(1:length(motor1_pitch)), motor1_pitch,'LineWidth',1.5);
title('Case 2: Pitch','FontSize',14);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax1 = gca; % Get the current axes for the first subplot
ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
ylim([min(motor1_pitch) max(motor1_pitch)]); % Set y-axis limits to be the same for both subplots


subplot(3,3,5);
plot(Tarray(1:length(motor1_pitch)), motor1_yaw,'LineWidth',1.5);
title('Case 2: Yaw','FontSize',12);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax1 = gca; % Get the current axes for the first subplot
ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
ylim([min(motor1_yaw) max(motor1_yaw)]); % Set y-axis limits to be the same for both subplots

subplot(3,3,6);
plot(Tarray(1:length(motor1_roll)), motor1_roll,'LineWidth',1.5);
title('Case 2: Roll','FontSize',12);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax1 = gca; % Get the current axes for the first subplot
ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
ylim([min(motor1_roll) max(motor1_roll)]); % Set y-axis limits to be the same for both subplots



subplot(3,3,7);
plot(Tarray(1:length(motor1_pitch)), motor2_pitch,'LineWidth',1.5);
title('Case 3: Pitch','FontSize',14);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax1 = gca; % Get the current axes for the first subplot
ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
ylim([min(motor2_pitch) max(motor2_pitch)]); % Set y-axis limits to be the same for both subplots

subplot(3,3,8);
plot(Tarray(1:length(motor1_pitch)), motor2_yaw,'LineWidth',1.5);
title('Case 3: Yaw','FontSize',14);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax1 = gca; % Get the current axes for the first subplot
ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
ylim([min(motor2_yaw) max(motor2_yaw)]); % Set y-axis limits to be the same for both subplots

subplot(3,3,9);
plot(Tarray(1:length(motor1_pitch)), motor2_roll,'LineWidth',1.5);
title('Case 3: Roll','FontSize',14);
xlabel('[s]');
ylabel('[rad/s]');
set(gca,'FontSize',10,'TickLength',[0.02 0.02],'LineWidth',1)
ax1 = gca; % Get the current axes for the first subplot
ax1.XAxis.FontSize = 9; % Set the font size of the x-axis label for the first subplot
ax1.YAxis.FontSize = 9; % Set the font size of the y-axis label for the first subplot
ax1.Title.FontSize = 9; % Set the font size of the title for the first subplot
ylim([min(motor2_roll) max(motor2_roll)]); % Set y-axis limits to be the same for both subplots



end

function k  = get_K(t, R1, R1dot, qp, qdp, physics, motors)

        % One might be tempted to pull R1 from physics, but the R1 here is
        % a prediction, as are qd and qdp
        B   = get_B(t, R1, physics, qp);
        Bd  = get_Bd(t, R1, R1dot, physics, qp, qdp);
        F   = get_F(motors, physics, t, qp, R1, R1dot);
        D   = get_D(qp, qdp, physics, t);  % this returns D for this local function only
        M   = physics.M;
        Cr  = physics.Cr;
        
        MB = M * B;
        Ms = B' * MB;
        Ns = B' * (M * Bd + D * MB);
        Fs = B' * F;
        
        Constraint = B'*D*M*Cr;
       
        
        k = inv(Ms) * (Fs - Ns*qdp - Constraint);   
      
end

function  F   = get_F(motors, physics, t, q, R1, R1dot)

    T1 = motors.T1;
    T2 = motors.T2;

%     See if motors should be turned off -- this is rather simple and
%     cannot all for off, on, off, on
    if(t > motors.T1stop) 
            T1 = 0;
    end
    
    if(t > motors.T2stop) 
            T2 = 0;
    end

    if abs(q(4)) > pi/4 && abs(q(5)) > pi/4
        T1 = 0;
        T2 = 0;
    end
    




    mc = physics.mc;
    mg = physics.mg;
    md = physics.md;
    g  = physics.g;
    Jc2 = physics.Jc2;
    dt = physics.dt;
    
%     if asin(R1(2,1)) < 0.0 
%         N = mc*g;
%     end
    
%     if asin(R1dot(1,1)) < 0 && asin(R1(2,1)) < 0.0
%         M_ground = -Jc2 * asin(R1(1,1)) / dt;
%     
%     end
%     
    




    F = [
%--------Car
        %CAR force
        0;
        0;
        -mc*g;
        %----------------------
        %CAR torque
        -T1 - T2;  % The reverse motor from the two towers preceeding
        0;
        0;
 %--------Left Gimbal
        
        % Left Gimbal force
        0;
        0;
        -mg*g;
        %----------------------    
        % Left Gimbal torque from motor
        T1;
        0;
        0;

%-------- Right Gimbal
        % Right Gimbal force
        0;
        0;
        -mg*g;

        % Right Gimbal moment from motor
        T2;
        0;
        0;
%--------   Left Disk    
        % Left disk force
        0;
        0;
        -md*g;
        %----------------------    
        % Left disk torque from motor
        0;
        0;
        0;

  %--------Right disk      
        % Right Disk force
        0;
        0;
        -md*g;
        %----------------------
        % Right disk moment
        0;
        0;
        0;
        
        
    ];



end



function B  = get_B(time, R1, physics, qp)

% Remember: you cannot pull R1 out of physics.
% You are in this function for each k, and each k has a different R1

% But you CAN pull the angles out of the last two rows of qp and, from
% that, build the relative rotation matrices, since those are already
% predictions inside of qp

        e1 = [1; 0; 0];

        I = eye(3);
        sc      = physics.sc;
        sLg     = physics.sLg;
        sRg     = physics.sRg;

        %Warning: on the left, below, the value is the angle; on the right
        %it is the rate (hence the time multiplication)       
        pL = physics.pL * time;
        pR = physics.pR * time;

        R21 =  [1, 0, 0;   0, cos(qp(4)), -sin(qp(4));   0, sin(qp(4)), cos(qp(4))];
        R31 =  [1, 0, 0;   0, cos(qp(5)), -sin(qp(5));   0, sin(qp(5)), cos(qp(5))]; 
        
        R42 =  [cos(pL), -sin(pL), 0;   sin(pL), cos(pL), 0;   0 , 0, 1];
        R53 =  [cos(pR), -sin(pR), 0;   sin(pR), cos(pR), 0;   0 , 0, 1];

        s1SkewT     = (skewV(sc))';
        s2ps1       = (sc + sLg);
        s2ps1SkewT  = (skewV(s2ps1))';
        s3ps1       = (sc + sRg);
        s3ps1SkewT  = (skewV(s3ps1))';


        B = zeros(30,5);
        B(1:3,      1:3)        = R1 * s1SkewT;
        B(4:6,      1:3)        = I;
        B(7:9,      1:3)        = R1 * s2ps1SkewT;
        B(10:12,    1:3)        = R21';
        B(13:15,    1:3)        = R1 * s3ps1SkewT;
        B(16:18,    1:3)        = R31';
        B(19:21,    1:3)        = R1 * s2ps1SkewT;
        B(22:24,    1:3)        = R42' * R21';
        B(25:27,    1:3)        = R1 * s3ps1SkewT;
        B(28:30,    1:3)        = R53' * R31';
        B(10:12,    4)          = e1;
        B(16:18,    5)          = e1; 
        B(22:24,    4)          = R42' * e1;
        B(28:30,    5)          = R53' * e1;

end




function Bd  = get_Bd(time, R1, R1dot, physics, qp, qdp)

% Remember: you cannot pull R1 out of physics.
% You are in this function for each k, and each k has a different R1

% But you CAN pull the angles out of the last two rows of qp and, from
% that, build the relative rotation matrices, since those are already
% predictions inside of qp

        e1 = [1; 0; 0];


        Z = zeros(3,3);
        sc      = physics.sc;
        sLg     = physics.sLg;
        sRg     = physics.sRg;

        %Warning: on the left, below, the value is the angle; on the right
        %it is the rate (hence the time multiplication)
        pL = physics.pL * time;
        pR = physics.pR * time;

        R21 =  [1, 0, 0; 0, cos(qp(4)), -sin(qp(4)); 0, sin(qp(4)), cos(qp(4))];
        R31 =  [1, 0, 0; 0, cos(qp(5)), -sin(qp(5)); 0, sin(qp(5)), cos(qp(5))]; 
        R42 =  [cos(pL), -sin(pL), 0; sin(pL), cos(pL), 0; 0 , 0, 1];
        R53 =  [cos(pR), -sin(pR), 0; sin(pR), cos(pR), 0; 0 , 0, 1];

        R21d =  qdp(4) * [0, 0, 0; 0, -sin(qp(4)), -cos(qp(4)); 0, cos(qp(4)), -sin(qp(4))];
        R31d =  qdp(5) * [0, 0, 0; 0, -sin(qp(5)), -cos(qp(5)); 0, cos(qp(5)), -sin(qp(5))]; 
        R42d =  physics.pL * [-sin(pL), -cos(pL), 0; cos(pL), -sin(pL), 0; 0 , 0, 0];
        R53d =  physics.pR * [-sin(pR), -cos(pR), 0; cos(pR), -sin(pR), 0; 0 , 0, 0];
        
        s1SkewT     = (skewV(sc))';
        s2ps1       = (sc + sLg);
        s2ps1SkewT  = (skewV(s2ps1))';
        s3ps1       = (sc + sRg);
        s3ps1SkewT  = (skewV(s3ps1))';

%{
        B(1:3,      1:3)        = R1 * s1SkewT;
        B(4:6,      1:3)        = I;
        B(7:9,      1:3)        = R1 * s2ps1SkewT;
        B(10:12,    1:3)        = R21';
        B(13:15,    1:3)        = R1 * s3ps1SkewT;
        B(16:18,    1:3)        = R31';
        B(19:21,    1:3)        = R1 * s2ps1SkewT;
        B(22:24,    1:3)        = R42' * R21';
        B(25:27,    1:3)        = R1 * s3ps1SkewT;
        B(28:30,    1:3)        = R53' * R31';
        B(10:12,    4)          = e1;
        B(16:18,    4)          = e1; 
        B(22:24,    4)          = R42' * e1;
        B(28:30,    5)          = R53' * e1;       
        
%}
        
        
        Bd = zeros(30,5);
        Bd(1:3,      1:3)        = R1dot * s1SkewT;
        Bd(4:6,      1:3)        = Z;
        Bd(7:9,      1:3)        = R1dot * s2ps1SkewT;
        Bd(10:12,    1:3)        = R21d';
        Bd(13:15,    1:3)        = R1dot * s3ps1SkewT;
        Bd(16:18,    1:3)        = R31d';
        Bd(19:21,    1:3)        = R1dot * s2ps1SkewT;
        Bd(22:24,    1:3)        = R42d' * R21' + R42' * R21d';
        Bd(25:27,    1:3)        = R1dot * s3ps1SkewT;
        Bd(28:30,    1:3)        = R53d' * R31' + R53' * R31d';
        Bd(22:24,    4)          = R42d' * e1;
        Bd(28:30,    5)          = R53d' * e1;
      
        return

end


function w  = skew(a, b,c)
    w = [0, -c, b; c, 0, -a; -b, a, 0];
end

function w  = skewV(v)
    w = [0, -v(3), v(2); v(3), 0, -v(1); -v(2), v(1), 0];
end



function D  = get_D(qp, qdp, physics, time)
        e1 = [1;0;0];
        e3 = [0;0;1];

        %Warning: on the left, below, the value is the angle; on the right
        %it is the rate (hence the time multiplication)
        pL = physics.pL * time;
        pR = physics.pR * time;

        R21 =  [1, 0, 0; 0, cos(qp(4)), -sin(qp(4)); 0, sin(qp(4)), cos(qp(4))];
        R31 =  [1, 0, 0; 0, cos(qp(5)), -sin(qp(5)); 0, sin(qp(5)), cos(qp(5))]; 
        R42 =  [cos(pL), -sin(pL), 0; sin(pL), cos(pL), 0; 0 , 0, 1];
        R53 =  [cos(pR), -sin(pR), 0; sin(pR), cos(pR), 0; 0 , 0, 1];

    % Create and set local D to all zero): there is clock cycle loss in
    % reinitializing this, but I have no time to check now.
    D = zeros(30,30);
    
    % Car omega as a COLUMN
    wcarC = [qdp(1); qdp(2); qdp(3)];
    wcarS =skew(qdp(1), qdp(2), qdp(3));
    
    
    D(4:6,      4:6)        = wcarS;
    D(10:12,  10:12)        = skewV(R21' * wcarC + e1*qdp(4));
    D(16:18,  16:18)        = skewV(R31' * wcarC + e1*qdp(5));
    D(22:24,  22:24)        = skewV(R42'*R21'*wcarC + R42'*e1*qdp(4) + e3 * physics.pL);
    D(28:30,  28:30)        = skewV(R53'*R31'*wcarC + R53'*e1*qdp(5) + e3 * physics.pR);
 
end

function R = Rodriguez(qd, t)

    w = qd(1:3,1);  %pulls out first three rows

    normw0 = sqrt(w(1)^2 +w(2)^2 + w(3)^2);
    I = eye(3);
    w_0 = skew(w(1), w(2), w(3));
    R = eye(3);
    if(normw0 > 0.0000000001)
        R = I + (w_0)*sin(t*normw0)/normw0  + w_0 * w_0 * (1 / normw0)^2 * (1-cos(t*normw0));
    end
end



