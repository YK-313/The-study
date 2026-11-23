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

% データサブキャリアのインデックス (L = 56)
% Null: DC(1), Guard(30,31,32,33,34,35,36) を除外
data_idx = [2:29, 37:64];
L = length(data_idx);

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Channel & Signal %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% 1. SIチャネル (CIR) の生成
rng(1); % 再現性のためのシード固定（任意）
phase_AA = exp(1i * 2 * pi * rand(SIM.AA, 1));

switch SIM.sir_mode
    case 'manual'
        % 各パスの電力を直接dB指定 (例: [30, 27] dB -> 実効SIRは約 -31.8 dB)
        amp_AA = 10.^(SIM.tap_pwr_dB / 20);
        
    case 'exact_sir'
        % 総電力が 10^(-SIM.SIR/10)、隣接パス比が SIM.rho になるよう厳密に正規化
        % (SIR = -30 dB, rho = -3 dB のとき、約 [28.24, 25.24] dB)
        rho_lin = 10^(SIM.rho / 10);
        pwr_rel = rho_lin .^ (0 : SIM.AA - 1).';
        pwr_AA  = (pwr_rel / sum(pwr_rel)) * 10^(-SIM.SIR / 10);
        amp_AA  = sqrt(pwr_AA);
        
    otherwise
        error('SIM.sir_mode must be ''manual'' or ''exact_sir''.');
end

delay_profile_AA_sir = amp_AA .* phase_AA;

% 確認用出力（必要に応じてコメントアウト可）
fprintf('Mode: %s | Tap powers [dB]: [%.2f, %.2f] | Actual SIR: %.2f dB\n', ...
    SIM.sir_mode, 20*log10(amp_AA(1)), 20*log10(amp_AA(2)), -10*log10(sum(amp_AA.^2)));

% インパルス応答ベクトル (時間領域, 長さ gamma*K)
tmp_profile_AA = zeros(fft_ptA, 1); 
tmp_profile_AA(1 : SIM.delayA : 1 + SIM.delayA * (SIM.AA - 1)) = delay_profile_AA_sir;

% 2. 周波数応答 (CFR) の作成
Xi_vec_AA_full = fft(tmp_profile_AA, fft_ptA); % 長さ gamma*K
Xi_AA = Xi_vec_AA_full(data_idx);              % データサブキャリア抽出: xi_AA[l] (長さ L=56)

% 3. 送信信号 x_A[l] の生成 (QPSK, |x_A[l]| = 1)
TX_b = randi([0 1], L * G.ml, 1);
TX_x = pskmod(TX_b, G.Q, pi/G.Q, 'InputType', 'bit');

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DASIC Process   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% 循環インデックスを用いた残留SIの計算 (l = 1, ..., L)
% 1-stage: \tilde{v}_A[l] = (xi_AA[l] - xi_AA[l-1]) * x_A[l]
v_tilde = (Xi_AA - circshift(Xi_AA, 1)) .* TX_x;

% 2-stage: \tilde{\tilde{v}}_A[l] = (xi_AA[l] - 2*xi_AA[l-1] + xi_AA[l-2]) * x_A[l]
v_ttilde = (Xi_AA - 2*circshift(Xi_AA, 1) + circshift(Xi_AA, 2)) .* TX_x;

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Visualization   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%
l_axis = 1:L;
font_sz = 24;
line_wd = 2.0;
marker_sz = 12;
y_lim_range = [-40 40]; % 比較しやすいように縦軸を統一

% --- Figure (a): 20log10|xi_AA[l]| ---
fig1 = figure('Color', 'w', 'Position', [100, 100, 650, 500]);
plot(l_axis, 20*log10(abs(Xi_AA)), 'b-', 'LineWidth', line_wd); hold on;
stem(l_axis, 20*log10(abs(Xi_AA)), 'b.', 'MarkerSize', marker_sz, 'BaseValue', y_lim_range(1));
xlabel('Data Index $l$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
ylabel('$20\log_{10}|\xi_{\mathrm{AA}}[l]|$ [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
xlim([1 L]); ylim(y_lim_range);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', font_sz, 'LineWidth', 1.2);
exportgraphics(fig1, 'SI_CFR.eps', 'ContentType', 'vector');

% --- Figure (b): 20log10|\tilde{v}_A[l]| ---
fig2 = figure('Color', 'w', 'Position', [150, 150, 650, 500]);
plot(l_axis, 20*log10(abs(v_tilde)), 'b-', 'LineWidth', line_wd); hold on;
stem(l_axis, 20*log10(abs(v_tilde)), 'b.', 'MarkerSize', marker_sz, 'BaseValue', y_lim_range(1));
xlabel('Data Index $l$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
ylabel('$20\log_{10}|\tilde{v}_{\mathrm{A}}[l]|$ [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
xlim([1 L]); ylim(y_lim_range);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', font_sz, 'LineWidth', 1.2);
exportgraphics(fig2, 'SI_Res1.eps', 'ContentType', 'vector');

% --- Figure (c): 20log10|\tilde{\tilde{v}}_A[l]| ---
fig3 = figure('Color', 'w', 'Position', [200, 200, 650, 500]);
plot(l_axis, 20*log10(abs(v_ttilde)), 'b-', 'LineWidth', line_wd); hold on;
stem(l_axis, 20*log10(abs(v_ttilde)), 'b.', 'MarkerSize', marker_sz, 'BaseValue', y_lim_range(1));
xlabel('Data Index $l$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
ylabel('$20\log_{10}|\widetilde{\tilde{v}}_{\mathrm{A}}[l]|$ [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', font_sz);
xlim([1 L]); ylim(y_lim_range);
grid on;
set(gca, 'TickLabelInterpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', font_sz, 'LineWidth', 1.2);
exportgraphics(fig3, 'SI_Res2.eps', 'ContentType', 'vector');