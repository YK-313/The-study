% 1. .figファイルを開く
fig1 = openfig( "AutoSir-60Rho-10.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xData1 = get(lines(i), 'XData'); % x軸のデータを取得
    yData1 = get(lines(i), 'YData'); % y軸のデータを取得
    
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xData1);
    disp('Y Data:');
    disp(yData1);
end
% 4. フィギュアを閉じる
close(fig1);

% 1. .figファイルを開く
fig2 = openfig( "AutoSir-60Rho-20.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xData2 = get(lines(i), 'XData'); % x軸のデータを取得
    yData2 = get(lines(i), 'YData'); % y軸のデータを取得
    
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xData2);
    disp('Y Data:');
    disp(yData2);
end
% 4. フィギュアを閉じる
close(fig2);

% 1. .figファイルを開く
fig3 = openfig( "AutoSir-60Rho-25.fig",'invisible'); % .figファイルを開く
ax = gca; % 現在IC_BER.fig',の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xData3 = get(lines(i), 'XData'); % x軸のデータを取得
    yData3 = get(lines(i), 'YData'); % y軸のデータを取得
    
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xData3);
    disp('Y Data:');
    disp(yData3);
end
% 4. フィギュアを閉じる
close(fig3);

% 1. .figファイルを開く
fig4 = openfig( "AutoSir-60Rho-30.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xData4 = get(lines(i), 'XData'); % x軸のデータを取得
    yData4 = get(lines(i), 'YData'); % y軸のデータを取得
    
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xData4);
    disp('Y Data:');
    disp(yData4);
end
% 4. フィギュアを閉じる
close(fig4);

% 1. .figファイルを開く
fig5 = openfig("AutoSir-60Rho-40.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xData5 = get(lines(i), 'XData'); % x軸のデータを取得
    yData5 = get(lines(i), 'YData'); % y軸のデータを取得
    
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xData5);
    disp('Y Data:');
    disp(yData5);
end
% 4. フィギュアを閉じる
close(fig5);
% 1. .figファイルを開く
fig6 = openfig( "ideal.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xData6 = get(lines(i), 'XData'); % x軸のデータを取得
    yData6 = get(lines(i), 'YData'); % y軸のデータを取得
    
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xData6);
    disp('Y Data:');
    disp(yData6);
end
% 4. フィギュアを閉じる
close(fig6);
%{
% 1. .figファイルを開く
fig7 = openfig( "QPSK_ECC_int_vitervi_path1-16.fig", 'invisible'); % .figファイルを開く
ax = gca; % 現在の軸を取得

% 2. プロットされたデータを抽出
lines = findobj(ax, 'Type', 'line'); % ラインオブジェクトを取得

% 3. 各ラインオブジェクトからデータを取得
for i = 1:length(lines)
    xData7 = get(lines(i), 'XData'); % x軸のデータを取得
    yData7 = get(lines(i), 'YData'); % y軸のデータを取得
    
    % データを表示する（必要に応じて保存や処理が可能）
    fprintf('Line %d:\n', i);
    disp('X Data:');
    disp(xData7);
    disp('Y Data:');
    disp(yData7);
end
% 4. フィギュアを閉じる
close(fig7);

%}
  figure (1)
l(1) = semilogy(xData1, yData1, 'ro-');
hold on
l(2) = semilogy(xData2, yData2, 'bsquare-');
l(3) = semilogy(xData3, yData3, 'ypentagram-');
l(4) = semilogy(xData4, yData4, "Marker", "diamond", "Color","#EDB120");
l(5) = semilogy(xData5, yData5, "Marker", "^", "Color", "#77AC30");
l(6) = semilogy(xData6, yData6, 'k--');
%l(7) = semilogy(xData7, yData7, 'k*-');
grid on;
legend ('$\rho_{(1)}=-10$ dB' ,'$\rho_{(1)}=-20$ dB' ,'$\rho_{(1)}=-25$ dB','$\rho_{(1)}=-30$ dB' ,'$\rho_{(1)}=-40$ dB','ideal','FontSize', 35,'FontName', 'Times New Roman','Interpreter','latex' )
lb(1) = xlabel('SNR [dB]');
lb(2) = ylabel('BER');
set(l(1), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(2), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(3), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(4), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(5), 'linewidth', 2, 'MarkerSize', 20, 'MarkerFaceColor', 'none');
set(l(6), 'linewidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', 'w');
%set(l(7), 'linewidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', 'w');
set(gca, 'linewidth', 2, 'FontSize', 40, 'FontName', 'Times New Roman', ....
    'xTick',0:2:14,'yTick', 10.^(-5:1:1));
set(lb, 'FontSize', 55, 'FontName', 'Times New Roman');
axis([0 14 10^-5 1]);