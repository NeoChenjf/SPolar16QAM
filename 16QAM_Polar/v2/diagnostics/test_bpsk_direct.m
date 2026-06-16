%% TEST_BPSK_DIRECT - 用直接 BPSK 方式重测 (不用 qammod/qamdemod)
% 目的: 绕过 qammod/qamdemod, 用纯数学 LLR 验证理论是否对

clear; clc;

N = 10000;
snr_db_vec = [-5, -2, 0, 2, 5];

fprintf('直接 BPSK LLR 测试（绕过 qammod/qamdemod）\n');
fprintf('================================================\n\n');

rng(42);

for snr_db = snr_db_vec
    snr_lin = 10^(snr_db/10);
    sigma = 1 / sqrt(2 * snr_lin);  % BPSK: Eb/N0 = 1
    
    % 生成信号
    tx_bits = randi([0 1], N, 1);
    tx_bpsk = 1 - 2*tx_bits;        % mapping: 0->+1, 1->-1
    noise = sigma * randn(N, 1);
    rx = tx_bpsk + noise;
    
    % LLR 计算 (两种方法)
    % 方法 A: 理论公式 LLR = 2*rx / sigma^2
    llr_a = (2 * rx) / (sigma^2);
    
    % 方法 B: 似然比 LLR = ln(P(rx|tx=0)/P(rx|tx=1))
    %         = ln[exp(-(rx-1)^2/2σ^2) / exp(-(rx+1)^2/2σ^2)]
    %         = [-(rx-1)^2 + (rx+1)^2] / (2σ^2)
    %         = 4*rx / (2σ^2)
    %         = 4*rx / (2σ^2)
    llr_b = (4 * rx) / (2 * sigma^2);  % 等同于 (2*rx)/sigma^2
    
    % 方法 C: 用 MATLAB erfc 定义 (最严谨)
    % LLR = ln[(P(0)/P(1))]，对应 sigm = log((1+exp(-L))/2)
    llr_c = (2 * rx) / (sigma^2);
    
    % 硬判决和 BER
    rx_bits_a = llr_a < 0;
    ber_a = sum(rx_bits_a ~= tx_bits) / N;
    
    % 理论 BER: Q(sqrt(2*SNR))
    ber_theory = 0.5 * erfc(sqrt(snr_lin) / sqrt(2));
    
    ratio = ber_theory / ber_a;
    
    fprintf('SNR=%+5.1f dB (sigma=%.4f):\n', snr_db, sigma);
    fprintf('  BER_measured: %.4e\n', ber_a);
    fprintf('  BER_theory:   %.4e\n', ber_theory);
    fprintf('  Ratio:        %.4f\n', ratio);
    if abs(ratio-1) < 0.5
        fprintf('  Status: ✓\n');
    else
        fprintf('  Status: ❌\n');
    end
    fprintf('\n');
end
