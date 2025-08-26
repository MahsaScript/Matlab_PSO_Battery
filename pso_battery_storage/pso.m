clear;clc;close all;tic;
%  energy management system (EMS) 
% This algorithm is used to learn how to size a PV-Bat-DG 
% standalone system using particle swarm optimization.

%% PSO Setting

set.Nparticle=50;
set.Niteration=1000;
set.w=1.5;
set.c1=1;
set.c2=0.75;

set.weight_LPSP=60;         %LPSP Weightage  Loss of Power Supply Probability
set.weight_COE=1;           %COE Weightage   Cost of Electricity 
set.desired_LPSP=0.01;      %Desired LPSP
set.Normal_COE=10;          %Normalize COE

set.Npv_min=1;
set.Npv_max=1000;
set.Nbat_min=1;
set.Nbat_max=100;
set.Ndg_min=1;
set.Ndg_max=10;


%% Initiate Particle
particle.position=[];
particle.velocity=[];
particle.best_position=[];
particle.best_LPSP=[];
particle.best_COE=[];
particle.best_Mark=[];
particle=repmat(particle,1,set.Nparticle);

best_global.position=[];
best_global.LPSP=[];
best_global.COE=[];
best_global.Mark=[];
log_global=repmat(best_global,1,set.Niteration);


%% Initiate initial Condition
temp_InitiateP(:,1)=randi([set.Npv_min,set.Npv_max],set.Nparticle,1);
temp_InitiateP(:,2)=randi([set.Nbat_min,set.Nbat_max],set.Nparticle,1);
temp_InitiateP(:,3)=randi([set.Ndg_min,set.Ndg_max],set.Nparticle,1);

for n_par=1:set.Nparticle
    particle(n_par).position=temp_InitiateP(n_par,:);
    particle(n_par).velocity=[0 0 0];
end
clear n_par temp_InitiateP


%% Main PSO
for n_ite=1:set.Niteration
    for n_par=1:set.Nparticle
        %Npv,Nbat,Ndg
        [LPSP,COE]=EMS(particle(n_par).position(1),...  
            particle(n_par).position(2),...
            particle(n_par).position(3));
        %% Calculate Mark
        Mark=set.weight_LPSP*abs(LPSP-set.desired_LPSP)+...
            set.weight_COE*COE/set.Normal_COE;
        %% Best Particle
        if isempty(particle(n_par).best_Mark) || particle(n_par).best_Mark>Mark
            particle(n_par).best_position=particle(n_par).position;
            particle(n_par).best_LPSP=LPSP;
            particle(n_par).best_COE=COE;
            particle(n_par).best_Mark=Mark;
        end
        %% Best Global
        if (n_ite==1 && n_par==1) || best_global.Mark>Mark
            best_global.position=particle(n_par).position;
            best_global.LPSP=LPSP;
            best_global.COE=COE;
            best_global.Mark=Mark;
        end
        log_global(n_ite)=best_global;
        
        %% Velocity and New Position
        particle(n_par).velocity=set.w*particle(n_par).velocity...
            +set.c1*(particle(n_par).best_position-particle(n_par).position)...
            +set.c2*(best_global.position-particle(n_par).position);
        particle(n_par).position=particle(n_par).position...
            +particle(n_par).velocity;
        
        %% Round Position
        particle(n_par).position(1)=round(particle(n_par).position(1));
        particle(n_par).position(2)=round(particle(n_par).position(2));
        particle(n_par).position(3)=round(particle(n_par).position(3));
        
        %% Limit Position
        if particle(n_par).position(1)<set.Npv_min
            particle(n_par).position(1)=set.Npv_min;
        end
        if particle(n_par).position(2)<set.Nbat_min
            particle(n_par).position(2)=set.Nbat_min;
        end
        if particle(n_par).position(3)<set.Ndg_min
            particle(n_par).position(3)=set.Ndg_min;
        end
        if particle(n_par).position(1)>set.Npv_max
            particle(n_par).position(1)=set.Npv_max;
        end
        if particle(n_par).position(2)>set.Nbat_max
            particle(n_par).position(2)=set.Nbat_max;
        end
        if particle(n_par).position(3)>set.Ndg_max
            particle(n_par).position(3)=set.Ndg_max;
        end
    end
end
clear LPSP COE Mark n_ite n_par

%% Show Result
for n_ite=1:set.Niteration
    LPSP(n_ite)=log_global(n_ite).LPSP;
    COE(n_ite)=log_global(n_ite).COE;
end
subplot(2,1,1);
plot(LPSP);
grid on;
xlabel('n-th Iteration')
ylabel('Loss of Load Probability, LPSP');

subplot(2,1,2);
plot(COE);
grid on;
xlabel('n-th Iteration')
ylabel('Cost of Energy, COE ($)');

tpro=toc;
fprintf('The optimum system size is:\n   Npv=%d\n   Nbat=%d\n   Ndg=%d\nwith the LPSP = %.3f%% and COE = $%.2f\nCompute in %.2f s\n',...
    best_global.position,best_global.LPSP*100,best_global.COE,tpro);
beep;