clear; clc; close all;

%% 1. パラメータ設定
N_loop   = 50000;
SNR_dB   = 10;     % 確認したいSNR [dB]
SIR_dB   = -50;    % SIR [dB]
rho_dB   = -3;     % SI遅延波電力比 [dB]
N0       = 10^(-SNR_dB / 10);

ndata    = 64;
over     = 2;
fft_pt   = ndata * over; % 128
delayA   = 1;
delayB   = 2;
num_AA   = 2;
num_AB   = 16;
Lp       = 16 * over + 1; % 33

% インデックス設定 (Nullあり)
data_idx         = [2:(ndata/2 - 3), (ndata/2 + 5):ndata];
freq_ordered_idx = [(ndata/2 + 5):ndata, 2:(ndata/2 - 3)];
num_subc         = length(data_idx); % 56
phys_idx         = [1:(ndata/2), (fft_pt - ndata/2 + 1):fft_pt].';
phys_ord_idx     = phys_idx(freq_ordered_idx);

% 不連続行の除外設定 (52行)
invalid_rows = [1, 2, (num_subc/2 + 1), (num_subc/2 + 2)];
valid_rows   = setdiff(1:num_subc, invalid_rows);
N_valid      = length(valid_rows); % 52

% Bのパイロット (S1G-LTF, 周波数順)
LTF_left  = [ 1,  1,  1,  1, -1, -1,  1,  1, -1,  1, -1,  1,  1,  1,  1,  1,  1, -1, -1,  1,  1, -1,  1, -1,  1,  1,  1,  1].';
LTF_right = [ 1, -1, -1,  1,  1, -1,  1, -1,  1, -1, -1, -1, -1, -1,  1,  1, -1, -1,  1, -1,  1, -1,  1,  1,  1,  1, -1, -1].';
xB_ltf_data = [LTF_left; LTF_right];
[~, inv_ord] = ismember(freq_ordered_idx, data_idx);
xB_ord = xB_ltf_data(inv_ord);

% 理論行列: 式(31) Omega_AB
F_norm   = fft(eye(fft_pt)) / sqrt(fft_pt);
F_p_ord  = F_norm(phys_ord_idx, 1:Lp);
Omega_AB_eq31 = (fft_pt / Lp) * (F_p_ord * F_p_ord');

% 集計用変数
R_xi_sim       = zeros(num_subc, num_subc);
R_eps_sim      = zeros(N_valid, N_valid);
sigma2_est_all = zeros(N_loop, 1);

%% 2. モンテカルロシミュレーション
for idx = 1:N_loop
    % --- チャネル生成 (AB) ---
    dp_AB = (randn(num_AB, 1) + 1i*randn(num_AB, 1)) / sqrt(2*num_AB);
    dp_AB_s = dp_AB ./ abs(dp_AB) / sqrt(num_AB);
    tmp_AB = zeros(fft_pt, 1);
    tmp_AB(1:delayB:delayB*num_AB) = dp_AB_s;
    Xi_AB_128 = fft(tmp_AB, fft_pt);
    xi_AB_ord = Xi_AB_128(phys_ord_idx);
    
    % --- チャネル生成 (AA) ---
    dp_AA = (randn(num_AA, 1) + 1i*randn(num_AA, 1)) / sqrt(2*num_AA);
    dp_AA_s = dp_AA ./ abs(dp_AA);
    rho = 10^(rho_dB / 10);
    dp_AA_rho = zeros(num_AA, 1);
    dp_AA_rho(1) = dp_AA_s(1) * sqrt(1 / (1 + rho));
    dp_AA_rho(2) = dp_AA_s(2) * sqrt(rho * abs(dp_AA_rho(1))^2);
    dp_AA_sir = dp_AA_rho * sqrt(10^(-SIR_dB / 10));
    tmp_AA = zeros(fft_pt, 1);
    tmp_AA(1:delayA:delayA*num_AA) = dp_AA_sir;
    Xi_AA_128 = fft(tmp_AA, fft_pt);
    xi_AA_ord = Xi_AA_128(phys_ord_idx);
    
    % --- 送信シンボル (AはランダムQPSK) と雑音 ---
    xA_ord = pskmod(randi([0 3], num_subc, 1), 4, pi/4);
    z_ord  = (randn(num_subc, 1) + 1i*randn(num_subc, 1)) * sqrt(N0 / 2);
    
    % --- 2段DASIC 差分行列 ---
    phi_A = xA_ord ./ circshift(xA_ord, 1);
    Diff_Op = eye(num_subc);
    for k = 1:num_subc
        k_prev = mod(k - 2, num_subc) + 1;
        Diff_Op(k, k_prev) = -phi_A(k);
    end
    
    % 誤差ベクトル (残留SI + 雑音)
    err_in = xi_AA_ord .* xA_ord + z_ord;
    eps_2  = Diff_Op * (Diff_Op * err_in);
    eps_pruned = eps_2(valid_rows);
    
    % 受信信号全体 (所望LTF + SI + 雑音) からの出力電力推定
    y_in = xi_AB_ord .* xB_ord + err_in;
    y_2  = Diff_Op * (Diff_Op * y_in);
    y_pruned = y_2(valid_rows);
    %sigma2_est_all(idx) = max(mean(abs(y_pruned).^2) - 6, 6 * N0);
    sigma2_est_all(idx) = mean(abs(y_pruned).^2) - 6;
    
    % 標本共分散の集計
    R_xi_sim  = R_xi_sim  + (xi_AB_ord * xi_AB_ord') / N_loop;
    R_eps_sim = R_eps_sim + (eps_pruned * eps_pruned') / N_loop;
end

%% 3. 3パターンの Psi_A 近似行列の作成
I2_theo = 16 * sin(pi * delayA / fft_pt)^4 * abs(dp_AA_sir(2))^2;

sigma2_theo = 6 * N0 + I2_theo;         % ① 理論値 (6*N0 + I2)
sigma2_n0   = 6 * N0;                   % ② 雑音のみ (6*N0)
sigma2_est_mean = mean(sigma2_est_all); % ③ 出力電力からの推定値 (平均)
sigma2_est_std  = std(sigma2_est_all);  % ③ の1パケットごとのばらつき (標準偏差)

Psi_theo = sigma2_theo * eye(N_valid);
Psi_n0   = sigma2_n0 * eye(N_valid);
Psi_est  = sigma2_est_mean * eye(N_valid);

%% 4. 数値評価の表示
fprintf('=== 式(31): Omega_AB の検証 ===\n');
fprintf('対角成分の平均 (実測) : %.4f\n', mean(real(diag(R_xi_sim))));
fprintf('対角成分の平均 (式31) : %.4f\n', mean(real(diag(Omega_AB_eq31))));
fprintf('相対誤差 (Frobenius)  : %.4f\n\n', norm(R_xi_sim - Omega_AB_eq31, 'fro') / norm(R_xi_sim, 'fro'));

fprintf('=== 式(32): Psi_A の検証 (SNR=%ddB, SIR=%ddB) ===\n', SNR_dB, SIR_dB);
fprintf('実測の対角成分平均         : %.4f\n', mean(real(diag(R_eps_sim))));
fprintf('① 理論値 (6*N0 + I2)       : %.4f -> 相対誤差: %.4f\n', sigma2_theo, norm(R_eps_sim - Psi_theo, 'fro') / norm(R_eps_sim, 'fro'));
fprintf('② 雑音のみ (6*N0)          : %.4f -> 相対誤差: %.4f\n', sigma2_n0,   norm(R_eps_sim - Psi_n0,   'fro') / norm(R_eps_sim, 'fro'));
fprintf('③ 出力電力推定 (平均±SD)  : %.4f (±%.4f) -> 平均での相対誤差: %.4f\n', ...
    sigma2_est_mean, sigma2_est_std, norm(R_eps_sim - Psi_est, 'fro') / norm(R_eps_sim, 'fro'));

%% 5. ヒートマップによる視覚的比較
figure('Position', [100 100 900 700]);

subplot(2,2,1); imagesc(abs(R_xi_sim)); colorbar; axis square;
title('実測 E\{\xi_{AB} \xi_{AB}^H\}');

subplot(2,2,2); imagesc(abs(Omega_AB_eq31)); colorbar; axis square;
title('式(31) \Omega_{AB} (近似)');

subplot(2,2,3); imagesc(abs(R_eps_sim)); colorbar; axis square;
title('実測 \Psi_A (x_A ランダム)');

subplot(2,2,4); imagesc(abs(Psi_theo)); colorbar; axis square;
title('式(32) \sigma^2 I (理論値)');