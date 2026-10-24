%% CSIとNullサブキャリア両者調整可能ver
clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     =0:2:18;         % 信号対雑音電力比
SIM.w_loop  = 5;            
SIM.nsamp   = 3*10^SIM.w_loop;  
SIM.err_max = 300;  
SIM.SIR     = -10;           % 希望信号対干渉電力比
SIM.rho     = -3;
SIM.Nrho    = -3;
SIM.nsym    = 64;           % シンボル数         
SIM.ndata = SIM.nsym;
SIM.over = 2;
SIM.delayA=1;%遅延波の離散チップ遅延時間(SIM.overと同じ値にすると1シンボル遅延になる)
SIM.delayB=2;
SIM.int=1; %インタリーバ 1:あり,2:なし
SIM.AA=2;%AA間パス数
SIM.AB=16;%AB間パス数
SIM.LLRclip = 10000000000;
G.Q = 4; %変調次数
G.ml=log2(G.Q);
SIM.AAWinWid = 16; %SIチャネル推定時の窓関数の窓幅(SIM.overに注意すること、over1で16なら16シンボル遅延まで、over2で16なら8シンボル遅延までの窓幅になる。)
SIM.ABWinWid = 32; %所望チャネル推定時の窓関数の窓幅
SIM.mode = 'xb_est2';    %チャネル推定のためのDASICの段数 (Perfect,DASIC1,DASIC2,est,xb_est,xb_est1,xb_est2) ※DASICはチャネル推定なしでDASICだけによるSIC,estは所望推定なし,xb_estはあり(DASICなし,1段,2段)
SIM.detmode='BCJR';     %BCJR,MLD(使わない)
SIM.CSI ='false';    %所望信号チャネルの推定ありorなし(完璧) 'true' or 'false' 
SIM.PilotMode='simul'; %パイロットシンボルの送信タイミング (alterは交互(コード上ではSIなしになる) simulはSIと所望信号同時、基本的にはsimul)
SIM.modeAB = 'SIC'; %ABチャネル推定用のモード選択 (WoSIC,SIC)
SIM.null ='true';
 
num_split = 5; % 1つのSNRあたり5分割する（10点×5分割 = 計50タスク）

% 分割に合わせて最大試行回数と目標エラー数を減らす
SIM.nsamp = ceil(SIM.nsamp / num_split);      % 30万回 → 6万回
SIM.err_max = ceil(SIM.err_max / num_split);  % 300エラー → 60エラーで打ち切り

% SNRリストを複製 (0,2..18, 0,2..18 を5回繰り返す)
SNR_list = repmat(SIM.SNR, 1, num_split); 

% 結果格納用配列
noe_raw = zeros(size(SNR_list));
nod_raw = zeros(size(SNR_list));

%%%%%%%%%%%%%%
%%%% Task %%%%
%%%%%%%%%%%%%% 
parfor idx = 1:length(SNR_list)
    % 分割された軽いタスクを独立して実行
    RES = main_task_nullsub_DASIC(SNR_list(idx), idx, SIM, G);
    
    % タスクごとのエラー数と総ビット数を記録
    noe_raw(idx) = RES.noe;
    nod_raw(idx) = RES.nod;
end
elapsedTime = etime(clock, startTime);         
fprintf('Elapsed time is %2.1f seconds\n', elapsedTime); 

% ==========================================
% 結果の集計 (分割したタスクをSNRごとに合算)
% ==========================================
BER = zeros(size(SIM.SNR)); 
for i = 1:length(SIM.SNR)
    target_snr = SIM.SNR(i);
    % このSNRと同じ条件で実行したタスクのインデックスを取得
    idx_match = (SNR_list == target_snr);
    
    % エラーと総ビットを合算してBERを計算
    total_noe = sum(noe_raw(idx_match));
    total_nod = sum(nod_raw(idx_match));
    BER(i) = total_noe / total_nod;
end

plot_BER                   % BER特性図を作成