function trel = BCJRTrellis(TX,xx,CH,G,dec_alg,term)

% Initialization
trel.num_in = 2.^G.ml;
trel.num_out = 4;
trel.num_state = 4;


sig=[cos(pi/4)+1j*sin(pi/4),cos(3*pi/4)+1j*sin(3*pi/4),cos(7*pi/4)+1j*sin(7*pi/4),cos(5*pi/4)+1j*sin(5*pi/4),];
for state = 1:trel.num_state
    for input = 1:trel.num_in
        state_bi = de2bi(state-1,log2(trel.num_state),'left-msb');
        state_alp = (2.^[G.ml-1:-1:0])*reshape(state_bi,G.ml,[]);
        current_state = [state_alp input-1];  
        next_state = current_state(2:end);
        trel.next_state(state,input) = next_state;
        
        trel.outputs(state,input) = TX.Xi_vec_AB(xx+1)*sig(input);
        
    end     %input
end         %state
%ここにDASICの出力

trel.outputs = complex(trel.outputs);%DASIC出力\tildex_B[k] 5点
trel.dec_alg = dec_alg;
trel.N0      = CH.N0;
trel.terminated = term;
%trel.bit     = G.bit;