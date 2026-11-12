%% === プロット処理 ===
figure(1)
LW = 2.0;
FN = 'Times New Roman';
FS = 18;
MS = 8;

% 横軸・縦軸ともに対数スケール
h = loglog(delay_time.*10^6, BER, '-o');
hold on
set(h, 'MarkerFaceColor', '#A2142F', 'color', '#A2142F');
grid on
lb(1) = xlabel('Delay time [μs] (Log Scale)');
lb(2) = ylabel('BER');

axis([min(delay_time.*10^6) max(delay_time.*10^6) 10^(-5) 10^(0)]);

set(gca, 'Linewidth', LW, 'FontName', FN, 'FontSize', FS, 'ytick', 10.^[-5:0], 'PlotBoxAspectRatio', [1 1 1]);
set(lb, 'FontName', FN, 'FontSize', FS);
set(h, 'Linewidth', LW, 'MarkerSize', MS);