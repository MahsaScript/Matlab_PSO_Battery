function [LPSP,COE]=EMS(Npv,Nbat,Ndg) % Energy Management System

LPSP = 1/(0.5*Npv+0.3*Nbat+0.1*Ndg);
COE = 0.1*(0.3*Npv+0.2*Nbat+0.4*Ndg);

end