%此程序为计算m-ASK调制格式在AWGN信道下的可达信息速率，即互信息I(X;Y)
%此程序采用的方法是数值计算的方法，即求积分的方法
%writen by FJF,20180326，看风景的心情

clear
clc

d = 2; % 星座点的距离
mod_order = 4; %ASK的阶数，2表示2ASK，4表示4ASK
ask = (1:mod_order)*d; %存储ASK调制格式的幅度
ask = ask - mean(ask); 
% pask=ones(1,length(ask)) * 1/ length(ask); %假设每个幅度等概率分布
pask=[0.4,0.1,0.1,0.4];  % 假设每个符号不等概率分布
pask=[0.1,0.4,0.4,0.1];  
snr_dB=[0:0.1:30]; %信噪比，根据不同的调制阶数可调整

for index_snr_dB=1:length(snr_dB)
    index_snr_dB
    global paramet;
    paramet=struct('snr_dB',snr_dB(index_snr_dB),...
        'ask',ask,...
        'pask',pask);
    fun=@sub_fy_awgn;
    y_start=10*min(ask);
    y_end=10*max(ask);
    c(index_snr_dB)=integral(fun,y_start,y_end);
end

plot(snr_dB,c);
grid on
legend(['Uniform ' num2str(mod_order) '-ASK']);
