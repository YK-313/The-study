clear; close all; clc;

% ==========================================
% 1. 設定パネル
% ==========================================
% 指定されたSIRのパターン (3種類)
sir_values = [-10, -30, -50];                  

% 手法ごとのファイル名のプレフィックス (6手法)
methods = {'1DASIC', '2DASIC', 'WoXbEst', '1Est', '2Est'};

% 凡例表示用の手法名
method_names = {'Type 1 (1-stage)', 'Type 1 (2-stage)', 'Naive CSI', 'Type 2 (1-stage)', 'Type 2 (2-stage)'};

% 色とマーカーの設定
colors = {'b', 'r', '#77AC30', 'c', '#D95319'}; % 手法ごとの色
markers = {'o', '^', 'd',};                           % SIRごとのマーカー (3種類に合わせて短縮)

% ==========================================
% 2. .figファイルからのデータ抽出 (メインデータ)
% ==========================================
dataX = cell(length(methods), length(sir_values));
dataY = cell(length(methods), length(sir_values));

for m = 1:length(methods)
    for s = 1:length(sir_values)
        % 読み込むファイル名を生成 (例: 1DASICSir-10.fig)
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
        else
            fprintf('警告: %s が見つかりません。\n', filename);
        end
    end
end

% ==========================================
% 3. プロット処理
% ==========================================
figure('Position', [1, 71, 813, 725]);
set(gca, 'YScale', 'log'); % 強制的に対数スケールに設定
hold on;

% メインデータのプロット
for m = 1:length(methods)
    for s = 1:length(sir_values)
        if ~isempty(dataX{m,s})
            x_plot = dataX{m,s};
            y_plot = dataY{m,s};
            
            % 【重要】BERが0の値をNaNに置き換えて対数グラフの破綻を防ぐ
            y_plot(y_plot == 0) = NaN; 
            
            semilogy(x_plot, y_plot, ...
                'Color', colors{m}, 'Marker', markers{s}, ...
                'LineStyle', '-', 'LineWidth', 2, ...
                'MarkerSize', 15, 'MarkerFaceColor', 'none'); 
        end
    end
end

% ==========================================
% 4. グラフの装飾と凡例設定
% ==========================================
grid on;

% X軸の範囲は、窓幅の最大値に合わせて適宜変更してください（ここでは最大16を想定）
axis([0 16 10^-5 1]); 

set(gca, 'LineWidth', 2, 'FontSize', 35, 'FontName', 'Times New Roman', ...
    'YScale', 'log', ... 
    'XTick', 0:2:16, 'YTick', 10.^(-5:1:0));

% 横軸窓幅をWとして表記
xlabel('Window size $W$', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 35);
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
    h_dummy = plot(NaN, NaN, 'k', 'Marker', markers{s}, ...
        'LineStyle', 'none', 'MarkerSize', 15, ...
        'MarkerFaceColor', 'none', 'LineWidth', 1.5); 
    
    h_legend_items = [h_legend_items, h_dummy];
    legend_strs{end+1} = sprintf('$\\eta=%d$ dB', sir_values(s));
end

lgd = legend(h_legend_items, legend_strs, 'FontSize', 30, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
lgd.NumColumns = 1; % 表示列指定
lgd.Location = 'eastoutside';

% プロット領域を論文で推奨される「正方形」に強制固定
axis square; 

hold off;