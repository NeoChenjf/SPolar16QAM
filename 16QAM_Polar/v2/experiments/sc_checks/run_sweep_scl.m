%% RUN_SWEEP_SCL - SCL(L=8, 带先验) p × SNR 全网格扫参
%
% 基于 run_sweep.m，专门用于 SCL 译码器的完整扫参。
% SCL 比 SC 慢约 1.5 倍，总耗时预计 8-18 小时。
%
% 输出目录：results/<timestamp>_pareto_sweep_SCL/

clear; clc; close all;

%% ===== 1. 初始化 =====
setup_paths();
cfg = config();

%% ===== 模式选择 =====
TRIAL_MODE = false;   % true=试扫(~10 min)  false=正式(数小时)

if TRIAL_MODE
    cfg.p_candidates = [0.50, 0.30, 0.10];
    cfg.SNR_dB       = 0:5:20;
    cfg.num_frames   = 100;
    fprintf('[试扫模式] SCL 快速验证\n\n');
else
    % 正式模式：config.m 的完整 10p × 31SNR × 1000帧
    fprintf('[正式模式] SCL 完整扫参\n\n');
end

%% ===== SCL 配置 =====
cfg.decoder = 'SCL';
cfg.SCL_L = 8;

p_list = cfg.p_candidates;
nP = length(p_list);

fprintf('========================================\n');
fprintf(' Shaped Polar 16QAM Sweep (SCL)\n');
fprintf(' p values: %d | SNR points: %d | Frames: %d\n', ...
        nP, length(cfg.SNR_dB), cfg.num_frames);
fprintf(' Decoder: %s (L=%d, with prior)\n', cfg.decoder, cfg.SCL_L);
fprintf('========================================\n\n');

%% ===== 2. 运行仿真 =====
all_results = cell(1, nP);
tic;

for ip = 1:nP
    p = p_list(ip);
    fprintf('--- p = %.3f (%d/%d) ---\n', p, ip, nP);
    all_results{ip} = sim_shaped_polar_16qam(p, cfg.SNR_dB, cfg);
    fprintf('\n');
end

elapsed = toc;
fprintf('========================================\n');
fprintf(' 总耗时: %.1f min (%.1f sec)\n', elapsed/60, elapsed);
fprintf('========================================\n\n');

%% ===== 3. 汇总数据 =====
snr_dB = cfg.SNR_dB;
nSNR = length(snr_dB);

BER_matrix      = zeros(nP, nSNR);
Goodput_matrix  = zeros(nP, nSNR);
MI_matrix       = zeros(nP, nSNR);
E_theory_vec    = zeros(nP, 1);
R_total_vec     = zeros(nP, 1);
K_matrix        = zeros(nP, 4);

for ip = 1:nP
    r = all_results{ip};
    BER_matrix(ip, :)     = r.BER;
    Goodput_matrix(ip, :) = compute_goodput(r);
    MI_matrix(ip, :)      = r.MI_total;
    E_theory_vec(ip)      = r.E_theory;
    R_total_vec(ip)       = r.R_total;
    K_matrix(ip, :)       = r.K;
end

E_norm_vec = E_theory_vec / cfg.E_baseline;

%% ===== 4. 保存结果 =====
out_dir = fullfile(cfg.output_dir, [cfg.timestamp '_pareto_sweep_SCL']);
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
fig_dir = fullfile(out_dir, 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

save(fullfile(out_dir, 'sweep_results.mat'), ...
     'all_results', 'cfg', 'p_list', 'snr_dB', ...
     'BER_matrix', 'Goodput_matrix', 'MI_matrix', ...
     'E_theory_vec', 'E_norm_vec', 'R_total_vec', 'K_matrix', ...
     'elapsed');

summary = table();
summary.p = p_list(:);
summary.K_total = sum(K_matrix, 2);
summary.R_total = R_total_vec;
summary.E_theory = E_theory_vec;
summary.E_norm = E_norm_vec;
writetable(summary, fullfile(out_dir, 'sweep_summary.csv'));

fprintf('结果已保存至: %s\n', out_dir);

%% ===== 5. 生成图表 =====
fprintf('生成图表...\n');

plot_ber_vs_snr(p_list, snr_dB, BER_matrix, fig_dir);
plot_goodput_vs_snr(p_list, snr_dB, Goodput_matrix, fig_dir);

snr_targets = [0, 5, 10, 15, 20];
plot_pareto(p_list, snr_dB, Goodput_matrix, E_norm_vec, snr_targets, fig_dir);
plot_mi_vs_snr(p_list, snr_dB, MI_matrix, fig_dir);

idx_baseline = find(p_list == 0.5, 1);
if ~isempty(idx_baseline)
    plot_cost_curves(p_list, snr_dB, Goodput_matrix, E_theory_vec, ...
                     idx_baseline, snr_targets, fig_dir);
end

fprintf('所有图表已保存至: %s\n', fig_dir);
fprintf('\n===== SCL 扫参完成 =====\n');
