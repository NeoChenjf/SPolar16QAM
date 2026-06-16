%%%  Shaped polar code  VS  Unary Code
% clc;close all;clear all;
%% K=4 unary code 
M=2;
K=4;
m=log2(M);
P_source=rand(1,K);
P_source=P_source/sum(P_source);
P_source=[0.41 0.35 0.07 0.17]; %
% % P_source=[0.1 0.25 0.25 0.4]; %
% P_source=[0.40 0.25 0.25 0.10]; %
P_c=zeros(K,K);
L=10000; % 
sequence=generate_sequence(L,P_source); %
N_Unary=length(sequence); %
N_Unary_1=sum(sequence==1)/N_Unary; % 
prob_sim=get_symbol_prob_sim(sequence,M,m);
if (N_Unary_1~=prob_sim)
    disp("false")
end
disp("true")



%% K=8 unary code 参数
K1=8;
% P_source_8=[0.16, 0.25, 0.13, 0.04,0.05, 0.05, 0.23, 0.09];%赵博使用的参�?
P_source_8=[0.4, 0.325, 0.225, 0.025,0.005, 0.005, 0.005, 0.01];
sequence_8=generate_sequence(L,P_source_8);
N_Unary_8=length(sequence_8); %Unary Coded 长度
N_Unary_8_1=sum(sequence_8==1)/N_Unary_8; % 验证在OOK中是否一�?
prob_sim2=get_symbol_prob_sim(sequence_8,M,m);
if (N_Unary_8_1~=prob_sim2)
    disp("false")
end
disp("true")

figure(1)
bar([prob_sim prob_sim2]);
grid on
% bar(K,prob_sim,'c')
legend('Unary code K=4','Unary code K=8','location','northwest');

%% Polar shaped 参数
N=1024;
p=0.5; %目标分布
% p=prob_sim;
% p=prob_sim2;
h_p=(-p*log2(p)+(-(1-p)*log2(1-p)));
S_size=ceil(N*(1-h_p));
S_size_complementary=N-S_size;
K_polar=ceil(S_size_complementary/2);

SNR_dB=-5:0.5:18;
BER_K_4=zeros(2,length(SNR_dB));
BER_K_8=zeros(2,length(SNR_dB));
BER=zeros(1,length(SNR_dB));
BLER=zeros(1,length(SNR_dB));
rho1=0;
rho2=0.5;
% rho2=0;
for i=1:length(SNR_dB)
    %     i
    %     tic
    Pt=1;
    sigma_a=10^(-SNR_dB(i)/20);
    sigma_cov=10^(-SNR_dB(i)/20);
    d=sqrt(3*Pt/(M-1));
    sigma1=(1-rho1)*sigma_a+sigma_cov;
    sigma2=(1-rho2)*sigma_a+sigma_cov;
%     sigma1=(1-rho1)*sigma_a;
%     sigma2=(1-rho2)*sigma_a;
    
    for j=1:L
        real_sigma=sigma1/(1-rho1);
        z_I=sqrt(real_sigma/2)*randn(1);
        z_Q=sqrt(real_sigma/2)*randn(1);
        if abs(z_I)>=d||abs(z_Q)>=d
            BER_K_4(1,i)=BER_K_4(1,i)+1;
        end
        
        real_sigma2=sigma2/(1-rho2);
        z_I_1=sqrt(real_sigma2/2)*randn(1);
        z_Q_1=sqrt(real_sigma2/2)*randn(1);
        if abs(z_I_1)>=d||abs(z_Q_1)>=d
            BER_K_4(2,i)=BER_K_4(2,i)+1;
        end
    end
    
    %% polar code
    sigma_polar=10^(-SNR_dB(i)/20);
%     sigma_polar=(1-rho1)*sigma_polar+sigma_polar;
     sigma_polar=(1-rho1)*sigma_polar;
     

    channels=GA(sigma_polar,N);
    [~,channels_ordered]=sort(channels,'descend');
    S_bits=sort(channels_ordered(1:S_size),'ascend');
    I_bits=sort(channels_ordered(S_size+1:S_size+K_polar),'ascend');%信息�? 升序
    F_set=sort(channels_ordered(S_size+1+K_polar:end),'ascend');
    F_bits=ones(S_size_complementary,1);
    F_bits(I_bits)=0;
    logic=mod(F_bits+1,2);
    I_bits_logical=logical(logic);
    u=zeros(S_size_complementary,1);
    
    S_set=S_bits;
    I_set=I_bits;
    F_set=F_set;
    
    c=zeros(N,1); %BSC all-zero vector
    llr=ones(N,1);
    lls=log((1-p)/p);
    llr(llr==1)=lls;
    L_polar=32;% List length
    frozen_bits=ones(N,1);
    frozen_bits(S_set)=0; %将S集合看作信息�?
    lambda_offset=2.^(0:log2(N));%分段向量
    llr_layer_vec = get_llr_layer(N); %LLR计算实际执行层数向量
    bit_layer_vec = get_bit_layer(N); %比特值返回时实际执行层数向量
    shaped_bits = SC_decoder(llr, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);
    code=zeros(N,1);
    origin_data=randsrc(K_polar,1,[0 1;0.5 0.5]);
    code(I_set)=origin_data;
    code(S_set)=shaped_bits;
    xxx=polar_encoder(code); %得出�?终的Encoded_bits
    p_encoded=sum(xxx==1)/(sum(xxx==1)+sum(xxx==0));
    
    bpsk=1-2*xxx;
    % bpsk=xxx;
    blenum_sc=0;
    blenum_scl=0;
    blenum_cascl=0;
    
    frozen_bits1=ones(N,1);
    frozen_bits1(I_set)=0;
    
    for i_runs=1:10000
        y=awgn(bpsk,SNR_dB(i));
        LLR=2/sigma_polar^2*y;
        polar_info_sc=SC_decoder(LLR,K_polar,frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
        %     polar_info_sc=SCL_decoder(LLR,L,K,frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
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
    BER(i)=BER(i)/(K_polar*10000);
    
    BLER(i)=BLER(i)+blenum_sc;
    BLER(i)=BLER(i)/10000;
    
    % nfails1=sum(polar_info_scl~=origin_data);
    % BER1(i)=BER1(i)+nfails1;
    % BER1(i)=BER1(i)/(K*1);
    
    % BLER1(i)=BLER1(i)+blenum_scl;
    % BLER1(i)=BLER1(i)/10000;
    
end
BER_K_4=BER_K_4/L;

figure(2)
% semilogy(SNR_dB,smooth(BER_K_4(1,:)),'k-+')
% hold on;
semilogy(SNR_dB,smooth(BER_K_4(2,:)),'k-d');
grid on;
hold on;
semilogy(SNR_dB,smooth(BER),'r--o');
xlabel('Transmite Power (dBm)');
ylabel('BER');
legend('Unary','Shaped Polar');

% figure(3)
% semilogy(SNR_dB,BER,'r-o');
% hold on
% xlabel('Transmite Power (dBm)');
% ylabel('BER');
% legend('p_1=0.9','p_1=0.5','p_1=0.1');
% figure(3)
% semilogy(SNR_dB,BLER,'r-o');
% xlabel('Transmite Power (dBm)');
% ylabel('BLER');






