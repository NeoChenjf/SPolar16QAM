function data = SPCcoder(data_t,p,SNR)
N=2*length(data_t);
h_p=(-p*log2(p)+(-(1-p)*log2(1-p)));
S_size=ceil(N*(1-h_p));
S_size_complementary=N-S_size;
K=ceil(S_size_complementary/2);

sigma=10^(-SNR/20);
channels=GA(sigma,N);
[~,channels_ordered]=sort(channels,'descend');
S_bits=sort(channels_ordered(1:S_size),'ascend');

I_bits=sort(channels_ordered(S_size+1:S_size+K),'ascend');%信息位 升序
F_set=sort(channels_ordered(S_size+1+K:end),'ascend');
F_bits=ones(S_size_complementary,1);
F_bits(I_bits)=0;
logic=mod(F_bits+1,2);
I_bits_logical=logical(logic);
u=zeros(S_size_complementary,1);

%% get I and F
S_set=S_bits;
I_set=I_bits;
% F_set=F_set;

%%prencoder
c=zeros(N,1); %BSC all-zero vector
llr=ones(N,1);
lls=log((1-p)/p);
llr(llr==1)=lls;
L=32;% List length

frozen_bits=ones(N,1);
frozen_bits(S_set)=0; %将S集合看作信息位
lambda_offset=2.^(0:log2(N));%分段向量
llr_layer_vec = get_llr_layer(N); %LLR计算实际执行层数向量
bit_layer_vec = get_bit_layer(N); %比特值返回时实际执行层数向量

shaped_bits = SC_decoder(llr, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);

code(I_set)=data_t;
code(S_set)=shaped_bits;

data=polar_encoder(code');
data=data';

end

