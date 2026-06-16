%% RUN_SINGLE_SCL - SCL 译码器快速验证
%
% 对比 SC 与 SCL（L=8, 带先验）在相同条件下的 BER 性能。
% 200 帧，预计 10-15 分钟。

clear; clc; close all;

%% ===== 初始化 =====
setup_paths();
cfg = config();

% 快速测试参数
cfg.num_frames = 200;
cfg.seed = 42;

p_test  = 0.30;
snr_test = [5, 8, 10, 12, 15, 18, 20];

%% ===== 1) SC 基线 =====
cfg.decoder = 'SC';
fprintf('===== SC Decoder =====\n');
fprintf('p = %.2f | SNR = [%s] | Frames = %d\n', p_test, num2str(snr_test), cfg.num_frames);
fprintf('======================\n\n');

tic;
result_SC = sim_shaped_polar_16qam(p_test, snr_test, cfg);
t_SC = toc;

%% ===== 2) SCL L=8 带先验 =====
cfg.decoder = 'SCL';
cfg.SCL_L = 8;
fprintf('\n===== SCL Decoder (L=%d, with prior) =====\n', cfg.SCL_L);
fprintf('p = %.2f | SNR = [%s] | Frames = %d\n', p_test, num2str(snr_test), cfg.num_frames);
fprintf('==========================================\n\n');

tic;
result_SCL = sim_shaped_polar_16qam(p_test, snr_test, cfg);
t_SCL = toc;

%% ===== 3) 对比结果 =====
G_SC  = compute_goodput(result_SC);
G_SCL = compute_goodput(result_SCL);

fprintf('\n============================================================\n');
fprintf(' SC vs SCL (L=8, prior) 对比  |  p = %.2f\n', p_test);
fprintf('============================================================\n');
fprintf('%-8s  %-12s  %-12s  %-12s  %-12s\n', ...
        'SNR(dB)', 'BER_SC', 'BER_SCL', 'G_SC', 'G_SCL');
fprintf('%-8s  %-12s  %-12s  %-12s  %-12s\n', ...
        '------', '----------', '----------', '----------', '----------');
for j = 1:length(snr_test)
    fprintf('%+6.1f    %.4e    %.4e    %.4f      %.4f\n', ...
            snr_test(j), result_SC.BER(j), result_SCL.BER(j), G_SC(j), G_SCL(j));
end
fprintf('\nSC 耗时: %.1f sec | SCL 耗时: %.1f sec (%.1fx slower)\n', ...
        t_SC, t_SCL, t_SCL/t_SC);

%% ===== 4) 绘图 =====
figure('Position', [100 100 1200 500]);

% BER 对比
subplot(1,2,1);
semilogy(snr_test, result_SC.BER, 'b-o', 'LineWidth', 1.5, 'DisplayName', 'SC');
hold on;
semilogy(snr_test, result_SCL.BER, 'r-s', 'LineWidth', 1.5, 'DisplayName', sprintf('SCL L=%d (prior)', cfg.SCL_L));
hold off;
xlabel('SNR (dB)'); ylabel('BER');
title(sprintf('BER: SC vs SCL  (p=%.2f, N=%d)', p_test, cfg.N));
legend('Location', 'southwest'); grid on;

% Goodput 对比
subplot(1,2,2);
plot(snr_test, G_SC, 'b-o', 'LineWidth', 1.5, 'DisplayName', 'SC');
hold on;
plot(snr_test, G_SCL, 'r-s', 'LineWidth', 1.5, 'DisplayName', sprintf('SCL L=%d (prior)', cfg.SCL_L));
hold off;
xlabel('SNR (dB)'); ylabel('Goodput');
title(sprintf('Goodput: SC vs SCL  (p=%.2f, N=%d)', p_test, cfg.N));
legend('Location', 'northwest'); grid on;

fprintf('\n===== 测试完成 =====\n');
