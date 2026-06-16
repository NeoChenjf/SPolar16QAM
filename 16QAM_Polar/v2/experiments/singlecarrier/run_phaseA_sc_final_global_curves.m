%% RUN_PHASEA_SC_FINAL_GLOBAL_CURVES
% 生成阶段 A 单载波 SC 统一统计口径 final global curve。
%
% 本脚本会运行较长 Monte Carlo：
%   - code-only: full p x dense SNR x repetitions；
%   - full-chain: full p x SNR x seeds。
%
% 用途：
%   生成论文级“统一口径”全局曲线，避免混合旧轻量点和局部复验点。

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg_base = config();

%% ===== 固定 final global 口径 =====
cfg_local = cfg_base;
cfg_local.decoder = 'SC';
cfg_local.snr_mode = 'fixed_esn0';

code_p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
code_snr_grid = 1:0.25:3.25;
code_n_rep = 5;
code_num_frames_min = 300;
code_num_frames_max = 2000;
code_min_total_bit_errors = 200;
code_seed_base = 20260521;

full_p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
full_snr_grid = 8:1:20;
full_seeds = [42, 43, 44];
full_num_frames = 300;

opts = struct();
opts.disable_geom = true;
opts.pe_floor = 1e-12;
opts.alpha_rel = 1.0;
opts.code_high_eta = 0.8;
opts.code_high_mid_db = 14.0;
opts.code_high_slope_db = 2.0;

aux = local_make_polar_aux(cfg_local.N);

%% ===== 输出目录 =====
out_dir = fullfile(cfg_local.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_phaseA_sc_final_global_curves']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

log_file = fullfile(out_dir, 'run_log.txt');
diary(log_file);
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Phase A SC Final Global Curves ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('Code-only p_list: %s\n', mat2str(code_p_list));
fprintf('Code-only snr_grid: %s\n', mat2str(code_snr_grid));
fprintf('Code-only n_rep: %d\n', code_n_rep);
fprintf('Full-chain p_list: %s\n', mat2str(full_p_list));
fprintf('Full-chain snr_grid: %s\n', mat2str(full_snr_grid));
fprintf('Full-chain seeds: %s\n', mat2str(full_seeds));
fprintf('Full-chain num_frames: %d\n', full_num_frames);

%% ===== code-only final global =====
nCodeP = numel(code_p_list);
nCodeS = numel(code_snr_grid);
code_ber = nan(code_n_rep, nCodeP, nCodeS);
code_frames = nan(code_n_rep, nCodeP, nCodeS);
code_errors = nan(code_n_rep, nCodeP, nCodeS);
code_theory = local_compute_theory(code_p_list, code_snr_grid, cfg_local, opts);

fprintf('\n========== CODE-ONLY FINAL GLOBAL ==========\n');
for rep = 1:code_n_rep
    rng(code_seed_base + 1000 * rep, 'twister');
    fprintf('\n--- Code-only repetition %d/%d ---\n', rep, code_n_rep);
    for ip = 1:nCodeP
        p = code_p_list(ip);
        fprintf('\nCode-only p=%.2f\n', p);
        for is = 1:nCodeS
            snr_db = code_snr_grid(is);
            local_append_progress(out_dir, sprintf('START code-only rep=%d p=%.2f SNR=%+.2f dB', rep, p, snr_db));
            [code_ber(rep, ip, is), code_frames(rep, ip, is), code_errors(rep, ip, is)] = ...
                local_sim_sc_point(p, snr_db, cfg_local, aux, code_num_frames_min, ...
                code_num_frames_max, code_min_total_bit_errors);
            fprintf('  SNR=%+5.2f dB | BER=%.3e | Theory=%.3e | frames=%d | errors=%d\n', ...
                snr_db, code_ber(rep, ip, is), code_theory(ip, is), ...
                code_frames(rep, ip, is), code_errors(rep, ip, is));
            local_write_codeonly_repetitions(fullfile(out_dir, 'codeonly_final_repetitions_partial.csv'), ...
                code_p_list, code_snr_grid, code_ber, code_frames, code_errors, code_theory);
            local_append_progress(out_dir, sprintf('DONE code-only rep=%d p=%.2f SNR=%+.2f dB', rep, p, snr_db));
        end
    end
end
T_code_rep = local_write_codeonly_repetitions(fullfile(out_dir, 'codeonly_final_repetitions.csv'), ...
    code_p_list, code_snr_grid, code_ber, code_frames, code_errors, code_theory);
T_code_summary = local_summarize_codeonly(T_code_rep);
writetable(T_code_summary, fullfile(out_dir, 'codeonly_final_summary.csv'));

%% ===== full-chain final global =====
nFullP = numel(full_p_list);
nFullS = numel(full_snr_grid);
nSeeds = numel(full_seeds);

full_ber = nan(nSeeds, nFullP, nFullS);
full_goodput = nan(nSeeds, nFullP, nFullS);
full_mi = nan(nSeeds, nFullP, nFullS);
full_errors = nan(nSeeds, nFullP, nFullS);
full_frames = nan(nSeeds, nFullP, nFullS);
full_r_total = nan(nSeeds, nFullP);
full_e_theory = nan(nSeeds, nFullP);
full_e_norm = nan(nSeeds, nFullP);

fprintf('\n========== FULL-CHAIN FINAL GLOBAL ==========\n');
for iseed = 1:nSeeds
    seed = full_seeds(iseed);
    for ip = 1:nFullP
        p = full_p_list(ip);
        cfg_run = cfg_local;
        cfg_run.seed = seed;
        cfg_run.num_frames = full_num_frames;
        cfg_run.p_candidates = full_p_list;
        cfg_run.SNR_dB = full_snr_grid;

        fprintf('\n--- Full-chain seed=%d p=%.2f ---\n', seed, p);
        local_append_progress(out_dir, sprintf('START full-chain seed=%d p=%.2f', seed, p));
        result = sim_shaped_polar_16qam(p, full_snr_grid, cfg_run);
        G = compute_goodput(result);

        full_ber(iseed, ip, :) = reshape(result.BER, [1, 1, nFullS]);
        full_goodput(iseed, ip, :) = reshape(G, [1, 1, nFullS]);
        full_mi(iseed, ip, :) = reshape(result.MI_total, [1, 1, nFullS]);
        full_r_total(iseed, ip) = result.R_total;
        full_e_theory(iseed, ip) = result.E_theory;
        full_e_norm(iseed, ip) = result.E_theory / cfg_run.E_baseline;
        for is = 1:nFullS
            full_frames(iseed, ip, is) = full_num_frames;
            full_errors(iseed, ip, is) = local_fullchain_errors(result, is, full_num_frames);
        end

        local_write_fullchain_repetitions(fullfile(out_dir, 'fullchain_final_repetitions_partial.csv'), ...
            full_p_list, full_snr_grid, full_seeds, full_ber, full_goodput, full_mi, ...
            full_frames, full_errors, full_r_total, full_e_theory, full_e_norm);
        local_append_progress(out_dir, sprintf('DONE full-chain seed=%d p=%.2f', seed, p));
    end
end
T_full_rep = local_write_fullchain_repetitions(fullfile(out_dir, 'fullchain_final_repetitions.csv'), ...
    full_p_list, full_snr_grid, full_seeds, full_ber, full_goodput, full_mi, ...
    full_frames, full_errors, full_r_total, full_e_theory, full_e_norm);
T_full_summary = local_summarize_fullchain(T_full_rep);
writetable(T_full_summary, fullfile(out_dir, 'fullchain_final_summary.csv'));

%% ===== 绘图 =====
local_plot_codeonly(fig_dir, T_code_summary, code_p_list);
local_plot_fullchain_ber(fig_dir, T_full_summary, full_p_list);
local_plot_fullchain_goodput(fig_dir, T_full_summary, full_p_list);
local_plot_fullchain_energy(fig_dir, T_full_summary, full_p_list);

save(fullfile(out_dir, 'phaseA_sc_final_global_curves.mat'), ...
    'cfg_local', 'code_p_list', 'code_snr_grid', 'code_n_rep', ...
    'full_p_list', 'full_snr_grid', 'full_seeds', 'full_num_frames', ...
    'T_code_summary', 'T_full_summary');

local_write_readme(out_dir, code_p_list, code_snr_grid, code_n_rep, ...
    code_num_frames_min, code_num_frames_max, code_min_total_bit_errors, ...
    full_p_list, full_snr_grid, full_seeds, full_num_frames);

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function aux = local_make_polar_aux(N)
    aux.N = N;
    aux.lambda_offset = 2.^(0:log2(N));
    aux.llr_layer_vec = get_llr_layer(N);
    aux.bit_layer_vec = get_bit_layer(N);
end

function local_append_progress(out_dir, msg)
    fid = fopen(fullfile(out_dir, 'progress_log.txt'), 'a');
    if fid < 0
        warning('Cannot write progress_log.txt in %s', out_dir);
        return;
    end
    fprintf(fid, '[%s] %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'), msg);
    fclose(fid);
end

function ber_theory = local_compute_theory(p_list, snr_grid, cfg, opts)
    ber_theory = zeros(numel(p_list), numel(snr_grid));
    for ip = 1:numel(p_list)
        model = estimate_ber_hat_sc_dual(p_list(ip), snr_grid, cfg, opts);
        ber_theory(ip, :) = model.BER_hat;
    end
end

function T = local_write_codeonly_repetitions(file_path, p_list, snr_grid, ber_all, frames_all, errors_all, theory)
    nRep = size(ber_all, 1);
    [Rep_g, P_g, S_g] = ndgrid(1:nRep, p_list, snr_grid);
    theory_all = nan(size(ber_all));
    for rep = 1:nRep
        theory_all(rep, :, :) = reshape(theory, [1, size(theory, 1), size(theory, 2)]);
    end
    T = table();
    T.rep_idx = Rep_g(:);
    T.p = P_g(:);
    T.snr_dB = S_g(:);
    T.BER = ber_all(:);
    T.BER_theory = theory_all(:);
    T.gap = T.BER - T.BER_theory;
    T.frames = frames_all(:);
    T.errors = errors_all(:);
    writetable(T, file_path);
end

function T = local_write_fullchain_repetitions(file_path, p_list, snr_grid, seeds, ber_all, goodput_all, mi_all, frames_all, errors_all, r_total_all, e_theory_all, e_norm_all)
    nSeeds = numel(seeds);
    [SeedIdx_g, P_g, S_g] = ndgrid(1:nSeeds, p_list, snr_grid);
    seed_values = seeds(SeedIdx_g(:)).';
    r_total_expanded = nan(size(ber_all));
    e_theory_expanded = nan(size(ber_all));
    e_norm_expanded = nan(size(ber_all));
    for iseed = 1:nSeeds
        for ip = 1:numel(p_list)
            r_total_expanded(iseed, ip, :) = r_total_all(iseed, ip);
            e_theory_expanded(iseed, ip, :) = e_theory_all(iseed, ip);
            e_norm_expanded(iseed, ip, :) = e_norm_all(iseed, ip);
        end
    end
    T = table();
    T.seed = seed_values(:);
    T.p = P_g(:);
    T.snr_dB = S_g(:);
    T.BER = ber_all(:);
    T.Goodput = goodput_all(:);
    T.MI_total = mi_all(:);
    T.R_total = r_total_expanded(:);
    T.E_theory = e_theory_expanded(:);
    T.E_norm = e_norm_expanded(:);
    T.frames = frames_all(:);
    T.errors = errors_all(:);
    writetable(T, file_path);
end

function T = local_summarize_codeonly(T_rep)
    T_base = local_summarize_metric(T_rep, 'BER');
    T = table();
    T.p = T_base.p;
    T.snr_dB = T_base.snr_dB;
    T.BER_mean = T_base.mean;
    T.BER_ci95 = T_base.ci95;
    T.BER_theory = local_group_mean(T_rep, 'BER_theory', T.p, T.snr_dB);
    T.frames = local_group_sum(T_rep, 'frames', T.p, T.snr_dB);
    T.errors = local_group_sum(T_rep, 'errors', T.p, T.snr_dB);
    T.n = T_base.n;
end

function T = local_summarize_fullchain(T_rep)
    T_ber = local_summarize_metric(T_rep, 'BER');
    T_goodput = local_summarize_metric(T_rep, 'Goodput');
    T = table();
    T.p = T_ber.p;
    T.snr_dB = T_ber.snr_dB;
    T.BER_mean = T_ber.mean;
    T.BER_ci95 = T_ber.ci95;
    T.Goodput_mean = T_goodput.mean;
    T.Goodput_ci95 = T_goodput.ci95;
    T.MI_mean = local_group_mean(T_rep, 'MI_total', T.p, T.snr_dB);
    T.R_total = local_group_mean(T_rep, 'R_total', T.p, T.snr_dB);
    T.E_theory = local_group_mean(T_rep, 'E_theory', T.p, T.snr_dB);
    T.E_norm = local_group_mean(T_rep, 'E_norm', T.p, T.snr_dB);
    T.frames = local_group_sum(T_rep, 'frames', T.p, T.snr_dB);
    T.errors = local_group_sum(T_rep, 'errors', T.p, T.snr_dB);
    T.n = T_ber.n;
end

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

function vals_out = local_group_sum(T_in, metric_name, p_vec, snr_vec)
    vals_out = nan(numel(p_vec), 1);
    for i = 1:numel(p_vec)
        mask = abs(T_in.p - p_vec(i)) < 1e-12 & abs(T_in.snr_dB - snr_vec(i)) < 1e-12;
        vals = T_in{mask, metric_name};
        vals = vals(~isnan(vals));
        if ~isempty(vals)
            vals_out(i) = sum(vals);
        end
    end
end

function total_errors = local_fullchain_errors(result, snr_idx, nFrames)
    K_vec = result.K(:);
    ber_per_bit = result.BER_per_bit(:, snr_idx);
    total_errors = sum(ber_per_bit(:) .* K_vec .* nFrames);
    total_errors = round(total_errors);
end

function local_plot_codeonly(fig_dir, T, p_list)
    colors = lines(numel(p_list));
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        rows = sortrows(T(abs(T.p - p_list(ip)) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.BER_mean, rows.BER_ci95, '-o', ...
            'Color', colors(ip, :), 'LineWidth', 1.4, 'MarkerSize', 5, ...
            'DisplayName', sprintf('Sim mean +/- CI p=%.1f', p_list(ip)));
        semilogy(rows.snr_dB, rows.BER_theory, '--', ...
            'Color', colors(ip, :), 'LineWidth', 1.0, ...
            'DisplayName', sprintf('Theory p=%.1f', p_list(ip)));
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Final Code-only SC BER');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'final_codeonly_ber_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'final_codeonly_ber_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'final_codeonly_ber_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_fullchain_ber(fig_dir, T, p_list)
    colors = lines(numel(p_list));
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        rows = sortrows(T(abs(T.p - p_list(ip)) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.BER_mean, rows.BER_ci95, '-o', ...
            'Color', colors(ip, :), 'LineWidth', 1.4, 'MarkerSize', 5, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Final Full-chain SC BER');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'final_fullchain_ber_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'final_fullchain_ber_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'final_fullchain_ber_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_fullchain_goodput(fig_dir, T, p_list)
    colors = lines(numel(p_list));
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        rows = sortrows(T(abs(T.p - p_list(ip)) < 1e-12, :), 'snr_dB');
        errorbar(rows.snr_dB, rows.Goodput_mean, rows.Goodput_ci95, '-o', ...
            'Color', colors(ip, :), 'LineWidth', 1.4, 'MarkerSize', 5, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    xlabel('SNR (dB)');
    ylabel('Goodput');
    title('Final Full-chain SC Goodput');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'final_fullchain_goodput_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'final_fullchain_goodput_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'final_fullchain_goodput_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_fullchain_energy(fig_dir, T, ~)
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
    title('Final Full-chain Goodput-Energy View');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'final_fullchain_goodput_energy.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'final_fullchain_goodput_energy.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'final_fullchain_goodput_energy.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_write_readme(out_dir, code_p_list, code_snr_grid, code_n_rep, code_min_frames, code_max_frames, code_min_errors, full_p_list, full_snr_grid, full_seeds, full_num_frames)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, '=== Phase A SC Final Global Curves ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/singlecarrier/run_phaseA_sc_final_global_curves.m'');\n\n');
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  Unified statistical口径 for final global curves.\n');
    fprintf(fid, '  Long-running Monte Carlo; intended for local user execution.\n\n');
    fprintf(fid, 'CODE-ONLY\n');
    fprintf(fid, '  p_list: %s\n', mat2str(code_p_list));
    fprintf(fid, '  snr_grid: %s\n', mat2str(code_snr_grid));
    fprintf(fid, '  n_rep: %d\n', code_n_rep);
    fprintf(fid, '  frames_min/max: %d/%d\n', code_min_frames, code_max_frames);
    fprintf(fid, '  min_total_bit_errors: %d\n\n', code_min_errors);
    fprintf(fid, 'FULL-CHAIN\n');
    fprintf(fid, '  p_list: %s\n', mat2str(full_p_list));
    fprintf(fid, '  snr_grid: %s\n', mat2str(full_snr_grid));
    fprintf(fid, '  seeds: %s\n', mat2str(full_seeds));
    fprintf(fid, '  num_frames: %d\n\n', full_num_frames);
    fprintf(fid, 'OUTPUTS\n');
    fprintf(fid, '  codeonly_final_repetitions.csv\n');
    fprintf(fid, '  codeonly_final_summary.csv\n');
    fprintf(fid, '  fullchain_final_repetitions.csv\n');
    fprintf(fid, '  fullchain_final_summary.csv\n');
    fprintf(fid, '  figures/final_codeonly_ber_vs_snr.*\n');
    fprintf(fid, '  figures/final_fullchain_ber_vs_snr.*\n');
    fprintf(fid, '  figures/final_fullchain_goodput_vs_snr.*\n');
    fprintf(fid, '  figures/final_fullchain_goodput_energy.*\n');
    clear cleanup_fid;
end

function [ber_sim, total_frames, total_errors] = local_sim_sc_point(p, snr_db, cfg, aux, num_frames_min, num_frames_max, min_total_bit_errors)
    N = aux.N;
    sigma = 10^(-snr_db / 20);
    channels = GA(sigma, N);
    [~, channels_ordered] = sort(channels, 'descend');

    p_vec_cur = cfg.p_fixed;
    p_vec_cur(isnan(p_vec_cur)) = p;

    K_vec = zeros(1, 4);
    S_vec = zeros(1, 4);
    SI_set = cell(1, 4);
    I_set = cell(1, 4);
    S_set = cell(1, 4);
    frozen_bits_dec = zeros(N, 4);
    shaped_bits = cell(1, 4);

    for b = 1:4
        pb = p_vec_cur(b);
        if pb > 0 && pb < 1
            hb = -pb * log2(pb) - (1 - pb) * log2(1 - pb);
        else
            hb = 0;
        end
        S_vec(b) = ceil(N * (1 - hb));
        K_vec(b) = ceil((N - S_vec(b)) / 2);

        I_pos = channels_ordered(S_vec(b) + 1 : S_vec(b) + K_vec(b));
        S_pos = channels_ordered(1 : S_vec(b));

        I_set{b} = sort(I_pos);
        S_set{b} = sort(S_pos);
        SI_set{b} = sort(channels_ordered(1 : S_vec(b) + K_vec(b)));

        frozen_bits_dec(:, b) = ones(N, 1);
        frozen_bits_dec(SI_set{b}, b) = 0;
        shaped_bits{b} = randi([0, 1], S_vec(b), 1);
    end

    bit_err_acc = zeros(4, 1);
    total_frames = 0;

    while true
        total_frames = total_frames + 1;
        for b = 1:4
            info = randi([0, 1], K_vec(b), 1);
            u = zeros(N, 1);
            u(I_set{b}) = info;
            u(S_set{b}) = shaped_bits{b};

            x = polar_encoder(u);
            tx = 1 - 2 * x;
            y = tx + sigma * randn(N, 1);
            llr = 2 * y / max(sigma^2, eps);

            decoded = SC_decoder(llr, K_vec(b) + S_vec(b), frozen_bits_dec(:, b), ...
                aux.lambda_offset, aux.llr_layer_vec, aux.bit_layer_vec);

            u_hat = zeros(N, 1);
            u_hat(SI_set{b}) = decoded;
            info_hat = u_hat(I_set{b});
            bit_err_acc(b) = bit_err_acc(b) + sum(info_hat ~= info);
        end

        total_errors = sum(bit_err_acc);
        if (total_frames >= num_frames_min && total_errors >= min_total_bit_errors) || ...
                (total_frames >= num_frames_max)
            break;
        end
    end

    ber_per_bit = zeros(4, 1);
    for b = 1:4
        ber_per_bit(b) = bit_err_acc(b) / max(K_vec(b) * total_frames, 1);
    end
    ber_sim = sum(K_vec(:) .* ber_per_bit(:)) / max(sum(K_vec), 1);
    total_errors = sum(bit_err_acc);
end
