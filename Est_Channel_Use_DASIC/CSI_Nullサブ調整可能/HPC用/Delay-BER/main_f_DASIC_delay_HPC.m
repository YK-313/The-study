%% CSIとNullサブキャリア両者調整可能ver (遅延時間-BER特性 HPC大規模並列用)
clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 10;            % 今回はSNR固定
SIM.w_loop  = 5;             % HPC用なので総試行回数を大きく設定
SIM.nsamp   = 3*10^SIM.w_loop;  
SIM.err_max = 300;  
SIM.SIR     = -40;           
SIM.rho     = -3;
SIM.Nrho    = -3;
SIM.nsym    = 64;                    
SIM.ndata   = SIM.nsym;

% IFFT方式・微小遅延再現用のオーバーサンプリング倍率
SIM.over    = 64;            

% CP長までの遅延をLogスケールで取得
max_delay_subc = 16;
max_delay_samp = max_delay_subc * SIM.over; 
SIM.delayA = unique(round(logspace(log10(1), log10(max_delay_samp), 10)));
SIM.delayB = SIM.over;

SIM.int = 1;                 
SIM.AA  = 2;                 
SIM.AB  = 16;                
SIM.LLRclip = 10000000000;
G.Q = 4;                     
G.ml = log2(G.Q);

% 窓関数方式の選択と設定
SIM.WindMode = 'IFFT';       % 'DFT' または 'IFFT'
SIM.AAWinWid = 16;           
SIM.ABWinWid = 16;           

SIM.mode = 'DASIC2';         
SIM.detmode = 'BCJR';        
SIM.CSI = 'true';           
SIM.PilotMode = 'simul';     
SIM.modeAB = 'SIC';          
SIM.null = 'true';

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
parfor idx = 1:length(delay_list)
    % 複製された遅延リストを用いて軽量タスクを実行
    RES = main_task_nullsub_DASIC_delay_HPC(SIM.SNR, idx, SIM, G, delay_list(idx));
    
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

%% === プロット処理 ===
figure(1)
LW = 2.0;
FN = 'Times New Roman';
FS = 18;
MS = 8;

% 横軸・縦軸ともに対数スケール
h = loglog(delay_time.*10^6, BER, '-o');
hold on
set(h, 'MarkerFaceColor', '#A2142F', 'color', '#A2142F');
grid on
lb(1) = xlabel('Delay time [μs] (Log Scale)');
lb(2) = ylabel('BER');

axis([min(delay_time.*10^6) max(delay_time.*10^6) 10^(-5) 10^(0)]);

set(gca, 'Linewidth', LW, 'FontName', FN, 'FontSize', FS, 'ytick', 10.^[-5:0], 'PlotBoxAspectRatio', [1 1 1]);
set(lb, 'FontName', FN, 'FontSize', FS);
set(h, 'Linewidth', LW, 'MarkerSize', MS);