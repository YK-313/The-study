%========================================================================
% 4つの手法 (DFT, MDFT, BMDFT, Wo) の .fig ファイルを統合するコード
%========================================================================

clear; clc; close all;

%% 1. DFTデータの抽出
fprintf('1. DFTのデータを抽出中...\n');
fig_dft = openfig('1DASICSir-10DFT.fig', 'invisible');
line_dft = findall(fig_dft, 'Type', 'Line');
x_dft = get(line_dft(1), 'XData');
y_dft = get(line_dft(1), 'YData');
close(fig_dft);
fprintf(' -> DFTデータ抽出成功 (データ数: %d)\n', length(x_dft));

%% 2. MDFTデータの抽出
fprintf('2. MDFTのデータを抽出中...\n');
fig_mdft = openfig('1DASICSir-10MDFT.fig', 'invisible');
line_mdft = findall(fig_mdft, 'Type', 'Line');
x_mdft = get(line_mdft(1), 'XData');
y_mdft = get(line_mdft(1), 'YData');
close(fig_mdft);
fprintf(' -> MDFTデータ抽出成功 (データ数: %d)\n', length(x_mdft));

%% 3. BMDFTデータの抽出
fprintf('3. BMDFTのデータを抽出中...\n');
fig_bmdft = openfig('1DASICSir-10BMDFT.fig', 'invisible');
line_bmdft = findall(fig_bmdft, 'Type', 'Line');
x_bmdft = get(line_bmdft(1), 'XData');
y_bmdft = get(line_bmdft(1), 'YData');
close(fig_bmdft);
fprintf(' -> BMDFTデータ抽出成功 (データ数: %d)\n', length(x_bmdft));

%% 4. Woデータの抽出
fprintf('4. Woのデータを抽出中...\n');
fig_wo = openfig('1DASICSir-10Wo.fig', 'invisible');
line_wo = findall(fig_wo, 'Type', 'Line');
x_wo = get(line_wo(1), 'XData');
y_wo = get(line_wo(1), 'YData');
close(fig_wo);
fprintf(' -> Woデータ抽出成功 (データ数: %d)\n', length(x_wo));

%% 5. 新しい図(Figure)への統合と再描画
fprintf('5. グラフを描画中...\n');
fig_main = figure('Name', 'Comparison: 4 Modes', 'Visible', 'on');
clf(fig_main);

LW = 2.0;                    
FN = 'Times New Roman';      
FS = 18;                     
MS = 8;                      

% SNR-BER特性を想定して semilogy でプロット
h1 = semilogy(x_dft, y_dft, '-o', 'Color', '#0072BD', 'MarkerFaceColor', '#0072BD', 'LineWidth', LW, 'MarkerSize', MS);
hold on;
h2 = semilogy(x_mdft, y_mdft, '-^', 'Color', '#7E2F8E', 'MarkerFaceColor', '#7E2F8E', 'LineWidth', LW, 'MarkerSize', MS);
h3 = semilogy(x_bmdft, y_bmdft, '-d', 'Color', '#77AC30', 'MarkerFaceColor', '#77AC30', 'LineWidth', LW, 'MarkerSize', MS);
h4 = semilogy(x_wo, y_wo, '-s', 'Color', '#A2142F', 'MarkerFaceColor', '#A2142F', 'LineWidth', LW, 'MarkerSize', MS);

% グラフの装飾
grid on;
xlabel('Average SNR [dB]', 'FontName', FN, 'FontSize', FS); % X軸ラベル（必要に応じて書き換えてください）
ylabel('BER', 'FontName', FN, 'FontSize', FS);

% 軸の調整
xlim([0, 14]); % 横軸の範囲を 0 から 14 に固定
ylim([10^(-5), 10^(0)]); % 縦軸の範囲を 10^-5 から 10^0 に固定
set(gca, 'YTick', 10.^[-5:0]); % y軸のメモリ指定
set(gca, 'Linewidth', LW, 'FontName', FN, 'FontSize', FS, 'PlotBoxAspectRatio', [1 1 1]);
% 凡例の設定
legend([h1, h2, h3, h4], ...
       {'DFT (従来コードの処理方法)', ...
        'MDFT (論文準拠の処理方法)', ...
        'BMDFT (論文準拠かつ両側に窓幅を設定)', ...
        'Wo (窓関数処理なし)'}, ...
       'Location', 'southwest', 'FontSize', 14);

fprintf('完了しました！\n');