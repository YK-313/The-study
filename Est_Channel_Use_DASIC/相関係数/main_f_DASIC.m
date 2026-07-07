clear
clc
startTime = clock;
%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 10;           % 信号対雑音電力比 (十分に高い値で固定)
SIM.w_loop  = 4;            
SIM.nsamp   = 5*10^SIM.w_loop;  
SIM.err_max = SIM.nsamp/10;  
SIM.SIR     = -100:10:0;    % 希望信号対干渉電力比 (SIRをスイープ)
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

SIM.mode    = 'xb_est1';     % xb_est や xb_est1 に変えて実験してください
SIM.detmode = 'BCJR';     
 
% --- 初期化部分 ---
BER   = zeros(size(SIM.SIR)); 
CORR  = zeros(size(SIM.SIR)); 
MIMIC = zeros(size(SIM.SIR)); % 【追加】擬態率の保存用

% --- ループ内 ---
parfor idx = 1:length(SIM.SIR)
%for idx = 1:length(SIM.SIR)
    sim_local = SIM;
    sim_local.SIR = SIM.SIR(idx); 
    RES = main_task_f_DASIC(SIM.SNR, idx, sim_local, G);  
    
    BER(idx)   = RES.BER; 
    CORR(idx)  = RES.corr; 
    MIMIC(idx) = RES.mimic; % 【追加】擬態率を取得
end

% --- グラフ描画部分 ---
figure;

% 【追加】BERが0の点を対数グラフで表示するための便宜的な置き換え
% （エラーがない点を 10^-6 の位置にプロットして線を繋ぎます）
plot_BER = BER;
plot_BER(plot_BER == 0) = 1e-6; 

% 1つ目のグラフ: BER特性
subplot(2,1,1);
semilogy(SIM.SIR, plot_BER, '-ro', 'LineWidth', 2);
grid on;
xlim([-100 0]); % 【追加】X軸の表示範囲を -100 から 0 に強制固定
set(gca, 'XDir', 'reverse');
xticks(-100:10:0); 
yticks(10.^(-4:1:0)); 
xlabel('SIR [dB]');
ylabel('BER');
title(sprintf('BER vs SIR (SNR = %d dB, Mode = %s)', SIM.SNR, SIM.mode));
ylim([1e-4 1]); % Y軸も見やすく固定（必要に応じて調整してください）

% 2つ目のグラフ: 相関係数と「擬態率（真のトラップ）」の比較
subplot(2,1,2);
plot(SIM.SIR, CORR, '-bo', 'LineWidth', 2, 'DisplayName', 'Signal Correlation (\mu)');
hold on;
plot(SIM.SIR, MIMIC, '-m*', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Error Mimicry to -H_A');
grid on;
xlim([-100 0]); % 【追加】下側のグラフも念のため固定
set(gca, 'XDir', 'reverse');
xticks(-100:10:0); 
yticks(0:0.2:1); 
xlabel('SIR [dB]');
ylabel('Value (0 to 1)');
title('Why the System Fails: The Error Mimicry Trap');
legend('Location', 'best');
ylim([0 1]);