clc; clear;


n             = 8;                    
R             = 4;                    
q             = 0.5;                  
lambda_E_vals = 0.1:0.1:0.9;          
num_trials    = 1000;                 
Kmax          = 2000;                 
p             = 1 - q;                


sim_dir    = zeros(size(lambda_E_vals));
sim_nc     = zeros(size(lambda_E_vals));
theory_dir = zeros(size(lambda_E_vals));
theory_nc  = zeros(size(lambda_E_vals));
k_frame    = 1:Kmax;
beta       = n:Kmax;

for li = 1:length(lambda_E_vals)
    lamE = lambda_E_vals(li);
    ED   = 1 + 1/lamE;                

    % Direct+EH 
    tot_dir = 0;
    for tr = 1:num_trials
        bat   = 0;
        slots = 0;
        for pkt = 1:n
            rec = zeros(1,R);
            while any(rec<1)
                if bat
                    bat = 0;
                    rec = rec + (rand(1,R) > q);
                else
                    if rand < lamE, bat = 1; end
                end
                slots = slots + 1;
            end
        end
        tot_dir = tot_dir + slots/2;
    end
    sim_dir(li) = tot_dir/num_trials;

    % NC+EH 
    tot_nc = 0;
    for tr = 1:num_trials
        bat   = 0;
        slots = 0;
        coded = zeros(1,R);
        while any(coded < n)
            if bat
                bat   = 0;
                coded = coded + (rand(1,R) > q);
            else
                if rand < lamE, bat = 1; end
            end
            slots = slots + 1;
        end
        tot_nc = tot_nc + slots/2;
    end
    sim_nc(li) = tot_nc/num_trials;

    % Direct+EH theoric
    EM_dir = sum( 1 - (1 - (1-p).^(k_frame-1)).^R );
    theory_dir(li) = n * EM_dir * ED / 2;

    % NC+EH theoric
    Pfail = binocdf(n-1, beta, p);
    EM_nc = sum( 1 - (1 - Pfail).^R );
    theory_nc(li) = 0.5*(n + EM_nc) * ED;
end


figure; hold on;
plot(lambda_E_vals, sim_dir,    '-o','LineWidth',2,'DisplayName','Sim Direct+EH');
plot(lambda_E_vals, theory_dir, '-s','LineWidth',2,'DisplayName','Teori Direct+EH');
plot(lambda_E_vals, sim_nc,     '-^','LineWidth',2,'DisplayName','Sim NC+EH');
plot(lambda_E_vals, theory_nc,  '-d','LineWidth',2,'DisplayName','Teori NC+EH');
xlabel('\lambda_E (Energy Harvest Rate)');
ylabel('Average AoI per Update');
title(sprintf('Direct+EH & NC+EH: Sim vs Teori (n=%d, R=%d, q=%.2f)',n,R,q));
legend('Location','NorthWest');
grid on;
