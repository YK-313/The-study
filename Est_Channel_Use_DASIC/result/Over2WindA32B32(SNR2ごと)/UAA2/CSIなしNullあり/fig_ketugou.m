clear; close all; clc;

% ==========================================
% 1. 設定パネル
% ==========================================
mode = 'SNR'; % 横軸の設定 ('SNR' または 'Eb/N0')
sir_values = [-10, -20, -30, -40];                  % 4つバージョン

% --- 【新規追加】出力グラフの選択フラグ ---
plot_type1_flag = true;  % (a) Type 1 のグラフを出力するか
plot_type2_flag = true;  % (b)/(c) Type 2 および比較手法 のグラフを出力するか

% --- Type 1 用設定 ---
methods_type1 = {'1DASIC', '2DASIC'};
names_type1 = {'Type 1 (1-stage)', 'Type 1 (2-stage)'};
colors_type1 = {'b', 'r'};

% --- Type 2 用設定 ---
methods_type2 = {'WoXbEst', 'XbEst', '1Est', '2Est'};
names_type2 = {'Naive CSI', 'Direct-MAP CSI', 'Type 2 (1-stage)', 'Type 2 (2-stage)'};
colors_type2 = {'#77AC30', 'm', 'c', '#D95319'};

markers = {'o', 's', '^', 'v', 'd', 'p', 'h'};       % SIRごとのマーカー

% ループ処理用に配列にまとめる
all_flags = [plot_type1_flag, plot_type2_flag];
all_methods = {methods_type1, methods_type2};
all_names = {names_type1, names_type2};
all_colors = {colors_type1, colors_type2};
fig_titles = {'(a) Type 1 Performance', '(b)/(c) Type 2 and Baseline Performance'};

% ==========================================
% 2. Perfect.fig の読み込み (共通)
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

% ループ処理用に配列にまとめる
all_flags = [plot_type1_flag, plot_type2_flag];
all_methods = {methods_type1, methods_type2};
all_names = {names_type1, names_type2};
all_colors = {colors_type1, colors_type2};
fig_titles = {'(a) Type 1 Performance', '(b)/(c) Type 2 and Baseline Performance'};

% --- 【新規追加】保存するファイル名 ---
out_filenames = {'Type1.eps', 'Type2.eps'};

% ==========================================
% 3. プロット実行ループ
% ==========================================
for fig_idx = 1:2
    % フラグが false ならこのグラフの作成をスキップ
    if ~all_flags(fig_idx)
        continue; 
    end
    
    methods = all_methods{fig_idx};
    method_names = all_names{fig_idx};
    colors = all_colors{fig_idx};
    
    % --- .figファイルからのデータ抽出 ---
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
    
    % --- プロット処理 ---
    figure('Name', fig_titles{fig_idx}, 'Position', [1, 71, 813, 725]);
    set(gca, 'YScale', 'log'); 
    hold on;
    
    % メインデータのプロット
    for m = 1:length(methods)
        for s = 1:length(sir_values)
            if ~isempty(dataX{m,s})
                x_plot = dataX{m,s};
                y_plot = dataY{m,s};
                
                if strcmp(mode, 'Eb/N0')
                    x_plot = x_plot - 3; 
                end
                
                y_plot(y_plot == 0) = NaN; 
                
                semilogy(x_plot, y_plot, ...
                    'Color', colors{m}, 'Marker', markers{s}, ...
                    'LineStyle', '-', 'LineWidth', 2, ...
                    'MarkerSize', 15, 'MarkerFaceColor', 'none'); 
            end
        end
    end
    
    % Perfect CSI のプロット
    if ~isempty(perfX)
        perfY_plot = perfY;
        perfY_plot(perfY_plot == 0) = NaN; 
        h_perf = semilogy(perfX, perfY_plot, 'k--', 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', 'none');
    end
    
    % --- グラフの装飾と凡例設定 ---
    grid on;
    axis([0 14 10^-5 1]);
    set(gca, 'LineWidth', 2, 'FontSize', 30, 'FontName', 'Times New Roman', ...
        'YScale', 'log', 'XTick', 0:2:14, 'YTick', 10.^(-5:1:0));
        
    if strcmp(mode ,'SNR')
        xlabel('SNR [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize',30);
    else
        xlabel('$E_\mathrm{b}/N_0$ [dB]', 'FontName', 'Times New Roman', 'Interpreter', 'latex', 'FontSize', 30);
    end
    ylabel('BER', 'FontName', 'Times New Roman', 'FontSize', 30);
    
    % 凡例（Legend）の作成
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
    
    % Perfect CSI の凡例
    if ~isempty(perfX)
        h_legend_items = [h_legend_items, h_perf];
        legend_strs{end+1} = 'Perfect SIC';
    end
    
    lgd = legend(h_legend_items, legend_strs, 'FontSize', 22, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
    lgd.NumColumns = 1; 
    %lgd.Location = 'eastoutside'; % 凡例の数が多いので枠外配置
    lgd.Location = 'southwest'; % 枠内の左下に配置
    axis square; 
    hold off;
    %exportgraphics(gcf, out_filenames{fig_idx}, 'ContentType', 'vector');
end