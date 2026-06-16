%%%%% 将Probabilistic shaping 拓展�?4-ASK
clc;clear all;
close all;
%% 参数设置
%N=1024; %code length
N=1024;
p=0.9; %for "1"
h_p=(-p*log2(p)+(-(1-p)*log2(1-p)));
S_size=ceil(N*(1-h_p));
S_size_complementary=N-S_size;
K=ceil(S_size_complementary/2);
%% design I ,F and S 对于第一个Precoder
SNR=-5:1:5;
BER=zeros(1,length(SNR));
BLER=zeros(1,length(SNR));
for i=1:length(SNR)
% sigma=10^(-SNR(i)/20);
sigma=10^(-SNR(i)/20);
channels=GA(sigma,N);
[~,channels_ordered]=sort(channels,'descend');
S_bits=sort(channels_ordered(1:S_size),'ascend');
%channels_I_F=channels(1:S_size_complementary);
%[~,channels_ordered]=sort(channels_I_F,'descend');%降序
I_bits=sort(channels_ordered(S_size+1:S_size+K),'ascend');%信息�? 升序
F_set=sort(channels_ordered(S_size+1+K:end),'ascend');
F_bits=ones(S_size_complementary,1);
F_bits(I_bits)=0;
logic=mod(F_bits+1,2);
I_bits_logical=logical(logic);
u=zeros(S_size_complementary,1);
%% get I and F
S_set=S_bits;
I_set=I_bits;
F_set=F_set;
c=zeros(N,1); %BSC all-zero vector
llr=ones(N,1);
lls=log((1-p)/p);
llr(llr==1)=lls;
% L=32;% List length
L=8;
frozen_bits=ones(N,1);
frozen_bits(S_set)=0; %将S集合看作信息�?
lambda_offset=2.^(0:log2(N));%分段向量
llr_layer_vec = get_llr_layer(N); %LLR计算实际执行层数向量
bit_layer_vec = get_bit_layer(N); %比特值返回时实际执行层数向量

shaped_bits = SC_decoder(llr, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
% shaped_bits = SCL_decoder(llr, L, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
%code=zeros(S_size_complementary,1);
code=zeros(N,1);
origin_data=randsrc(K,1,[0 1;0.5 0.5]);
code(I_set)=origin_data;
code(S_set)=shaped_bits;
%xx=[code;shaped_bits];
xxx=polar_encoder(code); %得出�?终的Encoded_bits
p_encoded=sum(xxx==1)/(sum(xxx==1)+sum(xxx==0)); %第一个预编码器中1的概�?

%% 4ASK 参数
% N_ASK=20;
% fc=5;
% t=0:2*pi/99:2*pi;
% fm=N_ASK/5; %码元速率
% B=2*fm; %带宽
% AWGN_variance=1;
% m1=[];
% ci=[];
% % ASK_symbol=[-3,-1,1,3];
% for i=1:N_ASK/2
%     
% end
bpsk=1-2*xxx;
% bpsk=xxx;

%是否能直接用Q函数求？


blenum_sc=0;
blenum_scl=0;
blenum_cascl=0;

frozen_bits1=ones(N,1);
frozen_bits1(I_set)=0; 

for i_runs=1:10000
    y=awgn(bpsk,SNR(i));
    LLR=2/sigma^2*y;
 %polar_info_sc=SC_decoder(LLR,K,frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
    polar_info_sc=SCL_decoder(LLR,L,K,frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
   if any(polar_info_sc~=origin_data)
        blenum_sc=blenum_sc+1;
   end
    
% %     if any(polar_info_scl~=origin_data)
% %      blenum_scl=blenum_scl+1;
% %   end
% %   BLER(i)=BLER(i)+blenum_sc;
end   
    
    nfails=sum(polar_info_sc~=origin_data);
    BER(i)=BER(i)+nfails;    
    BER(i)=BER(i)/(K*1);
    
    BLER(i)=BLER(i)+blenum_sc;
    BLER(i)=BLER(i)/10000;
    
   % nfails1=sum(polar_info_scl~=origin_data);
   % BER1(i)=BER1(i)+nfails1;    
   % BER1(i)=BER1(i)/(K*1);
    
   % BLER1(i)=BLER1(i)+blenum_scl;
   % BLER1(i)=BLER1(i)/10000;
end

figure(1)
semilogy(SNR,BER,'r-o');
% % hold on
% semilogy(SNR,BER2,'b-o');
% hold on
% semilogy(SNR,BER3,'g-o');
% hold on
xlabel('SNR (dB)');
ylabel('BER');
% legend('p_1=0.9','p_1=0.5','p_1=0.1');


figure(2)
semilogy(SNR,BLER,'r-o');
% hold on
% semilogy(SNR,BLER2,'b-o');
% hold on
% semilogy(SNR,BLER3,'g-o');
% hold on
xlabel('SNR (dB)');
ylabel('BLER');
% legend('p_1=0.9','p_1=0.5','p_1=0.1');
%%plot
%figure(1)
%semilogy(SNR,BER,'r-x');
%figure(2)
%semilogy(SNR,BLER,'r-o');









