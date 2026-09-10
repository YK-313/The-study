function SIM = main_task_f_DASIC(En,idx,SIM,G)
CH.N0 = 10^(-En/10); 
ERR.noe   = zeros(SIM.nsamp,1);    ERR.noe_p = zeros(SIM.nsamp,1);    
ERR.nod   = zeros(SIM.nsamp,1);    ERR.nod_p = zeros(SIM.nsamp,1);

% 【追加】検証用の配列を初期化
fft_ptA = SIM.over*SIM.ndata; 
ERR.Err_time_pow = zeros(fft_ptA, 1);
ERR.P_True_AA    = zeros(SIM.nsamp, 1);
ERR.P_Err_Interf = zeros(SIM.nsamp, 1);

num_of_paths_AA = SIM.AA; 
num_of_paths_AB = SIM.AB; 
CH.L=SIM.AB;
fft_ptB = SIM.over*SIM.ndata; 
intrlv=SIM.int;
constellation = [0.7071 + 0.7071i, -0.7071 + 0.7071i, 0.7071 - 0.7071i, -0.7071 - 0.7071i];
alp2bit = de2bi(0:G.Q-1,'left-msb');

%% トレリス作成 拘束長=7
trellis = poly2trellis(7,[171 133]); 
ConEnc = comm.ConvolutionalEncoder(trellis,'TerminationMethod','Terminated');
APPDec = comm.APPDecoder(trellis,'Algorithm','True APP','TerminationMethod','Terminated');

for idx_loop = 1:SIM.nsamp
    TX.b = randn(SIM.ndata-log2(trellis.numStates)-4,2)>0;
    
    TX.codedata(:,1) = step(ConEnc,TX.b(:,1)); 
    TX.codedata(:,2) = step(ConEnc,TX.b(:,2)); 
    
    if intrlv==1
        TX.codedata_in = round(TX.codedata);
        TX.codedata_in(:,1) = randintrlv(TX.codedata_in(:,1),1);
        TX.codedata_in(:,2) = randintrlv(TX.codedata_in(:,2),1);
    else
        TX.codedata_in = TX.codedata;
    end
    
    TX.codedata_int(:,1)=[0;0;0;0;TX.codedata_in(:,1);0;0;0;0];
    TX.codedata_int(:,2)=[0;0;0;0;TX.codedata_in(:,2);0;0;0;0];
    
    %% 変調 (QPSK)
    TX.x = pskmod(double(TX.codedata_int),G.Q,pi/G.Q,InputType="bit"); 
    
    %% 送信信号を時間領域へ
    TX.sA = ifft(TX.x(:,1), fft_ptA).*sqrt(fft_ptA);
    TX.sB = ifft(TX.x(:,2), fft_ptB).*sqrt(fft_ptB);
    
    %% 時空間通信路行列
    delay_profile_AA = (randn(num_of_paths_AA, 1) + 1i * randn(num_of_paths_AA, 1))./sqrt(2 * num_of_paths_AA);
    delay_profile_AB = (randn(num_of_paths_AB, 1) + 1i * randn(num_of_paths_AB, 1))./sqrt(2 * num_of_paths_AB);
    
    delay_profile_AA_s = delay_profile_AA./abs(delay_profile_AA);
    delay_profile_AB_s = delay_profile_AB./abs(delay_profile_AB)./sqrt(length(delay_profile_AB)); 
    
    if SIM.AA==1
        delay_profile_AA_rho=delay_profile_AA_s;
    else
        delay_profile_AA_rho=zeros(size(delay_profile_AA_s));
        rho_sum=0;
        for rr = 2:SIM.AA
            rho = 10^( (SIM.rho-5*(rr-2)) /10); 
            rho_sum = rho_sum+rho;
        end
        delay_profile_AA_rho(1) = delay_profile_AA_s(1)*sqrt(1/( 1 + rho_sum ) );
        for dd=2:SIM.AA
            delay_profile_AA_rho(dd) = delay_profile_AA_s(dd)*sqrt(10^( (SIM.rho-5*(dd-2))/10)*abs(delay_profile_AA_rho(1))^2);
        end
    end
        
    P_b = sum(abs(delay_profile_AB_s).^2);
    delay_profile_AA_sir = delay_profile_AA_rho*sqrt(P_b*10^(-SIM.SIR/10));
        
    %% 巡回通信路行列
    H_circ_AB = [];
    tmp_profile_AB = zeros(fft_ptB,1); 
    tmp_profile_AB (1:SIM.delayB:SIM.delayB*num_of_paths_AB)= delay_profile_AB_s;
    for iii = 1 : fft_ptB
        tmp_AB = circshift(tmp_profile_AB, iii - 1);
        H_circ_AB = [H_circ_AB tmp_AB];
    end
    
    H_circ_AA = [];
    tmp_profile_AA = zeros(fft_ptA,1); 
    tmp_profile_AA (1:SIM.delayA:SIM.delayA*num_of_paths_AA)= delay_profile_AA_sir;
    for iii = 1 : fft_ptA
        tmp_AA = circshift(tmp_profile_AA, iii - 1);
        H_circ_AA = [H_circ_AA tmp_AA];
    end
    
    H_circ_AB = sparse(H_circ_AB);
    H_circ_AA = sparse(H_circ_AA);
    
    Xi_vec_AB = fft(tmp_profile_AB, fft_ptB);
    Xi_mat_AB = diag(sparse(Xi_vec_AB));
    Xi_vec_AA = fft(tmp_profile_AA, fft_ptA);
    Xi_mat_AA = diag(sparse(Xi_vec_AA));
    
    %% Channel 
    ERR.tx_pow(idx_loop) = mean([sum(abs(TX.sA).^2) sum(abs(TX.sB).^2)]);
    
    RX.s_AA = H_circ_AA*TX.sA;
    RX.s_AB = H_circ_AB*TX.sB;    
    
    CH.f = (randn(SIM.ndata, 1) + 1i * randn(SIM.ndata, 1)) * sqrt(CH.N0 / 2);
    CH.n =  ifft(CH.f, fft_ptB).*sqrt(fft_ptB);
 
    RX.bA = fft(RX.s_AA, fft_ptA)./sqrt(fft_ptA);
    RX.bB = fft(RX.s_AB, fft_ptB)./sqrt(fft_ptB);
    RX.bN = fft(CH.n, fft_ptB)./sqrt(fft_ptB);
    RX.b = RX.bA + RX.bB + RX.bN;
    
    ERR.rx_pow(idx_loop) = sum(abs(RX.b).^2);
    
    switch(SIM.mode)
        case {'xb_est1','xb_est2','DASIC1','DASIC2'}
            %% DASIC (周波数領域)
            phi = TX.x(2:end,1) ./ TX.x(1:end-1,1); 
            RX.c=zeros(SIM.ndata,1);
            RX.c(1)=RX.b(1);
            RX.c(2:SIM.ndata) = RX.b(2:SIM.ndata) -  phi.*RX.b(1:SIM.ndata-1); 
            
            RX.c2=zeros(SIM.ndata,1);
            RX.c2(1)=RX.b(1);
            RX.c2(2)=RX.b(2);
            RX.c2(3:SIM.ndata) = RX.c(3:SIM.ndata) -  phi(2:end).*RX.c(2:SIM.ndata-1);  
    end
    
    % --- BCJRの処理部分は変更なし ---
    switch(SIM.mode)
        case {'xb_est'}
            BCJR.alpha = zeros(4,length(TX.x)) - 1e10;
            BCJR.alpha(1,1) = log(1); 
            BCJR.alpha(1,2) = log(1); 
            BCJR.beta = zeros(4,length(TX.x)) - 1e10;
            BCJR.beta(1,end) = log(1);
            BCJR.beta(1,end-1) = log(1);
            BCJR.Gamma = zeros(4,4,length(TX.x)-1) - 1e10;
            TX.Xi_vec_AB = Xi_vec_AB;
            
            for xx = 2:SIM.ndata-1
                trel = BCJRTrellis(TX,xx,CH,G,0,1); 
                for idx_in = 1:trel.num_in  
                    for sigi=1:trel.num_state 
                        BCJR.Gamma(sigi,trel.next_state(sigi,idx_in)+1,xx) = (-1*(abs(RX.b(xx+1)-trel.outputs(sigi,idx_in)))^2)/2/CH.N0;
                    end
                end
                for sigj = 1:trel.num_state
                    BCJR.aaa = zeros(trel.num_state,1);
                    for sigi=1:trel.num_state
                        BCJR.aaa(sigi)=BCJR.alpha(sigi,xx)+BCJR.Gamma(sigi,sigj,xx);
                    end
                    BCJR.alpha(sigj,xx+1) = LOG_MAP(BCJR.aaa,trel.num_state);
                end  
                BCJR.max_alpha = max(BCJR.alpha(:, xx+1));
                BCJR.alpha(:, xx+1) = BCJR.alpha(:, xx+1) - BCJR.max_alpha;
            end
            
            for xx = SIM.ndata:-1:2
                for sigi = 1:trel.num_state
                    BCJR.bbb = zeros(trel.num_state,1);
                    for sigj=1:trel.num_state 
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
                
                BCJR.L(2*(xx-1)-1,1) = BCJR.LLL1-BCJR.LLL2;
                BCJR.L(2*(xx-1),1) = BCJR.LLL3-BCJR.LLL4;
            end
            
            if intrlv==1
                BCJR.a=randdeintrlv(BCJR.L(3:end-4),1);
            else
                BCJR.a=BCJR.L(3:end-4);
            end
            BCJR.a = max(min(BCJR.a, SIM.LLRclip), -SIM.LLRclip); 
            BCJR.decode_bhat=APPDec(zeros(60,1),BCJR.a );
            det.decode=BCJR.decode_bhat>0;
            A=det.decode(1:end-6);
            AA=step(ConEnc,A);
            AAA=randintrlv(round(AA),1);
            AAAA=[0;0;0;0;AAA;0;0;0;0];
            xbhat = pskmod(double(AAAA),G.Q,pi/G.Q,InputType="bit");
            
        case {'xb_est1','DASIC1'}
            BCJR1.alpha = zeros(4,length(TX.x)) - 1e10;
            BCJR1.alpha(1,1) = log(1); 
            BCJR1.alpha(1,2) = log(1); 
            BCJR1.beta = zeros(4,length(TX.x)) - 1e10;
            BCJR1.beta(1,end) = log(1);
            BCJR1.beta(1,end-1) = log(1);
            BCJR1.Gamma= zeros(4,4,length(TX.x)-1) - 1e10;
            TX.Xi_vec_AB=Xi_vec_AB;
            TX.phi=phi;
        
            for xx = 2:length(RX.c)-1
                trel1 = BCJRTrellisDasic(TX,xx,CH,G,0,1); 
                for idx_in = 1:trel1.num_in  
                    for sigi=1:trel1.num_state 
                        BCJR1.Gamma(sigi,trel1.next_state(sigi,idx_in)+1,xx) = (-1*(abs(RX.c(xx+1)-trel1.outputs(sigi,idx_in)))^2)/2/CH.N0;
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
             
            for xx = length(RX.c):-1:3
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
                
                BCJR1.L(2*(xx-1)-1,1) = BCJR1.LLL1-BCJR1.LLL2;
                BCJR1.L(2*(xx-1),1) = BCJR1.LLL3-BCJR1.LLL4;
            end
            
            if intrlv==1
                BCJR1.a=randdeintrlv(BCJR1.L(3:end-4),1);
            else
                BCJR1.a=BCJR1.L(3:end-4);
            end
            BCJR1.a = max(min(BCJR1.a, SIM.LLRclip), -SIM.LLRclip); 
            BCJR1.decode_bhat=APPDec(zeros(60,1),BCJR1.a );
            BCJR1.decode=BCJR1.decode_bhat>0;
            
            A=BCJR1.decode(1:end-6);
            AA=step(ConEnc,A);
            AAA=randintrlv(round(AA),1);
            AAAA=[0;0;0;0;AAA;0;0;0;0];
            xbhat = pskmod(double(AAAA),G.Q,pi/G.Q,InputType="bit");
            
        case {'xb_est2','DASIC2'}
            BCJR2.alpha = zeros(16,length(TX.x))- 1e10;
            BCJR2.alpha(1,1) = log(1); 
            BCJR2.alpha(1,2) = log(1); 
            BCJR2.beta = zeros(16,length(TX.x))- 1e10;
            BCJR2.beta(1,end) = log(1);
            BCJR2.beta(1,end-1) = log(1);
            BCJR2.Gamma= zeros(16,16,length(TX.x)-1)- 1e10;
            TX.Xi_vec_AB=Xi_vec_AB;
            TX.phi=phi;
            
            for xx = 2:length(RX.c2)-1
                trel2 = BCJRTrellis2Dasic(TX,xx,CH,G,0,1); 
                for idx_in = 1:trel2.num_in 
                    for state=1:16 
                        BCJR2.Gamma(state,trel2.next_state(state,idx_in)+1,xx) = (-1*(abs(RX.c2(xx+1)-trel2.outputs(state,idx_in)))^2)/6/CH.N0;
                    end
                end  
                for sigk = 1:16 
                    BCJR2.aaa = zeros(16,1);
                    for state=1:16 
                        BCJR2.aaa(state) =  BCJR2.alpha(state,xx) +  BCJR2.Gamma(state,sigk,xx);
                    end
                    BCJR2.alpha(sigk, xx+1) = LOG_MAP( BCJR2.aaa, 16);
                end
                BCJR2.max_val = max( BCJR2.alpha(:, xx+1));
                BCJR2.alpha(:, xx+1) =  BCJR2.alpha(:, xx+1) -  BCJR2.max_val;
            end 
             
            for xx = length(RX.c2):-1:3
                for state = 1:16
                    BCJR2.bbb = zeros(16,1);
                    for sigk=1:16 
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
                
                BCJR2.L(2*(xx-1)-1,1) =  BCJR2.LLL1- BCJR2.LLL2;
                BCJR2.L(2*(xx-1),1) =  BCJR2.LLL3- BCJR2.LLL4;
            end
            
            if intrlv==1
                BCJR2.a=randdeintrlv( BCJR2.L(3:end-4),1);
            else
                BCJR2.a= BCJR2.L(3:end-4);
            end  
            BCJR2.a = max(min(BCJR2.a, SIM.LLRclip), -SIM.LLRclip); 
            BCJR2.decode_bhat=APPDec(zeros(60,1), BCJR2.a);
            BCJR2.decode= BCJR2.decode_bhat>0;
            
            A=BCJR2.decode(1:end-6);
            AA=step(ConEnc,A);
            AAA=randintrlv(round(AA),1);
            AAAA=[0;0;0;0;AAA;0;0;0;0];
            xbhat = pskmod(double(AAAA),G.Q,pi/G.Q,InputType="bit");
    end
    
    %% 【追加】チャネル推定と検証データの取得
    switch SIM.mode
        case 'est'
            EST.Xi = RX.b(1:SIM.ndata)./TX.x(:,1);
            True_HA = Xi_vec_AA(1:SIM.ndata);
            Raw_Error_Freq = EST.Xi - True_HA; 
            
            % 検証1：時間領域の誤差インパルス応答（128ポイントにゼロ詰めしてIFFT）
            Err_Freq_128 = [Raw_Error_Freq; zeros(fft_ptA - SIM.ndata, 1)];
            ERR.Err_time_pow = ERR.Err_time_pow + abs(ifft(Err_Freq_128, fft_ptA)).^2;
            
            % 検証2：真の信号電力 vs エラー干渉電力
            ERR.P_True_AA(idx_loop)    = mean(abs(RX.bA(1:SIM.ndata)).^2);
            ERR.P_Err_Interf(idx_loop) = mean(abs(RX.bB(1:SIM.ndata)).^2); 
            
        case {'xb_est','xb_est1','xb_est2'}
            EST.Xi = (RX.b(1:SIM.ndata)-Xi_vec_AB(1:SIM.ndata).*xbhat)./TX.x(:,1);
            True_HA = Xi_vec_AA(1:SIM.ndata); 
            Raw_Error_Freq = EST.Xi - True_HA; 
            
            % 検証1：時間領域の誤差インパルス応答
            Err_Freq_128 = [Raw_Error_Freq; zeros(fft_ptA - SIM.ndata, 1)];
            ERR.Err_time_pow = ERR.Err_time_pow + abs(ifft(Err_Freq_128, fft_ptA)).^2;
            
            % 検証2：真の信号電力 vs エラー干渉電力
            ERR.P_True_AA(idx_loop)    = mean(abs(RX.bA(1:SIM.ndata)).^2);
            ERR.P_Err_Interf(idx_loop) = mean(abs(RX.bB(1:SIM.ndata) - Xi_vec_AB(1:SIM.ndata).*xbhat).^2);
    end

    switch SIM.mode
        case{'est','xb_est','xb_est1','xb_est2'}
            %% 帯域制限(Virtual Subcarrier)を考慮した時間領域チャネル復元
            L = SIM.delayA * num_of_paths_AA; 
            F_matrix = fft(eye(fft_ptA)); 
            F_partial = F_matrix(1:SIM.ndata, 1:L);
            
            % LS推定
            EST.h_L = pinv(F_partial) * EST.Xi; 
            EST.h = [EST.h_L; zeros(fft_ptA - L, 1)]; 
            EST.Xi_vec_AA = fft(EST.h, fft_ptA);
            EST.XiHat = EST.Xi_vec_AA(1:SIM.ndata);
    end
    
    %% SIのレプリカを減算し，復号 (省略せず記述)
    switch SIM.mode
        case {'est','xb_est','xb_est1','xb_est2'}
            switch SIM.detmode
                case 'BCJR'
                    tilde_xb=RX.b(1:SIM.ndata)-EST.XiHat.*TX.x(:,1);
                    
                    %% BCJR
                    BCJR.alpha = zeros(4,length(TX.x)) - 1e10;
                    BCJR.alpha(1,1) = log(1); 
                    BCJR.alpha(1,2) = log(1); 
                    BCJR.beta = zeros(4,length(TX.x)) - 1e10;
                    BCJR.beta(1,end) = log(1);
                    BCJR.beta(1,end-1) = log(1);
                    BCJR.Gamma= zeros(4,4,length(TX.x)-1) - 1e10;
                    TX.Xi_vec_AB=Xi_vec_AB;
                    
                    for xx = 2:SIM.ndata-1
                        trel = BCJRTrellis(TX,xx,CH,G,0,1); 
                        for idx_in = 1:trel.num_in  
                            for sigi=1:trel.num_state 
                                BCJR.Gamma(sigi,trel.next_state(sigi,idx_in)+1,xx) = (-1*(abs(tilde_xb(xx+1)-trel.outputs(sigi,idx_in)))^2)/2/CH.N0;
                            end
                        end
                        for sigj = 1:trel.num_state 
                            BCJR.aaa = zeros(trel.num_state,1);
                            for sigi=1:trel.num_state 
                                BCJR.aaa(sigi)=BCJR.alpha(sigi,xx)+BCJR.Gamma(sigi,sigj,xx);
                            end
                            BCJR.alpha(sigj,xx+1) = LOG_MAP(BCJR.aaa,trel.num_state);
                        end  
                        BCJR.max_alpha = max(BCJR.alpha(:, xx+1));
                        BCJR.alpha(:, xx+1) = BCJR.alpha(:, xx+1) - BCJR.max_alpha;
                    end
                     
                    for xx = SIM.ndata:-1:2
                        for sigi = 1:trel.num_state
                            BCJR.bbb = zeros(trel.num_state,1);
                            for sigj=1:trel.num_state 
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
                        
                        BCJR.L(2*(xx-1)-1,1) = BCJR.LLL1-BCJR.LLL2;
                        BCJR.L(2*(xx-1),1) = BCJR.LLL3-BCJR.LLL4;
                    end
                    
                    if intrlv==1
                        BCJR.a=randdeintrlv(BCJR.L(3:end-4),1);
                    else
                        BCJR.a=BCJR.L(3:end-4);
                    end
                    BCJR.a = max(min(BCJR.a, SIM.LLRclip), -SIM.LLRclip); 
                    BCJR.decode_bhat=APPDec(zeros(60,1),BCJR.a );
                    det.decode=BCJR.decode_bhat>0;
            end
    end
    
    %% Error count
    switch SIM.mode
        case {'est','xb_est','xb_est1','xb_est2'}
            ERR.noe(idx_loop,:) = sum(det.decode(1:length(TX.b(:,2)),1) ~= TX.b(:,2));
        case 'DASIC1'
            ERR.noe(idx_loop,:) = sum(BCJR1.decode(1:length(TX.b(:,2)),1) ~= TX.b(:,2));
        case 'DASIC2'
            ERR.noe(idx_loop,:) = sum(BCJR2.decode(1:length(TX.b(:,2)),1) ~= TX.b(:,2));
    end
    ERR.noe_p(idx_loop,:) = (ERR.noe(idx_loop,:) ~=0);
    ERR.nod(idx_loop)   = size(TX.b,1); 
    ERR.nod_p(idx_loop) = 1;
    
    if(sum(ERR.noe_p)>SIM.err_max)
        break;
    end
    fprintf('%d/%d  %d/%d\n',idx,length(SIM.SIR),idx_loop,SIM.nsamp)
end
SIM.En  = En;
SIM.BER = sum(ERR.noe,1) / sum(ERR.nod);
SIM.PER = sum(ERR.noe_p,1) / sum(ERR.nod_p);
SIM.SIR = 10*log10(sum(ERR.tx_pow)/(sum(ERR.rx_pow)-sum(ERR.tx_pow)));
SIM.noe = sum(ERR.noe,1);
SIM.nod = sum(ERR.nod,1);

% 【追加】出力変数へ代入
SIM.Err_time_pow = ERR.Err_time_pow / idx_loop;
SIM.P_True_AA    = mean(ERR.P_True_AA(1:idx_loop));
SIM.P_Err_Interf = mean(ERR.P_Err_Interf(1:idx_loop));