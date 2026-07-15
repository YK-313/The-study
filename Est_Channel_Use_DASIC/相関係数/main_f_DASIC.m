clear
clc
startTime = clock;
%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 10;           % 信号対雑音電力比 (十分に高い値で固定)
SIM.w_loop  = 5;            
SIM.nsamp   = 5*10^SIM.w_loop;  
SIM.err_max = SIM.nsamp/10;  
SIM.SIR     = -100:20:0;    % 希望信号対干渉電力比 (SIRをスイープ)
SIM.rho     = -3;
SIM.nsym    = 64;           % シンボル数         
SIM.ndata   = SIM.nsym;
SIM.over    = 2;
SIM.delayA  = 1;
SIM.delayB  = 2;
SIM.int     = 1; 
SIM.AA      = 2;
SIM.AB      = 16;
SIM.LLRclip = 100000000;
G.Q         = 4; 
G.ml        = log2(G.Q);
SIM.mode    = 'est';     % xb_est や xb_est1 に変えて実験してください
SIM.detmode = 'BCJR';     

% --- 初期化部分 ---
BER              = zeros(length(SIM.SIR), 1); 
P_True_AA_arr    = zeros(length(SIM.SIR), 1); 
P_Err_Interf_arr = zeros(length(SIM.SIR), 1);
fft_ptA          = SIM.over * SIM.ndata;
PDP_Err          = zeros(length(SIM.SIR), fft_ptA); 

% --- ループ内 ---
parfor idx = 1:length(SIM.SIR)
%for idx = 1:length(SIM.SIR)
    sim_local = SIM;
    sim_local.SIR = SIM.SIR(idx); 
    RES = main_task_f_DASIC(SIM.SNR, idx, sim_local, G);  
    
    BER(idx)              = RES.BER; 
    P_True_AA_arr(idx)    = RES.P_True_AA;
    P_Err_Interf_arr(idx) = RES.P_Err_Interf;
    PDP_Err(idx, :)       = RES.Err_time_pow;
end

% --- グラフ描画部分 ---
figure('Position', [100, 100, 900, 900]);

% 【グラフ1】BER特性
subplot(3,1,1);
plot_BER = BER;
plot_BER(plot_BER == 0) = 1e-6; 
semilogy(SIM.SIR, plot_BER, '-ro', 'LineWidth', 2);
grid on;
xlim([-100 0]); 
ylim([1e-5 1e-1]); % ★追加：Y軸を 10^-5 から 10^-1 に固定
set(gca, 'XDir', 'reverse');
xticks(-100:10:0); 
yticks(10.^(-5:1:-1)); % ★追加：Y軸の目盛りを1桁ごとに表示
xlabel('SIR [dB]');
ylabel('BER');
title(sprintf('BER vs SIR (SNR = %d dB, Mode = %s)', SIM.SNR, SIM.mode));

% 【グラフ2】推定器入力における電力推移
subplot(3,1,2);
semilogy(SIM.SIR, P_True_AA_arr, '-bo', 'LineWidth', 2, 'DisplayName', 'SI信号の電力');
hold on;
semilogy(SIM.SIR, P_Err_Interf_arr, '-rx', 'LineWidth', 2, 'DisplayName', '所望信号の推定誤差電力');
grid on;
xlim([-100 0]); 
ylim([1e-5 1e10]); % ★追加：Y軸を 10^-5 から 10^10 に固定
set(gca, 'XDir', 'reverse');
xticks(-100:10:0); 
yticks(10.^(-5:3:10)); % ★追加：Y軸の目盛りを見やすく間引いて表示 (10^-5, 10^-2, ... 10^10)
xlabel('SIR [dB]');
ylabel('電力 (リニアスケール)');
title('チャネル推定器への入力電力比較');
legend('Location', 'best');

% 【グラフ3】時間領域エラーPDP
subplot(3,1,3);
% 表示するSIRのインデックスを取得
[~, idx_0]   = min(abs(SIM.SIR - (0)));
[~, idx_20]  = min(abs(SIM.SIR - (-20)));
[~, idx_40]  = min(abs(SIM.SIR - (-40)));
[~, idx_60]  = min(abs(SIM.SIR - (-60)));
[~, idx_80]  = min(abs(SIM.SIR - (-80)));
[~, idx_100] = min(abs(SIM.SIR - (-100)));

% 見やすさのため、フロア雑音レベル(1e-12)を足して対数化
% 線が重なっても見分けやすいように色を変えてプロット
plot(1:fft_ptA, 10*log10(PDP_Err(idx_0, :) + 1e-12), '-k', 'LineWidth', 1.5, 'DisplayName', 'SIR = 0 dB');
hold on;
plot(1:fft_ptA, 10*log10(PDP_Err(idx_20, :) + 1e-12), '-g', 'LineWidth', 1.5, 'DisplayName', 'SIR = -20 dB');
plot(1:fft_ptA, 10*log10(PDP_Err(idx_40, :) + 1e-12), '-c', 'LineWidth', 1.5, 'DisplayName', 'SIR = -40 dB');
plot(1:fft_ptA, 10*log10(PDP_Err(idx_60, :) + 1e-12), '-m', 'LineWidth', 1.5, 'DisplayName', 'SIR = -60 dB');
plot(1:fft_ptA, 10*log10(PDP_Err(idx_80, :) + 1e-12), '-r', 'LineWidth', 1.5, 'DisplayName', 'SIR = -80 dB');
plot(1:fft_ptA, 10*log10(PDP_Err(idx_100, :) + 1e-12), '-b', 'LineWidth', 1.5, 'DisplayName', 'SIR = -100 dB');
grid on;
xlim([1 20]); % AAパスが存在する先頭の20タップだけを拡大表示
ylim([-35 -10]); % ★追加：Y軸を -35 から -10 に固定
xticks(1:20);
yticks(-35:5:-10); % ★追加：Y軸の目盛りを5dB刻みで表示
xlabel('離散時間');
ylabel('誤差電力 [dB]');
title('チャネル推定誤差のインパルス応答の電力分布');
legend('Location', 'best');