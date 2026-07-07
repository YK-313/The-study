mode = 'SNR'; %横軸の設定(SNR,Eb/N0)


fig1 = openfig( "2EstSir0.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData1 = get(lines(i), 'XData'); % x軸のデータを取得
    yData1 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig1);

fig2 = openfig( "2EstSir-20.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData2 = get(lines(i), 'XData'); % x軸のデータを取得
    yData2 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig2);

fig3 = openfig( "2EstSir-40.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData3 = get(lines(i), 'XData'); % x軸のデータを取得
    yData3 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig3);

fig4 = openfig( "2EstSir-60.fig", 'invisible'); % .figファイルを開く
ax = gca; 
lines = findobj(ax, 'Type', 'line'); 
for i = 1:length(lines)
    xData4 = get(lines(i), 'XData'); % x軸のデータを取得
    yData4 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig4);

fig5 = openfig( "2EstSir-80.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData5 = get(lines(i), 'XData'); % x軸のデータを取得
    yData5 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig5);

fig6 = openfig( "2EstSir-100.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData6 = get(lines(i), 'XData'); % x軸のデータを取得
    yData6 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig6);

% fig7 = openfig( "2DasicSir-30.fig", 'invisible'); % .figファイルを開く
% ax = gca; % 現在の軸を取得
% lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
% for i = 1:length(lines)
%     xData7 = get(lines(i), 'XData'); % x軸のデータを取得
%     yData7 = get(lines(i), 'YData'); % y軸のデータを取得
% end
% close(fig7);
% 
% fig8 = openfig( "2DasicSir-20.fig", 'invisible'); % .figファイルを開く
% ax = gca; 
% lines = findobj(ax, 'Type', 'line'); 
% for i = 1:length(lines)
%     xData8 = get(lines(i), 'XData'); % x軸のデータを取得
%     yData8 = get(lines(i), 'YData'); % y軸のデータを取得
% end
% close(fig8);
% 
% fig9 = openfig( "AutoSir-50.fig", 'invisible'); % .figファイルを開く
% ax = gca; % 現在の軸を取得
% lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
% for i = 1:length(lines)
%     xData9 = get(lines(i), 'XData'); % x軸のデータを取得
%     yData9 = get(lines(i), 'YData'); % y軸のデータを取得
% end
% close(fig9);
% 
% fig10 = openfig( "AutoSir-40.fig", 'invisible'); % .figファイルを開く
% ax = gca; % 現在の軸を取得
% lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
% for i = 1:length(lines)
%     xData10 = get(lines(i), 'XData'); % x軸のデータを取得
%     yData10 = get(lines(i), 'YData'); % y軸のデータを取得
% end
% close(fig10);
% 
% fig11 = openfig( "AutoSir-30.fig", 'invisible'); % .figファイルを開く
% ax = gca; % 現在の軸を取得
% lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
% for i = 1:length(lines)
%     xData11 = get(lines(i), 'XData'); % x軸のデータを取得
%     yData11 = get(lines(i), 'YData'); % y軸のデータを取得
% end
% close(fig11);
% 
% fig12 = openfig( "AutoSir-20.fig", 'invisible'); % .figファイルを開く
% ax = gca; 
% lines = findobj(ax, 'Type', 'line'); 
% for i = 1:length(lines)
%     xData12 = get(lines(i), 'XData'); % x軸のデータを取得
%     yData12 = get(lines(i), 'YData'); % y軸のデータを取得
% end
% close(fig12);
% 
% % 1. .figファイルを開く
% fig13 = openfig( "HD.fig", 'invisible'); % .figファイルを開く
% ax = gca; % 現在の軸を取得
% 
% % 2. プロットされたデータを抽出
% lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% % 3. 各ラインオブジェクトからデータを取得
% for i = 1:length(lines)
%     xData13 = get(lines(i), 'XData'); % x軸のデータを取得
%     yData13 = get(lines(i), 'YData'); % y軸のデータを取得
% 
%     % データを表示する（必要に応じて保存や処理が可能）
%     fprintf('Line %d:\n', i);
%     disp('X Data:');
%     disp(xData13);
%     disp('Y Data:');
%     disp(yData13);
% end
% % 4. フィギュアを閉じる
% close(fig13);

if strcmp(mode ,'SNR')
figure('Position', [1, 71, 813, 725]);
l(1) = semilogy((xData1), yData1, 'ro-');
hold on
l(2) = semilogy(xData2, yData2, 'rsquare-');
l(3) = semilogy(xData3, yData3, 'r^-');
l(4) = semilogy(xData4, yData4, 'rv-');
l(5) = semilogy(xData5, yData5, 'rd-');
l(6) = semilogy(xData6, yData6, 'rp-');

% l(5) = semilogy(xData5, yData5, 'bo-');
% l(6) = semilogy(xData6, yData6, 'bsquare-');
% l(7) = semilogy(xData7, yData7, 'b^-');
% l(8) = semilogy(xData8, yData8, 'bv-');
% 
% l(9) = semilogy(xData9, yData9, "Marker", "o", "Color", "#77AC30");
% l(10) = semilogy(xData10, yData10, "Marker", "square", "Color", "#77AC30");
% l(11) = semilogy(xData11, yData11, "Marker", "^", "Color", "#77AC30");
% l(12) = semilogy(xData12, yData12, "Marker", "v", "Color", "#77AC30");
% 
% l(13) = semilogy(xData13, yData13, 'k--');
else

figure('Position', [1, 71, 813, 725]);
l(1) = semilogy((xData1)-3, yData1, 'ro-');
hold on
l(2) = semilogy((xData2)-3, yData2, 'rsquare-');
l(3) = semilogy((xData3)-3, yData3, 'r^-');
l(4) = semilogy((xData4)-3, yData4, 'rv-');

l(5) = semilogy((xData5)-3, yData5, 'bo-');
l(6) = semilogy((xData6)-3, yData6, 'bsquare-');
l(7) = semilogy((xData7)-3, yData7, 'b^-');
l(8) = semilogy((xData8)-3, yData8, 'bv-');

l(9) = semilogy((xData9)-3, yData9, "Marker", "o", "Color", "#77AC30");
l(10) = semilogy((xData10)-3, yData10, "Marker", "square", "Color", "#77AC30");
l(11) = semilogy((xData11)-3, yData11, "Marker", "^", "Color", "#77AC30");
l(12) = semilogy((xData12)-3, yData12, "Marker", "v", "Color", "#77AC30");

l(13) = semilogy(xData13, yData13, 'k--');
end

grid on;
legend ('$\eta=0$ dB' ,'$\eta=-20$ dB' ,'$\eta=-40$ dB' ,'$\eta=-60$ dB','$\eta=-80$ dB' ,'$\eta=-100$ dB' ,'FontSize', 20,'FontName', 'Times New Roman','Interpreter','latex' );

if strcmp(mode ,'SNR')
lb(1) = xlabel('SNR [dB]','FontName','Times New Roman','Interpreter','latex');
else
lb(1) = xlabel('$E_\mathrm{b}/N_0$ [dB]','FontName','Times New Roman','Interpreter','latex');
end
lb(2) = ylabel('BER');
set(l(1), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(2), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(3), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(4), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(5), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(6), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
% set(l(7), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
% set(l(8), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
% set(l(9), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
% set(l(10), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
% set(l(11), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
% set(l(12), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
% set(l(13), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(gca, 'linewidth', 2, 'FontSize', 35, 'FontName', 'Times New Roman', ....
    'xTick',0:2:11,'yTick', 10.^(-5:1:1));
set(lb, 'FontSize', 35, 'FontName', 'Times New Roman');
axis([0 11 10^-5 1]);