%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
SIM.sir_mode   = 'manual';   % 'manual': パスごとにdB指定 / 'exact_sir': SIM.SIRとSIM.rhoで厳密正規化
SIM.tap_pwr_dB = [30; 27];   % 'manual'時の各パスの電力 [dB]

SIM.SIR     = -30;           % 'exact_sir'時のSIR [dB]
SIM.rho     = -3;            % 'exact_sir'時の隣接パス電力比 [dB]
SIM.nsym    = 64;            % サブキャリア数 K = 64
SIM.over    = 2;             % オーバーサンプリング率 gamma = 2
SIM.delayA  = 1;             % 遅延サンプル数 tau = 1 (0.25 us)
SIM.AA      = 2;             % SIパス数 U_AA = 2
G.Q         = 4;             % QPSK
G.ml        = log2(G.Q);

fft_ptA = SIM.over * SIM.nsym; % FFTサイズ: gamma * K = 128

% 物理インデックス (128pt FFTにおける正・負の周波数帯域: [1:32, 97:128])
half_nsym = SIM.nsym / 2;
phys_idx = [1:half_nsym, (fft_ptA - half_nsym + 1):fft_ptA];

% 周波数軸順のデータサブキャリア抽出 (マイナス側[37:64] -> プラス側[2:29])
% 128pt FFT上では [101:128, 2:29] に対応 (L = 56)
freq_ordered_idx = [(half_nsym + 5):SIM.nsym, 2:(half_nsym - 3)];
data_idx_128 = phys_idx(freq_ordered_idx);
L = length(data_idx_128);

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Channel & Signal %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% 1. SIチャネル (CIR) の生成
rng(1); % 再現性のためのシード固定
phase_AA = exp(1i * 2 * pi * rand(SIM.AA, 1));

switch SIM.sir_mode
    case 'manual'
        amp_AA = 10.^(SIM.tap_pwr_dB / 20);
    case 'exact_sir'
        rho_lin = 10^(SIM.rho / 10);
        pwr_rel = rho_lin .^ (0 : SIM.AA - 1).';
        pwr_AA  = (pwr_rel / sum(pwr_rel)) * 10^(-SIM.SIR / 10);
        amp_AA  = sqrt(pwr_AA);
    otherwise
        error('SIM.sir_mode must be ''manual'' or ''exact_sir''.');
end

delay_profile_AA_sir = amp_AA .* phase_AA;

fprintf('Mode: %s | Tap powers [dB]: [%.2f, %.2f] | Actual SIR: %.2f dB\n', ...
    SIM.sir_mode, 20*log10(amp_AA(1)), 20*log10(amp_AA(2)), -10*log10(sum(amp_AA.^2)));

% インパルス応答ベクトル (時間領域, 長さ gamma*K)
tmp_profile_AA = zeros(fft_ptA, 1); 
tmp_profile_AA(1 : SIM.delayA : 1 + SIM.delayA * (SIM.AA - 1)) = delay_profile_AA_sir;

% 2. 周波数応答 (CFR) の作成
Xi_vec_AA_full = fft(tmp_profile_AA, fft_ptA); % 長さ gamma*K
Xi_AA = Xi_vec_AA_full(data_idx_128);          % 周波数軸順のデータサブキャリア抽出 (長さ L=56)

% 3. 送信信号 x_A[l] の生成 (QPSK, |x_A[l]| = 1)
TX_b = randi([0 1], L * G.ml, 1);
TX_x = pskmod(TX_b, G.Q, pi/G.Q, 'InputType', 'bit');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DASIC Process (定義式) %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 1-stage: l = 2, ..., L
v_tilde = NaN(L, 1);
v_tilde(2:L) = (Xi_AA(2:L) - Xi_AA(1:L-1)) .* TX_x(2:L);

% 2-stage: l = 3, ..., L
v_ttilde = NaN(L, 1);
v_ttilde(3:L) = (Xi_AA(3:L) - 2*Xi_AA(2:L-1) + Xi_AA(1:L-2)) .* TX_x(3:L);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DASIC Process (受信SI信号に対する実処理) %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 送信信号を128ptに配置 -> IFFT -> 時間領域巡回畳み込み -> FFT -> データ抽出
TX_x_128 = zeros(fft_ptA, 1);
TX_x_128(data_idx_128) = TX_x;
s_A = ifft(TX_x_128, fft_ptA) * sqrt(fft_ptA);

% SIチャネル通過 (巡回畳み込み: H_circ_AA * s_A と等価)
r_SI_time = cconv(tmp_profile_AA, s_A, fft_ptA);
Y_SI_128  = fft(r_SI_time, fft_ptA) / sqrt(fft_ptA);
Y_SI      = Y_SI_128(data_idx_128); % 受信SI信号 (長さ L=56)

% 位相回転 phi_A[l] = x_A[l] / x_A[l-1] (l = 2, ..., L)
phi_A = TX_x(2:L) ./ TX_x(1:L-1);

% 1-stage DASIC (実処理)
v_tilde_sim = NaN(L, 1);
v_tilde_sim(2:L) = Y_SI(2:L) - phi_A .* Y_SI(1:L-1);

% 2-stage DASIC (実処理)
v_ttilde_sim = NaN(L, 1);
v_ttilde_sim(3:L) = v_tilde_sim(3:L) - phi_A(2:end) .* v_tilde_sim(2:L-1);

% 定義式と実処理の最大誤差を確認
fprintf('Max diff (1-stage): %.3e\n', max(abs(v_tilde(2:L) - v_tilde_sim(2:L))));
fprintf('Max diff (2-stage): %.3e\n', max(abs(v_ttilde(3:L) - v_ttilde_sim(3:L))));

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Visualization   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%
l_axis = 1:L;
font_sz = 24;
line_wd = 2.0;
marker_sz = 20;
y_lim_range = [-40 40];

% --- Figure (a): 20log10|xi_AA[l]| ---
fig1 = figure('Color', 'w', 'Position', [100, 100, 650, 500]);
plot(l_axis, 20*log10(abs(Xi_AA)), 'b.-', 'LineWidth', line_wd, 'MarkerSize', marker_sz);
xlabel('Data Index $l$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
ylabel('$20\log_{10}|\xi_{\mathrm{AA}}[l]|$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
xlim([1 L]); ylim(y_lim_range);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', font_sz, 'LineWidth', 1.2);
exportgraphics(fig1, 'SI_CFR.eps', 'ContentType', 'vector');

% --- Figure (b): \tilde{\zeta}_A[l] [dB] ---
fig2 = figure('Color', 'w', 'Position', [150, 150, 650, 500]);
plot(l_axis, 20*log10(abs(v_tilde)), 'b.-', 'LineWidth', line_wd, 'MarkerSize', marker_sz);
xlabel('Data Index $l$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
ylabel('$\tilde{\zeta}_{\mathrm{A}}[l]$ [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
xlim([1 L]); ylim(y_lim_range);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', font_sz, 'LineWidth', 1.2);
exportgraphics(fig2, 'SI_Res1.eps', 'ContentType', 'vector');

% --- Figure (c): \tilde{\tilde{\zeta}}_A[l] [dB] ---
fig3 = figure('Color', 'w', 'Position', [200, 200, 650, 500]);
plot(l_axis, 20*log10(abs(v_ttilde)), 'b.-', 'LineWidth', line_wd, 'MarkerSize', marker_sz);
xlabel('Data Index $l$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
ylabel('$\tilde{\tilde{\zeta}}_{\mathrm{A}}[l]$ [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
xlim([1 L]); ylim(y_lim_range);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', font_sz, 'LineWidth', 1.2);
exportgraphics(fig3, 'SI_Res2.eps', 'ContentType', 'vector');

fig4 = figure('Color', 'w', 'Position', [250, 250, 750, 520]);
% plot(l_axis, 20*log10(abs(Xi_AA)),    'k-o',  'LineWidth', line_wd, 'MarkerSize', 6, 'DisplayName', '$\zeta_{\mathrm{A}}[l]$ (w/o DASIC)'); hold on;
% plot(l_axis, 20*log10(abs(v_tilde)),  'b-s', 'LineWidth', line_wd, 'MarkerSize', 6, 'DisplayName', '$\tilde{\zeta}_{\mathrm{A}}[l]$ (1-stage DASIC)');
% plot(l_axis, 20*log10(abs(v_ttilde)), 'r-^', 'LineWidth', line_wd, 'MarkerSize', 6, 'DisplayName', '$\tilde{\tilde{\zeta}}_{\mathrm{A}}[l]$ (2-stage DASIC)');
plot(l_axis, 20*log10(abs(Xi_AA)),    'k-o',  'LineWidth', line_wd, 'MarkerSize', 6, 'DisplayName', '$\zeta_{\mathrm{A}}[l]$'); hold on;
plot(l_axis, 20*log10(abs(v_tilde)),  'b-s', 'LineWidth', line_wd, 'MarkerSize', 6, 'DisplayName', '$\tilde{\zeta}_{\mathrm{A}}[l]$');
plot(l_axis, 20*log10(abs(v_ttilde)), 'r-^', 'LineWidth', line_wd, 'MarkerSize', 6, 'DisplayName', '$\tilde{\tilde{\zeta}}_{\mathrm{A}}[l]$');

xlabel('Data Index $l$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
ylabel('ISR [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
xlim([1 L]);
ylim(y_lim_range);
grid on;
legend('Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 24, 'Location', 'best');
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', font_sz, 'LineWidth', 1.2);
exportgraphics(fig4, 'SI_ISR_Combined.eps', 'ContentType', 'vector');

% --- 検証用プロット: 定義式 vs 受信SI信号に対する実DASIC処理 ---
fig_check = figure('Color', 'w', 'Position', [250, 250, 1100, 450]);
subplot(1, 2, 1);
plot(l_axis, 20*log10(abs(v_tilde)), 'b-', 'LineWidth', 1.8); hold on;
plot(l_axis, 20*log10(abs(v_tilde_sim)), 'ro', 'MarkerSize', 6, 'LineWidth', 1.2);
title('1-stage: Formula vs. Actual DASIC');
xlabel('Data Index $l$', 'Interpreter', 'latex'); ylabel('$20\log_{10}|\tilde{v}_{\mathrm{A}}[l]|$', 'Interpreter', 'latex');
legend('Formula', 'Actual DASIC (Sim)', 'Location', 'best');
xlim([1 L]); ylim(y_lim_range); grid on;

subplot(1, 2, 2);
plot(l_axis, 20*log10(abs(v_ttilde)), 'b-', 'LineWidth', 1.8); hold on;
plot(l_axis, 20*log10(abs(v_ttilde_sim)), 'ro', 'MarkerSize', 6, 'LineWidth', 1.2);
title('2-stage: Formula vs. Actual DASIC');
xlabel('Data Index $l$', 'Interpreter', 'latex'); ylabel('$20\log_{10}|\tilde{\tilde{v}}_{\mathrm{A}}[l]|$', 'Interpreter', 'latex');
legend('Formula', 'Actual DASIC (Sim)', 'Location', 'best');
xlim([1 L]); ylim(y_lim_range); grid on;