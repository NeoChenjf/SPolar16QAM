function [BER,BLER]=getSCL(p)

%N=1024; %code length
N=1024;
h_p=(-p*log2(p)+(-(1-p)*log2(1-p)));
S_size=ceil(N*(1-h_p));
% S_size=ceil(N*0.4);
%x=rand(N,1);
%for i=1:N
%    if  x(i)<p
%        x(i)=1;
%   else
%        x(i)=0;
%    end
%end
%A=xor(I,x);
S_size_complementary=N-S_size;
K=ceil(S_size_complementary/2);
%D=x(1:S_size_complementary);%I and F set
L=4;

%% design I and F
SNR=-5:0.5:18;
% SNR=40;
BER=zeros(1,length(SNR));
BLER=zeros(1,length(SNR));
% BER1=zeros(1,length(SNR));
% BLER1=zeros(1,length(SNR));

for i=1:length(SNR)
sigma=10^(-SNR(i)/20);
% sigma=10^((SNR(i))/20);
% sigma=sqrt(p)*10^(-SNR(i)/20);
channels=GA(sigma,N);
[~,channels_ordered]=sort(channels,'descend');
S_bits=sort(channels_ordered(1:S_size),'ascend');
%channels_I_F=channels(1:S_size_complementary);
%[~,channels_ordered]=sort(channels_I_F,'descend');%降序
I_bits=sort(channels_ordered(S_size+1:S_size+K),'ascend');%信息�? 升序

SandI_bits=sort(channels_ordered(1:S_size+K),'ascend');

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

SandI_set=SandI_bits;

%%prencoder
c=zeros(N,1); %BSC all-zero vector
llr=ones(N,1);
lls=log((1-p)/p);
llr(llr==1)=lls;
L=32;% List length

frozen_bits=ones(N,1);
frozen_bits(S_set)=0; %将S集合看作信息�?
lambda_offset=2.^(0:log2(N));%分段向量
llr_layer_vec = get_llr_layer(N); %LLR计算实际执行层数向量
bit_layer_vec = get_bit_layer(N); %比特值返回时实际执行层数向量

shaped_bits = SC_decoder(llr, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
% shaped_bits = SCL_decoder(llr, L, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
%shaped_bits=SCL_decoder(llr)

code=zeros(N,1);
origin_data=randsrc(K,1,[0 1;0.5 0.5]);
code(I_set)=origin_data;
code(S_set)=shaped_bits;

% code1=zeros(N,1);
% code1(I_set)=origin_data;
% code1(S_set)=shaped_bits;

%xx=[code;shaped_bits];
xxx=polar_encoder(code); %得出�?终的Encoded_bits
p_encoded=sum(xxx==1)/(sum(xxx==1)+sum(xxx==0));
%xxx1=polar_encoder(code1);
%p_encoded1=sum(xxx1==1)/(sum(xxx1==1)+sum(xxx1==0));

bpsk=1-2*xxx;
% bpsk=xxx;
blenum_sc=0;
blenum_scl=0;
blenum_cascl=0;

frozen_bits1=ones(N,1);
frozen_bits1(I_set)=0; 
frozen_bits1(S_set)=0;

for i_runs=1:1000
    
%     y=1-2*awgn(xxx,SNR(i)-3);
%     y=awgn(bpsk,SNR(i));
%     y=awgn(xxx,SNR(i),'measured');

      spow = sum(xxx'*xxx)/N; %���Ź���
      sigma_noise = sqrt(spow/(2*10^(SNR(i)/10)));
      y = xxx+sigma_noise*(randn(N,1)); % ���Ӹ�˹������
      
%     LLR=(2*y)/sigma^2;
%     LLR=y/sigma^2;
    LLR=(1-2*y)/(2*sigma^2);
%     LLR=-(1-2*y)/(sigma^2);
    SandI=SCL_decoder(LLR,L,(K+S_size),frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
    code_hat=zeros(N,1);
    code_hat(SandI_set)=SandI;
    polar_info_sc=code_hat(I_set);
%     polar_info_sc=SCL_decoder(LLR,L,K,frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
%     polar_info_sc=polar_info_sc(S_size+1,end);
   if any(polar_info_sc~=origin_data)
        blenum_sc=blenum_sc+1;
   end
   
   nfails=sum(polar_info_sc~=origin_data);
    BER(i)=BER(i)+nfails;
% %     if any(polar_info_scl~=origin_data)
% %      blenum_scl=blenum_scl+1;
% %   end
% %   BLER(i)=BLER(i)+blenum_sc;
end   
    
%     nfails=sum(polar_info_sc~=origin_data);
%     BER(i)=BER(i)+nfails;    
    BER(i)=BER(i)/(K*1000);
    
    BLER(i)=BLER(i)+blenum_sc;
    BLER(i)=BLER(i)/1000;
    
   % nfails1=sum(polar_info_scl~=origin_data);
   % BER1(i)=BER1(i)+nfails1;    
   % BER1(i)=BER1(i)/(K*1);
    
   % BLER1(i)=BLER1(i)+blenum_scl;
   % BLER1(i)=BLER1(i)/10000;
end