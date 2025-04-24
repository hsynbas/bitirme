clc; clear;

% 1) Parametreler
period        = 12;              % Her 10 slot'ta bir yeni update üretilir
n_pkt         = 4;               % Update başına paket sayısı
R             = 4;               % Alıcı sayısı
q             = 0.5;             % Erasure (kayıp) olasılığı
lambda_E_vals = 0.1:0.1:0.9;     % Enerji hasat oranları
num_trials    = 200;             % Monte Carlo deneme sayısı
T_total       = 500;             % Her trial için toplam slot sayısı
Bcap          = 20;              % Batarya kapasitesi (birim enerji)
E_tx          = 4;               % Bir iletim slotunda harcanan enerji
E_harvest     = 4;               % Bir hasat slotunda toplanan enerji

% 2) Sonuç dizisi
sim_dir = zeros(size(lambda_E_vals));

% 3) Monte Carlo döngüsü
for li = 1:length(lambda_E_vals)
  lamE   = lambda_E_vals(li);
  AoI_acc = 0;    % tüm slot'lar boyunca biriktirilen AoI toplamı

  for tr = 1:num_trials
    bat     = 20;      % batarya başlangıcı
    last_del= 0;      % en son teslim zamanı (AoI sıfırlama için)
    
    % FIFO kuyruğu: boş struct ile başlatıyoruz
    queue = struct('gen',{},'pkt',{},'rcv',{});
    
    % Her slot’ta:
    for t = 1:T_total
      % (a) Periyodik update üretimi
      if mod(t-1,period)==0
        queue(end+1) = struct( ...
          'gen', t, ...
          'pkt', 1, ...
          'rcv', zeros(1,R) ...
        );
      end

      % (b) AoI artışı (t anındaki AoI = t - last_del)
      AoI_acc = AoI_acc + (t - last_del);

      % (c) Kuyruk boşsa sadece enerji hasat et
      if isempty(queue)
        if rand < lamE && bat < Bcap
          bat = bat + E_harvest;
        end
        continue
      end

      % (d) Kuyruğun önündeki update
      upd = queue(1);

      % (d1) Bu update tümüyle bitti mi?
      if upd.pkt > n_pkt
        % Update teslim edildi (hepsini ilettik):
        last_del   = upd.gen;   % AoI sıfırlanır
        queue(1)   = [];        % dequeue
        continue
      end

      % (d2) Mevcut paketi iletmek mi, yoksa paket teslim edilmiş mi?
      if any(upd.rcv < 1)
        % hâlâ bu paketi tüm alıcılara iletmemiz lazım
        if bat >= E_tx
          % --- İletim slotu ---
          bat = bat - E_tx;
          % Her alıcı için bağımsız erasure denemesi:
          success      = (rand(1,R) > q);
          % Bir kere 1 oldu mu kalıcı say:
          upd.rcv(upd.rcv<1 & success) = 1;
          queue(1) = upd;
        else
          % --- Hasat slotu ---
          if rand < lamE && bat < Bcap
            bat = bat + E_harvest;
          end
        end
      else
        % bu paket tüm alıcılara iletildi → bir sonraki pakete geç
        upd.pkt = upd.pkt + 1;
        upd.rcv = zeros(1,R);
        queue(1)= upd;
      end
    end
  end

  % slot başına ort. AoI:
  sim_dir(li) = AoI_acc / (num_trials * T_total);
end

% 4) Sonuçların görselleştirilmesi
figure;
plot(lambda_E_vals, sim_dir, '-o', 'LineWidth',2);
xlabel('\lambda_E (Energy Harvest Rate)');
ylabel('Time-Average AoI (slots)');
title(sprintf('Direct+EH w/ Periodic Arrivals (period=%d, n=%d, R=%d, q=%.2f)', ...
  period, n_pkt, R, q));
grid on;
