%% RUN_SWEEP - 系统性 p × SNR 全网格扫参
%
% 功能：对所有候选 p 值和 SNR 范围运行仿真，保存完整结果并生成图表。
%
% 用法：直接运行此脚本（先确认 config.m 中参数正确）
%
% 输出：
%   results/<timestamp>_pareto_sweep/
%     ├── sweep_results.mat    % 完整结果
%     ├── sweep_summary.csv    % 汇总表
%     └── figures/             % 所有图表
%
% 预计运行时间：取决于 p_candidates × SNR_dB × num_frames
%   SC 译码: ~几小时 (10p × 31SNR × 1000帧)
%   建议先用 run_single.m 验证正确性

clear; clc; close all;

%% ===== 1. 初始化 =====
setup_paths();
cfg = config();

%% ===== 模式选择 =====
% 改为 false 进行正式扫参（耗时数小时）
TRIAL_MODE = false;

if TRIAL_MODE
    % 试扫模式：3 个 p × 5 SNR × 100 帧，~5-10 min
    cfg.p_candidates = [0.50, 0.30, 0.10];
    cfg.SNR_dB       = 0:5:20;
    cfg.num_frames   = 100;
    fprintf('[试扫模式] 快速验证 sweep 流程\n\n');
else
    % 正式模式：使用 config.m 中的完整参数
    % cfg.num_frames = 1000;        % 如需更多帧可在此覆盖
    fprintf('[正式模式] 完整 p × SNR 网格扫参\n\n');
end

p_list = cfg.p_candidates;
nP = length(p_list);

fprintf('========================================\n');
fprintf(' Shaped Polar 16QAM Sweep\n');
fprintf(' p values: %d | SNR points: %d | Frames: %d\n', ...
        nP, length(cfg.SNR_dB), cfg.num_frames);
fprintf(' Decoder: %s', cfg.decoder);
if strcmp(cfg.decoder, 'SCL')
    fprintf(' (L=%d)', cfg.SCL_L);
end
fprintf('\n');
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
% 提取关键量到矩阵，方便后续分析
snr_dB = cfg.SNR_dB;
nSNR = length(snr_dB);

BER_matrix      = zeros(nP, nSNR);   % (nP x nSNR)
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

% 归一化能量
E_norm_vec = E_theory_vec / cfg.E_baseline;

%% ===== 4. 保存结果 =====
out_dir = fullfile(cfg.output_dir, [cfg.timestamp '_pareto_sweep']);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
fig_dir = fullfile(out_dir, 'figures');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

% 保存完整 mat
save(fullfile(out_dir, 'sweep_results.mat'), ...
     'all_results', 'cfg', 'p_list', 'snr_dB', ...
     'BER_matrix', 'Goodput_matrix', 'MI_matrix', ...
     'E_theory_vec', 'E_norm_vec', 'R_total_vec', 'K_matrix', ...
     'elapsed');

% 保存 CSV 汇总（每个 p 一行，列为关键统计量）
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

% (a) BER vs SNR（不同 p）
plot_ber_vs_snr(p_list, snr_dB, BER_matrix, fig_dir);

% (b) Goodput vs SNR（不同 p）
plot_goodput_vs_snr(p_list, snr_dB, Goodput_matrix, fig_dir);

% (c) Pareto 前沿：Goodput vs E_norm（选定 SNR）
snr_targets = [0, 5, 10, 15, 20];
plot_pareto(p_list, snr_dB, Goodput_matrix, E_norm_vec, snr_targets, fig_dir);

% (d) MI vs SNR
plot_mi_vs_snr(p_list, snr_dB, MI_matrix, fig_dir);

% (e) Cost 曲线
idx_baseline = find(p_list == 0.5, 1);
if ~isempty(idx_baseline)
    plot_cost_curves(p_list, snr_dB, Goodput_matrix, E_theory_vec, ...
                     idx_baseline, snr_targets, fig_dir);
end

fprintf('所有图表已保存至: %s\n', fig_dir);
fprintf('\n===== 扫参完成 =====\n');
