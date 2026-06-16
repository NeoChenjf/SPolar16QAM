%% RECOVER_WATERFALL_OUTPUTS_FROM_CSV
% 从已完成的 CSV 结果恢复瀑布区图像和 README，不重新运行 SC 仿真。
%
% 用法：
%   1. 默认恢复最新的 *_sc_waterfall_refine 结果目录；
%   2. 如需指定目录，设置 target_result_dir 为完整路径。

clear; clc; close all;
script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();
cfg = config();

target_result_dir = '';  % 例如 fullfile(cfg.output_dir, '20260520_180719_sc_waterfall_refine')

if isempty(target_result_dir)
    result_dirs = dir(fullfile(cfg.output_dir, '*_sc_waterfall_refine'));
    if isempty(result_dirs)
        error('No *_sc_waterfall_refine result directory found in %s', cfg.output_dir);
    end
    [~, idx_latest] = max([result_dirs.datenum]);
    target_result_dir = fullfile(result_dirs(idx_latest).folder, result_dirs(idx_latest).name);
end

fig_dir = fullfile(target_result_dir, 'figures');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

curve_file = fullfile(target_result_dir, 'local_waterfall_curve.csv');
if ~exist(curve_file, 'file')
    error('Missing local_waterfall_curve.csv in %s', target_result_dir);
end
T_local = readtable(curve_file);

window_file = fullfile(target_result_dir, 'waterfall_window.csv');
if exist(window_file, 'file')
    T_window = readtable(window_file);
else
    T_window = table();
end

coarse_file = fullfile(target_result_dir, 'coarse_scan.csv');
has_coarse = exist(coarse_file, 'file') == 2;
if has_coarse
    T_coarse = readtable(coarse_file);
end

target_ber_low = 1e-4;
target_ber_high = 1e-1;
if ~isempty(T_window)
    target_ber_low = T_window.target_ber_low(1);
    target_ber_high = T_window.target_ber_high(1);
end

%% ===== 恢复粗扫图 =====
if has_coarse
    p_list = unique(T_coarse.p, 'stable');
    colors_coarse = lines(numel(p_list));
    fig1 = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        p = p_list(ip);
        idx = abs(T_coarse.p - p) < 1e-12;
        T_p = sortrows(T_coarse(idx, :), 'snr_dB');
        semilogy(T_p.snr_dB, T_p.ber_sim, '-o', 'Color', colors_coarse(ip, :), ...
            'LineWidth', 1.4, 'MarkerSize', 5, 'DisplayName', sprintf('Sim p=%.1f', p));
        semilogy(T_p.snr_dB, T_p.ber_theory, '--', 'Color', colors_coarse(ip, :), ...
            'LineWidth', 1.0, 'DisplayName', sprintf('Theory p=%.1f', p));
    end
    yline(target_ber_low, 'k:', 'BER=1e-4');
    yline(target_ber_high, 'k:', 'BER=1e-1');
    if ~isempty(T_window)
        xline(T_window.waterfall_start_dB(1), 'k--', 'Start');
        xline(T_window.waterfall_end_dB(1), 'k--', 'End');
    end
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Coarse Scan for SC Waterfall Region');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig1, fullfile(fig_dir, 'coarse_waterfall_scan.fig'));
    exportgraphics(fig1, fullfile(fig_dir, 'coarse_waterfall_scan.png'), 'Resolution', 300);
    exportgraphics(fig1, fullfile(fig_dir, 'coarse_waterfall_scan.pdf'), 'ContentType', 'vector');
    close(fig1);
end

%% ===== 恢复局部加密图 =====
local_p_list = unique(T_local.p, 'stable');
colors_local = lines(numel(local_p_list));
fig2 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:numel(local_p_list)
    p = local_p_list(ip);
    idx = abs(T_local.p - p) < 1e-12;
    T_p = sortrows(T_local(idx, :), 'snr_dB');
    errorbar(T_p.snr_dB, T_p.ber_sim_mean, T_p.ber_sim_ci95, '-o', ...
        'Color', colors_local(ip, :), 'LineWidth', 1.6, 'MarkerSize', 5, ...
        'DisplayName', sprintf('Sim mean +/-95%%CI p=%.1f', p));
    semilogy(T_p.snr_dB, T_p.ber_theory, '--', 'Color', colors_local(ip, :), ...
        'LineWidth', 1.2, 'DisplayName', sprintf('Theory p=%.1f', p));
end
yline(target_ber_low, 'k:', 'BER=1e-4');
yline(target_ber_high, 'k:', 'BER=1e-1');
set(gca, 'YScale', 'log');
xlabel('SNR (dB)');
ylabel('BER');
title('Local Refined SC Waterfall Check');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig2, fullfile(fig_dir, 'local_waterfall_curve.fig'));
exportgraphics(fig2, fullfile(fig_dir, 'local_waterfall_curve.png'), 'Resolution', 300);
exportgraphics(fig2, fullfile(fig_dir, 'local_waterfall_curve.pdf'), 'ContentType', 'vector');
close(fig2);

%% ===== 恢复 README =====
fid = fopen(fullfile(target_result_dir, 'README.txt'), 'w');
if fid < 0
    error('Cannot create README.txt in %s', target_result_dir);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, '=== SC Waterfall Finder and Local Refinement ===\n\n');
fprintf(fid, 'RECOVERY NOTE\n');
fprintf(fid, '  This README and figures were regenerated from CSV outputs by recover_waterfall_outputs_from_csv.m.\n');
fprintf(fid, '  No SC simulation was rerun during recovery.\n\n');
fprintf(fid, 'SCOPE\n');
fprintf(fid, '  Theory: estimate_ber_hat_sc_dual(..., disable_geom=true).\n');
fprintf(fid, '  Simulation: polar_encoder + BPSK-AWGN + SC_decoder.\n\n');
fprintf(fid, 'TARGET\n');
fprintf(fid, '  BER window: [%.1e, %.1e]\n', target_ber_low, target_ber_high);
fprintf(fid, '  Local p_list: %s\n', mat2str(local_p_list(:).'));
fprintf(fid, '  Local SNR grid: %s\n\n', mat2str(unique(T_local.snr_dB, 'stable').'));

summary_file = fullfile(target_result_dir, 'local_waterfall_summary.csv');
if exist(summary_file, 'file')
    T_summary = readtable(summary_file);
    fprintf(fid, 'LOCAL SUMMARY\n');
    fprintf(fid, '  p      snr_dB     ber_sim_mean   ci95           ber_theory     gap            conclusion\n');
    for i = 1:height(T_summary)
        fprintf(fid, '  %.2f   %.2f       %.6e   %.6e   %.6e   %.6e   %s\n', ...
            T_summary.p(i), T_summary.selected_snr_dB(i), T_summary.ber_sim_mean(i), ...
            T_summary.ber_sim_ci95(i), T_summary.ber_theory(i), T_summary.gap(i), ...
            string(T_summary.conclusion(i)));
    end
    fprintf(fid, '\n');
end

fprintf(fid, 'OUTPUT FILES\n');
fprintf(fid, '  coarse_scan.csv\n');
fprintf(fid, '  waterfall_window.csv\n');
fprintf(fid, '  local_waterfall_curve.csv\n');
fprintf(fid, '  local_waterfall_repetitions.csv\n');
fprintf(fid, '  local_waterfall_summary.csv\n');
fprintf(fid, '  figures/coarse_waterfall_scan.*\n');
fprintf(fid, '  figures/local_waterfall_curve.*\n');

clear cleanup_fid;
fprintf('Recovered figures and README in: %s\n', target_result_dir);
