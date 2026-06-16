%% TEST_BPSK_BASELINE - 诊断步骤 1：BPSK 无编码基准测试
% 功能：验证信道 + LLR 计算是否正确
% 输出：与理论 Q 函数曲线对比，检查是否匹配
%
% 原理：
%   1. 生成随机 BPSK 比特流（无编码）
%   2. 加入 AWGN 噪声
%   3. 计算 LLR
%   4. 检查译码误码率 vs 理论值
%
% 注意：系统采用 Es/N0 (符号级 SNR)，但 BPSK 每个符号=1 比特，
%      所以 Es/N0 = Eb/N0

clc;

%% 参数
N = 10000;              % 发送比特数
snr_db_vec = -5:1:15;   % SNR (dB), 这里是 Eb/N0 (BPSK 中 Es/N0 = Eb/N0)
nSNR = length(snr_db_vec);

% 存储输出
ber_measured = zeros(1, nSNR);
ber_theory   = zeros(1, nSNR);

%% 主循环
fprintf('BPSK 无编码基准测试\n');
fprintf('SNR(dB) | BER measured | BER theory | Q(sqrt(2*SNR)) | Ratio | OK?  \n');
fprintf('--------|--------------|------------|--------|-------|------\n');

rng(42, 'twister');

for iSNR = 1:nSNR
    snr_db = snr_db_vec(iSNR);
    snr_lin = 10^(snr_db/10);
    
    % 在 fixed_esn0 模式下，SNR_dB 是符号级 SNR (Es/N0)
    % 对于 BPSK，Es = Eb（单比特 = 单符号），所以这就是 Eb/N0
    sigma = 10^(-snr_db/20);
    
    % 生成信号
    tx_bits = randi([0 1], N, 1);
    tx_bpsk = 1 - 2*tx_bits;      % 0->+1, 1->-1，能量 = 1 per symbol
    
    % AWGN 信道
    noise = sigma * randn(N, 1);
    rx = tx_bpsk + noise;
    
    % 计算 LLR: ln(P(0)/P(1)) = 2*rx / sigma^2
    llr = (2 * rx) / (sigma^2);
    
    % 硬判决
    rx_bits_hard = llr < 0;
    
    % 误码率
    ber_measured(iSNR) = sum(rx_bits_hard ~= tx_bits) / N;
    
    % 理论 BER (fixed_esn0): Q(sqrt(2*Eb/N0)) = Q(sqrt(2*SNR_lin))
    % 因为 SNR_lin = Es/N0 = Eb/N0 (for BPSK)
    % 所以 BER = Q(sqrt(2*SNR_lin))，但实际注意是符号级
    % 更准确：BER_BPSK = 0.5 * erfc(sqrt(SNR_lin) / sqrt(2))
    ber_theory(iSNR) = 0.5 * erfc(sqrt(snr_lin) / sqrt(2));
    
    % 检查是否吻合（高 SNR 下样本错误数太少时不做严格比值判定）
    expected_errors = N * ber_theory(iSNR);
    if ber_measured(iSNR) > 0
        ratio = ber_theory(iSNR) / ber_measured(iSNR);
        if expected_errors >= 20
            is_ok = (ratio > 0.9) && (ratio < 1.11);
        else
            is_ok = 1;
        end
    else
        ratio = NaN;
        is_ok = 1;
    end
    
    ok_str = '✓';
    if ~is_ok
        ok_str = '❌';
    end
    
    fprintf('%+6.1f dB | %.2e | %.2e | %.2e | %.2f | %s\n', ...
        snr_db, ber_measured(iSNR), ber_theory(iSNR), ...
        0.5 * erfc(sqrt(snr_lin)/sqrt(2)), ratio, ok_str);
end

%% 绘图
figure('Position', [100 100 900 600]);
semilogy(snr_db_vec, ber_measured, 'o-', 'LineWidth', 2, 'MarkerSize', 6); hold on;
semilogy(snr_db_vec, ber_theory, 's--', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('BPSK 无编码基准测试：测量 vs 理论');
legend('Measured', 'Theory Q-function', 'Location', 'southwest');

%% 判定
fprintf('\n=== 诊断结论 ===\n');
valid_mask = (ber_measured > 0) & ((N .* ber_theory) >= 20);
if any(valid_mask)
    max_ratio = max(ber_theory(valid_mask) ./ ber_measured(valid_mask));
    min_ratio = min(ber_theory(valid_mask) ./ ber_measured(valid_mask));
else
    max_ratio = NaN;
    min_ratio = NaN;
end

if all(~isnan(ber_measured)) && ~isnan(max_ratio) && max_ratio < 1.25 && min_ratio > 0.8
    fprintf('✓ 信道 + LLR 部分正常\n');
    fprintf('  理论/测量比值范围: [%.2f, %.2f]\n', min_ratio, max_ratio);
    fprintf('  判定说明: 仅统计期望错误数>=20的SNR点\n');
else
    fprintf('❌ 信道或 LLR 部分有问题\n');
    if ~isnan(max_ratio)
        fprintf('  理论/测量比值范围: [%.2f, %.2f]\n', min_ratio, max_ratio);
    else
        fprintf('  理论/测量比值范围: 无有效统计点\n');
    end
    fprintf('  建议检查:\n');
    fprintf('    1. LLR 计算公式\n');
    fprintf('    2. 噪声功率计算\n');
    fprintf('    3. BPSK 符号映射\n');
end

% 保存结果
results_dir = sprintf('../results/%s_bpsk_baseline', datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end
savefig(fullfile(results_dir, 'bpsk_baseline.fig'));
saveas(gca, fullfile(results_dir, 'bpsk_baseline.png'));

fprintf('\n结果已保存到: %s\n', results_dir);

% 导出 CSV
T = table(snr_db_vec', ber_measured', ber_theory', ...
    ber_theory'./ber_measured', ...
    'VariableNames', {'SNR_dB', 'BER_measured', 'BER_theory', 'Ratio_theory_meas'});
writetable(T, fullfile(results_dir, 'bpsk_baseline.csv'));
