clear
clc
% 1. .figファイルを開く
xData=[];
yData=[];
FIG=["1Sir-50f.fig","1Sir-50b.fig","1Sir-40f.fig","1Sir-40b.fig","2Sir-50f.fig","2Sir-50b.fig","2Sir-40f.fig","2Sir-40b.fig","AutoSir-50f.fig","AutoSir-50b.fig","AutoSir-40f.fig","AutoSir-40b.fig",];
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
xData6=xData(6,:);
yData6=yData(6,:);
  
figure (1)
figure('Position', [1, 71, 813, 725]);
l(1) = loglog(xData1, yData1, 'ro-');
hold on
l(2) = loglog(xData2, yData2, 'rsquare-');
l(3) = loglog(xData3, yData3, 'bo-');
l(4) = loglog(xData4, yData4, 'bsquare-');
l(5) = loglog(xData5, yData5, "Marker", "o", "Color", "#77AC30");
l(6) = loglog(xData6, yData6, "Marker", "square", "Color", "#77AC30");

%l(7) = semilogy(xData7, yData7, 'ypentagram-');
grid on;
legend ('$\eta=-50$ dB (One)' ,'$\eta=-40$ dB (One)','$\eta=-50$ dB (Two)' ,'$\eta=-40$ dB (Two)','$\eta=-50$ dB (Adaptive)' ,'$\eta=-40$ dB (Adaptive)','FontSize', 25,'FontName', 'Times New Roman','Interpreter','latex' );
lb(1) = xlabel('Delay time [μs]');
lb(2) = ylabel('BER');
set(l(1), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(2), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(3), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(4), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(5), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(6), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
%set(l(7), 'linewidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', 'w');
set(gca, 'linewidth', 2, 'FontSize', 35, 'FontName', 'Times New Roman', ....
    'yTick', 10.^(-5:1:1));
set(lb, 'FontSize', 35, 'FontName', 'Times New Roman');
axis([0.04 0.5 10^-5 1]);