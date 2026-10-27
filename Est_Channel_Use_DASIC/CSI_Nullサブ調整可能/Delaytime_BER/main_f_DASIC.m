%% CSIとNullサブキャリア両者調整可能ver (遅延時間-BER特性用)
clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 10;            % 信号対雑音電力比 (今回は固定値)
SIM.w_loop  = 3;             
SIM.nsamp   = 3*10^SIM.w_loop;  
SIM.err_max = 300;  
SIM.SIR     = -50;           
SIM.rho     = -3;
SIM.Nrho    = -3;
SIM.nsym    = 64;                    
SIM.ndata   = SIM.nsym;

% IFFT方式で劣決定を回避するため、細かい遅延の再現用に十分なoverを設定可能
SIM.over    = 64;            

% CP長のまでの遅延をLogスケールで取得
max_delay_subc = 16;
max_delay_samp = max_delay_subc * SIM.over; 
% 対数軸上で均等になるように点を取得
SIM.delayA = unique(round(logspace(log10(1), log10(max_delay_samp), 10)));
SIM.delayB = SIM.over;

SIM.int = 1;                 
SIM.AA  = 2;                 
SIM.AB  = 16;                
SIM.LLRclip = 10000000000;
G.Q = 4;                     
G.ml = log2(G.Q);

% ★窓関数方式の選択と設定
SIM.WindMode = 'IFFT';       % 'DFT'(pinv方式) または 'IFFT'(ゼロパディング方式)
SIM.AAWinWid = 16;           % サブキャリア単位での窓幅 (基本はCP長)
SIM.ABWinWid = 16;           

SIM.mode = 'DASIC1';         % (Perfect, DASIC1, DASIC2, est, xb_est, xb_est1, xb_est2)
SIM.detmode = 'BCJR';        
SIM.CSI = 'true';           % 'true' or 'false'
SIM.PilotMode = 'simul';     
SIM.modeAB = 'SIC';          
SIM.null = 'true';
 
BER = zeros(size(SIM.delayA)); 

% グラフ描画用の実時間計算
symtime = 32 * 10^-6; 
delay_time = symtime / SIM.nsym / SIM.over .* SIM.delayA; 

%%%%%%%%%%%%%%
%%%% Task %%%%
%%%%%%%%%%%%%%% 
parfor idx = 1:length(SIM.delayA)
    RES = main_task_nullsub_DASIC_delay(SIM.SNR, idx, SIM, G, SIM.delayA(idx));
    BER(idx) = RES.BER;                       
end
elapsedTime = etime(clock, startTime);         
fprintf('Elapsed time is %2.1f seconds\n', elapsedTime); 

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