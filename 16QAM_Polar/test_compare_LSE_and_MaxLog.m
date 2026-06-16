clc; clear; close all;

%% ================= 参数设置 =================
M = 16;
k = log2(M);                 % bits per symbol = 4
Nbits = 4e4;                 % total bits (must be multiple of 4)
EsN0dB = -16:1:16;              % Es/N0 (dB)

BER_LSE    = zeros(size(EsN0dB));
BER_qamdem = zeros(size(EsN0dB));

%% ================= 发送端 =================
% 随机比特
txBits = randi([0 1], Nbits, 1);

% 16QAM Gray 调制（单位平均符号能量）
txSym = qammod(txBits, M, ...
               'gray', ...
               'InputType','bit', ...
               'UnitAveragePower', true);

Ns = length(txSym);  % 符号数

%% ================= SNR 循环 =================
for i = 1:length(EsN0dB)

    % 噪声标准差（I/Q 各自）
    sigma = sqrt(1/(2*10^(EsN0dB(i)/10)));

    % AWGN 信道
    noise = sigma * (randn(Ns,1) + 1j*randn(Ns,1));
    rxSym = txSym + noise;

    % ---------- 方案 1：qamdemod (max-log 等价) ----------
    LLR_qamdem = qamdemod(rxSym, M, 'gray', ...
                          'OutputType','llr', ...
                          'UnitAveragePower', true, ...
                          'NoiseVariance', 2*sigma^2);

    rxBits_qamdem = LLR_qamdem < 0;
    BER_qamdem(i) = mean(rxBits_qamdem ~= txBits);

    % ---------- 方案 2：精确 LSE ----------
    LLR_LSE = llr_16qam_gray_LSE(rxSym, sigma);

    rxBits_LSE = LLR_LSE < 0;
    BER_LSE(i) = mean(rxBits_LSE ~= txBits);

end

%% ================= 绘图 =================
figure;
semilogy(EsN0dB, BER_LSE, 'o-', 'LineWidth',1.6); hold on;
semilogy(EsN0dB, BER_qamdem, 's--', 'LineWidth',1.6);
grid on;
xlabel('E_s/N_0 (dB)');
ylabel('BER');
legend('Exact LSE (MAP)', 'qamdemod LLR (max-log equiv.)', ...
       'Location','southwest');
title('16QAM Gray over AWGN: LSE vs qamdemod (max-log)');
