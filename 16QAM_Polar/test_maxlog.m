clear all;
clc; close all;
addpath('ShapedpolarS/');

clc; clear; close all;

%% 参数
M = 16;
k = log2(M);
Nbits = 4e5;
EsN0dB = -16:2:16;

BER = zeros(size(EsN0dB));

%% 随机比特
txBits = randi([0 1], Nbits, 1);

%% 16QAM Gray 调制
txSym = qammod(txBits, M, ...
               'gray', ...
               'InputType', 'bit', ...
               'UnitAveragePower', true);

for i = 1:length(EsN0dB)

    % 噪声方差
    sigma2 = 1/(2*10^(EsN0dB(i)/10));
    noise = sqrt(sigma2) * (randn(size(txSym)) + 1j*randn(size(txSym)));

    rxSym = txSym + noise;

    % LLR 软解调
    LLR = qamdemod(rxSym, M, ...
                   'gray', ...
                   'OutputType', 'llr', ...
                   'NoiseVariance', 2*sigma2);

    % 硬判（LLR < 0 判为 1）
    rxBits = LLR < 0;

    BER(i) = mean(rxBits ~= txBits);
end

%% 绘图
figure;
semilogy(EsN0dB, BER, 's-','LineWidth',1.5);
grid on;
xlabel('E_s/N_0 (dB)');
ylabel('Bit Error Rate');
title('16QAM Gray Mapping over AWGN (LLR-based Decision)');

