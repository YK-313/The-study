% ==========================================
% グラフのプロット
% ==========================================
figure(1)
LW = 2.0;
FN = 'Times New Roman';
FS = 18;
MS = 8;

% 横軸をシンボル長に変換 (例: 32サンプル / 2 = 16シンボル)
win_symbols = SIM.AAWinWid_list / SIM.over;

% プロット
h = semilogy(win_symbols, BER, '-o');
hold on

set(h,'MarkerFaceColor','#A2142F','color','#A2142F');
grid on

lb(1) = xlabel('SI Channel Estimation Window Width [Symbols]');
lb(2) = ylabel('BER');

axis([min(win_symbols) max(win_symbols) 10^(-5) 10^0]);

set(gca,'Linewidth',LW,'FontName',FN,'FontSize',FS,...
    'ytick',10.^[-5:1:0], 'xTick', 0:2:max(win_symbols), ...
    'PlotBoxAspectRatio',[1 1 1]);

set(lb,'FontName',FN,'FontSize',FS);
set(h,'Linewidth',LW,'MarkerSize',MS);