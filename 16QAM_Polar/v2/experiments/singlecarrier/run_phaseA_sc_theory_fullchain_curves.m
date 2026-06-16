%% RUN_PHASEA_SC_THEORY_FULLCHAIN_CURVES
% 阶段 A 单载波 SC 纯理论 full-chain BER / Goodput 曲线。
%
% 口径：
%   - 不运行 Monte Carlo；
%   - 理论 BER 使用 estimate_ber_hat_sc_dual(..., disable_geom=false)；
%   - 几何项默认只作用于 cfg.p_fixed 中由 p 控制的 bit2/bit4；
%   - Goodput 使用 G_hat = R_total * (1 - BER_hat)。

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg = config();

%% ===== 参数 =====
p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
snr_grid = 0:1:20;

opts = struct();
opts.disable_geom = false;
opts.geom_model = 'strict_q';
opts.geom_apply_mode = 'shaped_only';
opts.geom_ref_p = 0.5;
opts.pe_floor = 1e-12;
opts.alpha_rel = 1.0;
opts.code_high_eta = 0.8;
opts.code_high_mid_db = 14.0;
opts.code_high_slope_db = 2.0;

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_phaseA_sc_theory_fullchain_curves']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

log_file = fullfile(out_dir, 'run_log.txt');
diary(log_file);
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Phase A SC Theory Full-chain Curves ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('p_list: %s\n', mat2str(p_list));
fprintf('snr_grid: %s\n', mat2str(snr_grid));
fprintf('geom_model: %s\n', opts.geom_model);
fprintf('geom_apply_mode: %s\n', opts.geom_apply_mode);

%% ===== 理论计算 =====
nP = numel(p_list);
nS = numel(snr_grid);

BER_hat = nan(nP, nS);
Goodput_hat = nan(nP, nS);
R_total = nan(nP, 1);
E_theory = nan(nP, 1);
E_norm = nan(nP, 1);
K_matrix = nan(nP, 4);
S_matrix = nan(nP, 4);
geom_ratio = nan(nP, nS);
geom_ratio_bit2 = nan(nP, nS);
geom_ratio_bit4 = nan(nP, nS);

models = cell(nP, 1);
for ip = 1:nP
    p = p_list(ip);
    fprintf('\nTheory p=%.2f\n', p);
    model = estimate_ber_hat_sc_dual(p, snr_grid, cfg, opts);
    models{ip} = model;

    BER_hat(ip, :) = model.BER_hat;
    R_total(ip) = model.R_total;
    Goodput_hat(ip, :) = model.R_total .* (1 - model.BER_hat);
    E_theory(ip) = 18 - 16 * p;
    E_norm(ip) = E_theory(ip) / cfg.E_baseline;
    K_matrix(ip, :) = model.K;
    S_matrix(ip, :) = model.S_size;
    geom_ratio(ip, :) = model.B_geom_ratio;
    geom_ratio_bit2(ip, :) = model.B_geom_ratio_per_bit(2, :);
    geom_ratio_bit4(ip, :) = model.B_geom_ratio_per_bit(4, :);
end

%% ===== 输出 CSV =====
[P_grid, S_grid] = ndgrid(p_list, snr_grid);
rows = nP * nS;
T = table();
T.p = P_grid(:);
T.snr_dB = S_grid(:);
T.BER_hat_full_theory = reshape(BER_hat, rows, 1);
T.Goodput_hat_theory = reshape(Goodput_hat, rows, 1);
T.R_total = repmat(R_total, nS, 1);
T.E_theory = repmat(E_theory, nS, 1);
T.E_norm = repmat(E_norm, nS, 1);
T.geom_ratio = reshape(geom_ratio, rows, 1);
T.geom_ratio_bit2 = reshape(geom_ratio_bit2, rows, 1);
T.geom_ratio_bit4 = reshape(geom_ratio_bit4, rows, 1);
writetable(T, fullfile(out_dir, 'theory_fullchain_curves.csv'));

T_p = table();
T_p.p = p_list(:);
T_p.R_total = R_total;
T_p.E_theory = E_theory;
T_p.E_norm = E_norm;
T_p.K1 = K_matrix(:, 1);
T_p.K2 = K_matrix(:, 2);
T_p.K3 = K_matrix(:, 3);
T_p.K4 = K_matrix(:, 4);
T_p.S1 = S_matrix(:, 1);
T_p.S2 = S_matrix(:, 2);
T_p.S3 = S_matrix(:, 3);
T_p.S4 = S_matrix(:, 4);
writetable(T_p, fullfile(out_dir, 'theory_p_summary.csv'));

save(fullfile(out_dir, 'theory_fullchain_curves.mat'), ...
    'cfg', 'opts', 'p_list', 'snr_grid', 'models', ...
    'BER_hat', 'Goodput_hat', 'R_total', 'E_theory', 'E_norm', ...
    'K_matrix', 'S_matrix', 'geom_ratio');

%% ===== 绘图 =====
colors = lines(nP);

fig1 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:nP
    semilogy(snr_grid, BER_hat(ip, :), '-o', ...
        'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', sprintf('Theory full-chain p=%.1f', p_list(ip)));
end
xlabel('SNR (dB)');
ylabel('BER');
title('Theory Full-chain SC BER vs SNR');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig1, fullfile(fig_dir, 'theory_fullchain_ber_vs_snr.fig'));
exportgraphics(fig1, fullfile(fig_dir, 'theory_fullchain_ber_vs_snr.png'), 'Resolution', 300);
exportgraphics(fig1, fullfile(fig_dir, 'theory_fullchain_ber_vs_snr.pdf'), 'ContentType', 'vector');
close(fig1);

fig2 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:nP
    plot(snr_grid, Goodput_hat(ip, :), '-o', ...
        'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', sprintf('Theory Goodput p=%.1f', p_list(ip)));
end
xlabel('SNR (dB)');
ylabel('Goodput');
title('Theory Full-chain SC Goodput vs SNR');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig2, fullfile(fig_dir, 'theory_fullchain_goodput_vs_snr.fig'));
exportgraphics(fig2, fullfile(fig_dir, 'theory_fullchain_goodput_vs_snr.png'), 'Resolution', 300);
exportgraphics(fig2, fullfile(fig_dir, 'theory_fullchain_goodput_vs_snr.pdf'), 'ContentType', 'vector');
close(fig2);

fig3 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:nP
    plot(snr_grid, geom_ratio_bit2(ip, :), '-o', ...
        'Color', colors(ip, :), 'LineWidth', 1.4, 'MarkerSize', 5, ...
        'DisplayName', sprintf('bit2/4 geom ratio p=%.1f', p_list(ip)));
end
xlabel('SNR (dB)');
ylabel('Geometry ratio on controlled bits');
title('Theory Geometry Ratio Applied to bit2/bit4');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig3, fullfile(fig_dir, 'theory_geom_ratio_vs_snr.fig'));
exportgraphics(fig3, fullfile(fig_dir, 'theory_geom_ratio_vs_snr.png'), 'Resolution', 300);
exportgraphics(fig3, fullfile(fig_dir, 'theory_geom_ratio_vs_snr.pdf'), 'ContentType', 'vector');
close(fig3);

%% ===== README =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
if fid < 0
    error('Cannot create README.txt in %s', out_dir);
end
cleanup_fid = onCleanup(@() fclose(fid));
fprintf(fid, '=== Phase A SC Theory Full-chain Curves ===\n\n');
fprintf(fid, 'RUN COMMAND\n');
fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/singlecarrier/run_phaseA_sc_theory_fullchain_curves.m'');\n\n');
fprintf(fid, 'SCOPE\n');
fprintf(fid, '  Pure theory only. No Monte Carlo simulation is run.\n');
fprintf(fid, '  BER source: estimate_ber_hat_sc_dual(..., disable_geom=false).\n');
fprintf(fid, '  Goodput: R_total * (1 - BER_hat).\n\n');
fprintf(fid, 'PARAMETERS\n');
fprintf(fid, '  p_list: %s\n', mat2str(p_list));
fprintf(fid, '  snr_grid: %s\n', mat2str(snr_grid));
fprintf(fid, '  geom_model: %s\n', opts.geom_model);
fprintf(fid, '  geom_apply_mode: %s\n', opts.geom_apply_mode);
fprintf(fid, '  geom_ref_p: %.2f\n\n', opts.geom_ref_p);
fprintf(fid, 'OUTPUTS\n');
fprintf(fid, '  theory_fullchain_curves.csv\n');
fprintf(fid, '  theory_p_summary.csv\n');
fprintf(fid, '  theory_fullchain_curves.mat\n');
fprintf(fid, '  figures/theory_fullchain_ber_vs_snr.*\n');
fprintf(fid, '  figures/theory_fullchain_goodput_vs_snr.*\n');
fprintf(fid, '  figures/theory_geom_ratio_vs_snr.*\n');
clear cleanup_fid;

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);
