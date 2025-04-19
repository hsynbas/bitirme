clc; clear;


q = 0.5;                     
R = 4;                        
n_values = [1, 2, 4, 6, 8];  
sim_time = 5000;             
num_trials = 100;           
lambda_E = 0.5;             


AoI_inf = zeros(num_trials, length(n_values));   
AoI_unit = zeros(num_trials, length(n_values));  


for trial = 1:num_trials
    for ni = 1:length(n_values)
        n = n_values(ni);

        %INFINITE BATTERY 
        AoI_users = ones(1, R);
        AoI_total = 0;
        t = 1;

        while t <= sim_time
            received = zeros(1, R);

            while any(received < n)
                AoI_users = AoI_users + 1;

               
                if rand > q
                    received(received < n) = received(received < n) + 1;
                end

                AoI_total = AoI_total + mean(AoI_users);
                t = t + 1;
                if t > sim_time, break; end
            end

            if all(received >= n)
                AoI_users(:) = 1;
            end
        end
        AoI_inf(trial, ni) = AoI_total / (sim_time * n);

        %  UNIT BATTERY
        AoI_users = ones(1, R);
        AoI_total = 0;
        t = 1;
        battery = 0;

        while t <= sim_time
            received = zeros(1, R);

            while any(received < n)
                AoI_users = AoI_users + 1;

                if battery >= 1
                    
                    battery = battery - 1;
                    if rand > q
                        received(received < n) = received(received < n) + 1;
                    end
                else
                    
                    if rand < lambda_E
                        battery = 1;
                    end
                end

                AoI_total = AoI_total + mean(AoI_users);
                t = t + 1;
                if t > sim_time, break; end
            end

            if all(received >= n)
                AoI_users(:) = 1;
            end
        end
        AoI_unit(trial, ni) = AoI_total / (sim_time * n);
    end
end


mean_inf = mean(AoI_inf, 1);
mean_unit = mean(AoI_unit, 1);


figure;
plot(n_values, mean_inf, '-o', 'LineWidth', 2); hold on;
plot(n_values, mean_unit, '-s', 'LineWidth', 2);
xlabel('n (Number of Packets in NC Block)');
ylabel('Average AoI per Packet');
title(['AoI per Packet vs n (q = ' num2str(q) ', R = ' num2str(R) ')']);
legend('Infinite Battery', 'Unit Battery with EH');
grid on;
