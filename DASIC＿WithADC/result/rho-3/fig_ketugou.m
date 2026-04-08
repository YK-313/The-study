holimode = 'Eb/N0'; %横軸の設定(SNR,Eb/N0)
mode = 'Auto';  %プロットする特性の選択(DASIC1,DASIC2,Auto)

switch mode
    case 'DASIC1'
fig1 = openfig( "1Sir-70.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData1 = get(lines(i), 'XData'); % x軸のデータを取得
    yData1 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig1);

fig2 = openfig( "1Sir-60.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData2 = get(lines(i), 'XData'); % x軸のデータを取得
    yData2 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig2);

fig3 = openfig( "1Sir-50.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData3 = get(lines(i), 'XData'); % x軸のデータを取得
    yData3 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig3);

fig4 = openfig( "1Sir-40.fig", 'invisible'); % .figファイルを開く
ax = gca; 
lines = findobj(ax, 'Type', 'line'); 
for i = 1:length(lines)
    xData4 = get(lines(i), 'XData'); % x軸のデータを取得
    yData4 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig4);
    case 'DASIC2'
fig1 = openfig( "2Sir-80.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData1 = get(lines(i), 'XData'); % x軸のデータを取得
    yData1 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig1);

fig2 = openfig( "2Sir-70.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData2 = get(lines(i), 'XData'); % x軸のデータを取得
    yData2 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig2);

fig3 = openfig( "2Sir-60.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData3 = get(lines(i), 'XData'); % x軸のデータを取得
    yData3 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig3);

fig4 = openfig( "2Sir-50.fig", 'invisible'); % .figファイルを開く
ax = gca; 
lines = findobj(ax, 'Type', 'line'); 
for i = 1:length(lines)
    xData4 = get(lines(i), 'XData'); % x軸のデータを取得
    yData4 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig4);
fig5 = openfig( "2Sir-40.fig", 'invisible'); % .figファイルを開く
ax = gca; 
lines = findobj(ax, 'Type', 'line'); 
for i = 1:length(lines)
    xData5 = get(lines(i), 'XData'); % x軸のデータを取得
    yData5 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig5);
    case 'Auto'
        fig1 = openfig( "AutoSir-80.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData1 = get(lines(i), 'XData'); % x軸のデータを取得
    yData1 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig1);

fig2 = openfig( "AutoSir-70.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData2 = get(lines(i), 'XData'); % x軸のデータを取得
    yData2 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig2);

fig3 = openfig( "AutoSir-60.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得
for i = 1:length(lines)
    xData3 = get(lines(i), 'XData'); % x軸のデータを取得
    yData3 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig3);

fig4 = openfig( "AutoSir-50.fig", 'invisible'); % .figファイルを開く
ax = gca; 
lines = findobj(ax, 'Type', 'line'); 
for i = 1:length(lines)
    xData4 = get(lines(i), 'XData'); % x軸のデータを取得
    yData4 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig4);
fig5 = openfig( "AutoSir-40.fig", 'invisible'); % .figファイルを開く
ax = gca; 
lines = findobj(ax, 'Type', 'line'); 
for i = 1:length(lines)
    xData5 = get(lines(i), 'XData'); % x軸のデータを取得
    yData5 = get(lines(i), 'YData'); % y軸のデータを取得
end
close(fig5);

end
% 1. .figファイルを開く
fig10 = openfig( "HD.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xData10 = get(lines(i), 'XData'); % x軸のデータを取得
    yData10 = get(lines(i), 'YData'); % y軸のデータを取得
end
% 4. フィギュアを閉じる
close(fig10);

if strcmp(holimode, 'SNR')
figure('Position', [1, 71, 813, 725]);
switch mode
    case 'DASIC1'
l(1) = semilogy((xData1), yData1, 'r>-');
hold on
l(2) = semilogy(xData2, yData2, 'r<-');
l(3) = semilogy(xData3, yData3, 'ro-');
l(4) = semilogy(xData4, yData4, 'rsquare-');
 case 'DASIC2'
l(1) = semilogy((xData1), yData1, 'b>-');
hold on
l(2) = semilogy(xData2, yData2, 'b<-');
l(3) = semilogy(xData3, yData3, 'bo-');
l(4) = semilogy(xData4, yData4, 'bsquare-');
 case 'Auto'
l(1) = semilogy(xData1, yData1, "Marker", "diamond", "Color", "#77AC30");
l(2) = semilogy(xData1, yData1, "Marker", ">", "Color", "#77AC30");
hold on
l(3) = semilogy(xData2, yData2, "Marker", "<", "Color", "#77AC30");
l(4) = semilogy(xData3, yData3, "Marker", "o", "Color", "#77AC30");
l(5) = semilogy(xData4, yData4, "Marker", "square", "Color", "#77AC30");
end
l(10) = semilogy(xData10, yData10, 'k--');

else

figure('Position', [1, 71, 813, 725]);
switch mode
    case 'DASIC1'
l(1) = semilogy((xData1)-3, yData1, 'r>-');
hold on
l(2) = semilogy((xData2)-3, yData2, 'r<-');
l(3) = semilogy((xData3)-3, yData3, 'ro-');
l(4) = semilogy((xData4)-3, yData4, 'rsquare-');
 case 'DASIC2'
l(1) = semilogy((xData1)-3, yData1, 'b>-');
hold on
l(2) = semilogy((xData2)-3, yData2, 'b<-');
l(3) = semilogy((xData3)-3, yData3, 'bo-');
l(4) = semilogy((xData4)-3, yData4, 'bsquare-');
 case 'Auto'
l(1) = semilogy((xData1)-3, yData1, "Marker", "diamond", "Color", "r");  
hold on
l(2) = semilogy((xData2)-3, yData2, "Marker", ">", "Color", "b");
l(3) = semilogy((xData3)-3, yData3, "Marker", "<", "Color", "m");
l(4) = semilogy((xData4)-3, yData4, "Marker", "o", "Color", "#EDB120");
l(5) = semilogy((xData5)-3, yData5, "Marker", "square", "Color", "#77AC30");
end
l(10) = semilogy(xData10, yData10, 'k--');
end

grid on;
%legend ('$\eta=-70$ dB','$\eta=-60$ dB','$\eta=-50$ dB','$\eta=-40$ dB','HD','FontSize', 25,'FontName', 'Times New Roman','Interpreter','latex' );

lgd = legend('$\eta=-80$ dB','$\eta=-70$ dB','$\eta=-60$ dB','$\eta=-50$ dB','$\eta=-40$ dB','HD');
set(lgd, 'FontSize', 25, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
lgd.Position = [0.199508348115086,0.207864160750507,0.269177162789412,0.284007352941176];

if strcmp(holimode, 'SNR')
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
set(l(10), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(gca, 'linewidth', 2, 'FontSize', 35, 'FontName', 'Times New Roman', ....
    'xTick',0:2:11,'yTick', 10.^(-5:1:1));
set(lb, 'FontSize', 35, 'FontName', 'Times New Roman');
axis([0 11 10^-5 1]);