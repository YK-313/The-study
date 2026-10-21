clear; close all; clc;

% ==========================================
% 1. 設定パネル
% ==========================================
mode = 'SNR'; % 横軸の設定 ('SNR' または 'Eb/N0')

% ポイント5: SIRのパターンの切り替え (使用したい方のコメントを外す)
% sir_values = [0, -10, -20, -30, -40, -50, -60]; % 7つバージョン
sir_values = [0, -20, -40, -60];                  % 4つバージョン

% 手法ごとのファイル名のプレフィックス
methods = {'1DASIC', '2DASIC', 'WoXbEst', 'XbEst', '1Est', '2Est'};

% 凡例表示用の手法名
method_names = {'Type 1 (1-stage)', 'Type 1 (2-stage)', 'Naive CSI', ...
                'Direct-MAP CSI', 'Type 2 (1-stage)', 'Type 2 (2-stage)'};

% ポイント4: 色とマーカーの設定
colors = {'r', 'b', '#77AC30', 'm', 'c', '#D95319'}; % 手法ごとの色
markers = {'o', 's', '^', 'v', 'd', 'p', 'h'};       % SIRごとのマーカー

% ==========================================
% 2. .figファイルからのデータ抽出 (メインデータ)
% ==========================================
dataX = cell(length(methods), length(sir_values));
dataY = cell(length(methods), length(sir_values));

for m = 1:length(methods)
    for s = 1:length(sir_values)
        filename = sprintf('%sSir%d.fig', methods{m}, sir_values(s));
        if exist(filename, 'file')
            fig = openfig(filename, 'invisible');
            ax = gca(fig);
            lines = findobj(ax, 'Type', 'line');
            for i = 1:length(lines)
                dataX{m, s} = get(lines(i), 'XData');
                dataY{m, s} = get(lines(i), 'YData');
            end
            close(fig);
        end
    end
end

% ==========================================
% 3. Perfect.fig の読み込み (最後に実行)
% ==========================================
perfX = []; perfY = [];
if exist('Perfect.fig', 'file')
    figP = openfig('Perfect.fig', 'invisible');
    axP = gca(figP);
    linesP = findobj(axP, 'Type', 'line');
    for i = 1:length(linesP)
        perfX = get(linesP(i), 'XData');
        perfY = get(linesP(i), 'YData');
    end
    close(figP);
else
    warning('Perfect.fig が見つかりません。');
end

%% 

% ==========================================
% 4. プロット処理
% ==========================================
figure('Position', [1, 71, 813, 725]);

set(gca, 'YScale', 'log'); % <--- 【ここを追加】強制的に対数スケールに設定する

hold on;

% メインデータのプロット
for m = 1:length(methods)
    for s = 1:length(sir_values)
        if ~isempty(dataX{m,s})
            x_plot = dataX{m,s};
            y_plot = dataY{m,s};
            
            % Eb/N0モードの場合は3dB左シフト
            if strcmp(mode, 'Eb/N0')
                x_plot = x_plot - 3; 
            end
            
            % 【重要】BERが0の値をNaNに置き換えて対数グラフの破綻を防ぐ
            y_plot(y_plot == 0) = NaN; 
            
            semilogy(x_plot, y_plot, ...
                'Color', colors{m}, 'Marker', markers{s}, ...
                'LineStyle', '-', 'LineWidth', 2, ...
                'MarkerSize', 15, 'MarkerFaceColor', 'none'); % サイズを20から10に変更
        end
    end
end

% Perfect CSI のプロット
if ~isempty(perfX)
    perfY(perfY == 0) = NaN; % 0をNaNに置き換え
    h_perf = semilogy(perfX, perfY, 'k--', 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', 'none');
end

% ==========================================
% 5. グラフの装飾と凡例設定
% ==========================================
grid on;
axis([0 18 10^-5 1]);

% YScaleをここでも'log'に指定し、YTickを明示します
set(gca, 'LineWidth', 2, 'FontSize', 35, 'FontName', 'Times New Roman', ...
    'YScale', 'log', ... % <--- 【ここを追加】
    'XTick', 0:2:18, 'YTick', 10.^(-5:1:0));

if strcmp(mode ,'SNR')
    xlabel('SNR [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 35);
else
    xlabel('$E_\mathrm{b}/N_0$ [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 35);
end
ylabel('BER', 'FontName', 'Times New Roman', 'FontSize', 35);

% --- 凡例（Legend）の作成 ---
h_legend_items = [];
legend_strs = {};

% 手法の凡例
for m = 1:length(methods)
    h_dummy = plot(NaN, NaN, '-', 'Color', colors{m}, 'LineWidth', 2);
    h_legend_items = [h_legend_items, h_dummy];
    legend_strs{end+1} = method_names{m};
end

% SIRの凡例 (黒色のマーカーのみ)
for s = length(sir_values):-1:1
    % 'LineWidth', 2 (あるいは3) を追加してマーカーの線を太く・濃くします
    h_dummy = plot(NaN, NaN, 'k', 'Marker', markers{s}, ...
        'LineStyle', 'none', 'MarkerSize', 15, ...
        'MarkerFaceColor', 'none', 'LineWidth', 1.5); % <--- ここを追加！
    
    h_legend_items = [h_legend_items, h_dummy];
    legend_strs{end+1} = sprintf('$\\eta=%d$ dB', sir_values(s));
end

% Perfect CSI の凡例 (一番最後に追加)
if ~isempty(perfX)
    h_legend_items = [h_legend_items, h_perf];
    legend_strs{end+1} = 'Perfect SIC';
end

lgd = legend(h_legend_items, legend_strs, 'FontSize', 30, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
lgd.NumColumns = 1; % 表示列指定

% 凡例の配置（左下の空きスペースに配置。完全に外が良い場合は 'eastoutside' に変更）
%lgd.Location = 'southwest'; 
lgd.Location = 'eastoutside';

% プロット領域を論文で推奨される「正方形」に強制固定
axis square; 

hold off;