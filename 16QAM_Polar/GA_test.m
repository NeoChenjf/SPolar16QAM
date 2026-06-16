% 生成随机比特
Nbits = 1024;
K = 512;  % 信息位数
u = randi([0 1], K, 1);  % 输入信息比特流

SNR = 5;
% 信道质量估计：通过高斯估计法计算每个比特的可靠性
% 计算接收符号的信道质量（高斯估计）
sigma = 10^(-SNR/20);
noise = sigma * (randn(Ns, 1) + 1j * randn(Ns, 1));

% 生成符号并映射到16QAM星座图
txSym = qammod(u, 16, 'gray', 'InputType', 'bit', 'UnitAveragePower', true);

% 计算每个比特的信道质量（高斯估计法）
LLR = llr_16qam_gray_gaussian(txSym, sigma);
