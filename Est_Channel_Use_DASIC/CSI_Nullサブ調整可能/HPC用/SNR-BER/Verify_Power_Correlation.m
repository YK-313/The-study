%% Verify_Power_Correlation.m
% Type 1 (1-stage / 2-stage) における「判定エラー」と「真のチャネル電力」の相関を定量的に検証するスクリプト

clear; clc;
startTime = clock;

%%%%%%%%%%%%%%%%%%%%
%%%% Parameters %%%%
%%%%%%%%%%%%%%%%%%%%
SIM.SNR     = 14;            % 14dBに固定
SIM.SIR     = -60;           % -60dBに固定
SIM.nsamp   = 100000;          % 平均を取るための十分なサンプル数
SIM.err_max = SIM.nsamp * 64; 
SIM.rho     = -3;
SIM.Nrho    = -3;
SIM.nsym    = 64;            
SIM.ndata   = SIM.nsym;
SIM.over    = 2;
SIM.delayA  = 1;
SIM.delayB  = 2;
SIM.int     = 1; 
SIM.AA      = 2;
SIM.AB      = 16;
SIM.LLRclip = 10000000000;
G.Q         = 4; 
G.ml        = log2(G.Q);
SIM.detmode = 'BCJR';     
SIM.PilotMode = 'simul'; 
SIM.modeAB  = 'SIC'; 
SIM.null    = 'true';

% 検証するモードのリスト
modes_to_test = {'xb_est1', 'xb_est2'};

fprintf('--- 判定エラーと所望チャネル電力(|Xi_AB|^2)の相関検証 ---\n');
fprintf('サンプル数: %d, SNR: %d dB, SIR: %d dB\n\n', SIM.nsamp, SIM.SNR, SIM.SIR);

for m = 1:length(modes_to_test)
    SIM.mode = modes_to_test{m};
    fprintf('[%s] のシミュレーションを実行中...\n', SIM.mode);
    
    % タスク実行
    RES = run_validation_task(SIM.SNR, 1, SIM, G);
    
    % 結果の表示
    fprintf('  => 正解サブキャリアの平均平均電力 : %.4f\n', RES.mean_pow_corr);
    fprintf('  => 間違えたサブキャリアの平均平均電力: %.4f\n', RES.mean_pow_err);
    fprintf('  => 平均BER: %.4f\n\n', RES.BER);
end

elapsedTime = etime(clock, startTime);
fprintf('Total elapsed time is %2.1f seconds\n', elapsedTime); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 以下、完全に統合されたメインタスク関数 (Local Function)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIM = run_validation_task(En, idx, SIM, G)
    CH.N0 = 10^(-En/10); 
    ERR.noe   = zeros(SIM.nsamp,1);    
    ERR.nod   = zeros(SIM.nsamp,1);    
    
    % 電力統計用配列の初期化
    ERR.pow_corr = NaN(SIM.nsamp, 1);
    ERR.pow_err  = NaN(SIM.nsamp, 1);
    
    num_of_paths_AA = SIM.AA; 
    num_of_paths_AB = SIM.AB; 
    fft_ptA = SIM.over*SIM.ndata; 
    fft_ptB = SIM.over*SIM.ndata; 
    intrlv=SIM.int;
    
    trellis = poly2trellis(7,[171 133]); 
    ConEnc = comm.ConvolutionalEncoder(trellis,'TerminationMethod','Terminated');
    APPDec = comm.APPDecoder(trellis,'Algorithm','True APP','TerminationMethod','Terminated');
    
    for idx_loop = 1:SIM.nsamp
        % --- 1. Nullサブキャリアの設定 ---
        data_idx = [2 : (SIM.ndata/2 - 3), (SIM.ndata/2 + 5) : SIM.ndata]; 
        freq_ordered_idx = [(SIM.ndata/2 + 5) : SIM.ndata, 2 : (SIM.ndata/2 - 3)];
        num_data_subc = length(data_idx); 
        
        bits_per_symbol = log2(G.Q);                  
        total_bits = num_data_subc * bits_per_symbol; 
        bcjr_pad_bits = 8;                            
        conv_tail_bits = log2(trellis.numStates);     
        conv_rate = 2;                                
        num_info_bits = (total_bits - bcjr_pad_bits) / conv_rate - conv_tail_bits;
        
        % --- 2. データの生成 ---
        TX.b = randn(num_info_bits, 2) > 0; 
        TX.p = randn(total_bits, 2) > 0;    
        TX.codedata(:,1) = step(ConEnc, TX.b(:,1)); 
        TX.codedata(:,2) = step(ConEnc, TX.b(:,2)); 
        
        if intrlv==1
            TX.codedata_in = round(TX.codedata);
            TX.codedata_in(:,1) = randintrlv(TX.codedata_in(:,1), 1);
            TX.codedata_in(:,2) = randintrlv(TX.codedata_in(:,2), 1);
        else
            TX.codedata_in = TX.codedata;
        end
        
        boundary_idx = 1;
        for i = 1:num_data_subc-1
            if freq_ordered_idx(i+1) < freq_ordered_idx(i)
                boundary_idx = i; break;
            end
        end
        pad_zeros = zeros(bcjr_pad_bits / 2, 1); 
        idx_data1 = boundary_idx * bits_per_symbol - length(pad_zeros);
        
        TX.codedata_int = zeros(total_bits, 2);
        TX.codedata_int(:,1) = [TX.codedata_in(1:idx_data1, 1); pad_zeros; pad_zeros; TX.codedata_in(idx_data1+1:end, 1)];
        TX.codedata_int(:,2) = [TX.codedata_in(1:idx_data1, 2); pad_zeros; pad_zeros; TX.codedata_in(idx_data1+1:end, 2)];
        
        % --- 3. 変調とマッピング ---
        TX_x_data = pskmod(double(TX.codedata_int), G.Q, pi/G.Q, InputType="bit");
        TX_p_data = pskmod(double(TX.p), G.Q, pi/G.Q, InputType="bit");
        TX.x = zeros(SIM.ndata, 2); TX.pSym = zeros(SIM.ndata, 2);
        TX.x(data_idx, 1) = TX_x_data(:, 1); TX.x(data_idx, 2) = TX_x_data(:, 2);
        TX.pSym(data_idx, 1) = TX_p_data(:, 1); TX.pSym(data_idx, 2) = TX_p_data(:, 2);
        
        half_ndata = SIM.ndata / 2;
        phys_idx_A = [1:half_ndata, (fft_ptA - half_ndata + 1):fft_ptA].';
        phys_idx_B = [1:half_ndata, (fft_ptB - half_ndata + 1):fft_ptB].';
        TX.x_128_A = zeros(fft_ptA, 1); TX.x_128_A(phys_idx_A) = TX.x(:,1);
        TX.x_128_B = zeros(fft_ptB, 1); TX.x_128_B(phys_idx_B) = TX.x(:,2);
        TX.p_128_A = zeros(fft_ptA, 1); TX.p_128_A(phys_idx_A) = TX.pSym(:,1);
        TX.p_128_B = zeros(fft_ptB, 1); TX.p_128_B(phys_idx_B) = TX.pSym(:,2);
        TX.sA = ifft(TX.x_128_A, fft_ptA) .* sqrt(fft_ptA);
        TX.sB = ifft(TX.x_128_B, fft_ptB) .* sqrt(fft_ptB);
        TX.pA = ifft(TX.p_128_A, fft_ptA) .* sqrt(fft_ptA);
        TX.pB = ifft(TX.p_128_B, fft_ptB) .* sqrt(fft_ptB);
        
        % --- 4. 通信路行列 ---
        delay_profile_AA = (randn(num_of_paths_AA, 1) + 1i * randn(num_of_paths_AA, 1))./sqrt(2 * num_of_paths_AA);
        delay_profile_AB = (randn(num_of_paths_AB, 1) + 1i * randn(num_of_paths_AB, 1))./sqrt(2 * num_of_paths_AB);
        delay_profile_AA_s = delay_profile_AA./abs(delay_profile_AA);
        delay_profile_AB_s = delay_profile_AB./abs(delay_profile_AB)./sqrt(length(delay_profile_AB)); 
        
        delay_profile_AA_rho=zeros(size(delay_profile_AA_s));
        rho_sum=0;
        for rr = 2:SIM.AA
            rho = 10^( (SIM.rho+SIM.Nrho*(rr-2)) /10); 
            rho_sum = rho_sum+rho;
        end
        delay_profile_AA_rho(1) = delay_profile_AA_s(1)*sqrt(1/( 1 + rho_sum ) );
        for dd=2:SIM.AA
            delay_profile_AA_rho(dd) = delay_profile_AA_s(dd)*sqrt(10^( (SIM.rho+SIM.Nrho*(dd-2))/10)*abs(delay_profile_AA_rho(1))^2);
        end
        
        P_b=sum(abs(delay_profile_AB_s).^2);
        delay_profile_AA_sir=delay_profile_AA_rho*sqrt(P_b*10^(-SIM.SIR/10));
        
        H_circ_AB = []; tmp_profile_AB = zeros(fft_ptB,1); tmp_profile_AB(1:SIM.delayB:SIM.delayB*num_of_paths_AB)= delay_profile_AB_s;
        for iii = 1:fft_ptB, H_circ_AB = [H_circ_AB circshift(tmp_profile_AB, iii - 1)]; end
        H_circ_AA = []; tmp_profile_AA = zeros(fft_ptA,1); tmp_profile_AA(1:SIM.delayA:SIM.delayA*num_of_paths_AA)= delay_profile_AA_sir;
        for iii = 1:fft_ptA, H_circ_AA = [H_circ_AA circshift(tmp_profile_AA, iii - 1)]; end
        
        H_circ_AB = sparse(H_circ_AB); H_circ_AA = sparse(H_circ_AA);
        Xi_vec_AB = fft(tmp_profile_AB, fft_ptB);
        Xi_vec_AA = fft(tmp_profile_AA, fft_ptA);
        
        % --- 5. 受信とノイズ ---
        RX.s_AA=H_circ_AA*TX.sA; RX.s_AB=H_circ_AB*TX.sB;
        RX.pAA=H_circ_AA*TX.pA; RX.pAB=H_circ_AB*TX.pB;
        CH.f = (randn(SIM.ndata, 1) + 1i * randn(SIM.ndata, 1)) * sqrt(CH.N0 / 2);
        CH_f_128 = zeros(fft_ptB, 1); CH_f_128(phys_idx_B) = CH.f; 
        CH.n = ifft(CH_f_128, fft_ptB) .* sqrt(fft_ptB);
        CH.pf = (randn(SIM.ndata, 1) + 1i * randn(SIM.ndata, 1)) * sqrt(CH.N0 / 2);
        CH_pf_128 = zeros(fft_ptB, 1); CH_pf_128(phys_idx_B) = CH.pf; 
        CH.pn = ifft(CH_pf_128, fft_ptB) .* sqrt(fft_ptB);
        
        RX.bA = fft(RX.s_AA, fft_ptA)./sqrt(fft_ptA); RX.bA = RX.bA(phys_idx_A);
        RX.bB = fft(RX.s_AB, fft_ptB)./sqrt(fft_ptB); RX.bB = RX.bB(phys_idx_B);
        RX.bN = fft(CH.n, fft_ptB)./sqrt(fft_ptB); RX.bN = RX.bN(phys_idx_B);
        RX.pA = fft(RX.pAA, fft_ptA)./sqrt(fft_ptA); RX.pA = RX.pA(phys_idx_A);
        RX.pB = fft(RX.pAB, fft_ptB)./sqrt(fft_ptB); RX.pB = RX.pB(phys_idx_B);
        RX.pN = fft(CH.pn, fft_ptB)./sqrt(fft_ptB); RX.pN = RX.pN(phys_idx_B);
        RX.b = RX.bA + RX.bB + RX.bN; 
        
        % --- 6. チャネル推定 ---
        RX.p=RX.pB+RX.pA+RX.pN; 
        P.EST.Xi_valid = RX.p(data_idx) ./ TX.pSym(data_idx, 1);
        P.L = SIM.delayA * num_of_paths_AA; 
        P.F_matrix = fft(eye(fft_ptA)); 
        P.F_partial_valid = P.F_matrix(phys_idx_A(data_idx), 1:P.L);
        P.EST.h_L = pinv(P.F_partial_valid) * P.EST.Xi_valid; 
        P.EST.h = [P.EST.h_L; zeros(fft_ptA - P.L, 1)]; 
        P.EST.Xi_vec_AA = fft(P.EST.h, fft_ptA);
        P.EST.XiHat = P.EST.Xi_vec_AA(phys_idx_A);
        
        TildePilot_valid = RX.p(data_idx) - P.EST.XiHat(data_idx) .* TX.pSym(data_idx, 1); 
        EST.XivecAB_valid = TildePilot_valid ./ TX.pSym(data_idx, 2);
        Lp = SIM.delayB * num_of_paths_AB; 
        F_matrix_p = fft(eye(fft_ptB)); 
        F_partial_p_valid = F_matrix_p(phys_idx_B(data_idx), 1:Lp);
        EST.h_LP = pinv(F_partial_p_valid) * EST.XivecAB_valid; 
        EST.hP = [EST.h_LP; zeros(fft_ptB - Lp, 1)]; 
        EST.Xi_vec_AB = fft(EST.hP, fft_ptB); 
        EST.HatXivecAB = EST.Xi_vec_AB(phys_idx_B);
        
        RX.b_valid = RX.b(data_idx);
        TX.x_valid = TX.x(data_idx, 1);
        RX.b_ordered = RX.b(freq_ordered_idx);
        TX.x_ordered = TX.x(freq_ordered_idx, 1);
        EST.HatXivecAB_ordered = EST.HatXivecAB(freq_ordered_idx);
        
        % --- 7. DASIC 演算 ---
        phi = TX.x_ordered(2:end) ./ TX.x_ordered(1:end-1); 
        RX.c_ordered = zeros(num_data_subc, 1);
        RX.c_ordered(1) = RX.b_ordered(1);
        RX.c_ordered(2:num_data_subc) = RX.b_ordered(2:num_data_subc) - phi .* RX.b_ordered(1:num_data_subc-1);
        RX.c2_ordered = zeros(num_data_subc, 1);
        RX.c2_ordered(1) = RX.b_ordered(1);
        RX.c2_ordered(2) = RX.b_ordered(2);
        RX.c2_ordered(3:num_data_subc) = RX.c_ordered(3:num_data_subc) - phi(2:end) .* RX.c_ordered(2:num_data_subc-1);
        
        % --- 8. レプリカ生成 (xb_est1 / xb_est2) 完全版 ---
        if strcmp(SIM.mode, 'xb_est1')
            %% 一段用BCJR
            BCJR1.alpha = zeros(4, num_data_subc) - 1e10;
            BCJR1.alpha(1,1) = log(1); BCJR1.alpha(1,2) = log(1);
            BCJR1.beta = zeros(4, num_data_subc) - 1e10;
            BCJR1.beta(1,end) = log(1); BCJR1.beta(1,end-1) = log(1);
            BCJR1.Gamma= zeros(4,4, num_data_subc-1) - 1e10;
            TX.Xi_vec_AB = EST.HatXivecAB_ordered;
            TX.phi=phi;
            
            for xx = 2:length(RX.c_ordered)-1
                trel1 = BCJRTrellisDasic(TX,xx,CH,G,0,1);
                for idx_in = 1:trel1.num_in
                    for sigi=1:trel1.num_state 
                        BCJR1.Gamma(sigi,trel1.next_state(sigi,idx_in)+1,xx) = (-1*(abs(RX.c_ordered(xx+1)-trel1.outputs(sigi,idx_in)))^2)/2/CH.N0;
                    end
                end
                for sigj = 1:trel1.num_state
                    BCJR1.aaa = zeros(trel1.num_state,1);
                    for sigi=1:trel1.num_state 
                        BCJR1.aaa(sigi)=BCJR1.alpha(sigi,xx)+BCJR1.Gamma(sigi,sigj,xx);
                    end
                    BCJR1.alpha(sigj,xx+1) = LOG_MAP(BCJR1.aaa,trel1.num_state);
                end
                BCJR1.max_alpha = max(BCJR1.alpha(:, xx+1));
                BCJR1.alpha(:, xx+1) = BCJR1.alpha(:, xx+1) - BCJR1.max_alpha;
            end
            
            for xx = length(RX.c_ordered):-1:2
                for sigi = 1:trel1.num_state
                    BCJR1.bbb = zeros(trel1.num_state,1);
                    for sigj=1:trel1.num_state 
                        BCJR1.bbb(sigj)=BCJR1.beta(sigj,xx)+BCJR1.Gamma(sigi,sigj,xx-1);
                    end
                    BCJR1.beta(sigi,xx-1) = LOG_MAP(BCJR1.bbb,trel1.num_state );
                end
                BCJR1.max_beta = max(BCJR1.beta(:, xx-1));
                BCJR1.beta(:, xx-1) = BCJR1.beta(:, xx-1) - BCJR1.max_beta;
                
                for idx_in = 1:trel1.num_in
                    for sigi = 1:trel1.num_state
                        state = trel1.next_state(sigi,idx_in)+1;
                        BCJR1.L0(sigi) = BCJR1.Gamma(sigi,state,xx-1)+BCJR1.beta(state,xx)+BCJR1.alpha(sigi,xx-1);
                    end
                    BCJR1.LL(idx_in) = LOG_MAP(BCJR1.L0,trel1.num_state );
                end
                
                BCJR1.LLL1 = BCJR1.LL(3) + log(1+exp(-1*(abs( BCJR1.LL(3)- BCJR1.LL(4)))));
                if BCJR1.LL(4)>BCJR1.LL(3), BCJR1.LLL1 = BCJR1.LL(4) + log(1+exp(-1*(abs( BCJR1.LL(3)- BCJR1.LL(4))))); end
                BCJR1.LLL2 = BCJR1.LL(1) + log(1+exp(-1*(abs(BCJR1.LL(1)-BCJR1.LL(2)))));
                if BCJR1.LL(2)>BCJR1.LL(1), BCJR1.LLL2 = BCJR1.LL(2) + log(1+exp(-1*(abs(BCJR1.LL(1)-BCJR1.LL(2))))); end
                BCJR1.LLL3 = BCJR1.LL(2) + log(1+exp(-1*(abs(BCJR1.LL(2)-BCJR1.LL(4)))));
                if BCJR1.LL(4)>BCJR1.LL(2), BCJR1.LLL3 = BCJR1.LL(4) + log(1+exp(-1*(abs(BCJR1.LL(2)-BCJR1.LL(4))))); end
                BCJR1.LLL4 = BCJR1.LL(1) + log(1+exp(-1*(abs(BCJR1.LL(1)-BCJR1.LL(3)))));
                if BCJR1.LL(3)>BCJR1.LL(1), BCJR1.LLL4 = BCJR1.LL(3) + log(1+exp(-1*(abs(BCJR1.LL(1)-BCJR1.LL(3))))); end
                
                BCJR1.L(2*(xx-1)-1,1) = BCJR1.LLL1-BCJR1.LLL2;
                BCJR1.L(2*(xx-1),1) = BCJR1.LLL3-BCJR1.LLL4;
            end
            
            L_ordered_data = BCJR1.L(3:end-4);
            chunk2_len = length(L_ordered_data) - idx_data1;
            BCJR1.L_valid = [L_ordered_data(chunk2_len+1 : end); L_ordered_data(1 : chunk2_len)];
            
            if intrlv==1, BCJR1.a = randdeintrlv(BCJR1.L_valid, 1);
            else, BCJR1.a = BCJR1.L_valid; end
            BCJR1.a = max(min(BCJR1.a, SIM.LLRclip), -SIM.LLRclip);
            
            app_dummy = zeros(length(BCJR1.a)/2, 1);
            BCJR1.decode_bhat = APPDec(app_dummy, BCJR1.a);
            BCJR1.decode = BCJR1.decode_bhat > 0;
            
            A = BCJR1.decode(1:end-conv_tail_bits);
            AA = step(ConEnc,A);
            AAA = randintrlv(round(AA),1);
            AAAA = [AAA(1:idx_data1); pad_zeros; pad_zeros; AAA(idx_data1+1:end)];
            xbhat = pskmod(double(AAAA), G.Q, pi/G.Q, InputType="bit");
            
        elseif strcmp(SIM.mode, 'xb_est2')
            %% 二段用BCJR
            BCJR2.alpha = zeros(16, num_data_subc)- 1e10;
            BCJR2.alpha(1,1) = log(1); BCJR2.alpha(1,2) = log(1);
            BCJR2.beta = zeros(16, num_data_subc)- 1e10;
            BCJR2.beta(1,end) = log(1); BCJR2.beta(1,end-1) = log(1);
            BCJR2.Gamma= zeros(16,16, num_data_subc-1)- 1e10;
            TX.Xi_vec_AB = EST.HatXivecAB_ordered;
            TX.phi=phi;
            
            for xx = 2:length(RX.c2_ordered)-1
                trel2 = BCJRTrellis2Dasic(TX,xx,CH,G,0,1);
                for idx_in = 1:trel2.num_in
                    for state=1:16 
                        BCJR2.Gamma(state,trel2.next_state(state,idx_in)+1,xx) = (-1*(abs(RX.c2_ordered(xx+1)-trel2.outputs(state,idx_in)))^2)/6/CH.N0;
                    end
                end
                for sigk = 1:16 
                    BCJR2.aaa = zeros(16,1);
                    for state=1:16 
                        BCJR2.aaa(state) = BCJR2.alpha(state,xx) + BCJR2.Gamma(state,sigk,xx);
                    end
                    BCJR2.alpha(sigk, xx+1) = LOG_MAP( BCJR2.aaa, 16);
                end
                BCJR2.max_val = max( BCJR2.alpha(:, xx+1));
                BCJR2.alpha(:, xx+1) = BCJR2.alpha(:, xx+1) - BCJR2.max_val;
            end
            
            for xx = length(RX.c2_ordered):-1:2
                for state = 1:16
                    BCJR2.bbb = zeros(16,1);
                    for sigk=1:16 
                        BCJR2.bbb(sigk)= BCJR2.beta(sigk,xx)+ BCJR2.Gamma(state,sigk,xx-1);
                    end
                    BCJR2.beta(state,xx-1) = LOG_MAP( BCJR2.bbb,16);
                end
                BCJR2.max_val = max( BCJR2.beta(:, xx-1));
                BCJR2.beta(:, xx-1) = BCJR2.beta(:, xx-1) - BCJR2.max_val;
                
                for idx_in = 1:trel2.num_in
                    for state = 1:16
                        nstate = trel2.next_state(state,idx_in)+1;
                        BCJR2.L0(state) = BCJR2.Gamma(state,nstate,xx-1)+ BCJR2.beta(nstate,xx)+ BCJR2.alpha(state,xx-1);
                    end
                    BCJR2.LL(idx_in) = LOG_MAP( BCJR2.L0,16);
                end
                
                BCJR2.LLL1 = BCJR2.LL(3) + log(1+exp(-1*(abs( BCJR2.LL(3)- BCJR2.LL(4)))));
                if BCJR2.LL(4)> BCJR2.LL(3), BCJR2.LLL1 = BCJR2.LL(4) + log(1+exp(-1*(abs( BCJR2.LL(3)- BCJR2.LL(4))))); end
                BCJR2.LLL2 = BCJR2.LL(1) + log(1+exp(-1*(abs( BCJR2.LL(1)- BCJR2.LL(2)))));
                if BCJR2.LL(2)> BCJR2.LL(1), BCJR2.LLL2 = BCJR2.LL(2) + log(1+exp(-1*(abs( BCJR2.LL(1)- BCJR2.LL(2))))); end
                BCJR2.LLL3 = BCJR2.LL(2) + log(1+exp(-1*(abs( BCJR2.LL(2)- BCJR2.LL(4)))));
                if BCJR2.LL(4)> BCJR2.LL(2), BCJR2.LLL3 = BCJR2.LL(4) + log(1+exp(-1*(abs( BCJR2.LL(2)- BCJR2.LL(4))))); end
                BCJR2.LLL4 = BCJR2.LL(1) + log(1+exp(-1*(abs( BCJR2.LL(1)- BCJR2.LL(3)))));
                if BCJR2.LL(3)> BCJR2.LL(1), BCJR2.LLL4 = BCJR2.LL(3) + log(1+exp(-1*(abs( BCJR2.LL(1)- BCJR2.LL(3))))); end
                
                BCJR2.L(2*(xx-1)-1,1) = BCJR2.LLL1- BCJR2.LLL2;
                BCJR2.L(2*(xx-1),1) = BCJR2.LLL3- BCJR2.LLL4;
            end
            
            L_ordered_data = BCJR2.L(3:end-4);
            chunk2_len = length(L_ordered_data) - idx_data1;
            BCJR2.L_valid = [L_ordered_data(chunk2_len+1 : end); L_ordered_data(1 : chunk2_len)];
            
            if intrlv==1, BCJR2.a = randdeintrlv(BCJR2.L_valid, 1);
            else, BCJR2.a = BCJR2.L_valid; end
            BCJR2.a = max(min(BCJR2.a, SIM.LLRclip), -SIM.LLRclip);
            
            app_dummy = zeros(length(BCJR2.a)/2, 1);
            BCJR2.decode_bhat = APPDec(app_dummy, BCJR2.a);
            BCJR2.decode = BCJR2.decode_bhat > 0;
            
            A = BCJR2.decode(1:end-conv_tail_bits);
            AA = step(ConEnc,A);
            AAA = randintrlv(round(AA),1);
            AAAA = [AAA(1:idx_data1); pad_zeros; pad_zeros; AAA(idx_data1+1:end)];
            xbhat = pskmod(double(AAAA), G.Q, pi/G.Q, InputType="bit");
        end
        
        % --- 9. 【重要】判定エラーと真のチャネル電力の相関計算 ---
        if exist('xbhat', 'var')
            true_Xi_AB_valid = Xi_vec_AB(phys_idx_B(data_idx));
            pow_Xi_AB = abs(true_Xi_AB_valid).^2; % 電力を計算
            
            TX_xB_valid = TX.x(data_idx, 2); 
            sym_error = abs(TX_xB_valid(:) - xbhat(:)) > 0.1; 
            
            % 1シンボル内で正解・不正解それぞれの平均電力を取得
            if sum(~sym_error) > 0
                ERR.pow_corr(idx_loop) = mean(pow_Xi_AB(~sym_error));
            end
            if sum(sym_error) > 0
                ERR.pow_err(idx_loop) = mean(pow_Xi_AB(sym_error));
            end
            
            % エラーカウント (最終BER計算用)
            ERR.noe(idx_loop,:) = sum(sym_error);
            ERR.nod(idx_loop) = length(sym_error);
        end
    end
    
    % サンプル全体の「平均の平均」を計算 (NaNを除外)
    SIM.mean_pow_corr = mean(ERR.pow_corr, 'omitnan');
    SIM.mean_pow_err  = mean(ERR.pow_err, 'omitnan');
    SIM.BER = sum(ERR.noe) / sum(ERR.nod);
end