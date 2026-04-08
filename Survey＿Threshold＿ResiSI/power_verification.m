clear
clc
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
%% Simulation parameter
SIM.SNR     = 8;         % 信号対雑音電力比
SIM.w_loop  = 3;            
SIM.nsamp   = 10^SIM.w_loop;  
SIM.err_max = SIM.nsamp/10;  
SIM.SIR     = -30;           % 希望信号対干渉電力比
SIM.rho     = -3;        
SIM.Nrho    =-3;
SIM.ndata = 64; % シンボル数  
SIM.over = 2;
SIM.delayA=1;%遅延波の離散チップ遅延時間(SIM.overと同じ値にすると1シンボル遅延になる)
SIM.delayB=2;
SIM.int=1; %インタリーバ 1:あり,2:なし
SIM.AA=3;%AA間パス数
SIM.AB=16;%AB間パス数
G.Q = 4; %変調次数
G.ml=log2(G.Q);

%QPSK　BCJR MAP
%1段DASICによりチャネルを推定し，残留SIの通信路の大きさを閾値と比較して二段適用するか判断する．
CH.N0 = 10^(-SIM.SNR/10); %1シンボル間隔の雑音エネルギー密度
ERR.noe   = zeros(SIM.nsamp,1);    ERR.noe_p = zeros(SIM.nsamp,1);    
ERR.nod   = zeros(SIM.nsamp,1);    ERR.nod_p = zeros(SIM.nsamp,1);
num_of_paths_AA = SIM.AA; 
num_of_paths_AB = SIM.AB; 
CH.L=SIM.AB;
fft_ptA = SIM.over*SIM.ndata; 
fft_ptB = SIM.over*SIM.ndata; 
intrlv=SIM.int;
constellation = [0.7071 + 0.7071i, -0.7071 + 0.7071i, 0.7071 - 0.7071i, -0.7071 - 0.7071i];
alp2bit = de2bi(0:G.Q-1,'left-msb');
 %% トレリス作成 拘束長=7
    trellis = poly2trellis(7,[171 133]); %11ahで用いられるもの
    ConEnc = comm.ConvolutionalEncoder(trellis,'TerminationMethod','Terminated');
    APPDec = comm.APPDecoder(trellis,'Algorithm','True APP','TerminationMethod','Terminated');
    viterbidecoder = comm.ViterbiDecoder(trellis,'InputFormat','hard','TerminationMethod','Terminated');
    decUnquant = comm.ViterbiDecoder(trellis,'InputFormat','Unquantized','TracebackDepth',32,'TerminationMethod','Terminated');

for idx_loop = 1:SIM.nsamp
    TX.b    = randn(SIM.ndata-log2(trellis.numStates)-4,2)>0;%(A,B)情報ビット 【終端ビット分減らす(畳み込みの分とBCJRの分)】
   %畳み込み符号化
    TX.codedata(:,1) = step(ConEnc,TX.b(:,1)); % A 符号化
    TX.codedata(:,2) = step(ConEnc,TX.b(:,2)); % b 符号化
   %インタリーブ
if intrlv==1
    TX.codedata_in = round(TX.codedata);
    TX.codedata_in(:,1) = randintrlv(TX.codedata_in(:,1),1);
    TX.codedata_in(:,2) = randintrlv(TX.codedata_in(:,2),1);
else
    TX.codedata_in=TX.codedata;%インタリーバ無しの場合ここをつかう(32-34コメントアウト)
end
    TX.codedata_int(:,1)=[0;0;0;0;TX.codedata_in(:,1);0;0;0;0];%BCJRの終端ビット(前後0を4bit)追加
    TX.codedata_int(:,2)=[0;0;0;0;TX.codedata_in(:,2);0;0;0;0];

    


    %% 変調
    %AさんBさん変調 (QPSK)
    TX.x   = pskmod(double(TX.codedata_int),G.Q,pi/G.Q,InputType="bit"); 
    %% あとは既存のOFDMのプログラム(AB)にAAのものをコピペする形で作成するだけ
    %%送信信号を時間領域へ
    TX.sA = ifft(TX.x(:,1), fft_ptA).*sqrt(fft_ptA);
    TX.sB = ifft(TX.x(:,2), fft_ptB).*sqrt(fft_ptB);
     %% 時空間通信路行列

        %位相回転あり
        delay_profile_AA = (randn(num_of_paths_AA, 1) + 1i * randn(num_of_paths_AA, 1))./sqrt(2 * num_of_paths_AA);
        delay_profile_AB = (randn(num_of_paths_AB, 1) + 1i * randn(num_of_paths_AB, 1))./sqrt(2 * num_of_paths_AB);
        %delay_profile_AB=1;
        %位相回転なし
        %delay_profile_AA = ones(num_of_paths_AA, 1);
        %delay_profile_AB = ones(num_of_paths_AB, 1);
        
        %規格化
        delay_profile_AA_s = delay_profile_AA./abs(delay_profile_AA);
        delay_profile_AB_s =delay_profile_AB./abs(delay_profile_AB)./sqrt(length(delay_profile_AB)); %各パス等電力&P_b1に調整
       %電力比を導入
    if SIM.AA==1
        delay_profile_AA_rho=delay_profile_AA_s;%遅延波なし
    else
        delay_profile_AA_rho=zeros(size(delay_profile_AA_s));
        rho_sum=0;
            for rr = 2:SIM.AA
             rho = 10^( (SIM.rho+SIM.Nrho*(rr-2)) /10); %3波目以降-5dB
             rho_sum = rho_sum+rho;
            end
        delay_profile_AA_rho(1) =delay_profile_AA_s(1)*sqrt(1/( 1 + rho_sum ) );
         for dd=2:SIM.AA
                 delay_profile_AA_rho(dd) =delay_profile_AA_s(dd)*sqrt(10^( (SIM.rho+SIM.Nrho*(dd-2))/10)*abs(delay_profile_AA_rho(1))^2);
         end
    end
        
        P_a=sum(abs(delay_profile_AA_rho).^2);
        %SIR考慮
        P_b=sum(abs(delay_profile_AB_s).^2);
        
        delay_profile_AA_sir=delay_profile_AA_rho*sqrt(P_b*10^(-SIM.SIR/10));
        P_a_sir=sum(abs(delay_profile_AA_sir).^2);
        
    %% 巡回通信路行列
        %AB間
        H_circ_AB = [];
tmp_profile_AB = zeros(fft_ptB,1); 
tmp_profile_AB (1:SIM.delayB:SIM.delayB*num_of_paths_AB)= delay_profile_AB_s;
for iii = 1 : fft_ptB
    tmp_AB = circshift(tmp_profile_AB, iii - 1);
    H_circ_AB = [H_circ_AB tmp_AB];
end
        %AA間
        H_circ_AA = [];
tmp_profile_AA = zeros(fft_ptA,1); 
tmp_profile_AA (1:SIM.delayA:SIM.delayA*num_of_paths_AA)= delay_profile_AA_sir;
for iii = 1 : fft_ptA
    tmp_AA = circshift(tmp_profile_AA, iii - 1);
    H_circ_AA = [H_circ_AA tmp_AA];
end
% 巡回通信路行列をスパース行列へ
H_circ_AB = sparse(H_circ_AB);
H_circ_AA = sparse(H_circ_AA);

% 周波数領域通信路行列の作成
Xi_vec_AB = fft(tmp_profile_AB, fft_ptB);
Xi_mat_AB = diag(sparse(Xi_vec_AB));
Xi_vec_AA = fft(tmp_profile_AA, fft_ptA);
Xi_mat_AA = diag(sparse(Xi_vec_AA));

   %% Channel　
    %送信電力計算（TX電力）
    ERR.tx_pow(idx_loop) = mean([sum(abs(TX.sA).^2) sum(abs(TX.sB).^2)]);
    % 干渉チャネルと希望チャネルの適用（チャネル行列を使用）
    RX.s_AA=H_circ_AA*TX.sA;
    RX.s_AB=H_circ_AB*TX.sB;    
    % 雑音の生成
    CH.f = (randn(SIM.ndata, 1) + 1i * randn(SIM.ndata, 1)) * sqrt(CH.N0 / 2);
    CH.n =  ifft(CH.f, fft_ptB).*sqrt(fft_ptB);
%{
% SNRの計算 (dBスケール)
SNR_linear = sum(abs(RX.s_AB).^2) / sum(abs(CH.n).^2);
SNR_dB = 10 * log10(SNR_linear);
%}
   
 
RX.bA = fft(RX.s_AA, fft_ptA)./sqrt(fft_ptA);%64個の受信シンボル
RX.bB = fft(RX.s_AB, fft_ptB)./sqrt(fft_ptB);%64個の受信シンボル
RX.bN = fft(CH.n, fft_ptB)./sqrt(fft_ptB);%64個の受信シンボル


RX.b=RX.bA+RX.bB;
powA=sum(abs(RX.bA).^2);
powB=sum(abs(RX.bB).^2);
powN=sum(abs(RX.bN).^2);

    % 受信電力計算（RX電力）
    ERR.rx_pow(idx_loop) = sum(abs(RX.b).^2);

    %% DASIC (周波数領域)
    phi = TX.x(2:end,1) ./ TX.x(1:end-1,1);  % 位相シフトを計算
    RX.c=zeros(SIM.ndata,1);
    RX.c(1)=RX.b(1);
    RX.c(2:SIM.ndata) = RX.b(2:SIM.ndata) -  phi.*RX.b(1:SIM.ndata-1); %自己干渉除去
    %電力計算
    power.All = abs(RX.b).^2; %受信信号の電力
    power.A = abs(RX.bA).^2; %受信信号におけるSIの電力
    power.B = abs(RX.bB).^2; %受信信号における所望信号の電力
    power.Cross = 2*real(conj(RX.bA).*RX.bB); %受信信号におけるSIと所望信号のクロス項

    power.dAll=abs(RX.c(2:end)).^2;  %DASIC後の電力
    power.dSI= abs(Xi_vec_AA(2:SIM.ndata)-Xi_vec_AA(1:SIM.ndata-1)).^2;%DASIC後SIの電力
    power.dDesired = abs(RX.bB(2:SIM.ndata)-RX.bB(1:SIM.ndata-1).*phi).^2; %DASIC後の所望信号電力
    power.dNoise= abs(RX.bN(2:SIM.ndata)-RX.bN(1:SIM.ndata-1).*phi).^2; %DASIC後の雑音電力
    power.dSDcross= 2*real(conj( (Xi_vec_AA(2:SIM.ndata)-Xi_vec_AA(1:SIM.ndata-1)).*TX.x(2:SIM.ndata,1) ).* (RX.bB(2:SIM.ndata)-RX.bB(1:SIM.ndata-1).*phi ) ); %DASIC後のSIと所望信号のクロス項
    power.dSNcross= 2*real(conj( (Xi_vec_AA(2:SIM.ndata)-Xi_vec_AA(1:SIM.ndata-1)).*TX.x(2:SIM.ndata,1) ).* (RX.bN(2:SIM.ndata)-RX.bN(1:SIM.ndata-1).*phi)  ); %DASIC後のSIと雑音のクロス項
    power.dDNcross= 2*real(conj( RX.bB(2:SIM.ndata)-RX.bB(1:SIM.ndata-1).*phi ).* ( RX.bN(2:SIM.ndata)-RX.bN(1:SIM.ndata-1).*phi ) ); %所望信号と雑音のクロス項

    %% 期待値に収束した場合の平均電力
    %power.tSI(1:SIM.ndata-1,1) = 2*abs(delay_profile_AA_sir(2))^2*(1-cos(2*pi/fft_ptA)); 2波
    power.tSI(1:SIM.ndata-1,1)  = 4*abs(delay_profile_AA_sir(2)).^2.*(sin(pi/fft_ptA))^2+4*abs(delay_profile_AA_sir(3)).^2.*(sin(pi/fft_ptA)^2);
    power.tDesired =abs(Xi_vec_AB(2:SIM.ndata)).^2+abs(Xi_vec_AB(1:SIM.ndata-1)).^2 ;
    power.tNoise= abs(RX.bN(2:SIM.ndata)-RX.bN(1:SIM.ndata-1)).^2; %2N_0になるはず
    power.tAll = power.tSI + power.tDesired + power.tNoise;
    
    %% 期待値をもとに予測する残留SIの電力
    power.gSI = power.dAll - power.tDesired - 2*CH.N0;
    %% 期待値をもとに予測するSIの電力
    power.gA = power.All - power.B - CH.N0;
  

%% それぞれの電力とクロス項を格納
St.PowerAll(:,idx_loop) = power.All;
St.PowerA(:,idx_loop) = power.A;
St.PowerB(:,idx_loop) = power.B;
St.PowerCross(:,idx_loop) = power.Cross;
St.dPowerAll(:,idx_loop) =   power.dAll;
St.dPowerSI(:,idx_loop) =   power.dSI;
St.dPowerDesired(:,idx_loop) =   power.dDesired;
St.dPowerNoise(:,idx_loop) =   power.dNoise;
St.dPowerSD(:,idx_loop) =   power.dSDcross;
St.dPowerSN(:,idx_loop) =   power.dSNcross;
St.dPowerDN(:,idx_loop) =   power.dDNcross;
St.tPowerAll(:,idx_loop) =   power.tAll;
St.tPowerSI(:,idx_loop) =   power.tSI;
St.tPowerDesired(:,idx_loop) =   power.tDesired;
St.tPowerNoise(:,idx_loop) =   power.tNoise;
St.gPowerSI(:,idx_loop) = power.gSI;
St.gPowerA(:,idx_loop) = power.gA;
 fprintf('%d/%d\n',idx_loop,SIM.nsamp)
end
%% 平均を計算
avg.All=mean(St.PowerAll,"all");
avg.A=mean(St.PowerA,"all");
avg.B=mean(St.PowerB,"all");
avg.Cross=mean(St.PowerCross,"all");
avg.dAll=mean(St.dPowerAll,"all");
avg.dSI=mean(St.dPowerSI,"all");
avg.dDesired=mean(St.dPowerDesired,"all");
avg.dNoise=mean(St.dPowerNoise,"all");
avg.dSD=mean(St.dPowerSD,"all");
avg.dSN=mean(St.dPowerSN,"all");
avg.dDN=mean(St.dPowerDN,"all");
avg.tAll=mean(St.tPowerAll,"all");
avg.tSI=mean(St.tPowerSI,"all");
avg.tDesired=mean(St.tPowerDesired,"all");
avg.tNoise=mean(St.tPowerNoise,"all");
avg.gSI=mean(St.gPowerSI,"all");
avg.gA=mean(St.gPowerA,"all");