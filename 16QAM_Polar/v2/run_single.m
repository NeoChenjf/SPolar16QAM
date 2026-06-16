%% RUN_SINGLE - 单点快速测试
%
% 功能：对单个 p 值和少量 SNR 运行仿真，用于验证代码正确性。
%       帧数和 SNR 点都较少，几分钟内出结果。
%
% 用法：直接运行此脚本

clear; clc; close all;

%% ===== 初始化 =====
setup_paths();
cfg = config();

% 快速测试参数覆盖
cfg.num_frames = 100;           % 少帧快速验证
cfg.seed = 42;

% 选择要测试的 p 和 SNR
p_test = 0.3;
snr_test = [0, 5, 10, 15, 20];

fprintf('===== 单点快速测试 =====\n');
fprintf('p = %.2f | SNR = [%s] | Frames = %d | Decoder = %s\n', ...
        p_test, num2str(snr_test), cfg.num_frames, cfg.decoder);
fprintf('========================\n\n');

%% ===== 运行仿真 =====
tic;
result = sim_shaped_polar_16qam(p_test, snr_test, cfg);
elapsed = toc;

%% ===== 显示结果 =====
fprintf('\n===== 结果汇总 =====\n');
fprintf('p = %.2f | N = %d | 译码器 = %s\n', p_test, cfg.N, cfg.decoder);
fprintf('K = [%s] | S = [%s] | R_total = %.4f\n', ...
        num2str(result.K), num2str(result.S_size), result.R_total);
fprintf('E(p) = %.2f | E_norm = %.3f\n', ...
        result.E_theory, result.E_theory / cfg.E_baseline);
fprintf('\n');

fprintf('%-8s  %-10s  %-10s  %-10s  %-10s\n', ...
        'SNR(dB)', 'BER', 'BLER', 'Goodput', 'MI_total');
fprintf('%-8s  %-10s  %-10s  %-10s  %-10s\n', ...
        '------', '--------', '--------', '--------', '--------');
G = compute_goodput(result);
for j = 1:length(snr_test)
    fprintf('%+6.1f    %.2e    %.2e    %.4f      %.3f\n', ...
            snr_test(j), result.BER(j), result.BLER(j), G(j), result.MI_total(j));
end
fprintf('\n耗时: %.1f sec\n', elapsed);

%% ===== 快速绘图 =====
figure('Position', [100 100 900 400]);

subplot(1,2,1);
semilogy(snr_test, result.BER, '-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
xlabel('SNR (dB)'); ylabel('BER');
title(sprintf('BER (p=%.2f)', p_test));
grid on;

subplot(1,2,2);
plot(snr_test, G, '-s', 'LineWidth', 2, 'MarkerFaceColor', 'r');
xlabel('SNR (dB)'); ylabel('Goodput');
title(sprintf('Goodput (p=%.2f)', p_test));
grid on;

sgtitle(sprintf('Quick Test: p=%.2f, N=%d, %s decoder', ...
        p_test, cfg.N, cfg.decoder));

%% ===== 对比 SC 与 SCL（可选）=====
% 取消注释以下代码，可同时对比两种译码器
%{
cfg_scl = cfg;
cfg_scl.decoder = 'SCL';
cfg_scl.SCL_L = 8;

fprintf('\n--- SCL 对比 ---\n');
tic;
result_scl = sim_shaped_polar_16qam(p_test, snr_test, cfg_scl);
elapsed_scl = toc;

G_scl = compute_goodput(result_scl);
fprintf('\nSCL 结果:\n');
for j = 1:length(snr_test)
    fprintf('  SNR=%+.0f: BER=%.2e → %.2e (SC→SCL), Goodput=%.4f → %.4f\n', ...
            snr_test(j), result.BER(j), result_scl.BER(j), G(j), G_scl(j));
end
fprintf('SCL 耗时: %.1f sec\n', elapsed_scl);
%}
