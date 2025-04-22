clc; clear;


n         = 8;            % Packet number
q         = 0.5;          % Erasure
lamE      = 0.5;          % EH rate
R_vals    = 1:10;         % Receiver
num_trials= 1000;         % Monte Carlo
Kmax      = 2000;         % tail‑sum
p         = 1 - q;        % success


sim_dir    = zeros(size(R_vals));
sim_nc     = zeros(size(R_vals));
theory_dir = zeros(size(R_vals));
theory_nc  = zeros(size(R_vals));
k_frame    = 1:Kmax;
beta       = n:Kmax;
ED         = 1 + 1/lamE;  

for ri = 1:length(R_vals)
    R = R_vals(ri);

    % Direct+EH 
    tot = 0;
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
                    if rand < lamE, bat = 1; end
                end
                slots = slots + 1;
            end
        end
        tot = tot + slots/2;
    end
    sim_dir(ri) = tot/num_trials;

    % NC+EH 
    tot = 0;
    for tr = 1:num_trials
        bat   = 0;
        slots = 0;
        coded = zeros(1,R);
        while any(coded<n)
            if bat
                bat   = 0;
                coded = coded + (rand(1,R)>q);
            else
                if rand < lamE, bat = 1; end
            end
            slots = slots + 1;
        end
        tot = tot + slots/2;
    end
    sim_nc(ri) = tot/num_trials;

    % Direct+EH theoretical
    EM_dir = sum( 1 - (1 - (1-p).^(k_frame-1)).^R );
    theory_dir(ri) = n * EM_dir * ED / 2;

    % NC+EH theoretical
    Pfail   = binocdf(n-1, beta, p);
    EM_nc   = sum( 1 - (1 - Pfail).^R );
    theory_nc(ri) = 0.5*(n + EM_nc)*ED;
end


figure; hold on;
plot(R_vals, sim_dir,    '-o','LineWidth',2,'DisplayName','Sim: Direct+EH');
plot(R_vals, theory_dir, '-s','LineWidth',2,'DisplayName','Teori: Direct+EH');
plot(R_vals, sim_nc,     '-^','LineWidth',2,'DisplayName','Sim: NC+EH');
plot(R_vals, theory_nc,  '-d','LineWidth',2,'DisplayName','Teori: NC+EH');
xlabel('Receiver Sayısı R');
ylabel('Average AoI per Update');
title(sprintf('EH=%.2f Sabit, n=%d, q=%.2f', lamE,n,q));
legend('Location','NorthEast');
grid on;
