clc; clear; close all;

%% 参数
M = 16;
k = log2(M);              % 4
Nbits = 4e6;              % 建议别太小，否则统计不稳；别太大否则LLR散点图太密
EsN0dB = -16;             % 你要对比的点

% Es/N0 -> I/Q 噪声标准差 sigma（UnitAveragePower=true => Es=1）
sigma = sqrt(1/(2*10^(EsN0dB/10)));
Ns = Nbits/k;

%% 生成同一组数据
% txBits = randi([0 1], Nbits, 1);
txBits = [0;0;0;1];

txSym = qammod(txBits, M, 'gray', ...
               'InputType','bit', ...
               'UnitAveragePower', true);

% 同一组噪声（保证两种LLR比较的是同一组rxSym）
noise = sigma*(randn(Ns,1) + 1j*randn(Ns,1));
rxSym = txSym + noise;

%% 两种方法算 LLR
LLR_LSE = llr_16qam_gray_LSE(rxSym, sigma);

LLR_qam = qamdemod(rxSym, M, 'gray', ...
                   'OutputType','llr', ...
                   'UnitAveragePower', true, ...
                   'NoiseVariance', 2*sigma^2);

LLR_qam = LLR_qam(:);  % 保证列向量

%% 1) 最直观：符号一致率（决定硬判是否一样）
signAgree = mean((LLR_LSE < 0) == (LLR_qam < 0));
fprintf("Sign agreement (hard decisions identical ratio) = %.6f\n", signAgree);

%% 2) 数值差异统计（幅度/偏置差异）
diff = LLR_LSE - LLR_qam;
fprintf("mean(diff)      = %.6g\n", mean(diff));
fprintf("mean(|diff|)    = %.6g\n", mean(abs(diff)));
fprintf("RMSE(diff)      = %.6g\n", sqrt(mean(diff.^2)));
fprintf("max(|diff|)     = %.6g\n", max(abs(diff)));

%% 3) 相关性（看是否只是线性缩放差）
R = corr(LLR_LSE, LLR_qam);
fprintf("corr(LLR_LSE, LLR_qam) = %.6f\n", R);

% 线性拟合：LLR_LSE ≈ a*LLR_qam + b
p = polyfit(LLR_qam, LLR_LSE, 1);
a = p(1); b = p(2);
fprintf("Linear fit: LLR_LSE ≈ a*LLR_qam + b,  a=%.6f, b=%.6g\n", a, b);

%% 4) 可视化（散点图 + 直方图）
figure; 
plot(LLR_qam(1:4000), LLR_LSE(1:4000), '.'); grid on;
xlabel('LLR from qamdemod');
ylabel('LLR from LSE');
title(sprintf('Es/N0 = %g dB (first 4000 bits)', EsN0dB));

figure;
histogram(diff, 80); grid on;
xlabel('LLR\_LSE - LLR\_qamdemod');
ylabel('count');
title(sprintf('LLR difference histogram at Es/N0 = %g dB', EsN0dB));
