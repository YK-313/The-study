clear
%遅延時間に対する遅延スプレッド計算 ただし「AA間2波、所望信号は遅延時間の変更なし」にのみ対応
SIM.SIR     = -60;           % 希望信号対干渉電力比
SIM.rho     = -40;    
SIM.overA = 2; 
SIM.overB = 1;
symtime=32*10^-6;
num_of_sub=64;
SIM.AA=2;
SIM.AB=16;
SIM.delaysubA=1:1:32;
SIM.delaysubB=1;
num_of_paths_AA=SIM.AA;%AA間パス数
num_of_paths_AB=SIM.AB;%AB間パス数
for idx=1:length(SIM.delaysubA)
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
        delay_profile_AB_s =delay_profile_AB./abs(delay_profile_AB)./sqrt(length(delay_profile_AB));
        %電力比を導入
   if SIM.AA==1
        delay_profile_AA_rho=delay_profile_AA_s;%遅延波なし
    else
        delay_profile_AA_rho=zeros(size(delay_profile_AA_s));
        rho_sum=0;
            for rr = 2:SIM.AA
             rho = 10^( (SIM.rho-5*(rr-2)) /10); %3波目以降-5dB
             rho_sum = rho_sum+rho;
            end
        delay_profile_AA_rho(1) =delay_profile_AA_s(1)*sqrt(1/( 1 + rho_sum ) );
         for dd=2:SIM.AA
                 delay_profile_AA_rho(dd) =delay_profile_AA_s(dd)*sqrt(10^( (SIM.rho-5*(dd-2))/10)*abs(delay_profile_AA_rho(1))^2);
         end
    end
        P_a=sum(abs(delay_profile_AA_rho).^2);
        %SIR考慮
        P_b=sum(abs(delay_profile_AB_s).^2);        

%%遅延スプレッド計算
subtimeA=symtime/num_of_sub/SIM.overA*SIM.delaysubA;
subtimeB=symtime/num_of_sub/SIM.overB*SIM.delaysubB;

tau.a=zeros(length(num_of_paths_AA));
tau.b=zeros(length(num_of_paths_AB));

for k=2:num_of_paths_AA
tau.a(k)=tau.a(k-1)+subtimeA(idx);
end

for k=2:num_of_paths_AB
tau.b(k)=tau.b(k-1)+subtimeB;
end
tau.am = (tau.a*(abs(delay_profile_AA_rho).^2))/P_a;%tau_0
tau.bm = (tau.b*(abs(delay_profile_AB_s).^2))/P_b;

tau.ad=zeros(length(num_of_paths_AA)); 
tau.bd=zeros(length(num_of_paths_AB));

tau.ad= tau.a.^2 * abs(delay_profile_AA_rho).^2/ P_a ;
tau.bd= tau.b.^2 * abs(delay_profile_AB_s).^2/ P_b;

tau.arms=sqrt( tau.ad - tau.am^2) ;
tau.brms=sqrt( tau.bd - tau.bm^2) ;
SI_delay(idx)=tau.arms;
Syomou_delay=tau.brms;
end
%plot(SIM.rho,SI_delay);