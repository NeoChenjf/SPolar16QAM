%% RUN_PHASEA_SC_MECHANISM_FIGURES
% 从阶段 A final global CSV 重绘机制分解图。
%
% 本脚本不运行 Monte Carlo，只读取已有统一口径结果并生成 p=0.5/0.3/0.1 三线图：
%   1. geometry-only BER；
%   2. code-only SC BER theory-only；
%   3. code-only SC BER simulation-only；
%   4. full-chain SC BER simulation-only；
%   5. full-chain SC Goodput simulation-only；
%   6. full-chain Goodput-Energy view。

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg = config();

%% ===== 输入与输出 =====
source_dir = fullfile(cfg.output_dir, '20260521_150555_phaseA_sc_final_global_curves');
source_code_csv = fullfile(source_dir, 'codeonly_final_summary.csv');
source_full_csv = fullfile(source_dir, 'fullchain_final_summary.csv');

if ~exist(source_code_csv, 'file')
    error('Missing source file: %s', source_code_csv);
end
if ~exist(source_full_csv, 'file')
    error('Missing source file: %s', source_full_csv);
end

out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_phaseA_sc_mechanism_figures']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

diary(fullfile(out_dir, 'run_log.txt'));
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Phase A SC Mechanism Figures ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('Source final global: %s\n', source_dir);

%% ===== 读取已有统一口径结果 =====
T_code = readtable(source_code_csv);
T_full = readtable(source_full_csv);

p_keep = [0.5, 0.3, 0.1];
T_code = T_code(ismembertol(T_code.p, p_keep, 1e-12), :);
T_full = T_full(ismembertol(T_full.p, p_keep, 1e-12), :);

p_list = p_keep;
code_snr_grid = sort(unique(T_code.snr_dB)).';
full_snr_grid = sort(unique(T_full.snr_dB)).';

%% ===== 几何-only BER =====
geom_snr_grid = full_snr_grid;
T_geom = local_compute_geometry_only_table(p_list, geom_snr_grid, cfg);
writetable(T_geom, fullfile(out_dir, 'geometry_only_ber.csv'));

%% ===== 保存来源数据副本，便于追溯 =====
copyfile(source_code_csv, fullfile(out_dir, 'codeonly_final_summary_source.csv'));
copyfile(source_full_csv, fullfile(out_dir, 'fullchain_final_summary_source.csv'));
writetable(T_code, fullfile(out_dir, 'codeonly_final_summary_p01305.csv'));
writetable(T_full, fullfile(out_dir, 'fullchain_final_summary_p01305.csv'));

%% ===== 绘图 =====
colors = lines(numel(p_list));
local_plot_geometry_only(fig_dir, T_geom, p_list, colors);
local_plot_codeonly_theory(fig_dir, T_code, p_list, colors);
local_plot_codeonly_sim(fig_dir, T_code, p_list, colors);
local_plot_fullchain_sim(fig_dir, T_full, p_list, colors);
local_plot_fullchain_goodput(fig_dir, T_full, p_list, colors);
local_plot_fullchain_energy(fig_dir, T_full);

save(fullfile(out_dir, 'phaseA_sc_mechanism_figures.mat'), ...
    'cfg', 'source_dir', 'T_code', 'T_full', 'T_geom', ...
    'p_list', 'code_snr_grid', 'full_snr_grid', 'geom_snr_grid');

local_write_readme(out_dir, source_dir, p_list, code_snr_grid, full_snr_grid, geom_snr_grid);

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function T = local_compute_geometry_only_table(p_list, snr_grid, cfg)
    rows = numel(p_list) * numel(snr_grid);
    [P_grid, S_grid] = ndgrid(p_list, snr_grid);
    T = table();
    T.p = P_grid(:);
    T.snr_dB = S_grid(:);
    T.P_inner = nan(rows, 1);
    T.P_middle = nan(rows, 1);
    T.P_outer = nan(rows, 1);
    T.geom_neighbor_factor = nan(rows, 1);
    T.geometry_only_BER = nan(rows, 1);
    T.E_theory = nan(rows, 1);
    T.E_norm = nan(rows, 1);

    for i = 1:rows
        p = T.p(i);
        snr_db = T.snr_dB(i);
        [p_in, p_mid, p_out] = local_radius_probabilities(p);
        neighbor_factor = 2 * p_out + 3 * p_mid + 4 * p_in;
        q_gamma = local_geometry_q(snr_db);
        T.P_inner(i) = p_in;
        T.P_middle(i) = p_mid;
        T.P_outer(i) = p_out;
        T.geom_neighbor_factor(i) = neighbor_factor;
        T.geometry_only_BER(i) = min(0.5, max(1e-12, neighbor_factor * q_gamma));
        T.E_theory(i) = 18 - 16 * p;
        T.E_norm(i) = T.E_theory(i) / cfg.E_baseline;
    end
end

function [p_in, p_mid, p_out] = local_radius_probabilities(p)
    p_in = p^2;
    p_mid = 2 * p * (1 - p);
    p_out = (1 - p)^2;
end

function q_gamma = local_geometry_q(snr_db)
    geom_dmin2 = 0.4;
    geom_es = 1.0;
    snr_lin = 10^(snr_db / 10);
    N0 = geom_es / max(snr_lin, eps);
    q_arg = sqrt(2 * geom_dmin2 / max(N0, eps));
    q_gamma = 0.5 * erfc(q_arg / sqrt(2));
end

function local_plot_geometry_only(fig_dir, T, p_list, colors)
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        rows = sortrows(T(abs(T.p - p_list(ip)) < 1e-12, :), 'snr_dB');
        semilogy(rows.snr_dB, rows.geometry_only_BER, '-o', ...
            'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    xlabel('SNR (dB)');
    ylabel('BER proxy');
    title('Geometry-only 16QAM BER Proxy');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'phaseA_geometry_only_ber_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_geometry_only_ber_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_geometry_only_ber_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_codeonly_theory(fig_dir, T, p_list, colors)
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        rows = sortrows(T(abs(T.p - p_list(ip)) < 1e-12, :), 'snr_dB');
        semilogy(rows.snr_dB, rows.BER_theory, '-o', ...
            'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Code-only SC BER Theory');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'phaseA_codeonly_ber_theory_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_codeonly_ber_theory_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_codeonly_ber_theory_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_codeonly_sim(fig_dir, T, p_list, colors)
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        rows = sortrows(T(abs(T.p - p_list(ip)) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.BER_mean, rows.BER_ci95, '-o', ...
            'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Code-only SC BER Simulation');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'phaseA_codeonly_ber_sim_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_codeonly_ber_sim_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_codeonly_ber_sim_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_fullchain_sim(fig_dir, T, p_list, colors)
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        rows = sortrows(T(abs(T.p - p_list(ip)) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.BER_mean, rows.BER_ci95, '-o', ...
            'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Full-chain SC BER Simulation');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'phaseA_fullchain_ber_sim_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_fullchain_ber_sim_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_fullchain_ber_sim_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_write_readme(out_dir, source_dir, p_list, code_snr_grid, full_snr_grid, geom_snr_grid)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, '=== Phase A SC Mechanism Figures ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/singlecarrier/run_phaseA_sc_mechanism_figures.m'');\n\n');
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  Replot mechanism figures from existing final global CSV files.\n');
    fprintf(fid, '  No Monte Carlo simulation is run.\n\n');
    fprintf(fid, 'SOURCE\n');
    fprintf(fid, '  %s\n\n', source_dir);
    fprintf(fid, 'PARAMETERS\n');
    fprintf(fid, '  p_list: %s\n', mat2str(p_list));
    fprintf(fid, '  code_snr_grid: %s\n', mat2str(code_snr_grid));
    fprintf(fid, '  full_snr_grid: %s\n', mat2str(full_snr_grid));
    fprintf(fid, '  geometry_snr_grid: %s\n\n', mat2str(geom_snr_grid));
    fprintf(fid, 'OUTPUTS\n');
    fprintf(fid, '  geometry_only_ber.csv\n');
    fprintf(fid, '  codeonly_final_summary_source.csv\n');
    fprintf(fid, '  fullchain_final_summary_source.csv\n');
    fprintf(fid, '  codeonly_final_summary_p01305.csv\n');
    fprintf(fid, '  fullchain_final_summary_p01305.csv\n');
    fprintf(fid, '  figures/phaseA_geometry_only_ber_vs_snr.*\n');
    fprintf(fid, '  figures/phaseA_codeonly_ber_theory_vs_snr.*\n');
    fprintf(fid, '  figures/phaseA_codeonly_ber_sim_vs_snr.*\n');
    fprintf(fid, '  figures/phaseA_fullchain_ber_sim_vs_snr.*\n');
    fprintf(fid, '  figures/phaseA_fullchain_goodput_sim_vs_snr.*\n');
    fprintf(fid, '  figures/phaseA_fullchain_goodput_energy.*\n');
    fprintf(fid, '\nINTERPRETATION\n');
    fprintf(fid, '  Geometry-only is a 16QAM nearest-neighbor/Q-function proxy, not Monte Carlo.\n');
    fprintf(fid, '  Code-only theory and simulation are separated to avoid mixing model and data in one visual claim.\n');
    fprintf(fid, '  Display p values are restricted to p=[0.5 0.3 0.1] for paper-facing figures.\n');
end

function local_plot_fullchain_goodput(fig_dir, T, p_list, colors)
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        rows = sortrows(T(abs(T.p - p_list(ip)) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.Goodput_mean, rows.Goodput_ci95, '-o', ...
            'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    xlabel('SNR (dB)');
    ylabel('Goodput');
    title('Full-chain SC Goodput Simulation');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'phaseA_fullchain_goodput_sim_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_fullchain_goodput_sim_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_fullchain_goodput_sim_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_fullchain_energy(fig_dir, T)
    snr_values = sort(unique(T.snr_dB));
    colors = lines(numel(snr_values));
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for is = 1:numel(snr_values)
        rows = sortrows(T(abs(T.snr_dB - snr_values(is)) < 1e-12, :), 'E_norm');
        plot(rows.E_norm, rows.Goodput_mean, '-o', ...
            'Color', colors(is, :), 'LineWidth', 1.2, 'MarkerSize', 4, ...
            'DisplayName', sprintf('SNR=%g dB', snr_values(is)));
    end
    xlabel('Normalized energy E/E_0');
    ylabel('Goodput');
    title('Full-chain Goodput-Energy View');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'phaseA_fullchain_goodput_energy.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_fullchain_goodput_energy.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'phaseA_fullchain_goodput_energy.pdf'), 'ContentType', 'vector');
    close(fig);
end
