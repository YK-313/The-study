%% CSIとNullサブキャリア両者調整可能ver (遅延時間-BER特性用)
clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 10;            % 信号対雑音電力比 (今回は固定値)
SIM.w_loop  = 5;             
SIM.nsamp   = 3*10^SIM.w_loop;  
SIM.err_max = 300;  
SIM.SIR     = -10;           
SIM.rho     = -3;
SIM.Nrho    = -3;
SIM.nsym    = 64;                    
SIM.ndata   = SIM.nsym;

% IFFT方式で劣決定を回避するため、細かい遅延の再現用に十分なoverを設定可能
SIM.over    = 2;            

% CP長のまでの遅延をLogスケールで取得
max_delay_subc = 16;
max_delay_samp = max_delay_subc * SIM.over; 
% 対数軸上で均等になるように点を取得
SIM.delayA = unique(round(logspace(log10(1), log10(max_delay_samp), 10)));
%SIM.delayA = 1;
SIM.delayB = SIM.over;

SIM.int = 1;                 
SIM.AA  = 2;                 
SIM.AB  = 16;                
SIM.LLRclip = 10000000000;
G.Q = 4;                     
G.ml = log2(G.Q);

% ★窓関数方式の選択と設定
SIM.WindMode = 'BMDFT';       % 'DFT'(pinv方式) または 'IFFT'(ゼロパディング方式)
SIM.AAWinWid = 16;           % サブキャリア単位での窓幅 (基本はCP長)
SIM.ABWinWid = 16;           

SIM.mode = 'xb_est1';         % (Perfect, DASIC1, DASIC2, est, xb_est, xb_est1, xb_est2)
SIM.detmode = 'BCJR';        
SIM.CSI = 'false';           % 'true' or 'false'
SIM.PilotMode = 'simul';     
SIM.modeAB = 'SIC';          
SIM.null = 'false';
 
% ==========================================
% HPC用 タスク分割設定
% ==========================================
num_split = 5; % 1つの遅延時間あたり5分割する

% 分割に合わせて最大試行回数と目標エラー数を減らす
SIM.nsamp = ceil(SIM.nsamp / num_split);      
SIM.err_max = ceil(SIM.err_max / num_split);  

% delayAリストを複製 (10点×5分割 = 計50タスク)
delay_list = repmat(SIM.delayA, 1, num_split); 

% 結果格納用配列
noe_raw = zeros(size(delay_list));
nod_raw = zeros(size(delay_list));

%%%%%%%%%%%%%%
%%%% Task %%%%
%%%%%%%%%%%%%% 
for idx = 1:length(delay_list)
    % 複製された遅延リストを用いて軽量タスクを実行
    RES = main_task_nullsub_DASIC_delay(SIM.SNR, idx, SIM, G, delay_list(idx));
    
    % タスクごとのエラー数と総ビット数を記録
    noe_raw(idx) = RES.noe;
    nod_raw(idx) = RES.nod;
end
elapsedTime = etime(clock, startTime);         
fprintf('Elapsed time is %2.1f seconds\n', elapsedTime); 

% ==========================================
% 結果の集計 (分割したタスクを遅延時間ごとに合算)
% ==========================================
BER = zeros(size(SIM.delayA)); 
for i = 1:length(SIM.delayA)
    target_delay = SIM.delayA(i);
    % この遅延時間と同じ条件で実行したタスクのインデックスを取得
    idx_match = (delay_list == target_delay);
    
    % エラーと総ビットを合算してBERを計算
    total_noe = sum(noe_raw(idx_match));
    total_nod = sum(nod_raw(idx_match));
    BER(i) = total_noe / total_nod;
end

% グラフ描画用の実時間計算
symtime = 32 * 10^-6; 
delay_time = symtime / SIM.nsym / SIM.over .* SIM.delayA; 

plot_BER