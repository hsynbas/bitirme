
clc; clear; close all;


R             = 4;       
n             = 4;       
Ccap          = 5;       % battery capacity
E_tx          = 1;       % energy for a transmission attempt
q             = 0.3;     % erasure prob
lambda_U      = 0.05;   % update arrival rate
lambda_E_vals = 0.1:0.05:0.9;  % energy harvesting rates
K             = 100;     
n_trials      = 600;     


l               = 1000; m = 0;
Ccomp           = 10000;
Rjk             = 1000;

direct_tx_delay = (l*(m+1))           / Rjk;  %tranmsission delay for direct  1
enc_delay       = ((m+1)*(l*(n-1)+n)) / Ccomp; % encoding delay for nc  0.3
nc_tx_delay     = ((l + n)*(m+1))     / Rjk;   % transmission delay for nc 1
dec_delay       = (n^3 + n^2*l + (n-1)*n*l) / Ccomp; %  decoding delay for nc  2.8


AoI_direct = zeros(size(lambda_E_vals));
AoI_nc     = zeros(size(lambda_E_vals));

for li = 1:length(lambda_E_vals)
  lambda_E = lambda_E_vals(li);
  resultsD = zeros(1,n_trials);
  resultsN = zeros(1,n_trials);

  for tr = 1:n_trials
    %updates generated
    I = exprnd(1/lambda_U,1,K-1);
    U = [0, cumsum(I)];    % first update at t= 0
    
    %Direct sim
    t        = 0;
    AoI      = 0;
    last_received_gt = 0;
    bat      = Ccap;

    for i = 1:K
      u_i = U(i);
      % harvesting until new update comes at source
      while t < u_i && bat < Ccap
        tau = exprnd(1/lambda_E);
        AoI = AoI + 0.5*tau*((t-last_received_gt)+((t+tau)-last_received_gt));
        t   = t + tau;
        bat = min(bat+1, Ccap);
      end
      t = max(t, u_i);

      % transmit n packets
      rec = zeros(1, R);
      pkt = 1;
      while pkt <= n
        % harvest if no energy available for transmission
        while bat < E_tx
          tau = exprnd(1/lambda_E);
          AoI = AoI + 0.5*tau*((t-last_received_gt)+((t+tau)-last_received_gt));
          t   = t + tau;
          bat = min(bat+1, Ccap);
        end
        % transmit one packet
        bat = bat - E_tx;
        tau = direct_tx_delay;
        AoI = AoI + 0.5*tau*((t-last_received_gt)+((t+tau)-last_received_gt));
        t   = t + tau;
        % erasure check
        rec = min(rec + (rand(1,R)>q), 1);
        if all(rec)
          pkt = pkt + 1;
          rec(:) = 0;
        end
      end
      
      last_received_gt = u_i; % generation time of last received update
    end
    resultsD(tr) = AoI / t;

    %Network Coding sim
    t        = 0;
    AoI      = 0;
    last_received_gt = 0;
    bat      = Ccap;

    for i = 1:K
      u_i = U(i);
       %harvesting until new update comes at source
      while t < u_i && bat < Ccap
        tau = exprnd(1/lambda_E);
        AoI = AoI + 0.5*tau*((t-last_received_gt)+((t+tau)-last_received_gt));
        t   = t + tau;
        bat = min(bat+1, Ccap);
      end
      t = max(t, u_i);
      % transmit n coded packets
      recv = zeros(1, R);
      while any(recv < n)
        while bat < E_tx
          tau = exprnd(1/lambda_E);
          AoI = AoI + 0.5*tau*((t-last_received_gt)+((t+tau)-last_received_gt));
          t   = t + tau;
          bat = min(bat+1, Ccap);
        end
        bat = bat - E_tx;
        tau = enc_delay + nc_tx_delay;
        AoI = AoI + 0.5*tau*((t-last_received_gt)+((t+tau)-last_received_gt));
        t   = t + tau;
        recv = min(recv + (rand(1,R)>q), n);
      end
      % adding decoding delay 
      tau = dec_delay;
      AoI = AoI + 0.5*tau*((t-last_received_gt)+((t+tau)-last_received_gt));
      t   = t + tau;
      
      last_received_gt = u_i; % generation time of last received update
    end
    resultsN(tr) = AoI / t;
  end

  AoI_direct(li) = mean(resultsD);
  AoI_nc(li)     = mean(resultsN);
end

%--- PLOT ---
figure; hold on;
plot(lambda_E_vals, AoI_direct, '-o','LineWidth',1.5,'DisplayName','Direct');
plot(lambda_E_vals, AoI_nc,     '-s','LineWidth',1.5,'DisplayName','Network Coding');
xlabel('\lambda_E (Energy Harvest Rate)');
ylabel('Average AoI');
title('AoI vs. \lambda_E');
legend('Location','northeast');
grid on;
