clc; clear;

R = 4;                         
n = 8;                          
q_values = [0.1 0.3 0.5 0.7 0.9];  
num_trials = 1000;             
lambda_E = 0.5;              

avg_aoi_direct = zeros(size(q_values));
avg_aoi_nc = zeros(size(q_values));
avg_aoi_direct_eh = zeros(size(q_values));
avg_aoi_nc_eh = zeros(size(q_values));
theory_direct = zeros(size(q_values));
theory_nc = zeros(size(q_values));
theory_direct_eh = zeros(size(q_values));
theory_nc_eh = zeros(size(q_values));

for qi = 1:length(q_values)
    q = q_values(qi);

    total_aoi_direct = 0;
    total_aoi_nc = 0;
    total_aoi_direct_eh = 0;
    total_aoi_nc_eh = 0;

    for trial = 1:num_trials
        % Direct Transmission (inf batt)
        total_slots = 0;
        for pkt = 1:n
            receivers = zeros(1, R);
            while any(receivers < 1)
                success = rand(1, R) > q;
                receivers = receivers + success;
                receivers(receivers > 1) = 1;
                total_slots = total_slots + 1;
            end
        end
        total_aoi_direct = total_aoi_direct + (total_slots) / 2;

        % Network Coding Transmission (inf batt)
        coded_received = zeros(1, R);
        t_nc = 0;
        while any(coded_received < n)
            success = rand(1, R) > q;
            coded_received = coded_received + success;
            coded_received(coded_received > n) = n;
            t_nc = t_nc + 1;
        end
        total_aoi_nc = total_aoi_nc + (t_nc ) / 2;

        % Direct Transmission (Unit Battery)
        total_slots_eh = 0;
        battery = 1;
        for pkt = 1:n
            receivers = zeros(1, R);
            while any(receivers < 1)
                if battery >= 1
                    battery = battery - 1;
                    success = rand(1, R) > q;
                    receivers = receivers + success;
                    receivers(receivers > 1) = 1;
                else
                    if rand < lambda_E
                        battery = 1;
                    end
                end
                total_slots_eh = total_slots_eh + 1;
            end
        end
        total_aoi_direct_eh = total_aoi_direct_eh + (total_slots_eh ) / 2;

        % Network Coding Transmission (Unit Battery)
        coded_received = zeros(1, R);
        t_nc_eh = 0;
        battery = 1;
        while any(coded_received < n)
            if battery >= 1
                battery = battery - 1;
                success = rand(1, R) > q;
                coded_received = coded_received + success;
                coded_received(coded_received > n) = n;
            else
                if rand < lambda_E
                    battery = 1;
                end
            end
            t_nc_eh = t_nc_eh + 1;
        end
        total_aoi_nc_eh = total_aoi_nc_eh + (t_nc_eh ) / 2;
    end

    avg_aoi_direct(qi) = total_aoi_direct / num_trials;
    avg_aoi_nc(qi) = total_aoi_nc / num_trials;
    avg_aoi_direct_eh(qi) = total_aoi_direct_eh / num_trials;
    avg_aoi_nc_eh(qi) = total_aoi_nc_eh / num_trials;

    % Teorik 
    max_transmissions = 3000; 
    p = 1 - q;
    % Direct Transmission teorik 
    E_T_packet = 0;
    for beta = 0:max_transmissions
        P_fail = 1 - (1 - (1 - p)^beta)^R;
        E_T_packet = E_T_packet + P_fail;
        if P_fail < 1e-6
            break;
        end
    end
    T_dir = n * E_T_packet;
    theory_direct(qi) = (T_dir ) / (2 );


    % Network Coding teorik
    T_nc = n; % min needed
    for beta = n:max_transmissions
        Pc_suc = 1 - sum(arrayfun(@(gamma) nchoosek(beta, gamma) * (p^gamma) * ((1 - p)^(beta - gamma)), 0:n-1));
        Pc_all = Pc_suc^R;
        T_nc = T_nc + (1 - Pc_all);
        if (1 - Pc_all) < 1e-6
            break;
        end
    end
    theory_nc(qi) = (T_nc ) / 2;

    gamma = 1.1;  
    T_dir_EH = T_dir * ((1+lambda_E)/lambda_E);
    T_nc_EH = T_nc * ((1+lambda_E)/lambda_E);
    
    theory_direct_eh(qi) = T_dir_EH / 2;
    theory_nc_eh(qi) = T_nc_EH / 2;
end

figure;
plot(q_values, avg_aoi_direct, '-o', 'LineWidth', 2); hold on;
plot(q_values, avg_aoi_nc, '-s', 'LineWidth', 2);
plot(q_values, avg_aoi_direct_eh, '--o', 'LineWidth', 2);
plot(q_values, avg_aoi_nc_eh, '--s', 'LineWidth', 2);
plot(q_values, theory_direct, ':o', 'LineWidth', 1.5);
plot(q_values, theory_nc, ':s', 'LineWidth', 1.5);
plot(q_values, theory_direct_eh, ':^', 'LineWidth', 1.5);
plot(q_values, theory_nc_eh, ':v', 'LineWidth', 1.5);
xlabel('Erasure Probability q');
ylabel('Average AoI per Update');
title(['AoI Comparison with/without EH (n = ' num2str(n) ', R = ' num2str(R) ')']);
legend('Direct', 'NC', 'Direct + EH', 'NC + EH', 'Theoretical Direct', 'Theoretical NC', 'Theoretical Direct + EH', 'Theoretical NC + EH');
grid on;
