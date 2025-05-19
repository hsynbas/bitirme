clc; clear;

R             = 4;       
n             = 4;       
Ccap          = 5;        
E_tx          = 1;        

lambda_U      = 0.02;     
lambda_E_vals = 0.1:0.05:0.9; 
q             = 0.5;      
K             = 100;       
n_trials      = 200;      

%delay params
l               = 1000; m = 1;
Ccomp           = 10000;
Rjk             = 1500;

direct_tx_delay = (l*(m+1))           / Rjk;  
enc_delay       = ((m+1)*(l*(n-1)+n)) / Ccomp; 
nc_tx_delay     = ((l + n)*(m+1))     / Rjk;   
dec_delay       = (n^3 + n^2*l + (n-1)*n*l) / Ccomp;   

AoI_direct = zeros(size(lambda_E_vals));
AoI_nc     = zeros(size(lambda_E_vals));

for li = 1:length(lambda_E_vals)
  lambda_E = lambda_E_vals(li);
  trialsD  = zeros(1,n_trials);
  trialsN  = zeros(1,n_trials);

  for tr = 1:n_trials
    
   I = exprnd(1/lambda_U,1,K-1);   
   U = [0, cumsum(I)];            %ilk update hazır

    %direct 
    t        = 0;
    AoI      = 0;
    last_del = 0;
    bat      = 5;

    for i = 1:K
      u_i = U(i);

      
      t_idle_end = u_i;
      if i > 1
     
        while t < t_idle_end && bat < Ccap
          tau = exprnd(1/lambda_E);
          if t + tau > t_idle_end
            break;
          end
          t   = t + tau;
          bat = bat + 1;
        end
        t = t_idle_end;
      else
       
        while t < t_idle_end && bat < Ccap
          tau = exprnd(1/lambda_E);
          if t + tau > t_idle_end
            break;
          end
           AoI = AoI + 0.5*tau*((t-last_del)+((t+tau)-last_del));
          t   = t + tau;
          bat = bat + 1;
        end
        dt  = t_idle_end - t;
         AoI = AoI + 0.5*dt*((t-last_del)+(t_idle_end-last_del));
        t   = t_idle_end;
      end

      
      rec = zeros(1,R);
      pkt = 1;
      while pkt <= n
        
        while bat < E_tx
          tau = exprnd(1/lambda_E);
          AoI = AoI + 0.5*tau*((t-last_del)+((t+tau)-last_del));
          t   = t + tau;
          bat = min(bat+1,Ccap);
        end
      
        bat = bat - E_tx;
        tau =  direct_tx_delay;
        AoI = AoI + 0.5*tau*((t-last_del)+((t+tau)-last_del));
        t   = t + tau;
        rec = min(rec + (rand(1,R)>q), 1);
        if all(rec)
          pkt   = pkt + 1;
          rec(:)= 0;
        end
      end
      t_serv_end = t;

      
      if i < K && U(i+1) < t_serv_end
        last_del = U(i+1);
      else
        last_del = u_i;
      end
    end

    trialsD(tr) = AoI / t;


    %network coding 
    t        = 0;
    AoI      = 0;
    last_del = 0;
    bat      = 5;

    for i = 1:K
      u_i = U(i);

  
      t_idle_end = u_i;
      if i > 1
        while t < t_idle_end && bat < Ccap
          tau = exprnd(1/lambda_E);
          if t + tau > t_idle_end
            break;
          end
          t   = t + tau;
          bat = bat + 1;
        end
        t = t_idle_end;
      else
        while t < t_idle_end && bat < Ccap
          tau = exprnd(1/lambda_E);
          if t + tau > t_idle_end
            break;
          end
          AoI = AoI + 0.5*tau*((t-last_del)+((t+tau)-last_del));
          t   = t + tau;
          bat = bat + 1;
        end
        dt  = t_idle_end - t;
        AoI = AoI + 0.5*dt*((t-last_del)+(t_idle_end-last_del));
        t   = t_idle_end;
      end

   
      recv = zeros(1,R);
      while any(recv < n)
        while bat < E_tx
          tau = exprnd(1/lambda_E);
          AoI = AoI + 0.5*tau*((t-last_del)+((t+tau)-last_del));
          t   = t + tau;
          bat = min(bat+1,Ccap);
        end
        bat = bat - E_tx;
        tau = enc_delay + nc_tx_delay;
        AoI = AoI + 0.5*tau*((t-last_del)+((t+tau)-last_del));
        t   = t + tau;
        recv= min(recv + (rand(1,R)>q), n);
      end
      % decoding del
      tau = dec_delay;
      AoI = AoI + 0.5*tau*((t-last_del)+((t+tau)-last_del));
      t   = t + tau;

 
      if i < K && U(i+1) < t
        last_del = U(i+1);
      else
        last_del = u_i;
      end
    end

    trialsN(tr) = AoI / t;
  end

  AoI_direct(li) = mean(trialsD);
  AoI_nc(li)     = mean(trialsN);
end


figure; hold on;
plot(lambda_E_vals, AoI_direct, '-o','LineWidth',1.5,'DisplayName','Direct');
plot(lambda_E_vals, AoI_nc,     '-s','LineWidth',1.5,'DisplayName','Network Coding');
xlabel('\lambda_E (Energy Harvest Rate)');
ylabel('Average AoI (until K deliveries)');
title('AoI vs. \lambda_E ');
legend('Location','northeast');
grid on;
