function [rdata,idata] = Polar_Modulation16(data,SNR)
%输入二进制序列 输出16QAM实部和虚部
data_1_t=data(1:4:end);
data_2_t=data(2:4:end);
data_3_t=data(3:4:end);
data_4_t=data(4:4:end);

p1=0.5;
p2=0.5;
p3=0.5;
p4=0.5;

data_1=SPCcoder(data_1_t,p1,SNR);
data_2=SPCcoder(data_2_t,p2,SNR);
data_3=SPCcoder(data_3_t,p3,SNR);
data_4=SPCcoder(data_4_t,p4,SNR);

rdata=4*data_1-2+2*data_3-1;
idata=4*data_2-2+2*data_4-1;

end

