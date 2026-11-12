%========================================================================
% 既存の .fig ファイル (DFT, IFFT, MDFT) からデータを抽出・結合するコード
%========================================================================

clear; clc; close all;

%% 1. DFTデータの抽出
fprintf('1. DFTのデータを抽出中...\n');
fig_dft = openfig('1EstSir-40Dft.fig', 'invisible');
line_dft = findall(fig_dft, 'Type', 'Line'); 
x_dft = get(line_dft(1), 'XData');
y_dft = get(line_dft(1), 'YData');
close(fig_dft);
fprintf(' -> DFTデータ抽出成功 (データ数: %d)\n', length(x_dft));

%% 2. IFFTデータの抽出
fprintf('2. IFFTのデータを抽出中...\n');
fig_ifft = openfig('1EstSir-40Ifft.fig', 'invisible');
line_ifft = findall(fig_ifft, 'Type', 'Line');
x_ifft = get(line_ifft(1), 'XData');
y_ifft = get(line_ifft(1), 'YData');
close(fig_ifft);
fprintf(' -> IFFTデータ抽出成功 (データ数: %d)\n', length(x_ifft));

%% 3. MDFTデータの抽出
fprintf('3. MDFTのデータを抽出中...\n');
fig_mdft = openfig('1EstSir-40MDft.fig', 'invisible');
line_mdft = findall(fig_mdft, 'Type', 'Line');
x_mdft = get(line_mdft(1), 'XData');
y_mdft = get(line_mdft(1), 'YData');
close(fig_mdft);
fprintf(' -> MDFTデータ抽出成功 (データ数: %d)\n', length(x_mdft));

%% 4. 新しい図(Figure)への統合と再描画
fprintf('4. グラフを描画中...\n');
fig_main = figure('Name', 'Comparison: IFFT vs DFT vs MDFT', 'Visible', 'on');
clf(fig_main);

LW = 2.0;                    
FN = 'Times New Roman';      
FS = 18;                     
MS = 8;                      

% プロットの実行 (視認性のため色とマーカーを変更)
h1 = loglog(x_ifft, y_ifft, '-s', 'Color', '#D95319', 'MarkerFaceColor', '#D95319', 'LineWidth', LW, 'MarkerSize', MS);
hold on;
h2 = loglog(x_dft, y_dft, '-o', 'Color', '#0072BD', 'MarkerFaceColor', '#0072BD', 'LineWidth', LW, 'MarkerSize', MS);
h3 = loglog(x_mdft, y_mdft, '-^', 'Color', '#7E2F8E', 'MarkerFaceColor', '#7E2F8E', 'LineWidth', LW, 'MarkerSize', MS);

% グラフの装飾
grid on;
xlabel('Delay time [\mus] (Log Scale)', 'FontName', FN, 'FontSize', FS);
ylabel('BER', 'FontName', FN, 'FontSize', FS);

axis([0.25 max(x_dft) 10^(-5) 10^(0)]);
set(gca, 'Linewidth', LW, 'FontName', FN, 'FontSize', FS, 'ytick', 10.^[-5:0], 'PlotBoxAspectRatio', [1 1 1]);

% 凡例の設定 (日本語が含まれるためFontNameはデフォルトに任せるか、指定外にする)
legend([h1, h2, h3], ...
       {'IFFT (帯域外ゼロパディング処理)', ...
        'DFT (従来の処理方法)', ...
        'MDFT (論文通りの処理)'}, ...
       'Location', 'southwest', 'FontSize', 14);

fprintf('完了しました！\n');