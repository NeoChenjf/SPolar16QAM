function p=post_probality(y,ask,yita_squ)
%此函数用于计算高斯信道的转移概率
p=(2*pi*yita_squ)^(-0.5)*exp(-(y-ask).^2/(2*yita_squ));