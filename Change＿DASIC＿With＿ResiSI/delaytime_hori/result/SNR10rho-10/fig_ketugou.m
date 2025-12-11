clear
clc
% 1. .figファイルを開く
xData=[];
yData=[];
FIG=["AutoSir-100f.fig","AutoSir-100b.fig","AutoSir-90f.fig","AutoSir-90b.fig","AutoSir-80f.fig","AutoSir-80b.fig","AutoSir-70f.fig","AutoSir-70b.fig","AutoSir-60f.fig","AutoSir-60b.fig"];
for ii= 1:length(FIG)/2
fig1 = openfig(FIG(ii*2-1), 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:2:length(lines)
    xDataf(ii,:) = get(lines(i), 'XData'); % x軸のデータを取得
    yDataf(ii,:) = get(lines(i), 'YData'); % y軸のデータを取得
    %{
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xDataf);
    disp('Y Data:');
    disp(yDataf);
    %}
end
% 4. フィギュアを閉じる
close(fig1);
% 1. .figファイルを開く
fig2 = openfig(FIG(ii*2), 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines2 = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xDatab(ii,:) = get(lines2(i), 'XData'); % x軸のデータを取得
    yDatab(ii,:) = get(lines2(i), 'YData'); % y軸のデータを取得
    
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xDatab);
    disp('Y Data:');
    disp(yDatab);
end
% 4. フィギュアを閉じる
close(fig2);
xData(ii,:)=[xDataf(ii,:) xDatab(ii,2:end)];
yData(ii,:)=[yDataf(ii,:) yDatab(ii,2:end)];
end
xData1=xData(1,:);
yData1=yData(1,:);
xData2=xData(2,:);
yData2=yData(2,:);
xData3=xData(3,:);
yData3=yData(3,:);
xData4=xData(4,:);
yData4=yData(4,:);
xData5=xData(5,:);
yData5=yData(5,:);
  
figure (1)
figure('Position', [1, 71, 813, 725]);
l(1) = loglog(xData1, yData1, 'ro-');
hold on
l(2) = loglog(xData2, yData2, 'bsquare-');
l(3) = loglog(xData3, yData3, "Marker", "diamond", "Color","#EDB120");
l(4) = loglog(xData4, yData4, "Marker", "^", "Color", "#77AC30");
l(5) = loglog(xData5, yData5, 'k<-');
%l(6) = semilogy(xData6, yData6, 'k*-');
%l(7) = semilogy(xData7, yData7, 'ypentagram-');
grid on;
legend ('$\eta=-100$ dB' ,'$\eta=-90$ dB' ,'$\eta=-80$ dB' ,'$\eta=-70$ dB','$\eta=-60$ dB','FontSize', 25,'FontName', 'Times New Roman','Interpreter','latex' )
lb(1) = xlabel('Delay time [μs]');
lb(2) = ylabel('BER');
set(l(1), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(2), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(3), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(4), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(5), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
%set(l(6), 'linewidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', 'w');
%set(l(7), 'linewidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', 'w');
set(gca, 'linewidth', 2, 'FontSize', 35, 'FontName', 'Times New Roman', ....
    'yTick', 10.^(-5:1:1));
set(lb, 'FontSize', 35, 'FontName', 'Times New Roman');
axis([0.01 0.5 10^-5 1]);