%QPSK　BCJR MAP
%1段DASICによりチャネルを推定し，残留SIの通信路の大きさを閾値と比較して二段適用するか判断する．
function SIM = main_task_f_DASIC(En,idx,SIM,G)
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
    pilot.b = randn(SIM.over*SIM.ndata,1)>0;
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
    pilot.x   = pskmod(double(pilot.b),G.Q,pi/G.Q,InputType="bit"); 

    %送信信号を時間領域へ
    pilot.s = ifft(pilot.x, fft_ptB).*sqrt(fft_ptB);
    TX.sA = ifft(TX.x(:,1), fft_ptA).*sqrt(fft_ptA);
    TX.sB = ifft(TX.x(:,2), fft_ptB).*sqrt(fft_ptB);
    
    % ==========================================================
    % CPの付与と連続したフレームの作成
    % ==========================================================
    pilot_cp = [pilot.s(end-SIM.cp_len+1:end); pilot.s];
    TX_sA_cp = [TX.sA(end-SIM.cp_len+1:end); TX.sA];
    TX_sB_cp = [TX.sB(end-SIM.cp_len+1:end); TX.sB];
    
    % 時間領域でパケットを構成 (1シンボル目: Pilot, 2シンボル目: Data)
    % Node B は Pilot を送った後に Data を送る
    tx_B_time = [pilot_cp; TX_sB_cp];
    % Node A は Pilot 送信時は無音(0)、その後 Data を送る
    tx_A_time = [zeros(length(pilot_cp), 1); TX_sA_cp];
    
    % ==========================================================
    % 時変動レイリーフェージングチャネルの生成
    % ==========================================================
    % 遅延プロファイルの作成 (秒単位)
    delay_A_sec = (0:(SIM.AA-1)) * SIM.delayA / SIM.fs;
    delay_B_sec = (0:(SIM.AB-1)) * SIM.delayB / SIM.fs;
    
    % 電力プロファイルの作成 (dB単位)
    gain_A_dB = zeros(1, SIM.AA);
    if SIM.AA > 1
        gain_A_dB(2) = SIM.rho;
        for dd = 3:SIM.AA
            gain_A_dB(dd) = SIM.rho + SIM.nrho*(dd-2);
        end
    end
    gain_B_dB = zeros(1, SIM.AB); % Bは等電力モデル
    
    % チャネルオブジェクトの生成
    chanAA = comm.RayleighChannel('SampleRate', SIM.fs, ...
        'PathDelays', delay_A_sec, 'AveragePathGains', gain_A_dB, ...
        'MaximumDopplerShift', SIM.fd);
    
    chanAB = comm.RayleighChannel('SampleRate', SIM.fs, ...
        'PathDelays', delay_B_sec, 'AveragePathGains', gain_B_dB, ...
        'MaximumDopplerShift', SIM.fd);
        
    % ==========================================================
    % 時変動チャネルの適用とSIR調整
    % ==========================================================
    rx_A_time = step(chanAA, tx_A_time);
    rx_B_time = step(chanAB, tx_B_time);
    
    % SIRの考慮 (AAの電力を調整)
    rx_A_time = rx_A_time * sqrt(10^(-SIM.SIR/10));
    
    % 雑音の生成 (時間領域で全体に付与)
    noise_time = (randn(length(rx_B_time), 1) + 1i * randn(length(rx_B_time), 1)) * sqrt(CH.N0 / 2);
    
    % 最終的な時間領域受信信号
    rx_total_time = rx_A_time + rx_B_time + noise_time;
    
    % 送信・受信電力計算
    ERR.tx_pow(idx_loop) = mean([sum(abs(TX.sA).^2) sum(abs(TX.sB).^2)]);
    ERR.rx_pow(idx_loop) = sum(abs(rx_total_time).^2);
    
    % ==========================================================
    % CPの除去とFFT (受信機処理)
    % ==========================================================
    % 1シンボル目 (Pilot) の抽出
    rx_pilot_cp = rx_total_time(1 : length(pilot_cp));
    rx_pilot    = rx_pilot_cp(SIM.cp_len+1 : end); % CP除去
    RX.Ap       = fft(rx_pilot, fft_ptB) ./ sqrt(fft_ptB);
    
    % 2シンボル目 (Data) の抽出
    rx_data_cp = rx_total_time(length(pilot_cp)+1 : end);
    rx_data    = rx_data_cp(SIM.cp_len+1 : end); % CP除去
    RX.b       = fft(rx_data, fft_ptA) ./ sqrt(fft_ptA);
    %% 2. 帯域制限(Virtual Subcarrier)を考慮した時間領域チャネル復元
    % パイロットによる初期チャネル推定 (LS推定)
    EstXiAB_LS = RX.Ap(1:SIM.ndata) ./ pilot.x(1:SIM.ndata);
    L = SIM.delayB * num_of_paths_AB; % 有効な最大遅延サンプル数 (これ以降の時間はパスが存在しないとする)
    F_matrix = fft(eye(fft_ptB));  % 128ポイントのFFT行列を生成
    F_partial = F_matrix(1:SIM.ndata, 1:L); 
    alpha = CH.N0;

    F_H = F_partial';% 共役転置を取得

    % pinv(F_partial) の代わりに、MMSE基準の連立方程式を解く
    h_est_time_L_MMSE = (F_H * F_partial + alpha * eye(L)) \ (F_H * EstXiAB_LS);

    % 128ポイントのインパルス応答として再構成 (L以降はゼロ詰め)
    h_est_time_128_MMSE = [h_est_time_L_MMSE; zeros(fft_ptB - L, 1)];

    % 128ポイントFFTで周波数領域へ
    H_est_clean_128_MMSE = fft(h_est_time_128_MMSE, fft_ptB);

    EstXiABMMSE = H_est_clean_128_MMSE(1:SIM.ndata);% 3. 最終的なチャネル推定値 (BCJRなどのデータ復号用) 
    %%MMSEを用いない場合
    % h_est_time_L = pinv(F_partial) * EstXiAB_LS;　% 擬似逆行列(pinv)を用いて、64個の周波数成分からL個の時間タップを逆算
    % h_est_time_128 = [h_est_time_L; zeros(fft_ptB - L, 1)]; % 128ポイントのインパルス応答として再構成 (L以降はゼロ詰め＝完全な窓関数) 
    % H_est_clean_128 = fft(h_est_time_128, fft_ptB);% 128ポイントFFTで周波数領域へ
    % EstXiAB = H_est_clean_128(1:SIM.ndata);% 3. 最終的なチャネル推定値 (BCJRなどのデータ復号用)

    %比較用
    % True_Channel = Xi_vec_AB(1:SIM.ndata);
    % MSE_LS   = mean(abs(True_Channel - EstXiAB_LS).^2);
    % MSE_DFT  = mean(abs(True_Channel - EstXiAB).^2);       % pinvのみ（雑音で爆発する版）
    % MSE_MMSE = mean(abs(True_Channel - EstXiABMMSE).^2);
    %% DASIC (周波数領域)
    phi = TX.x(2:end,1) ./ TX.x(1:end-1,1);  % 位相シフトを計算
    RX.c=zeros(SIM.ndata,1);
    RX.c(1)=RX.b(1);
    RX.c(2:SIM.ndata) = RX.b(2:SIM.ndata) -  phi.*RX.b(1:SIM.ndata-1); %自己干渉除去
    
if strcmp(SIM.mode ,'Auto')
    EstResidualSi = abs(RX.c(2:end)).^2 - (abs(EstXiABMMSE(2:SIM.ndata)).^2+abs(EstXiABMMSE(1:SIM.ndata-1)).^2) - 2*CH.N0; %DASIC後の信号電力から，所望信号と雑音成分に関する電力を減算し，残留SIの電力を得る
    if EstResidualSi <= SIM.threshold
        mode = 'DASIC1';
    else
        mode = 'DASIC2';
    end
else
    mode=SIM.mode;
end

    RX.c2=zeros(SIM.ndata,1);
    RX.c2(1)=RX.b(1);
    RX.c2(2)=RX.b(2);
    RX.c2(3:SIM.ndata) = RX.c(3:SIM.ndata) -  phi(2:end).*RX.c(2:SIM.ndata-1); %自己干渉除去 


switch(mode)
    case {'DASIC1'}
   %% BCJR
        BCJR1.alpha = zeros(4,length(TX.x))-1000000;
        BCJR1.alpha(1,1) = log(1); %log取ると1→確率100%
        BCJR1.alpha(1,2) = log(1); %log取ると1→確率100%
        BCJR1.beta = zeros(4,length(TX.x))-1000000;
        BCJR1.beta(1,end) = log(1);
        BCJR1.beta(1,end-1) = log(1);

        BCJR1.Gamma= zeros(4,4,length(TX.x)-1)-1000000;
        TX.Xi_vec_AB=EstXiABMMSE;
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
end
switch mode
    case {'DASIC2'}
%% 二段用BCJR

        BCJR2.alpha = zeros(16,length(TX.x))-1000000;
        BCJR2.alpha(1,1) = log(1); %log取ると1→確率100%
        BCJR2.alpha(1,2) = log(1); %log取ると1→確率100%
        BCJR2.beta = zeros(16,length(TX.x))-1000000;
        BCJR2.beta(1,end) = log(1);
        BCJR2.beta(1,end-1) = log(1);

        BCJR2.Gamma= zeros(16,16,length(TX.x)-1)-1000000;
        TX.Xi_vec_AB=EstXiABMMSE;
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

end
    %% Error count

    switch mode
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
    fprintf('%d/%d  %d/%d\n',idx,length(SIM.SNR),idx_loop,SIM.nsamp)
end
SIM.En  = En;
SIM.BER = sum(ERR.noe,1) / sum(ERR.nod);
SIM.PER = sum(ERR.noe_p,1) / sum(ERR.nod_p);
SIM.SIR = 10*log10(sum(ERR.tx_pow)/(sum(ERR.rx_pow)-sum(ERR.tx_pow)));
SIM.noe = sum(ERR.noe,1);
SIM.nod = sum(ERR.nod,1);
SIM.noe_p = sum(ERR.noe_p,1);
SIM.nod_p = sum(ERR.nod_p,1);
