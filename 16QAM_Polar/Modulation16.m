function [rdata,idata] = Modulation16(data)
%输入二进制序列 输出16QAM实部和虚部
data_1=data(1:4:end);
data_2=data(2:4:end);
data_3=data(3:4:end);
data_4=data(4:4:end);

rdata=4*data_1-2+2*data_3-1;
idata=4*data_2-2+2*data_4-1;

end

