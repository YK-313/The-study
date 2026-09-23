%QPSK　BCJR MAP
%1段DASICによりチャネルを推定し，残留SIの通信路の大きさを閾値と比較して二段適用するか判断する．
function SIM = main_task_middle0_DASIC(En,idx,SIM,G)
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
    % Nullサブキャリアの設定 (DC: 1番目, プラス側ガード: 上位3つ, マイナス側ガード: 下位4つ)
switch(SIM.null)
    case 'true'
        % Nullあり (DCとガードバンドを除外)
        % data_idx: [2~29, 37~64]
        data_idx = [2 : (SIM.ndata/2 - 3), (SIM.ndata/2 + 5) : SIM.ndata]; 
        % freq_ordered_idx: マイナス側[37~64] -> プラス側[2~29]
        freq_ordered_idx = [(SIM.ndata/2 + 5) : SIM.ndata, 2 : (SIM.ndata/2 - 3)];
        
    case 'false'
        % Nullなし (全サブキャリア使用)
        % data_idx: [1~64]
        data_idx = 1 : SIM.ndata;
        % freq_ordered_idx: マイナス側[33~64] -> DCとプラス側[1~32]
        freq_ordered_idx = [(SIM.ndata/2 + 1) : SIM.ndata, 1 : (SIM.ndata/2)];
end
    num_data_subc = length(data_idx); % 割り当てられるデータサブキャリア数 (64の場合 56)
    
    % ビット数の逆算
    bits_per_symbol = log2(G.Q);                  % 1シンボルあたりのビット数 (QPSKなら2)
    total_bits = num_data_subc * bits_per_symbol; % 1OFDMシンボルあたりの全ビット数
    bcjr_pad_bits = 8;                            % BCJRパディングビット総数 (前後4bitずつ)
    conv_tail_bits = log2(trellis.numStates);     % 畳み込み符号の終端ビット数
    conv_rate = 2;                                % 畳み込み符号化率 (1/2 なので2)
    
    % 実際に送信する情報ビット数を逆算
    num_info_bits = (total_bits - bcjr_pad_bits) / conv_rate - conv_tail_bits;
    
    % 2. データの生成
    TX.b = randn(num_info_bits, 2) > 0; % 情報ビット
    TX.p = randn(total_bits, 2) > 0;    % パイロット (データサブキャリア分)
    
    % 畳み込み符号化
    TX.codedata(:,1) = step(ConEnc, TX.b(:,1)); 
    TX.codedata(:,2) = step(ConEnc, TX.b(:,2)); 
    
    % インタリーブ
    if intrlv==1
        TX.codedata_in = round(TX.codedata);
        TX.codedata_in(:,1) = randintrlv(TX.codedata_in(:,1), 1);
        TX.codedata_in(:,2) = randintrlv(TX.codedata_in(:,2), 1);
    else
        TX.codedata_in = TX.codedata;
    end
    
    % BCJRの終端ビット(前後0を均等に)追加
    pad_zeros = zeros(bcjr_pad_bits / 2, 1);
    half_data_bits = length(TX.codedata_in(:,1)) / 2; % 104 / 2 = 52 bits
    TX.codedata_int(:,1) = [pad_zeros; TX.codedata_in(:,1); pad_zeros];
    TX.codedata_int(:,2) = [pad_zeros; TX.codedata_in(:,2); pad_zeros];

    % 3. 変調とNullサブキャリアへのマッピング
    % QPSK変調
    TX_x_data = pskmod(double(TX.codedata_int), G.Q, pi/G.Q, InputType="bit");
    TX_p_data = pskmod(double(TX.p), G.Q, pi/G.Q, InputType="bit");
    
    % 全サブキャリアを 0 (Null) で初期化
    TX.x    = zeros(SIM.ndata, 2);
    TX.pSym = zeros(SIM.ndata, 2);
    
    % 算出したデータインデックス位置にシンボルを配置
    TX.x(data_idx, 1) = TX_x_data(:, 1);
    TX.x(data_idx, 2) = TX_x_data(:, 2);
    TX.pSym(data_idx, 1) = TX_p_data(:, 1);
    TX.pSym(data_idx, 2) = TX_p_data(:, 2);

    % 4. 送信信号を時間領域へ (IFFT)
    half_ndata = SIM.ndata / 2;
    % 物理インデックスの計算 (DC~プラス帯域, マイナス帯域) ※列ベクトル化
    phys_idx_A = [1:half_ndata, (fft_ptA - half_ndata + 1):fft_ptA].';
    phys_idx_B = [1:half_ndata, (fft_ptB - half_ndata + 1):fft_ptB].';
    
    % 128pt用のゼロ配列を用意し、物理インデックスの位置に64個のデータを配置
    TX.x_128_A = zeros(fft_ptA, 1); TX.x_128_A(phys_idx_A) = TX.x(:,1);
    TX.x_128_B = zeros(fft_ptB, 1); TX.x_128_B(phys_idx_B) = TX.x(:,2);
    TX.p_128_A = zeros(fft_ptA, 1); TX.p_128_A(phys_idx_A) = TX.pSym(:,1);
    TX.p_128_B = zeros(fft_ptB, 1); TX.p_128_B(phys_idx_B) = TX.pSym(:,2);

    % IFFT実行
    TX.sA = ifft(TX.x_128_A, fft_ptA) .* sqrt(fft_ptA);
    TX.sB = ifft(TX.x_128_B, fft_ptB) .* sqrt(fft_ptB);
    TX.pA = ifft(TX.p_128_A, fft_ptA) .* sqrt(fft_ptA);
    TX.pB = ifft(TX.p_128_B, fft_ptB) .* sqrt(fft_ptB);
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
    RX.pAA=H_circ_AA*TX.pA;
    RX.pAB=H_circ_AB*TX.pB;
    % 雑音の生成
    CH.f = (randn(SIM.ndata, 1) + 1i * randn(SIM.ndata, 1)) * sqrt(CH.N0 / 2);
    CH.n =  ifft(CH.f, fft_ptB).*sqrt(fft_ptB);
    CH.pf = (randn(SIM.ndata, 1) + 1i * randn(SIM.ndata, 1)) * sqrt(CH.N0 / 2);
    CH.pn =  ifft(CH.pf, fft_ptB).*sqrt(fft_ptB);
%{
% SNRの計算 (dBスケール)
SNR_linear = sum(abs(RX.s_AB).^2) / sum(abs(CH.n).^2);
SNR_dB = 10 * log10(SNR_linear);
%}
   
 
    RX.bA_128 = fft(RX.s_AA, fft_ptA)./sqrt(fft_ptA);
    RX.bB_128 = fft(RX.s_AB, fft_ptB)./sqrt(fft_ptB);
    RX.bN_128 = fft(CH.n, fft_ptB)./sqrt(fft_ptB);
    RX.pA_128 = fft(RX.pAA, fft_ptA)./sqrt(fft_ptA);
    RX.pB_128 = fft(RX.pAB, fft_ptB)./sqrt(fft_ptB);
    RX.pN_128 = fft(CH.pn, fft_ptB)./sqrt(fft_ptB);
    
    % 物理インデックスから本来のベースバンド(SIM.ndata個)のみを抽出
    RX.bA = RX.bA_128(phys_idx_A);
    RX.bB = RX.bB_128(phys_idx_B);
    RX.bN = RX.bN_128(phys_idx_B);
    RX.pA = RX.pA_128(phys_idx_A);
    RX.pB = RX.pB_128(phys_idx_B);
    RX.pN = RX.pN_128(phys_idx_B);

    RX.b = RX.bA + RX.bB + RX.bN; % 抽出された64個の受信シンボルで構成
    powA = sum(abs(RX.bA).^2);
    powB = sum(abs(RX.bB).^2);
    powN = sum(abs(RX.bN).^2);
% 10*log10(powB/powA)
% 10*log10(powB/powN)
    % 受信電力計算（RX電力）
    ERR.rx_pow(idx_loop) = sum(abs(RX.b).^2);

%% 所望信号チャネルの推定
switch(SIM.PilotMode)
    case 'alter'
        RX.p=RX.pB+RX.pN; %パイロット送信時はSIなし
        EST.XivecAB_valid = RX.p(data_idx)./TX.pSym(data_idx,2); %【修正】有効サブキャリアのみで計算
    case 'simul'
    RX.p=RX.pB+RX.pA+RX.pN; %同時にパイロット送信
    
        switch(SIM.modeAB)
            case {'WoSIC'}
            EST.XivecAB_valid = RX.p(data_idx)./TX.pSym(data_idx,2); %【修正】有効サブキャリアのみで計算
    
            case {'SIC'}
          %% SIのレプリカを作成し，減算後パイロットからXi_ABを推定
            % 1. 有効サブキャリアのみ抽出してXi_AAをLS推定
            P.EST.Xi_valid = RX.p(data_idx) ./ TX.pSym(data_idx, 1);
            
            P.L = SIM.delayA * num_of_paths_AA; % 有効な最大遅延サンプル数
            P.F_matrix = fft(eye(fft_ptA)); % 128ポイントのFFT行列を生成
            
            phys_valid_idx_A = phys_idx_A(data_idx); %【追加】128pt FFT上での有効サブキャリアの物理インデックス
            
            % 行: 物理インデックス, 列: パス数(1~P.L) の部分行列を抽出
            P.F_partial_valid = P.F_matrix(phys_valid_idx_A, 1:P.L);
            % LS推定 (擬似逆行列を用いて時間タップを逆算)
            P.EST.h_L = pinv(P.F_partial_valid) * P.EST.Xi_valid; 
            P.EST.h = [P.EST.h_L; zeros(fft_ptA - P.L, 1)]; % ゼロ詰め (完全な窓関数)
            P.EST.Xi_vec_AA = fft(P.EST.h, fft_ptA); % 128ポイントFFTで周波数領域へ
            P.EST.XiHat = P.EST.Xi_vec_AA(phys_idx_A); %【修正】ベースバンド(64個)を抽出
    
            % 2. SIレプリカの減算とXi_ABのLS推定 (有効サブキャリアのみ)
            % SIレプリカで減算 (有効インデックスのみ計算)
            TildePilot_valid = RX.p(data_idx) - P.EST.XiHat(data_idx) .* TX.pSym(data_idx, 1); 
            EST.XivecAB_valid = TildePilot_valid ./ TX.pSym(data_idx, 2);
        end
end
            % 3. Xi_ABの時間領域補間と全帯域復元
            Lp = SIM.delayB * num_of_paths_AB; % 有効な最大遅延サンプル数
            F_matrix_p = fft(eye(fft_ptB)); % 128ポイントのFFT行列を生成
            
            phys_valid_idx_B = phys_idx_B(data_idx); %【追加】128pt FFT上での物理インデックス
            
            % 行: 物理インデックス, 列: パス数(1~Lp) の部分行列を抽出
            F_partial_p_valid = F_matrix_p(phys_valid_idx_B, 1:Lp);
            
            % 擬似逆行列を用いて時間タップを逆算
            EST.h_LP = pinv(F_partial_p_valid) * EST.XivecAB_valid; 
            EST.hP = [EST.h_LP; zeros(fft_ptB - Lp, 1)]; % ゼロ詰め
            EST.Xi_vec_AB = fft(EST.hP, fft_ptB); % 128ポイントFFTで周波数領域へ
            EST.HatXivecAB = EST.Xi_vec_AB(phys_idx_B); %【修正】ベースバンド(64個)を抽出


%nullサブキャリアの除去・有効なサブキャリアのみを抽出
RX.b = RX.b(data_idx);
TX_x_valid = TX.x(data_idx, 1);

switch(SIM.mode)
    case {'xb_est1','xb_est2','DASIC1','DASIC2'}
    %% DASIC (周波数領域)
    phi = TX_x_valid(2:end) ./ TX_x_valid(1:end-1);  % 位相シフトを計算
    RX.c=zeros(num_data_subc,1);
    RX.c(1)=RX.b(1);
    RX.c(2: num_data_subc) = RX.b(2: num_data_subc) -  phi.*RX.b(1: num_data_subc-1); %自己干渉除去

    
    RX.c2=zeros( num_data_subc,1);
    RX.c2(1)=RX.b(1);
    RX.c2(2)=RX.b(2);
    RX.c2(3: num_data_subc) = RX.c(3: num_data_subc) -  phi(2:end).*RX.c(2:num_data_subc-1); %自己干渉除去 
end
switch(SIM.mode)
    case {'xb_est'}
            %% BCJR(DASICなしで所望信号推定)
                BCJR.alpha = zeros(4, num_data_subc) - 1e10;
                BCJR.alpha(1,1) = log(1); %log取ると1→確率100%
                BCJR.alpha(1,2) = log(1); %log取ると1→確率100%
                BCJR.beta = zeros(4,num_data_subc) - 1e10;
                BCJR.beta(1,end) = log(1);
                BCJR.beta(1,end-1) = log(1);
                
                BCJR.Gamma = zeros(4,4, num_data_subc-1) - 1e10;
                TX.Xi_vec_AB = EST.HatXivecAB(data_idx);
                
                % --- 前向き処理 (alpha) ---
                for xx = 2: num_data_subc-1
                    trel = BCJRTrellis(TX,xx,CH,G,0,1); 
                
                    for idx_in = 1:trel.num_in  
                        for sigi=1:trel.num_state %状態i
                            BCJR.Gamma(sigi,trel.next_state(sigi,idx_in)+1,xx) = (-1*(abs(RX.b(xx+1)-trel.outputs(sigi,idx_in)))^2)/2/CH.N0;%尤度の計算
                        end
                    end
                   
                    for sigj = 1:trel.num_state%状態j 
                        BCJR.aaa = zeros(trel.num_state,1);
                        for sigi=1:trel.num_state %状態i
                            BCJR.aaa(sigi)=BCJR.alpha(sigi,xx)+BCJR.Gamma(sigi,sigj,xx);
                        end
                        BCJR.alpha(sigj,xx+1) = LOG_MAP(BCJR.aaa,trel.num_state);
                    end  
                    
                    % 【追加】alphaの規格化（最大値を0にシフト）
                    BCJR.max_alpha = max(BCJR.alpha(:, xx+1));
                    BCJR.alpha(:, xx+1) = BCJR.alpha(:, xx+1) - BCJR.max_alpha;
                end
                
                % --- 後ろ向き処理 (beta) ---
                for xx =  num_data_subc:-1:2
                    for sigi = 1:trel.num_state%状態i
                        BCJR.bbb = zeros(trel.num_state,1);
                        for sigj=1:trel.num_state %状態j
                            BCJR.bbb(sigj)=BCJR.beta(sigj,xx)+BCJR.Gamma(sigi,sigj,xx-1);
                        end
                        BCJR.beta(sigi,xx-1) = LOG_MAP(BCJR.bbb,trel.num_state );
                    end  
                    
                    % 【追加】betaの規格化（最大値を0にシフト）
                    BCJR.max_beta = max(BCJR.beta(:, xx-1));
                    BCJR.beta(:, xx-1) = BCJR.beta(:, xx-1) - BCJR.max_beta;
                
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
                end
                %% BCJRからの判定
                if intrlv==1
                    BCJR.a=randdeintrlv(BCJR.L(3:end-4),1);
                else
                    BCJR.a=BCJR.L(3:end-4);
                end
                 BCJR.a = max(min(BCJR.a, SIM.LLRclip), -SIM.LLRclip); %APPDecでオーバーフローしないためのクリッピング
                 
                 % 【修正】52固定から動的サイズに変更
                 app_dummy = zeros(length(BCJR.a)/2, 1);
                 BCJR.decode_bhat = APPDec(app_dummy, BCJR.a);
                 det.decode = BCJR.decode_bhat>0;
                 
                 % 【修正】6固定から動的変数に変更
                 A = det.decode(1:end-conv_tail_bits);
                 AA = step(ConEnc, A);
                 AAA = randintrlv(round(AA), 1);
                 
                 % 【修正】ゼロ配列を直書きせず pad_zeros を使用
                 AAAA = [pad_zeros; AAA; pad_zeros];
                 xbhat = pskmod(double(AAAA), G.Q, pi/G.Q, InputType="bit");
    case {'xb_est1','DASIC1'}
                %% 一段用BCJR

                BCJR1.alpha = zeros(4, num_data_subc) - 1e10;
                BCJR1.alpha(1,1) = log(1); %log取ると1→確率100%
                BCJR1.alpha(1,2) = log(1); %log取ると1→確率100%
                BCJR1.beta = zeros(4, num_data_subc) - 1e10;
                BCJR1.beta(1,end) = log(1);
                BCJR1.beta(1,end-1) = log(1);
                BCJR1.Gamma= zeros(4,4, num_data_subc-1) - 1e10;
                TX.Xi_vec_AB = EST.HatXivecAB(data_idx);
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
            
                % 【追加】alphaの規格化（最大値を0にシフト）
                BCJR1.max_alpha = max(BCJR1.alpha(:, xx+1));
                BCJR1.alpha(:, xx+1) = BCJR1.alpha(:, xx+1) - BCJR1.max_alpha;
             end
             
             
             for xx = length(RX.c):-1:3
                 
                 for sigi = 1:trel1.num_state%状態i
                    BCJR1.bbb = zeros(trel1.num_state,1);
                    for sigj=1:trel1.num_state %状態j
                      BCJR1.bbb(sigj)=BCJR1.beta(sigj,xx)+BCJR1.Gamma(sigi,sigj,xx-1);
                    end
               
                     BCJR1.beta(sigi,xx-1) = LOG_MAP(BCJR1.bbb,trel1.num_state );
               
                 end  
            
                % 【追加】betaの規格化（最大値を0にシフト）
                BCJR1.max_beta = max(BCJR1.beta(:, xx-1));
                BCJR1.beta(:, xx-1) = BCJR1.beta(:, xx-1) - BCJR1.max_beta;
            
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
            BCJR1.a = max(min(BCJR1.a, SIM.LLRclip), -SIM.LLRclip);
            
            % 【修正】動的サイズ
            app_dummy = zeros(length(BCJR1.a)/2, 1);
            BCJR1.decode_bhat = APPDec(app_dummy, BCJR1.a);
            BCJR1.decode = BCJR1.decode_bhat>0;
            
            %%推定所望信号シンボルの作成
            % 【修正】動的変数と pad_zeros を使用
            A = BCJR1.decode(1:end-conv_tail_bits);
            AA = step(ConEnc, A);
            AAA = randintrlv(round(AA), 1);
            
            AAAA = [pad_zeros; AAA; pad_zeros];
            xbhat = pskmod(double(AAAA), G.Q, pi/G.Q, InputType="bit");
end
switch SIM.mode
case {'xb_est2','DASIC2'}
%% 二段用BCJR

        BCJR2.alpha = zeros(16, num_data_subc)- 1e10;
        BCJR2.alpha(1,1) = log(1); %log取ると1→確率100%
        BCJR2.alpha(1,2) = log(1); %log取ると1→確率100%
        BCJR2.beta = zeros(16, num_data_subc)- 1e10;
        BCJR2.beta(1,end) = log(1);
        BCJR2.beta(1,end-1) = log(1);

        BCJR2.Gamma= zeros(16,16, num_data_subc-1)- 1e10;
        TX.Xi_vec_AB = EST.HatXivecAB(data_idx);
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
BCJR2.a = max(min(BCJR2.a, SIM.LLRclip), -SIM.LLRclip);

% 【修正】動的サイズ
app_dummy = zeros(length(BCJR2.a)/2, 1);
BCJR2.decode_bhat = APPDec(app_dummy, BCJR2.a);
BCJR2.decode = BCJR2.decode_bhat>0;

%シンボルを復号してから作成
% 【修正】動的変数と pad_zeros を使用
A = BCJR2.decode(1:end-conv_tail_bits);
AA = step(ConEnc, A);
AAA = randintrlv(round(AA), 1);

AAAA = [pad_zeros; AAA; pad_zeros];
xbhat = pskmod(double(AAAA), G.Q, pi/G.Q, InputType="bit");
end
%%チャネル推定
switch SIM.mode
    case 'est'
        % 所望信号も雑音扱いでXi_AA推定 (有効サブキャリアのみ)
        EST.Xi_valid = RX.b ./ TX.x(data_idx, 1);
        
    case {'xb_est','xb_est1','xb_est2'}
        % 推定した所望信号を減算してXi_AA推定 (有効サブキャリアのみ)
        % ※ xbhat は既に56要素なので、(data_idx) は不要です
        EST.Xi_valid = (RX.b - EST.HatXivecAB(data_idx) .* xbhat) ./ TX.x(data_idx, 1);
end

switch SIM.mode
    case {'est','xb_est','xb_est1','xb_est2'}
        %% 帯域制限(Virtual Subcarrier)を考慮した時間領域チャネル復元  
        L = SIM.delayA * num_of_paths_AA; % 有効な最大遅延サンプル数 (これ以降の時間は0)
        F_matrix = fft(eye(fft_ptA)); % 128ポイントのFFT行列を生成     
        
        phys_valid_idx_A = phys_idx_A(data_idx); %【追加】物理インデックス
        
        % 行: 物理インデックス, 列: パス数(1~L) の部分行列を抽出
        F_partial_valid = F_matrix(phys_valid_idx_A, 1:L);  
        % LS推定: 擬似逆行列(pinv)を用いて、56個の周波数成分からL個の時間タップを逆算
        EST.h_L = pinv(F_partial_valid) * EST.Xi_valid; 
        % 128ポイントのインパルス応答として再構成 (L以降はゼロ詰め＝完全な窓関数)
        EST.h = [EST.h_L; zeros(fft_ptA - L, 1)]; 
        % 128ポイントFFTで周波数領域へ
        EST.Xi_vec_AA = fft(EST.h, fft_ptA);
        % 3. 最終的なチャネル推定値 (ベースバンド64個を抽出)
        EST.XiHat = EST.Xi_vec_AA(phys_idx_A);
        
    case {'Perfect'}
        EST.XiHat = Xi_vec_AA(phys_idx_A); %【修正】物理インデックスで抽出
end
%% SIのレプリカを減算し，復号
switch SIM.mode
    case {'Perfect','est','xb_est','xb_est1','xb_est2'}
        tilde_xb = RX.b - EST.XiHat(data_idx) .* TX.x(data_idx, 1);
%% BCJR
        % 【修正】初期値を -1000000 から -1e10 に変更
        BCJR.alpha = zeros(4,num_data_subc) - 1e10;
        BCJR.alpha(1,1) = log(1); %log取ると1→確率100%
        BCJR.alpha(1,2) = log(1); %log取ると1→確率100%
        BCJR.beta = zeros(4,num_data_subc) - 1e10;
        BCJR.beta(1,end) = log(1);
        BCJR.beta(1,end-1) = log(1);
        BCJR.Gamma= zeros(4,4,num_data_subc-1) - 1e10;
        TX.Xi_vec_AB=EST.HatXivecAB(data_idx);

 for xx = 2:num_data_subc-1
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

    BCJR.max_alpha = max(BCJR.alpha(:, xx+1));
    BCJR.alpha(:, xx+1) = BCJR.alpha(:, xx+1) - BCJR.max_alpha;
 end
 
 
 for xx = num_data_subc:-1:2
     
     for sigi = 1:trel.num_state%状態i
        BCJR.bbb = zeros(trel.num_state,1);
        for sigj=1:trel.num_state %状態j
          BCJR.bbb(sigj)=BCJR.beta(sigj,xx)+BCJR.Gamma(sigi,sigj,xx-1);
        end
   
         BCJR.beta(sigi,xx-1) = LOG_MAP(BCJR.bbb,trel.num_state );
   
     end  

    BCJR.max_beta = max(BCJR.beta(:, xx-1));
    BCJR.beta(:, xx-1) = BCJR.beta(:, xx-1) - BCJR.max_beta;

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
 end
 % この後に続くデインターリーブや APPDec の処理はそのままお使いください
%% BCJRからの判定
% b_hat_t=b_hat(1:end-2);
% deint_bhat = randdeintrlv(double(b_hat_t),1);
if intrlv==1
    BCJR.a=randdeintrlv(BCJR.L(3:end-4),1);
else
    BCJR.a=BCJR.L(3:end-4);
end
BCJR.a = max(min(BCJR.a, SIM.LLRclip), -SIM.LLRclip);

% 【修正】動的サイズ
app_dummy = zeros(length(BCJR.a)/2, 1);
BCJR.decode_bhat = APPDec(app_dummy, BCJR.a);
det.decode = BCJR.decode_bhat>0;
end
    %% Error count

    switch SIM.mode
        case {'Perfect','est','xb_est','xb_est1','xb_est2'}
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
