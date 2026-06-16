function z=sub_fy_awgn(y)
%此函数用于计算被积函数，输入为被积函数的自变量序列，输出为被积函数的相应输出值
global paramet;
snr=10^(paramet.snr_dB/10);
signal_power=sum(paramet.ask.*paramet.ask.*paramet.pask);
yita_squ=signal_power/snr;
ask=paramet.ask;
pask=paramet.pask;

temp_p=zeros(length(ask),length(y));
for index_ask=1:length(ask)
    temp_p(index_ask,:)=post_probality(y,ask(index_ask),yita_squ);
    %             pask_new(index_ask)=mean(x==ask(index_ask));
end
z_temp=zeros(length(ask),length(y));
for index_ask=1:length(ask)
    z_temp(index_ask,:)=temp_p(index_ask,:).*log2(temp_p(index_ask,:)./(pask*temp_p));
end
z_temp(temp_p==0)=0;
z_temp(z_temp==inf)=0;
z=pask*z_temp;
