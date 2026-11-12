%% CSIとNullサブキャリア両者調整可能ver (窓幅スイープ & タスク分割版)
clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR           = 10;           % SNRを固定（例：10dB）
SIM.AAWinWid_list = [2, 4, 8, 16, 32]; % 評価する窓幅(サンプル数)のリスト

SIM.w_loop  = 5;            
SIM.nsamp   = 3*10^SIM.w_loop;  
SIM.err_max = 300;  
SIM.SIR     = -10;           % 希望信号対干渉電力比
SIM.rho     = -3;
SIM.Nrho    = -3;
SIM.nsym    = 64;            % シンボル数         
SIM.ndata   = SIM.nsym;
SIM.over    = 2;
SIM.delayA  = 1; %遅延波の離散チップ遅延時間
SIM.delayB  = 2;
SIM.int     = 1; %インタリーバ 1:あり,2:なし
SIM.AA      = 2; %AA間パス数
SIM.AB      = 16;%AB間パス数
SIM.LLRclip = 10000000000;
G.Q = 4; %変調次数
G.ml=log2(G.Q);
SIM.ABWinWid = 32; %所望チャネル推定時の窓関数の窓幅
SIM.mode = 'DASIC1';    
SIM.detmode='BCJR';     
SIM.CSI ='false';    
SIM.PilotMode='simul'; 
SIM.modeAB = 'SIC'; 
SIM.null ='true';

% ==========================================
% タスク分割の設定
% ==========================================
num_split = 5; % 1つの窓幅あたり5分割する（5点×5分割 = 計25タスク）

% 分割に合わせて最大試行回数と目標エラー数を減らす
SIM.nsamp = ceil(SIM.nsamp / num_split);      % 30万回 → 6万回
SIM.err_max = ceil(SIM.err_max / num_split);  % 300エラー → 60エラーで打ち切り

% 窓幅リストを複製 (2,4,8,16,32 を5回繰り返す配列を作成)
WinWid_task_list = repmat(SIM.AAWinWid_list, 1, num_split); 

% 結果格納用配列
noe_raw = zeros(size(WinWid_task_list));
nod_raw = zeros(size(WinWid_task_list));
SIM.TotalPoints = length(WinWid_task_list);

%%%%%%%%%%%%%%
%%%% Task %%%%
%%%%%%%%%%%%%% 
parfor idx = 1:length(WinWid_task_list)
    % parfor内でSIM構造体を安全に扱うためのローカル変数
    SIM_local = SIM;
    
    % タスクごとに割り当てられた窓幅をセット
    SIM_local.AAWinWid = WinWid_task_list(idx);
    
    % 第1引数には固定のSNR(SIM_local.SNR)を渡す
    RES = main_task_nullsub_DASIC(SIM_local.SNR, idx, SIM_local, G);
    
    % タスクごとのエラー数と総ビット数を記録
    noe_raw(idx) = RES.noe;
    nod_raw(idx) = RES.nod;
end
elapsedTime = etime(clock, startTime);         
fprintf('Elapsed time is %2.1f seconds\n', elapsedTime); 

% ==========================================
% 結果の集計 (分割したタスクを窓幅ごとに合算)
% ==========================================
BER = zeros(size(SIM.AAWinWid_list)); 
for i = 1:length(SIM.AAWinWid_list)
    target_win = SIM.AAWinWid_list(i);
    % この窓幅と同じ条件で実行したタスクのインデックスを取得
    idx_match = (WinWid_task_list == target_win);
    
    % エラーと総ビットを合算してBERを計算
    total_noe = sum(noe_raw(idx_match));
    total_nod = sum(nod_raw(idx_match));
    BER(i) = total_noe / total_nod;
end

plot_BER                   % BER特性図を作成