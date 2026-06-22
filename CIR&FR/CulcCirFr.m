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
SIM.delayA  = 2;             % AA間の遅延間隔（大きくするとFRが激しく変化する）
SIM.AA      = 2;             % AA間パス数（1なら直接波のみ、増やすとマルチパス）
G.Q = 4;                     % QPSK
G.ml = log2(G.Q);
fft_ptA = SIM.over * SIM.ndata;
T_sym_us = 32; % 1シンボルの時間 [μs]
dt_us = T_sym_us / fft_ptA; % 1サンプルあたりの時間 [μs]
time_axis_us = (0:fft_ptA-1) * dt_us; % 横軸ベクトル (0 μs から 32 μsの少し手前まで)

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Channel & Signal %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% 1. AA間パスの生成 (CIRの作成)
num_of_paths_AA = SIM.AA;
delay_profile_AA = (randn(num_of_paths_AA, 1) + 1i * randn(num_of_paths_AA, 1)) ./ sqrt(2 * num_of_paths_AA);
delay_profile_AA_s = delay_profile_AA ./ abs(delay_profile_AA); % 位相のみ抽出

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

% SIRの考慮 (便宜上、希望信号電力を1としてスケーリング)
% 実際にはAB間の電力との兼ね合いですが、ここではSI成分単体の絶対値として計算
delay_profile_AA_sir = delay_profile_AA_rho * sqrt(10^(-SIM.SIR/10));

% インパルス応答ベクトル (時間領域) の作成
tmp_profile_AA = zeros(fft_ptA, 1); 
tmp_profile_AA(1 : SIM.delayA : SIM.delayA * num_of_paths_AA) = delay_profile_AA_sir;
H_circ_AA = [];
for iii = 1 : fft_ptA
    tmp_AA = circshift(tmp_profile_AA, iii - 1);
    H_circ_AA = [H_circ_AA tmp_AA];
end
% 巡回通信路行列をスパース行列へ
H_circ_AA = sparse(H_circ_AA);

% 2. 周波数応答 (FR) の作成
Xi_vec_AA = fft(tmp_profile_AA, fft_ptA);

% 3. 送信信号の生成 (DASIC評価用)
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

% 残留SI成分のみを計算 (RX_bAのみを用いる)
% 元のコード: RX.c(2:end) = RX.b(2:end) - phi.*RX.b(1:end-1)
RX_c_SI_only(2:SIM.ndata) = RX_bA(2:SIM.ndata) - phi .* RX_bA(1:SIM.ndata-1);
ResidualSI = Xi_vec_AA(2:end)-Xi_vec_AA(1:end-1);
ResidualSI2 = Xi_vec_AA(3:end)-2*Xi_vec_AA(2:end-1)+Xi_vec_AA(1:end-2);

%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Visualization   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

figure('Color', 'w', 'Position', [100, 100, 500, 800]);

% --- Plot 1: CIR (Channel Impulse Response) dB表記 & 物理時間軸版（修正版） ---
subplot(3,1,1);
% 1. 振幅を計算
amp_profile = abs(tmp_profile_AA);
% 2. 信号が存在するパス（ゼロでない要素）のインデックスを抽出
% （数値誤差を考慮して 1e-10 以上のものを有効なパスとみなす）
valid_idx = find(amp_profile > 1e-10); 
% 3. 存在するパスのみをdBに変換して stem でプロット
stem(time_axis_us(valid_idx), 20*log10(amp_profile(valid_idx)), ...
    'filled', 'LineWidth', 2, 'MarkerSize', 6);
title('(a) SI Channel Impulse Response');

% \mu (斜体) ではなく、直接文字の μ (立体) を入力します
xlabel('Time [μs]'); 
%xlabel({'Time [μs]', '', ['(a) SI Channel Impulse Response']});
ylabel('Magnitude [dB]');
ylim([0 55]); % Y軸の下限を適切に設定
xlim([0 0.5]); % X軸を1シンボル分に固定
%xlim([0 T_sym_us]); % X軸を1シンボル分に固定
grid on;
% フォントをTimes New Romanに変更 (メモリ、ラベル、タイトル全てに適用)
set(gca, 'FontName', 'Times New Roman');


% --- Plot 2: FR (Frequency Response) ---
subplot(3,1,2);
plot(0:fft_ptA-1, 20*log10(abs(Xi_vec_AA)), 'b-', 'LineWidth', 1.5);
hold on;
stem(0:fft_ptA-1, 20*log10(abs(Xi_vec_AA)), 'b.', 'MarkerSize', 10);
title('(b) SI Frequency Response');
%xlabel({'Subcarrier Index', '', '(b) SI Frequency Response'});
xlabel('Subcarrier Index');
ylabel('Magnitude [dB]');
xlim([0 127]); 
ylim([0 55]);
grid on;
% フォントをTimes New Romanに変更
set(gca, 'FontName', 'Times New Roman');


% --- Plot 3: Residual SI after DASIC ---
subplot(3,1,3);
plot(1:SIM.over*SIM.ndata-1, 20*log10(abs(ResidualSI(1:end))), 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
stem(1:SIM.over*SIM.ndata-1, 20*log10(abs(ResidualSI(1:end))), 'b.', 'MarkerSize', 10);
title('(c) Residual SI Power in Frequency Domain');
xlabel('Subcarrier Index');
%xlabel({'Subcarrier Index', '', '(c) Residual SI Power in Frequency Domain'});
ylabel('Magnitude [dB]');
xlim([1 127]); 
ylim([0 55]);
grid on;
% フォントをTimes New Romanに変更
set(gca, 'FontName', 'Times New Roman');

figure(2)
plot(1:SIM.over*SIM.ndata-1, 20*log10(abs(ResidualSI(1:end))), 'b-', 'LineWidth', 1.5);
hold on; % plotの上にstemを重ねるために必須
stem(1:SIM.over*SIM.ndata-1, 20*log10(abs(ResidualSI(1:end))), 'b.', 'MarkerSize', 12);
title('Residual SI Power in Frequency Domain (One-stage)', 'FontSize', 18); % タイトルをさらに大きく
xlabel('Subcarrier Index', 'FontSize', 16); % ラベルを大きく
ylabel('Magnitude [dB]', 'FontSize', 16);
xlim([1 127]); 
ylim([0 30]);
grid on;
% フォントをTimes New Romanに変更し、メモリ(軸の数字)のサイズを14に設定
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14);


figure(3)
plot(1:SIM.over*SIM.ndata-2, 20*log10(abs(ResidualSI2(1:end))), 'b-', 'LineWidth', 1.5);
hold on; % 同上
stem(1:SIM.over*SIM.ndata-2, 20*log10(abs(ResidualSI2(1:end))), 'b.', 'MarkerSize', 12);
title('Residual SI Power in Frequency Domain (Two-stage)', 'FontSize', 18);
xlabel('Subcarrier Index', 'FontSize', 16);
ylabel('Magnitude [dB]', 'FontSize', 16);
xlim([1 127]); 
ylim([0 30]);
grid on;
% 同様にフォントとメモリサイズを設定
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14);

figure(5)
subplot(2,1,1);
plot(0:fft_ptA-1, 20*log10(abs(Xi_vec_AA)), 'b-', 'LineWidth', 1.5);
hold on;
stem(0:fft_ptA-1, 20*log10(abs(Xi_vec_AA)), 'b.', 'MarkerSize', 10);
title('(a) SI Frequency Response');
%xlabel({'Subcarrier Index', '', '(b) SI Frequency Response'});
xlabel('Subcarrier Index');
ylabel('Magnitude [dB]');
xlim([0 127]); 
ylim([0 55]);
grid on;
% フォントをTimes New Romanに変更
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14);


% --- Plot 3: Residual SI after DASIC ---
subplot(2,1,2);
plot(1:SIM.over*SIM.ndata-1, 20*log10(abs(ResidualSI(1:end))), 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4);
stem(1:SIM.over*SIM.ndata-1, 20*log10(abs(ResidualSI(1:end))), 'b.', 'MarkerSize', 10);
title('(b) Residual SI Power in Frequency Domain');
xlabel('Subcarrier Index');
%xlabel({'Subcarrier Index', '', '(c) Residual SI Power in Frequency Domain'});
ylabel('Magnitude [dB]');
xlim([1 127]); 
ylim([0 55]);
grid on;
% フォントをTimes New Romanに変更
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14);

% 解析結果の表示
mean_si = mean(abs(RX_bA).^2);
mean_res = mean(abs(RX_c_SI_only(2:end)).^2);
fprintf('--- Simulation Results ---\n');
fprintf('Original SI Power: %.2f dB\n', 10*log10(mean_si));
fprintf('Residual SI Power: %.2f dB\n', 10*log10(mean_res));
fprintf('SI Cancellation Amount: %.2f dB\n', 10*log10(mean_si) - 10*log10(mean_res));