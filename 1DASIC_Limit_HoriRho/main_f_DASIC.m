clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 8;         % 信号対雑音電力比
SIM.w_loop  = 4;            
SIM.nsamp   = 10^SIM.w_loop;  
SIM.err_max = SIM.nsamp/10;  
SIM.SIR     = -60;           % 希望信号対干渉電力比
SIM.rho     = -20:1:-15;
SIM.nsym    = 64;           % シンボル数         
SIM.ndata = SIM.nsym;
SIM.over = 2;
SIM.delayA=1;%遅延波の離散チップ遅延時間(SIM.overと同じ値にすると1シンボル遅延になる)
SIM.delayB=2;
SIM.int=1; %インタリーバ 1:あり,2:なし
SIM.AA=2;%AA間パス数
SIM.AB=16;%AB間パス数
G.Q = 4; %変調次数
G.ml=log2(G.Q);
SIM.mode = 'DASIC2';    %DASICの段数
SIM.detmode='BCJR';     %BCJR,MLD(使わない)
SIM.plot ='ResSi';     %Rho,ResSi 横軸を(rhoでプロットするか，残留SI平均電力で書くか

%%残留SIの平均電力を計算
        fft_ptA = SIM.over*SIM.ndata;
        delay_profile_AA = (randn(SIM.AA, length(SIM.rho)) + 1i * randn(SIM.AA, length(SIM.rho)))./sqrt(2 * SIM.AA);
        delay_profile_AB = (randn(SIM.AB, length(SIM.rho)) + 1i * randn(SIM.AB, length(SIM.rho)))./sqrt(2 * SIM.AB);
        delay_profile_AA_s = delay_profile_AA./abs(delay_profile_AA);
        delay_profile_AB_s =delay_profile_AB./abs(delay_profile_AB)./sqrt(length(delay_profile_AB)); %各パス等電力&P_b1に調整
        delay_profile_AA_rho=zeros(size(delay_profile_AA_s));
        rho = 10.^(SIM.rho/10); %3波目以降-5dB
        delay_profile_AA_rho(1,:) =delay_profile_AA_s(1,:).*sqrt(1./( 1 + rho) );
        delay_profile_AA_rho(2,:) =delay_profile_AA_s(2,:).*sqrt(10.^(SIM.rho/10).*abs(delay_profile_AA_rho(1,:)).^2);
        P_b=sum(abs(delay_profile_AB_s).^2);
        delay_profile_AA_sir=delay_profile_AA_rho.*sqrt(P_b*10^(-SIM.SIR/10));

SIM.ResSi= 2*abs(delay_profile_AA_sir(2,:)).^2.*(1-cos(2*pi/fft_ptA));
BER = zeros(size(SIM.rho)); 

%%%%%%%%%%%%%%
%%%% Task %%%%
%%%%%%%%%%%%%%%
SIM.nsamp   = 10^SIM.w_loop; 
%for idx = 1:length(SIM.rho)
parfor idx = 1:length(SIM.rho)
    RES = main_task_f_DASIC(SIM.SNR,idx,SIM,G,SIM.rho(idx));  
    BER(idx) = RES.BER;                       
end
elapsedTime = etime(clock, startTime);         % プログラムの実行時間を測定
fprintf('Elapsed time is %2.1f seconds\n', elapsedTime); 

switch(SIM.plot)
    case {'Rho'}
        plot_BER                   % BER特性図を作成
    case {'ResSi'}
        plot_BER_ResSi
end