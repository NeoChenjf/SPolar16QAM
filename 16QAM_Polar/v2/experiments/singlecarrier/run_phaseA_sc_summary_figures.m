%% RUN_PHASEA_SC_SUMMARY_FIGURES
% 生成阶段 A 单载波 SC 汇总图。
%
% 图形口径：
%   - 旧全 p 数据画主趋势；
%   - 收尾复验数据在异常区间叠加均值与 95% CI；
%   - 本脚本只读已有 CSV，不重新运行 Monte Carlo。

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();
cfg = config();

%% ===== 数据源 =====
code_global_dir = fullfile(v2_root, 'results', '20260520_180719_sc_waterfall_refine');
full_global_dir = fullfile(v2_root, 'results', '20260520_231445_singlecarrier_sc_closure');
recheck_dir = fullfile(v2_root, 'results', '20260521_141330_phaseA_sc_closure_check');

code_global_file = fullfile(code_global_dir, 'local_waterfall_curve.csv');
full_global_file = fullfile(full_global_dir, 'fullchain_sc_closure.csv');
code_recheck_file = fullfile(recheck_dir, 'codeonly_local_recheck.csv');
full_recheck_file = fullfile(recheck_dir, 'fullchain_local_recheck.csv');

required_files = {code_global_file, full_global_file, code_recheck_file, full_recheck_file};
for i = 1:numel(required_files)
    if exist(required_files{i}, 'file') ~= 2
        error('Required CSV not found: %s', required_files{i});
    end
end

T_code_global = readtable(code_global_file);
T_full_global = readtable(full_global_file);
T_code_recheck = readtable(code_recheck_file);
T_full_recheck = readtable(full_recheck_file);

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_phaseA_sc_summary_figures']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

log_file = fullfile(out_dir, 'run_log.txt');
diary(log_file);
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Phase A SC Summary Figures ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('Code global: %s\n', code_global_file);
fprintf('Full global: %s\n', full_global_file);
fprintf('Code recheck: %s\n', code_recheck_file);
fprintf('Full recheck: %s\n', full_recheck_file);

%% ===== 聚合复验数据 =====
T_code_recheck_summary = local_summarize_metric(T_code_recheck, 'BER');
T_code_recheck_summary.BER_theory = local_group_mean(T_code_recheck, 'BER_theory', ...
    T_code_recheck_summary.p, T_code_recheck_summary.snr_dB);
writetable(T_code_recheck_summary, fullfile(out_dir, 'codeonly_recheck_summary.csv'));

T_full_recheck_ber = local_summarize_metric(T_full_recheck, 'BER');
T_full_recheck_goodput = local_summarize_metric(T_full_recheck, 'Goodput');
T_full_recheck_summary = table();
T_full_recheck_summary.p = T_full_recheck_ber.p;
T_full_recheck_summary.snr_dB = T_full_recheck_ber.snr_dB;
T_full_recheck_summary.BER_mean = T_full_recheck_ber.mean;
T_full_recheck_summary.BER_ci95 = T_full_recheck_ber.ci95;
T_full_recheck_summary.Goodput_mean = T_full_recheck_goodput.mean;
T_full_recheck_summary.Goodput_ci95 = T_full_recheck_goodput.ci95;
T_full_recheck_summary.n = T_full_recheck_ber.n;
T_full_recheck_summary.R_total = local_group_mean(T_full_recheck, 'R_total', ...
    T_full_recheck_summary.p, T_full_recheck_summary.snr_dB);
writetable(T_full_recheck_summary, fullfile(out_dir, 'fullchain_recheck_summary.csv'));

%% ===== 绘图 =====
colors = lines(5);
p_global = sort(unique(T_code_global.p), 'descend').';

fig1 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:numel(p_global)
    p = p_global(ip);
    rows = T_code_global(abs(T_code_global.p - p) < 1e-12, :);
    rows = sortrows(rows, 'snr_dB');
    color_idx = min(ip, size(colors, 1));
    semilogy(rows.snr_dB, rows.ber_sim_mean, '-o', ...
        'Color', colors(color_idx, :), 'LineWidth', 1.1, 'MarkerSize', 4, ...
        'DisplayName', sprintf('Old full-p p=%.1f', p));
end
for p = [0.5, 0.4]
    rows = T_code_recheck_summary(abs(T_code_recheck_summary.p - p) < 1e-12, :);
    rows = sortrows(rows, 'snr_dB');
    errorbar(rows.snr_dB, rows.mean, rows.ci95, 'ks', ...
        'LineWidth', 1.8, 'MarkerSize', 7, 'MarkerFaceColor', 'w', ...
        'DisplayName', sprintf('Recheck mean +/- CI p=%.1f', p));
end
set(gca, 'YScale', 'log');
xlabel('SNR (dB)');
ylabel('BER');
title('Code-only SC BER: Global Trend with Local Recheck Overlay');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig1, fullfile(fig_dir, 'phaseA_codeonly_global_with_recheck.fig'));
exportgraphics(fig1, fullfile(fig_dir, 'phaseA_codeonly_global_with_recheck.png'), 'Resolution', 300);
exportgraphics(fig1, fullfile(fig_dir, 'phaseA_codeonly_global_with_recheck.pdf'), 'ContentType', 'vector');
close(fig1);

p_full = sort(unique(T_full_global.p), 'descend').';
fig2 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:numel(p_full)
    p = p_full(ip);
    rows = T_full_global(abs(T_full_global.p - p) < 1e-12, :);
    rows = sortrows(rows, 'snr_dB');
    color_idx = min(ip, size(colors, 1));
    semilogy(rows.snr_dB, rows.BER, '-o', ...
        'Color', colors(color_idx, :), 'LineWidth', 1.1, 'MarkerSize', 4, ...
        'DisplayName', sprintf('Old full-p p=%.1f', p));
end
for p = [0.5, 0.1]
    rows = T_full_recheck_summary(abs(T_full_recheck_summary.p - p) < 1e-12, :);
    rows = sortrows(rows, 'snr_dB');
    errorbar(rows.snr_dB, rows.BER_mean, rows.BER_ci95, 'ks', ...
        'LineWidth', 1.8, 'MarkerSize', 7, 'MarkerFaceColor', 'w', ...
        'DisplayName', sprintf('Recheck BER mean +/- CI p=%.1f', p));
end
set(gca, 'YScale', 'log');
xlabel('SNR (dB)');
ylabel('BER');
title('Full-chain SC BER: Global Trend with Local Recheck Overlay');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig2, fullfile(fig_dir, 'phaseA_fullchain_ber_global_with_recheck.fig'));
exportgraphics(fig2, fullfile(fig_dir, 'phaseA_fullchain_ber_global_with_recheck.png'), 'Resolution', 300);
exportgraphics(fig2, fullfile(fig_dir, 'phaseA_fullchain_ber_global_with_recheck.pdf'), 'ContentType', 'vector');
close(fig2);

fig3 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:numel(p_full)
    p = p_full(ip);
    rows = T_full_global(abs(T_full_global.p - p) < 1e-12, :);
    rows = sortrows(rows, 'snr_dB');
    color_idx = min(ip, size(colors, 1));
    plot(rows.snr_dB, rows.Goodput, '-o', ...
        'Color', colors(color_idx, :), 'LineWidth', 1.1, 'MarkerSize', 4, ...
        'DisplayName', sprintf('Old full-p p=%.1f', p));
end
for p = [0.5, 0.1]
    rows = T_full_recheck_summary(abs(T_full_recheck_summary.p - p) < 1e-12, :);
    rows = sortrows(rows, 'snr_dB');
    errorbar(rows.snr_dB, rows.Goodput_mean, rows.Goodput_ci95, 'ks', ...
        'LineWidth', 1.8, 'MarkerSize', 7, 'MarkerFaceColor', 'w', ...
        'DisplayName', sprintf('Recheck Goodput mean +/- CI p=%.1f', p));
end
xlabel('SNR (dB)');
ylabel('Goodput');
title('Full-chain SC Goodput: Global Trend with Local Recheck Overlay');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig3, fullfile(fig_dir, 'phaseA_fullchain_goodput_global_with_recheck.fig'));
exportgraphics(fig3, fullfile(fig_dir, 'phaseA_fullchain_goodput_global_with_recheck.png'), 'Resolution', 300);
exportgraphics(fig3, fullfile(fig_dir, 'phaseA_fullchain_goodput_global_with_recheck.pdf'), 'ContentType', 'vector');
close(fig3);

fig4 = figure('Color', 'w', 'Position', [80 80 1280 820]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
local_plot_codeonly_tile(T_code_global, T_code_recheck_summary, colors);
local_plot_fullchain_ber_tile(T_full_global, T_full_recheck_summary, colors);
local_plot_fullchain_goodput_tile(T_full_global, T_full_recheck_summary, colors);
nexttile;
axis off;
text(0, 0.85, 'Data sources', 'FontWeight', 'bold', 'FontSize', 12);
text(0, 0.68, 'Lines: old full-p global trend runs', 'FontSize', 10);
text(0, 0.52, 'Black squares: local recheck mean +/- 95% CI', 'FontSize', 10);
text(0, 0.36, 'Use as stage-document explanatory figure.', 'FontSize', 10);
text(0, 0.20, 'Do not treat as statistically uniform final paper curve.', 'FontSize', 10);
savefig(fig4, fullfile(fig_dir, 'phaseA_summary_overlay_panel.fig'));
exportgraphics(fig4, fullfile(fig_dir, 'phaseA_summary_overlay_panel.png'), 'Resolution', 300);
exportgraphics(fig4, fullfile(fig_dir, 'phaseA_summary_overlay_panel.pdf'), 'ContentType', 'vector');
close(fig4);

%% ===== README =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
if fid < 0
    error('Cannot create README.txt in %s', out_dir);
end
cleanup_fid = onCleanup(@() fclose(fid));
fprintf(fid, '=== Phase A SC Summary Figures ===\n\n');
fprintf(fid, 'RUN COMMAND\n');
fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/singlecarrier/run_phaseA_sc_summary_figures.m'');\n\n');
fprintf(fid, 'SCOPE\n');
fprintf(fid, '  This script does not run Monte Carlo simulation.\n');
fprintf(fid, '  It overlays local recheck mean/CI on older full-p global trend data.\n');
fprintf(fid, '  Use these figures for stage-document explanation, not as statistically uniform final paper curves.\n\n');
fprintf(fid, 'INPUTS\n');
fprintf(fid, '  %s\n', code_global_file);
fprintf(fid, '  %s\n', full_global_file);
fprintf(fid, '  %s\n', code_recheck_file);
fprintf(fid, '  %s\n\n', full_recheck_file);
fprintf(fid, 'OUTPUTS\n');
fprintf(fid, '  codeonly_recheck_summary.csv\n');
fprintf(fid, '  fullchain_recheck_summary.csv\n');
fprintf(fid, '  figures/phaseA_codeonly_global_with_recheck.*\n');
fprintf(fid, '  figures/phaseA_fullchain_ber_global_with_recheck.*\n');
fprintf(fid, '  figures/phaseA_fullchain_goodput_global_with_recheck.*\n');
fprintf(fid, '  figures/phaseA_summary_overlay_panel.*\n');
clear cleanup_fid;

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function T = local_summarize_metric(T_in, metric_name)
    p_values = sort(unique(T_in.p), 'descend');
    snr_values = sort(unique(T_in.snr_dB));
    rows = {};
    for ip = 1:numel(p_values)
        for is = 1:numel(snr_values)
            mask = abs(T_in.p - p_values(ip)) < 1e-12 & abs(T_in.snr_dB - snr_values(is)) < 1e-12;
            vals = T_in{mask, metric_name};
            vals = vals(~isnan(vals));
            if isempty(vals)
                continue;
            end
            mu = mean(vals);
            if numel(vals) > 1
                ci95 = 1.96 * std(vals, 0) / sqrt(numel(vals));
            else
                ci95 = nan;
            end
            rows(end + 1, :) = {p_values(ip), snr_values(is), mu, ci95, numel(vals)}; %#ok<AGROW>
        end
    end
    T = cell2table(rows, 'VariableNames', {'p', 'snr_dB', 'mean', 'ci95', 'n'});
end

function vals_out = local_group_mean(T_in, metric_name, p_vec, snr_vec)
    vals_out = nan(numel(p_vec), 1);
    for i = 1:numel(p_vec)
        mask = abs(T_in.p - p_vec(i)) < 1e-12 & abs(T_in.snr_dB - snr_vec(i)) < 1e-12;
        vals = T_in{mask, metric_name};
        vals = vals(~isnan(vals));
        if ~isempty(vals)
            vals_out(i) = mean(vals);
        end
    end
end

function local_plot_codeonly_tile(T_global, T_recheck, colors)
    nexttile;
    hold on; grid on; box on;
    p_values = sort(unique(T_global.p), 'descend').';
    for ip = 1:numel(p_values)
        rows = sortrows(T_global(abs(T_global.p - p_values(ip)) < 1e-12, :), 'snr_dB');
        plot(rows.snr_dB, rows.ber_sim_mean, '-o', 'Color', colors(ip, :), ...
            'LineWidth', 1.0, 'MarkerSize', 3);
    end
    for p = [0.5, 0.4]
        rows = sortrows(T_recheck(abs(T_recheck.p - p) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.mean, rows.ci95, 'ks', ...
            'LineWidth', 1.4, 'MarkerSize', 5, 'MarkerFaceColor', 'w');
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Code-only BER');
end

function local_plot_fullchain_ber_tile(T_global, T_recheck, colors)
    nexttile;
    hold on; grid on; box on;
    p_values = sort(unique(T_global.p), 'descend').';
    for ip = 1:numel(p_values)
        rows = sortrows(T_global(abs(T_global.p - p_values(ip)) < 1e-12, :), 'snr_dB');
        semilogy(rows.snr_dB, rows.BER, '-o', 'Color', colors(ip, :), ...
            'LineWidth', 1.0, 'MarkerSize', 3);
    end
    for p = [0.5, 0.1]
        rows = sortrows(T_recheck(abs(T_recheck.p - p) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.BER_mean, rows.BER_ci95, 'ks', ...
            'LineWidth', 1.4, 'MarkerSize', 5, 'MarkerFaceColor', 'w');
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Full-chain BER');
end

function local_plot_fullchain_goodput_tile(T_global, T_recheck, colors)
    nexttile;
    hold on; grid on; box on;
    p_values = sort(unique(T_global.p), 'descend').';
    for ip = 1:numel(p_values)
        rows = sortrows(T_global(abs(T_global.p - p_values(ip)) < 1e-12, :), 'snr_dB');
        plot(rows.snr_dB, rows.Goodput, '-o', 'Color', colors(ip, :), ...
            'LineWidth', 1.0, 'MarkerSize', 3);
    end
    for p = [0.5, 0.1]
        rows = sortrows(T_recheck(abs(T_recheck.p - p) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.Goodput_mean, rows.Goodput_ci95, 'ks', ...
            'LineWidth', 1.4, 'MarkerSize', 5, 'MarkerFaceColor', 'w');
    end
    xlabel('SNR (dB)');
    ylabel('Goodput');
    title('Full-chain Goodput');
end
