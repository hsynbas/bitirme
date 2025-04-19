clc; clear;
%Infinite Batt - Best Eff
% Parametreler
q = 0.5;
R = 4;
n_values = [1, 2, 4, 6, 8];
sim_time = 5000;
num_trials = 1000;

AoI_packet = zeros(num_trials, length(n_values));

% Simülasyon
for trial = 1:num_trials
    for ni = 1:length(n_values)
        n = n_values(ni);
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

        AoI_packet(trial, ni) = AoI_total / (sim_time * n);
    end
end

%Ortalama
mean_packet = mean(AoI_packet, 1);

%Grafik
figure;
plot(n_values, mean_packet, '-o', 'LineWidth', 2);
xlabel('n (Number of Packets in NC Block)');
ylabel('Average AoI per Packet');
title(['AoI per Packet vs n (q = ' num2str(q) ', R = ' num2str(R) ')']);
grid on;

%okey