clc;
clear all;close all;
N=1024; %code length
p=0.9; %for "1"
h_p=(-p*log2(p)+(-(1-p)*log2(1-p)));
S_size=ceil(N*(1-h_p));
x=rand(N,1);
for i=1:N
    if x(i)<p
        x(i)=1;
    else
        x(i)=0;
    end
end
%A=xor(I,x);
S_size_complementary=N-S_size;
K=S_size_complementary/2;
D=x(1:S_size_complementary);

%% design I and F
SNR=5;
sigma=10^(-SNR/20);
channels=GA(sigma,N);
channels_I_F=channels(1:S_size_complementary);
[~,channels_ordered]=sort(channels_I_F,'descend');
I_bits=sort(channels_ordered(1:K),'ascend');
F_set=sort(channels_ordered(K+1:end),'ascend');
F_bits=ones(S_size_complementary,1);
F_bits(I_bits)=0;
logic=mod(F_bits+1,2);
I_bits_logical=logical(logic);
u=zeros(S_size_complementary,1);

%% get I and F
S_set=[N-S_size+1:N];
I_set=I_bits;
F_set=F_set;

%%precoder 
c=zeros(N,1); %BSC all-zero vector
llr=ones(N,1);
lls=log((1-p)/p);
llr(llr==1)=lls;
L=32;% List length

frozen_bits=ones(N,1);
frozen_bits(S_set)=0; 
lambda_offset=2.^(0:log2(N));%分段向量
llr_layer_vec = get_llr_layer(N); 
bit_layer_vec = get_bit_layer(N); 

shaped_bits = SC_decoder(llr, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
%shaped_bits = SCL_decoder(llr, L, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
%shaped_bits=SCL_decoder(llr)

code=zeros(S_size_complementary,1);
origin_data=randsrc(K,1,[0 1;0.5 0.5]);
code(I_set)=origin_data;
xx=[code;shaped_bits];
xxx=polar_encoder(xx); 
bpsk=1-2*xxx;

blenum_sc=0;
blenum_scl=0;
blenum_cascl=0;

frozen_bits1=ones(N,1);
frozen_bits1(I_set)=0; 

for i_runs=1:10000
    y=awgn(bpsk,SNR);
    LLR=2/sigma^2*y;
    polar_info_sc=SC_decoder(LLR,K,frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
   % polar_info_scl = SCL_decoder(LLR, K, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
    if any(polar_info_sc~=origin_data)
    blenum_sc=blenum_sc+1;
    end
end

nfails=sum(polar_info_sc~=origin_data);





