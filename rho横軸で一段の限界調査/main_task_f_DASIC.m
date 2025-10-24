%QPSK　BCJR MAP
%1段DASICによりチャネルを推定し，残留SIの通信路の大きさを閾値と比較して二段適用するか判断する．
function SIM = main_task_f_DASIC(En,idx,SIM,G,Rho)
CH.N0 = 10^(-En/10); %1シンボル間隔の雑音エネルギー密度
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
             rho = 10^( (Rho-5*(rr-2)) /10); %3波目以降-5dB
             rho_sum = rho_sum+rho;
            end
        delay_profile_AA_rho(1) =delay_profile_AA_s(1)*sqrt(1/( 1 + rho_sum ) );
         for dd=2:SIM.AA
                 delay_profile_AA_rho(dd) =delay_profile_AA_s(dd)*sqrt(10^( (Rho-5*(dd-2))/10)*abs(delay_profile_AA_rho(1))^2);
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


RX.b=RX.bA+RX.bB+RX.bN;
    % 受信電力計算（RX電力）
    ERR.rx_pow(idx_loop) = sum(abs(RX.b).^2);

switch(SIM.mode)
    case {'cn_est1','cn_est2','DASIC1','DASIC2'}
    %% DASIC (周波数領域)
    phi = TX.x(2:end,1) ./ TX.x(1:end-1,1);  % 位相シフトを計算
    RX.c=zeros(SIM.ndata,1);
    RX.c(1)=RX.b(1);
    RX.c(2:SIM.ndata) = RX.b(2:SIM.ndata) -  phi.*RX.b(1:SIM.ndata-1); %自己干渉除去

    RX.c2=zeros(SIM.ndata,1);
    RX.c2(1)=RX.b(1);
    RX.c2(2)=RX.b(2);
    RX.c2(3:SIM.ndata) = RX.c(3:SIM.ndata) -  phi(2:end).*RX.c(2:SIM.ndata-1); %自己干渉除去 
end
switch(SIM.mode)
    case {'cn_est1','DASIC1'}
   %% BCJR
        BCJR1.alpha = zeros(4,length(TX.x))-1000000;
        BCJR1.alpha(1,1) = log(1); %log取ると1→確率100%
        BCJR1.alpha(1,2) = log(1); %log取ると1→確率100%
        BCJR1.beta = zeros(4,length(TX.x))-1000000;
        BCJR1.beta(1,end) = log(1);
        BCJR1.beta(1,end-1) = log(1);

        BCJR1.Gamma= zeros(4,4,length(TX.x)-1)-1000000;
        TX.Xi_vec_AB=Xi_vec_AB;
        TX.phi=phi;

 for xx = 2:length(RX.c)-1
     trel1 = BCJRTrellisDasic(TX,xx,CH,G,0,1); 

    for idx_in = 1:trel1.num_in  
     for sigi=1:trel1.num_state %状態i
           BCJR1.Gamma(sigi,trel1.next_state(sigi,idx_in)+1,xx) = (-1*(abs(RX.c(xx+1)-trel1.outputs(sigi,idx_in)))^2)/2/CH.N0;%尤度の計算
      end
    end
   
    for sigj = 1:trel1.num_state%状態j 
       BCJR1.aaa = zeros(trel1.num_state,1);
     for sigi=1:trel1.num_state %状態i
          BCJR1.aaa(sigi)=BCJR1.alpha(sigi,xx)+BCJR1.Gamma(sigi,sigj,xx);

      end
      BCJR1.alpha(sigj,xx+1) = LOG_MAP(BCJR1.aaa,trel1.num_state);
    end  

 end
 
 
 for xx = length(RX.c):-1:3
     
     for sigi = 1:trel1.num_state%状態i
        BCJR1.bbb = zeros(trel1.num_state,1);
        for sigj=1:trel1.num_state %状態j

          BCJR1.bbb(sigj)=BCJR1.beta(sigj,xx)+BCJR1.Gamma(sigi,sigj,xx-1);

        end
   
         BCJR1.beta(sigi,xx-1) = LOG_MAP(BCJR1.bbb,trel1.num_state );
   
     end  

  for idx_in = 1:trel1.num_in

    
       for sigi = 1:trel1.num_state
          
           state = trel1.next_state(sigi,idx_in)+1;
           BCJR1.L0(sigi) = BCJR1.Gamma(sigi,state,xx-1)+BCJR1.beta(state,xx)+BCJR1.alpha(sigi,xx-1);
      
       end
    
       BCJR1.LL(idx_in) = LOG_MAP(BCJR1.L0,trel1.num_state );
  end
   %%%%%%%%%%%%%%%%%%
      BCJR1.LLL1 = BCJR1.LL(3);
          log_MAP = log(1+exp(-1*(abs( BCJR1.LL(3)- BCJR1.LL(4)))));
            if BCJR1.LL(4)>BCJR1.LL(3)
                 BCJR1.LLL1 = BCJR1.LL(4);
            end
              BCJR1.LLL1 = BCJR1.LLL1+log_MAP;
 
      BCJR1.LLL2 = BCJR1.LL(1);
          log_MAP = log(1+exp(-1*(abs(BCJR1.LL(1)-BCJR1.LL(2)))));
            if BCJR1.LL(2)>BCJR1.LL(1)
                 BCJR1.LLL2 = BCJR1.LL(2);
            end
              BCJR1.LLL2 = BCJR1.LLL2+log_MAP;

      BCJR1.LLL3 = BCJR1.LL(2);
          log_MAP = log(1+exp(-1*(abs(BCJR1.LL(2)-BCJR1.LL(4)))));
            if BCJR1.LL(4)>BCJR1.LL(2)
                 BCJR1.LLL3 = BCJR1.LL(4);
            end
              BCJR1.LLL3 = BCJR1.LLL3+log_MAP;
 
      BCJR1.LLL4 = BCJR1.LL(1);
          log_MAP = log(1+exp(-1*(abs(BCJR1.LL(1)-BCJR1.LL(3)))));
            if BCJR1.LL(3)>BCJR1.LL(1)
                 BCJR1.LLL4 = BCJR1.LL(3);
            end
              BCJR1.LLL4 = BCJR1.LLL4+log_MAP;
    %%%%%%%%%%%%%%%%%%%%
     BCJR1.L(2*(xx-1)-1,1) = BCJR1.LLL1-BCJR1.LLL2;%ooビットの左 LLL1>LLL2→1
     BCJR1.L(2*(xx-1),1) = BCJR1.LLL3-BCJR1.LLL4;%ooビットの右
      b_hat = BCJR1.L>0 ;
 end
%% BCJRからの判定
if intrlv==1
BCJR1.a=randdeintrlv(BCJR1.L(3:end-4),1);
else
BCJR1.a=BCJR1.L(3:end-4);
end
 BCJR1.decode_bhat=APPDec(zeros(60,1),BCJR1.a );
BCJR1.decode=BCJR1.decode_bhat>0;
%%推定所望信号シンボルの作成
%シンボルをそのまま
% b_hat_t=[0;0;b_hat];
% xbhat = pskmod(double(b_hat_t),G.Q,pi/G.Q,InputType="bit"); 
%復号してから作成
A=BCJR1.decode(1:end-6);
AA=step(ConEnc,A);
AAA=randintrlv(round(AA),1);
AAAA=[0;0;0;0;AAA;0;0;0;0];
xbhat = pskmod(double(AAAA),G.Q,pi/G.Q,InputType="bit");
end
switch SIM.mode
case {'cn_est2','DASIC2'}
%% 二段用BCJR

        BCJR2.alpha = zeros(16,length(TX.x))-1000000;
        BCJR2.alpha(1,1) = log(1); %log取ると1→確率100%
        BCJR2.alpha(1,2) = log(1); %log取ると1→確率100%
        BCJR2.beta = zeros(16,length(TX.x))-1000000;
        BCJR2.beta(1,end) = log(1);
        BCJR2.beta(1,end-1) = log(1);

        BCJR2.Gamma= zeros(16,16,length(TX.x)-1)-1000000;
        TX.Xi_vec_AB=Xi_vec_AB;
        TX.phi=phi;

 for xx = 2:length(RX.c2)-1
     trel2 = BCJRTrellis2Dasic(TX,xx,CH,G,0,1); 

    for idx_in = 1:trel2.num_in 
     for state=1:16 %状態数(二段だと16)
          BCJR2.Gamma(state,trel2.next_state(state,idx_in)+1,xx) = (-1*(abs(RX.c2(xx+1)-trel2.outputs(state,idx_in)))^2)/6/CH.N0;
      end
    end  
for sigk = 1:16 % 次状態
     BCJR2.aaa = zeros(16,1);
    for state=1:16 % 現在の状態(1~16)
         BCJR2.aaa(state) =  BCJR2.alpha(state,xx) +  BCJR2.Gamma(state,sigk,xx);
    end
     BCJR2.alpha(sigk, xx+1) = LOG_MAP( BCJR2.aaa, 16);
end
     BCJR2.max_val = max( BCJR2.alpha(:, xx+1));%規格化
     BCJR2.alpha(:, xx+1) =  BCJR2.alpha(:, xx+1) -  BCJR2.max_val;
end 
 
for xx = length(RX.c2):-1:3
     
     for state = 1:16%状態
         BCJR2.bbb = zeros(16,1);
        for sigk=1:16 %次状態
           BCJR2.bbb(sigk)= BCJR2.beta(sigk,xx)+ BCJR2.Gamma(state,sigk,xx-1);
        end  
          BCJR2.beta(state,xx-1) = LOG_MAP( BCJR2.bbb,16);
     end  
      BCJR2.max_val = max( BCJR2.beta(:, xx-1));
      BCJR2.beta(:, xx-1) =  BCJR2.beta(:, xx-1) -  BCJR2.max_val;
    
  for idx_in = 1:trel2.num_in
    
       for state = 1:16     
           nstate = trel2.next_state(state,idx_in)+1;
            BCJR2.L0(state) =  BCJR2.Gamma(state,nstate,xx-1)+ BCJR2.beta(nstate,xx)+ BCJR2.alpha(state,xx-1);  
       end
        BCJR2.LL(idx_in) = LOG_MAP( BCJR2.L0,16);
  end
   %%%%%%%%%%%%%%%%%%
       BCJR2.LLL1 =  BCJR2.LL(3);
          log_MAP = log(1+exp(-1*(abs( BCJR2.LL(3)- BCJR2.LL(4)))));
            if  BCJR2.LL(4)> BCJR2.LL(3)
                  BCJR2.LLL1 =  BCJR2.LL(4);
            end
               BCJR2.LLL1 =  BCJR2.LLL1+log_MAP;
 
       BCJR2.LLL2 =  BCJR2.LL(1);
          log_MAP = log(1+exp(-1*(abs( BCJR2.LL(1)- BCJR2.LL(2)))));
            if  BCJR2.LL(2)> BCJR2.LL(1)
                  BCJR2.LLL2 =  BCJR2.LL(2);
            end
               BCJR2.LLL2 =  BCJR2.LLL2+log_MAP;

       BCJR2.LLL3 =  BCJR2.LL(2);
          log_MAP = log(1+exp(-1*(abs( BCJR2.LL(2)- BCJR2.LL(4)))));
            if  BCJR2.LL(4)> BCJR2.LL(2)
                  BCJR2.LLL3 =  BCJR2.LL(4);
            end
               BCJR2.LLL3 =  BCJR2.LLL3+log_MAP;
 
       BCJR2.LLL4 =  BCJR2.LL(1);
          log_MAP = log(1+exp(-1*(abs( BCJR2.LL(1)- BCJR2.LL(3)))));
            if  BCJR2.LL(3)> BCJR2.LL(1)
                  BCJR2.LLL4 =  BCJR2.LL(3);
            end
               BCJR2.LLL4 =  BCJR2.LLL4+log_MAP;
    %%%%%%%%%%%%%%%%%%%%
      BCJR2.L(2*(xx-1)-1,1) =  BCJR2.LLL1- BCJR2.LLL2;%ooビットの左 LLL1>LLL2→1
      BCJR2.L(2*(xx-1),1) =  BCJR2.LLL3- BCJR2.LLL4;%ooビットの右
           b_hat = BCJR2.L>0 ;
 end
%% BCJRからの判定
if intrlv==1
 BCJR2.a=randdeintrlv( BCJR2.L(3:end-4),1);
else
 BCJR2.a= BCJR2.L(3:end-4);
end
 BCJR2.decode_bhat=APPDec(zeros(60,1), BCJR2.a);
 BCJR2.decode= BCJR2.decode_bhat>0;

%シンボルを復号してから作成
A=BCJR2.decode(1:end-6);
AA=step(ConEnc,A);
AAA=randintrlv(round(AA),1);
AAAA=[0;0;0;0;AAA;0;0;0;0];
xbhat = pskmod(double(AAAA),G.Q,pi/G.Q,InputType="bit");
end
%%チャネル推定
switch SIM.mode
    case 'cn_est'
EST.Xi=RX.b./TX.x(:,1);%所望信号も雑音扱いでxiAA推定
    case{'cn_est1','cn_est2'}
EST.Xi=(RX.b(1:SIM.ndata)-Xi_vec_AB(1:SIM.ndata).*xbhat)./TX.x(:,1);%所望信号も雑音扱いでxiAA推定
end
% EST.h = ifft(EST.Xi, SIM.ndata);
% Window = zeros (length(EST.h),1);
% Window(1:2) = 1;
% EST.hTilde = EST.h.*Window;
% EST.NewXi = fft(EST.hTilde,SIM.ndata);

%% SIのレプリカを減算し，復号
switch SIM.mode
    case {'cn_est','cn_est1','cn_est2'}
switch SIM.detmode
    case'MLD'
tilde_xb=(RX.b-EST.NewXi.*TX.x(:,1))./Xi_vec_AB;%SIのシンボル減算し，xiABで割る
[~,rxalp]   = min(abs(tilde_xb(:)-constellation),[],2); %ユークリッド距離が最小のM進数の記号を探索
rxdata_p      = alp2bit(rxalp,:); % 記号をビットに変換
for i=1:length(rxdata_p)
 rxdata(2*i-1)=rxdata_p(i,1);
 rxdata(2*i)=rxdata_p(i,2);
end
 det.orig=rxdata';
det.deint=randdeintrlv(det.orig(5:end-4),1);
det.decode=APPDec(zeros(60,1), det.deint)>0;
    case 'BCJR'
tilde_xb=RX.b-EST.NewXi.*TX.x(:,1);
%%BCJR
  BCJR.alpha = zeros(4,length(TX.x))-1000000;
        BCJR.alpha(1,1) = log(1); %log取ると1→確率100%
        BCJR.alpha(1,2) = log(1); %log取ると1→確率100%
        BCJR.beta = zeros(4,length(TX.x))-1000000;
        BCJR.beta(1,end) = log(1);
        BCJR.beta(1,end-1) = log(1);

        BCJR.Gamma= zeros(4,4,length(TX.x)-1)-1000000;
        TX.Xi_vec_AB=Xi_vec_AB;

 for xx = 2:length(RX.b)-1
     trel = BCJRTrellis(TX,xx,CH,G,0,1); 

    for idx_in = 1:trel.num_in  
     for sigi=1:trel.num_state %状態i
           BCJR.Gamma(sigi,trel.next_state(sigi,idx_in)+1,xx) = (-1*(abs(tilde_xb(xx+1)-trel.outputs(sigi,idx_in)))^2)/2/CH.N0;%尤度の計算
      end
    end
   
    for sigj = 1:trel.num_state%状態j 
       BCJR.aaa = zeros(trel.num_state,1);
     for sigi=1:trel.num_state %状態i
          BCJR.aaa(sigi)=BCJR.alpha(sigi,xx)+BCJR.Gamma(sigi,sigj,xx);

      end
      BCJR.alpha(sigj,xx+1) = LOG_MAP(BCJR.aaa,trel.num_state);
    end  

 end
 
 
 for xx = length(RX.b):-1:2
     
     for sigi = 1:trel.num_state%状態i
        BCJR.bbb = zeros(trel.num_state,1);
        for sigj=1:trel.num_state %状態j

          BCJR.bbb(sigj)=BCJR.beta(sigj,xx)+BCJR.Gamma(sigi,sigj,xx-1);

        end
   
         BCJR.beta(sigi,xx-1) = LOG_MAP(BCJR.bbb,trel.num_state );
   
     end  

  for idx_in = 1:trel.num_in

    
       for sigi = 1:trel.num_state
          
           state = trel.next_state(sigi,idx_in)+1;
           BCJR.L0(sigi) = BCJR.Gamma(sigi,state,xx-1)+BCJR.beta(state,xx)+BCJR.alpha(sigi,xx-1);
      
       end
    
       BCJR.LL(idx_in) = LOG_MAP(BCJR.L0,trel.num_state );
  end
   %%%%%%%%%%%%%%%%%%
      BCJR.LLL1 = BCJR.LL(3);
          log_MAP = log(1+exp(-1*(abs( BCJR.LL(3)- BCJR.LL(4)))));
            if BCJR.LL(4)>BCJR.LL(3)
                 BCJR.LLL1 = BCJR.LL(4);
            end
              BCJR.LLL1 = BCJR.LLL1+log_MAP;
 
      BCJR.LLL2 = BCJR.LL(1);
          log_MAP = log(1+exp(-1*(abs(BCJR.LL(1)-BCJR.LL(2)))));
            if BCJR.LL(2)>BCJR.LL(1)
                 BCJR.LLL2 = BCJR.LL(2);
            end
              BCJR.LLL2 = BCJR.LLL2+log_MAP;

      BCJR.LLL3 = BCJR.LL(2);
          log_MAP = log(1+exp(-1*(abs(BCJR.LL(2)-BCJR.LL(4)))));
            if BCJR.LL(4)>BCJR.LL(2)
                 BCJR.LLL3 = BCJR.LL(4);
            end
              BCJR.LLL3 = BCJR.LLL3+log_MAP;
 
      BCJR.LLL4 = BCJR.LL(1);
          log_MAP = log(1+exp(-1*(abs(BCJR.LL(1)-BCJR.LL(3)))));
            if BCJR.LL(3)>BCJR.LL(1)
                 BCJR.LLL4 = BCJR.LL(3);
            end
              BCJR.LLL4 = BCJR.LLL4+log_MAP;
    %%%%%%%%%%%%%%%%%%%%
     BCJR.L(2*(xx-1)-1,1) = BCJR.LLL1-BCJR.LLL2;%ooビットの左 LLL1>LLL2→1
     BCJR.L(2*(xx-1),1) = BCJR.LLL3-BCJR.LLL4;%ooビットの右
     % b_hat(2*(xx-1)-1,1) = BCJR1.L(2*(xx-1)-1)>0 ;
     % b_hat(2*(xx-1),1) = BCJR1.L(2*(xx-1))>0 ;
 end
%% BCJRからの判定
% b_hat_t=b_hat(1:end-2);
% deint_bhat = randdeintrlv(double(b_hat_t),1);
if intrlv==1
BCJR.a=randdeintrlv(BCJR.L(3:end-4),1);
else
BCJR.a=BCJR.L(3:end-4);
end
 BCJR.decode_bhat=APPDec(zeros(60,1),BCJR.a );
    det.decode=BCJR.decode_bhat>0;
end
end
    %% Error count

    switch SIM.mode
        case {'cn_est','cn_est1','cn_est2'}
    ERR.noe(idx_loop,:) = sum(det.decode(1:length(TX.b(:,2)),1) ~= TX.b(:,2));%map
        case 'DASIC1'
    ERR.noe(idx_loop,:) = sum(BCJR1.decode(1:length(TX.b(:,2)),1) ~= TX.b(:,2));%map
        case 'DASIC2'
    ERR.noe(idx_loop,:) = sum(BCJR2.decode(1:length(TX.b(:,2)),1) ~= TX.b(:,2));%map
    end

    ERR.noe_p(idx_loop,:) = (ERR.noe(idx_loop,:) ~=0);
    ERR.nod(idx_loop)   = size(TX.b,1); 
    ERR.nod_p(idx_loop) = 1;
    if(sum(ERR.noe_p)>SIM.err_max)
        break;
    end
    fprintf('%d/%d  %d/%d\n',idx,length(SIM.rho),idx_loop,SIM.nsamp)
end
SIM.En  = En;
SIM.BER = sum(ERR.noe,1) / sum(ERR.nod);
SIM.PER = sum(ERR.noe_p,1) / sum(ERR.nod_p);
SIM.SIR = 10*log10(sum(ERR.tx_pow)/(sum(ERR.rx_pow)-sum(ERR.tx_pow)));
SIM.noe = sum(ERR.noe,1);
SIM.nod = sum(ERR.nod,1);
SIM.noe_p = sum(ERR.noe_p,1);
SIM.nod_p = sum(ERR.nod_p,1);
