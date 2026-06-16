%% RUN_SC_GA_ONLY_CURVE
% 目的：只画 SC 编码侧的 GA 理论估计曲线，不包含仿真、不包含校准
%
% 适用场景：
% 1) 先单独看理论趋势是否合理
% 2) 作为后续和 Monte Carlo 仿真对照的基础图
% 3) 避免校准线和真实仿真线干扰理论判断

clear; clc; close all;
setup_paths();
cfg = config();

%% ===== 参数配置 =====
p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
snr_grid = -20:2:10;
pe_floor = 1e-12;

cfg.decoder = 'SC';
cfg.seed = 20260421;
rng(cfg.seed, 'twister');

N = cfg.N;
nP = numel(p_list);
nS = numel(snr_grid);

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_sc_ga_only_curve']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

%% ===== 理论计算：GA 估计 =====
fprintf('========== GA ONLY: Theory curve computation =========\n');
ber_theory = zeros(nP, nS);

for ip = 1:nP
    p = p_list(ip);
    fprintf('GA theory: p=%.2f\n', p);

    % 让四路都使用同一个 p，避免“部分固定 0.5、部分变化”导致的混合效应
    cfg_local = cfg;
    cfg_local.p_fixed = [p, p, p, p];

    opts = struct();
    opts.disable_geom = true;      % 纯编码侧，不引入几何项
    opts.pe_floor = pe_floor;
    opts.alpha_rel = 1.0;
    opts.code_high_eta = 0.8;
    opts.code_high_mid_db = 14.0;
    opts.code_high_slope_db = 2.0;

    model = estimate_ber_hat_sc_dual(p, snr_grid, cfg_local, opts);
    ber_theory(ip, :) = model.BER_hat;
end

%% ===== 导出数据 =====
[P_grid, S_grid] = ndgrid(p_list, snr_grid);
T = table();
T.p = P_grid(:);
T.snr_dB = S_grid(:);
T.ber_theory = reshape(ber_theory, nP * nS, 1);
writetable(T, fullfile(out_dir, 'ga_only_curve.csv'));

%% ===== 绘图：只画 GA 理论曲线 =====
fig = figure('Position', [80 80 1100 620], 'Visible', 'off');
colors = lines(nP);
hold on;

for ip = 1:nP
    semilogy(snr_grid, ber_theory(ip, :), '-o', ...
        'Color', colors(ip, :), 'LineWidth', 1.8, 'MarkerSize', 5, ...
        'DisplayName', sprintf('GA theory p=%.1f', p_list(ip)));
end

grid on;
hold off;
xlabel('SNR (dB)', 'FontSize', 12);
ylabel('BER', 'FontSize', 12);
title('SC Encoding-Side GA Estimate Only', 'FontSize', 13);
legend('Location', 'southwest', 'FontSize', 9);
exportgraphics(fig, fullfile(fig_dir, 'ga_only_curve.png'), 'Resolution', 300);
exportgraphics(fig, fullfile(fig_dir, 'ga_only_curve.pdf'), 'ContentType', 'vector');
close(fig);

%% ===== README =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
fprintf(fid, 'GA-only curve for SC encoding-side analysis\n');
fprintf(fid, 'p_list = [0.5 0.4 0.3 0.2 0.1]\n');
fprintf(fid, 'snr_grid = -20:2:10 dB\n');
fprintf(fid, 'This output contains ONLY the theoretical GA estimate, no simulation and no calibration.\n');
fprintf(fid, 'All four bit streams share the same p in this version, so p is a single control variable.\n');
fprintf(fid, 'Data file: ga_only_curve.csv\n');
fprintf(fid, 'Figure: figures/ga_only_curve.(png/pdf)\n');
fclose(fid);

fprintf('\n>>> GA-only curve saved to: %s\n', out_dir);
