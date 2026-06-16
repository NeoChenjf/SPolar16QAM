clc;
clear all;
close all;

N=1024;
p=0.5;
Fsize=N/2;
Isize=N/2;
L=4;

SNR=-5:0.5:18;
BER=zeros(1,length(SNR));
BLER=zeros(1,length(SNR));

for i=1:length(SNR)
    sigma=10^(-SNR(i)/20);
    channels=GA(sigma,N);
    [~,channels_ordered]=sort(channels,'descend');
    I_bits=sort(channels_ordered(1:Isize),'ascend');%信息位 升序
    F_set=sort(channels_ordered(Isize+1:end),'ascend');
    F_bits=ones(N,1);
    F_bits(I_bits)=0;
    logic=mod(F_bits+1,2);
    I_bits_logical=logical(logic);
    u=zeros(N,1);
    
    I_set=I_bits;
    F_set=F_set;
    
    lambda_offset=2.^(0:log2(N));%分段向量
    llr_layer_vec = get_llr_layer(N); %LLR计算实际执行层数向量
    bit_layer_vec = get_bit_layer(N); %比特值返回时实际执行层数向量

    
    code=zeros(N,1);
    origin_data=randsrc(Isize,1,[1 0;0.1 0.9]);
    code(I_set)=origin_data;
    xxx=polar_encoder(code); %得出最终的Encoded_bits
    p_encoded=sum(xxx==1)/(sum(xxx==1)+sum(xxx==0));
    
    blenum_sc=0;
    blenum_scl=0;
    blenum_cascl=0;
    
    frozen_bits1=ones(N,1);
    frozen_bits1(I_set)=0; 
    
    
for i_runs=1:100
    
    spow = sum(xxx'*xxx)/N; %符号功率
      sigma_noise = sqrt(spow/(2*10^(SNR(i)/10)));
      y = xxx+sigma_noise*(randn(N,1)); % 添加高斯白噪声
    LLR=(1-2*y)/(2*sigma^2);
%  polar_info_sc=SC_decoder(LLR,K,frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
    polar_info_sc=SCL_decoder(LLR,L,Isize,frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
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
     BER(i)=BER(i)/(Isize*100);
    
    BLER(i)=BLER(i)+blenum_sc;
    BLER(i)=BLER(i)/100;
    
   
end

figure(1)
semilogy(SNR,BER,'r-o');
% hold on
% semilogy(SNR,BER2,'b-o');
% hold on
% semilogy(SNR,BER3,'g-o');
hold on
xlabel('SNR (dB)');
ylabel('BER');
% legend('p_1=0.9','p_1=0.5','p_1=0.1');


figure(2)
semilogy(SNR,BLER,'r-o');
hold on
% semilogy(SNR,BLER2,'b-o');
% hold on
% semilogy(SNR,BLER3,'g-o');
hold on
xlabel('SNR (dB)');
ylabel('BLER');

