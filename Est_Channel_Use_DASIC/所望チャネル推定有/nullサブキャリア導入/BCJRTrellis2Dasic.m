function trel = BCJRTrellis2Dasic(TX,xx,CH,G,dec_alg,term)
G.ml=2;
% Initialization
trel.num_in = 2.^G.ml;
trel.num_out = 4;
trel.num_state = 4;
state=1;

sig=[cos(pi/4)+1j*sin(pi/4),cos(3*pi/4)+1j*sin(3*pi/4),cos(7*pi/4)+1j*sin(7*pi/4),cos(5*pi/4)+1j*sin(5*pi/4),];
for i_state=1:trel.num_state%現在の状態
    for h_state = 1:trel.num_state%一つ前の状態
         for input = 1:trel.num_in%入力
           i_state_bi = de2bi(i_state-1,log2(trel.num_state),'left-msb');%QPSK0~3の各状態を二進数に変換
           i_state_alp = (2.^[G.ml-1:-1:0])*reshape(i_state_bi,G.ml,[]);%
          
           h_state_bi = de2bi(h_state-1,log2(trel.num_state),'left-msb');%QPSK0~3の各状態を二進数に変換
           h_state_alp = (2.^[G.ml-1:-1:0])*reshape(h_state_bi,G.ml,[]);%
          
           
           current_state = [h_state_alp i_state_alp input-1];  
           next_state_mat = current_state(2:end);
           y = "";
          for i = 1:length(next_state_mat)
              bin = dec2bin(next_state_mat(end-i+1), 2);  % 各要素を2bitの2進数文字列に
              y = y+bin;             % 連結
          end
           next_state=bin2dec(y); 
           trel.next_state(state,input) = next_state;
              %一段DASIC  
                 %trel.outputs(state,input) = TX.Xi_vec_AB(xx+1)*sig(input)-TX.Xi_vec_AB(xx)*sig(state)*TX.phi(xx);
    
              %二段DASIC  
                 trel.outputs(state,input) = TX.Xi_vec_AB(xx+1)*sig(input)-2*TX.Xi_vec_AB(xx)*sig(i_state)*TX.phi(xx)+TX.phi(xx)*TX.phi(xx-1)*TX.Xi_vec_AB(xx-1)*sig(h_state);
        end 
        state=state+1;  
    end        
end

trel.outputs = complex(trel.outputs);%DASIC出力\tildex_B[k] 5点
trel.dec_alg = dec_alg;
trel.N0      = CH.N0;
trel.terminated = term;
%trel.bit     = G.bit;