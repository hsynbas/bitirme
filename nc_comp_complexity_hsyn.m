clc; clear;


n             = 8;                    
R             = 4;                    
q             = 0.5;                  
lambda_E_vals = 0.1:0.1:0.9;          
num_trials    = 1000;                 
Ccomp         = 1e6;                  % İşlemci hızı
l             = 1000;                 % Paket uzunluğu (bit)
m             = 1;                    % m+1 bit/sembol
slot_dur      = 1;                    
Kmax          = 2000;                 
p             = 1 - q;                

% Comp. complexity
tau_enc   = (m+1)*( l*(n-1) + n ) / Ccomp;
tau_dec   = ( n^3 + 2*n^2*l + (n-1)*n*l ) / Ccomp;
enc_slots = ceil(tau_enc/slot_dur);
dec_slots = ceil(tau_dec/slot_dur);


sim_dir    = zeros(size(lambda_E_vals));
theory_dir = zeros(size(lambda_E_vals));
sim_nc     = zeros(size(lambda_E_vals));
theory_nc  = zeros(size(lambda_E_vals));
k_frame    = (1:Kmax);


for idx = 1:length(lambda_E_vals)
  lamE = lambda_E_vals(idx);
  
  % Direct + EH 
  total_dir = 0;
  for tr = 1:num_trials
    bat   = 0;
    slots = 0;
    for pkt = 1:n
      rec = zeros(1,R);
      while any(rec<1)
        if bat
          bat = 0;
          rec = rec + (rand(1,R)>q);
        else
          if rand<lamE, bat=1; end
        end
        slots = slots + 1;
      end
    end
    
    total_dir = total_dir + slots/2;
  end
  sim_dir(idx) = total_dir/num_trials;
  
  % Direct + EH theoric
  ED = 1 + 1/lamE;  
  
  Pr_Mge = 1 - (1 - (1-p).^(k_frame-1)).^R;  
  EM_dir = sum(Pr_Mge);            
  theory_dir(idx) = (n * EM_dir * ED)/2;
  
  % NC + EH 
  total_nc = 0;
  for tr = 1:num_trials
    bat   = 0;
    slots = 0;
    coded = zeros(1,R);
    while any(coded<n)
      if bat
        slots = slots + enc_slots;           
        bat   = 0;
        coded = coded + (rand(1,R)>q);       
        slots = slots + 1;
      else
        if rand<lamE, bat=1; end             
        slots = slots + 1;
      end
    end
    slots = slots + dec_slots;              
    total_nc = total_nc + slots/2;
  end
  sim_nc(idx) = total_nc/num_trials;
  
  % NC + EH theoric
  ED = 1 + 1/lamE;
  beta = n:Kmax;
  Pfail = binocdf(n-1, beta, p);          
  Pr_Mge_nc = 1 - (1 - Pfail).^R;         
  EM_nc = sum(Pr_Mge_nc);                
  
  
  E_frames = n + EM_nc;
  
  theory_nc(idx) = 0.5*(E_frames*(ED + enc_slots) + dec_slots);
end

figure; hold on;
plot(lambda_E_vals, sim_dir,    '-o','LineWidth',2,'DisplayName','Sim Direct+EH');
plot(lambda_E_vals, theory_dir, '-s','LineWidth',2,'DisplayName','Teori Direct+EH');
plot(lambda_E_vals, sim_nc,     '-^','LineWidth',2,'DisplayName','Sim NC+EH');
plot(lambda_E_vals, theory_nc,  '-d','LineWidth',2,'DisplayName','Teori NC+EH');
xlabel('\lambda_E (Energy Harvest Rate)');
ylabel('Avg AoI per Update');
title(sprintf('Direct+EH & NC+EH w/ Enc/Dec (n=%d,R=%d,q=%.2f)',n,R,q));
legend('Location','NorthWest');
grid on;
