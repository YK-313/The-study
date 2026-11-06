%% DASIC SI Component Visualization Script
clear; clc; close all;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
SIM.SNR     = 10;            
SIM.SIR     = -50;           % 希望信号対干渉電力比
SIM.rho     = -3;            % 2波目と直接波の電力比
SIM.Nrho    = -3;            % 3波目以降の減衰電力
SIM.nsym    = 64;            % シンボル数         
SIM.ndata   = SIM.nsym;
SIM.over    = 2;             % 簡易化のため1
SIM.delayA  = 2;             % AA間の遅延間隔
SIM.AA      = 2;             % AA間パス数（1なら直接波のみ、増やすとマルチパス）
G.Q = 4;                     % QPSK
G.ml = log2(G.Q);
fft_ptA = SIM.over * SIM.ndata;
T_sym_us = 32;               % 1シンボルの時間 [μs]
dt_us = T_sym_us / fft_ptA;  % 1サンプルあたりの時間 [μs]
time_axis_us = (0:fft_ptA-1) * dt_us; % 横軸ベクトル

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Channel & Signal %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% 1. AA間パスの生成 (CIRの作成)
num_of_paths_AA = SIM.AA;
delay_profile_AA = (randn(num_of_paths_AA, 1) + 1i * randn(num_of_paths_AA, 1)) ./ sqrt(2 * num_of_paths_AA);
delay_profile_AA_s = delay_profile_AA ./ abs(delay_profile_AA);

% 電力比(rho)の適用
if SIM.AA == 1
    delay_profile_AA_rho = delay_profile_AA_s;
else
    delay_profile_AA_rho = zeros(size(delay_profile_AA_s));
    rho_sum = 0;
    for rr = 2:SIM.AA
        rho = 10^( (SIM.rho + SIM.Nrho*(rr-2)) / 10);
        rho_sum = rho_sum + rho;
    end
    delay_profile_AA_rho(1) = delay_profile_AA_s(1) * sqrt(1/( 1 + rho_sum ) );
    for dd = 2:SIM.AA
        delay_profile_AA_rho(dd) = delay_profile_AA_s(dd) * sqrt(10^( (SIM.rho + SIM.Nrho*(dd-2))/10) * abs(delay_profile_AA_rho(1))^2);
    end
end

delay_profile_AA_sir = delay_profile_AA_rho * sqrt(10^(-SIM.SIR/10));

% インパルス応答ベクトル (時間領域) の作成
tmp_profile_AA = zeros(fft_ptA, 1); 
tmp_profile_AA(1 : SIM.delayA : SIM.delayA * num_of_paths_AA) = delay_profile_AA_sir;
H_circ_AA = [];
for iii = 1 : fft_ptA
    tmp_AA = circshift(tmp_profile_AA, iii - 1);
    H_circ_AA = [H_circ_AA tmp_AA];
end
H_circ_AA = sparse(H_circ_AA);

% 2. 周波数応答 (FR) の作成
Xi_vec_AA = fft(tmp_profile_AA, fft_ptA);

% 3. 送信信号の生成
TX_b = randi([0 1], SIM.ndata * G.ml, 1);
TX_x = pskmod(TX_b, G.Q, pi/G.Q, 'InputType', 'bit');
TX_s = ifft(TX_x(:,1), fft_ptA).*sqrt(fft_ptA);

% 受信SI成分
RX_s=H_circ_AA*TX_s;
RX_bA = fft(RX_s, fft_ptA)./sqrt(fft_ptA);

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DASIC Process   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% DASICの核：隣接サブキャリア間の位相回転差を利用した除去
phi = TX_x(2:end) ./ TX_x(1:end-1); 
RX_c_SI_only = zeros(SIM.ndata, 1);

RX_c_SI_only(2:SIM.ndata) = RX_bA(2:SIM.ndata) - phi .* RX_bA(1:SIM.ndata-1);
ResidualSI = Xi_vec_AA(2:end) - Xi_vec_AA(1:end-1);
ResidualSI2 = Xi_vec_AA(3:end) - 2*Xi_vec_AA(2:end-1) + Xi_vec_AA(1:end-2);

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Visualization   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% ウィンドウサイズ設定（2x2のサブプロット用）
figure('Color', 'w', 'Position', [100, 100, 900, 700]);

% --- Plot 1: CIR (Channel Impulse Response) ---
subplot(2,2,1);
amp_profile = abs(tmp_profile_AA);
valid_idx = find(amp_profile > 1e-10); 
stem(time_axis_us(valid_idx), 20*log10(amp_profile(valid_idx)), ...
    'filled', 'LineWidth', 2, 'MarkerSize', 6);
% ※MATLABのlatexインタープリタでは $\mu$ はデフォルトで斜体になります。
% もし完全に直立の「μ」にしたい場合は、ここだけ 'Interpreter', 'tex' に変更し、'Time [\mu s]' としてください。
xlabel({'Time [μs]', '', '(a) SI Channel Impulse Response.'}, ...
    'FontName', 'Times New Roman', 'Interpreter', 'tex', 'FontSize', 25);
ylabel('ISR [dB]', ...
    'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 25);
ylim([0 60]); 
xlim([0 1.0]); 
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 25);

% --- Plot 2: FR (Frequency Response) ---
subplot(2,2,2);
plot(0:fft_ptA-1, 20*log10(abs(Xi_vec_AA)), 'b-', 'LineWidth', 1.5);
hold on;
stem(0:fft_ptA-1, 20*log10(abs(Xi_vec_AA)), 'b.', 'MarkerSize', 10);
xlabel({'Subcarrier Index $k$', '', '(b) SI Frequency Response.'}, ...
    'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 25);
ylabel('ISR [dB]', ...
    'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 25);
xlim([0 127]); 
ylim([0 60]);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 25);

% --- Plot 3: 1-stage Residual SI ---
subplot(2,2,3);
plot(1:SIM.over*SIM.ndata-1, 20*log10(abs(ResidualSI(1:end))), 'b-', 'LineWidth', 1.5);
hold on;
stem(1:SIM.over*SIM.ndata-1, 20*log10(abs(ResidualSI(1:end))), 'b.', 'MarkerSize', 10);
xlabel({'Subcarrier Index $k$', '', '(c) Residual SI power in frequency domain (1-stage).'}, ...
    'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 25);
ylabel('ISR [dB]', ...
    'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 25);
xlim([1 127]); 
ylim([0 60]);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 25);

% --- Plot 4: 2-stage Residual SI ---
subplot(2,2,4);
plot(1:SIM.over*SIM.ndata-2, 20*log10(abs(ResidualSI2(1:end))), 'b-', 'LineWidth', 1.5);
hold on;
stem(1:SIM.over*SIM.ndata-2, 20*log10(abs(ResidualSI2(1:end))), 'b.', 'MarkerSize', 10);
xlabel({'Subcarrier Index $k$', '', '(d) Residual SI power in frequency domain (2-stage).'}, ...
    'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 25);
ylabel('ISR [dB]', ...
    'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 25);
xlim([1 127]); 
ylim([0 60]);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 25);

% 解析結果の表示
mean_si = mean(abs(RX_bA).^2);
mean_res1 = mean(abs(ResidualSI).^2);
mean_res2 = mean(abs(ResidualSI2).^2);
fprintf('--- Simulation Results ---\n');
fprintf('Original SI Energy: %.2f dB\n', 10*log10(mean_si));
fprintf('1-stage Residual SI Energy: %.2f dB\n', 10*log10(mean_res1));
fprintf('2-stage Residual SI Energy: %.2f dB\n', 10*log10(mean_res2));