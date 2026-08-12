clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 0:2:14;         % 信号対雑音電力比
SIM.w_loop  = 5;            
SIM.nsamp   = 10^SIM.w_loop;  
SIM.err_max = SIM.nsamp/10;  
SIM.SIR     = -100;           % 希望信号対干渉電力比
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
SIM.mode = 'xb_est';    %チャネル推定のためのDASICの段数 (Perfect,DASIC1,DASIC2,est,xb_est,xb_est1,xb_est2) ※DASICはチャネル推定なしでDASICだけによるSIC,estは所望推定なし,xb_estはあり(DASICなし,1段,2段)
SIM.detmode='BCJR';     %BCJR,MLD(使わない)
SIM.PilotMode='simul'; %パイロットシンボルの送信タイミング (alterは交互(コード上ではSIなしになる) simulはSIと所望信号同時)
SIM.modeAB = 'SIC'; %ABチャネル推定用のモード選択 (20260728現在はWoSIC,SICのみ)

 
BER = zeros(size(SIM.SNR)); 

%%%%%%%%%%%%%%
%%%% Task %%%%
%%%%%%%%%%%%%%% 
%for idx = 1:length(SIM.SNR)
parfor idx = 1:length(SIM.SNR)
    RES = main_task_f_DASIC(SIM.SNR(idx),idx,SIM,G);  
    BER(idx) = RES.BER;                       
end
elapsedTime = etime(clock, startTime);         % プログラムの実行時間を測定
fprintf('Elapsed time is %2.1f seconds\n', elapsedTime); 

plot_BER                   % BER特性図を作成
