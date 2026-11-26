%% CSIとNullサブキャリア両者調整可能ver
clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 10;            % 固定SNR (10dBに固定)
SIM.WinWid_list = [1 2 4 8 16]; % SI(AA)窓幅のリスト
SIM.w_loop  = 5;            
SIM.nsamp   = 3*10^SIM.w_loop;  
SIM.err_max = 300;  
SIM.SIR     = -10;           % 希望信号対干渉電力比
SIM.rho     = -3;
SIM.Nrho    = -3;
SIM.nsym    = 64;            % シンボル数         
SIM.ndata   = SIM.nsym;
SIM.over    = 2;
SIM.delayA  = 1; % 遅延波の離散チップ遅延時間(SIM.overと同じ値にすると1シンボル遅延になる)
SIM.delayB  = 2;
SIM.int     = 1; % インタリーバ 1:あり,2:なし
SIM.AA      = 2; % AA間パス数
SIM.AB      = 16; % AB間パス数
SIM.LLRclip = 10000000000;
G.Q         = 4; % 変調次数
G.ml        = log2(G.Q);
SIM.ABWinWid = 16; % 所望チャネル推定時の窓関数の窓幅
SIM.WindModeAB = 'MMSE';    % 'DFT'(pinv方式) または 'IFFT' または 'MDFT'(論文準拠) または 'BMDFT(漏れ込みに対する両側に窓関数)' または 'MMSE' または 'Wo'(窓関数処理なし)
SIM.WindModeAA = 'MMSE';     % 'DFT'(pinv方式) または 'IFFT' または 'MDFT'(論文準拠) または 'BMDFT(漏れ込みに対する両側に窓関数)' または 'MMSE' または 'Wo'(窓関数処理なし)
SIM.mode     = 'xb_est2';   % チャネル推定のためのDASICの段数 (Perfect,DASIC1,DASIC2,est,xb_est,xb_est1,xb_est2)
SIM.detmode  = 'BCJR';      % BCJR,MLD(使わない)
SIM.CSI      = 'false';      % 所望信号チャネルの推定ありorなし(完璧) 'true' or 'false' 
SIM.PilotSym = 'LTF';       % QPSKもしくはLTF
SIM.PilotMode = 'simul';    % パイロットシンボルの送信タイミング (alter, simul)
SIM.modeAB   = 'DASIC2';    % ABチャネル推定用のモード選択 (Perfect,WoSIC,SIC,DASIC1,DASIC2)
SIM.null     = 'true';

% ==========================================
% タスク分割処理 (並列計算の効率化)
% ==========================================
num_split = 5; % 1つの窓幅あたり5分割する

% 分割に合わせて最大試行回数と目標エラー数を減らす
SIM.nsamp = ceil(SIM.nsamp / num_split);      
SIM.err_max = ceil(SIM.err_max / num_split);  

% 窓幅リストを複製
Win_list = repmat(SIM.WinWid_list, 1, num_split); 

% 結果格納用配列
noe_raw = zeros(size(Win_list));
nod_raw = zeros(size(Win_list));

%%%%%%%%%%%%%%
%%%% Task %%%%
%%%%%%%%%%%%%% 
parfor idx = 1:length(Win_list)
    % 分割された軽いタスクを独立して実行
    RES = main_task_nullsub_DASIC_window(Win_list(idx), idx, SIM, G);
    
    % タスクごとのエラー数と総ビット数を記録
    noe_raw(idx) = RES.noe;
    nod_raw(idx) = RES.nod;
end
elapsedTime = etime(clock, startTime);         
fprintf('Elapsed time is %2.1f seconds\n', elapsedTime); 

% ==========================================
% 結果の集計 (分割したタスクを窓幅ごとに合算)
% ==========================================
BER = zeros(size(SIM.WinWid_list)); 
for i = 1:length(SIM.WinWid_list)
    target_win = SIM.WinWid_list(i);
    % この窓幅と同じ条件で実行したタスクのインデックスを取得
    idx_match = (Win_list == target_win);
    
    % エラーと総ビットを合算してBERを計算
    total_noe = sum(noe_raw(idx_match));
    total_nod = sum(nod_raw(idx_match));
    BER(i) = total_noe / total_nod;
end

plot_BER