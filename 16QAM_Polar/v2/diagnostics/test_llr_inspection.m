%% TEST_LLR_INSPECTION - 细粒度 LLR 检测
% 逐层检查 LLR 的正确性

clear; clc;

N = 1000;
snr_db = 5;
snr_lin = 10^(snr_db/10);
sigma = 1 / sqrt(2 * snr_lin);  % BPSK Eb/N0 = 1

fprintf('LLR 正确性检测 (SNR=%.1f dB, sigma=%.4f)\n', snr_db, sigma);
fprintf('=============================================\n\n');

rng(42);

%% 生成信号
tx_bits = randi([0 1], N, 1);
tx_bpsk = 1 - 2*tx_bits;  % 0->+1, 1->-1
noise = sigma * randn(N, 1);
rx = tx_bpsk + noise;

%% 方法 1: 理论 BPSK LLR (参考)
llr_theory = (2 * rx) / (sigma^2);

%% 方法 2: 用 qamdemod 计算 (16QAM 嵌入 BPSK)
% 构造伪 16QAM: 每 4 个 BPSK 比特 → 1 个 16QAM 符号
% (这模拟了当前系统中 BPSK-AWGN 链路的 qamdemod 调用)

% 把 BPSK 信号扩展成 16QAM 形式(仅使用第 1 层)
rx_qam = zeros(N/4, 1);
ts_idx = 1:4:N;
for i = 1:length(ts_idx)
    idx = ts_idx(i);
    if idx + 3 <= N
        % 打包 4 个 BPSK 为 16QAM (format: I从 bit1/2, Q 从 bit3/4)
        rx_qam(i) = complex(rx(idx), rx(idx+2));
    end
end

% 计算 LLR (使用 qamdemod)
noise_var_llr = 2 * sigma^2;
fprintf('qamdemod 配置:\n');
fprintf('  NoiseVariance: %.6f\n', noise_var_llr);
fprintf('  Mapping: gray\n');
fprintf('  UnitAveragePower: false\n\n');

llr_qam_out = qamdemod(rx_qam, 16, 'gray', ...
    'OutputType', 'llr', ...
    'UnitAveragePower', false, ...
    'NoiseVariance', noise_var_llr);

% 提取第 1 bit (BPSK 对应)
llr_qam = llr_qam_out(1:4:end);

%% 比较
fprintf('逐点 LLR 对比 (前 20 点):\n');
fprintf('i   | rx      | tx | llr_theory | llr_qam   | sign_match | mag_ratio\n');
fprintf('----|---------|----|-----------|-----------|-----------|---------\n');

for i = 1:min(20, N)
    sign_match = (sign(llr_theory(i)) == sign(llr_qam(i)));
    if llr_theory(i) ~= 0
        mag_ratio = llr_qam(i) / llr_theory(i);
    else
        mag_ratio = NaN;
    end
    
    marker = '  ';
    if ~sign_match
        marker = '❌';
    end
    
    fprintf('%3d | %+7.3f | %d | %+9.4f | %+9.4f | %d | %.3f %s\n', ...
        i, rx(i), tx_bits(i), llr_theory(i), llr_qam(i), ...
        sign_match, mag_ratio, marker);
end

%% 统计相关性
corr_theory = corr(llr_theory, sign(2*tx_bits-1));
corr_qam = corr(llr_qam, sign(2*tx_bits(1:4:end)-1));

fprintf('\n相关性分析:\n');
fprintf('  LLR_theory vs TX: r=%.4f\n', corr_theory);
fprintf('  LLR_qam vs TX:    r=%.4f\n', corr_qam);

%% 硬判决 BER
ber_theory = sum((llr_theory < 0) ~= tx_bits) / N;
ber_qam = sum((llr_qam < 0) ~= tx_bits(1:4:end)) / (N/4);

fprintf('\nBER 比较:\n');
fprintf('  BER_theory: %.4e\n', ber_theory);
fprintf('  BER_qam:    %.4e\n', ber_qam);
fprintf('  Ratio:      %.4f\n', ber_qam / ber_theory);

fprintf('\n=== 结论 ===\n');
if abs(median(llr_qam(llr_theory~=0) ./ llr_theory(llr_theory~=0)) - 1.0) < 0.2
    fprintf('✓ LLR 幅度对，符号对 → qamdemod 正常\n');
else
    fprintf('❌ LLR 幅度或符号偏离 → qamdemod 可能问题\n');
end
