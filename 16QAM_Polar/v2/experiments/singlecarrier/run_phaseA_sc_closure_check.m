%% RUN_PHASEA_SC_CLOSURE_CHECK
% 阶段 A 单载波 SC 收尾复验脚本。
%
% 目的：
%   1. 复验 code-only 中 p=0.5 与 p=0.4 在 3 dB 附近的局部反转；
%   2. 复验 full-chain 中 p=0.1 在 10 dB 附近的稀疏曲线异常；
%   3. 生成阶段 A 收尾所需 CSV、图表和 README。
%
% 注意：
%   本脚本会运行较多 Monte Carlo 点，默认由用户本地执行。

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg_base = config();

%% ===== 固定收尾口径 =====
cfg_local = cfg_base;
cfg_local.decoder = 'SC';
cfg_local.snr_mode = 'fixed_esn0';

code_p_list = [0.5, 0.4];
code_snr_grid = [2.75, 3.0, 3.25];
code_n_rep = 5;
code_num_frames_min = 300;
code_num_frames_max = 2000;
code_min_total_bit_errors = 200;
code_seed_base = 20260521;

full_p_list = [0.5, 0.1];
full_snr_grid = 8:1:16;
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
out_dir = fullfile(cfg_local.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_phaseA_sc_closure_check']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

log_file = fullfile(out_dir, 'run_log.txt');
diary(log_file);
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Phase A SC Closure Check ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('Decoder: %s\n', cfg_local.decoder);
fprintf('SNR mode: %s\n', cfg_local.snr_mode);
fprintf('Code-only p_list: %s\n', mat2str(code_p_list));
fprintf('Code-only snr_grid: %s\n', mat2str(code_snr_grid));
fprintf('Code-only n_rep: %d\n', code_n_rep);
fprintf('Full-chain p_list: %s\n', mat2str(full_p_list));
fprintf('Full-chain snr_grid: %s\n', mat2str(full_snr_grid));
fprintf('Full-chain seeds: %s\n', mat2str(full_seeds));
fprintf('Full-chain num_frames: %d\n', full_num_frames);

%% ===== code-only 局部反转复验 =====
fprintf('\n========== CODE-ONLY LOCAL RECHECK ==========\n');
nCodeP = numel(code_p_list);
nCodeS = numel(code_snr_grid);

code_ber = nan(code_n_rep, nCodeP, nCodeS);
code_frames = nan(code_n_rep, nCodeP, nCodeS);
code_errors = nan(code_n_rep, nCodeP, nCodeS);
code_theory = local_compute_theory(code_p_list, code_snr_grid, cfg_local, opts);

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
            local_write_codeonly_table(fullfile(out_dir, 'codeonly_local_recheck_partial.csv'), ...
                code_p_list, code_snr_grid, code_ber, code_frames, code_errors, code_theory);
            local_append_progress(out_dir, sprintf('DONE code-only rep=%d p=%.2f SNR=%+.2f dB BER=%.3e frames=%d errors=%d', ...
                rep, p, snr_db, code_ber(rep, ip, is), code_frames(rep, ip, is), code_errors(rep, ip, is)));
        end
    end
end

T_code = local_write_codeonly_table(fullfile(out_dir, 'codeonly_local_recheck.csv'), ...
    code_p_list, code_snr_grid, code_ber, code_frames, code_errors, code_theory);

%% ===== full-chain 稀疏曲线异常复验 =====
fprintf('\n========== FULL-CHAIN LOCAL RECHECK ==========\n');
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

        local_write_fullchain_table(fullfile(out_dir, 'fullchain_local_recheck_partial.csv'), ...
            full_p_list, full_snr_grid, full_seeds, full_ber, full_goodput, full_mi, ...
            full_frames, full_errors, full_r_total, full_e_theory, full_e_norm);
        local_append_progress(out_dir, sprintf('DONE full-chain seed=%d p=%.2f', seed, p));
    end
end

T_full = local_write_fullchain_table(fullfile(out_dir, 'fullchain_local_recheck.csv'), ...
    full_p_list, full_snr_grid, full_seeds, full_ber, full_goodput, full_mi, ...
    full_frames, full_errors, full_r_total, full_e_theory, full_e_norm);

%% ===== 收尾摘要 =====
T_summary = local_make_summary(T_code, T_full);
writetable(T_summary, fullfile(out_dir, 'phaseA_closure_summary.csv'));

save(fullfile(out_dir, 'phaseA_sc_closure_check.mat'), ...
    'cfg_local', 'code_p_list', 'code_snr_grid', 'code_n_rep', ...
    'code_num_frames_min', 'code_num_frames_max', 'code_min_total_bit_errors', ...
    'full_p_list', 'full_snr_grid', 'full_seeds', 'full_num_frames', ...
    'code_ber', 'code_frames', 'code_errors', 'code_theory', ...
    'full_ber', 'full_goodput', 'full_mi', 'full_errors', 'full_frames', ...
    'full_r_total', 'full_e_theory', 'full_e_norm', 'T_summary');

%% ===== 绘图 =====
local_plot_codeonly(fig_dir, T_code, code_p_list, code_snr_grid);
local_plot_fullchain(fig_dir, T_full, full_p_list, full_snr_grid);

%% ===== README =====
local_write_readme(out_dir, code_p_list, code_snr_grid, code_n_rep, ...
    code_num_frames_min, code_num_frames_max, code_min_total_bit_errors, ...
    full_p_list, full_snr_grid, full_seeds, full_num_frames, T_summary);

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

function T = local_write_codeonly_table(file_path, p_list, snr_grid, ber_all, frames_all, errors_all, theory)
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

function T = local_write_fullchain_table(file_path, p_list, snr_grid, seeds, ber_all, goodput_all, mi_all, frames_all, errors_all, r_total_all, e_theory_all, e_norm_all)
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

function total_errors = local_fullchain_errors(result, snr_idx, nFrames)
    K_vec = result.K(:);
    ber_per_bit = result.BER_per_bit(:, snr_idx);
    total_errors = sum(ber_per_bit(:) .* K_vec .* nFrames);
    total_errors = round(total_errors);
end

function T_summary = local_make_summary(T_code, T_full)
    T_summary = table();

    code_snr3 = T_code(abs(T_code.snr_dB - 3.0) < 1e-12, :);
    code_p05 = code_snr3(abs(code_snr3.p - 0.5) < 1e-12, :);
    code_p04 = code_snr3(abs(code_snr3.p - 0.4) < 1e-12, :);
    code_gap_mean = local_nanmean(code_p05.BER) - local_nanmean(code_p04.BER);
    code_gap_std = local_nanstd(code_p05.BER - code_p04.BER);
    code_gap_ci95 = local_ci95(code_p05.BER - code_p04.BER);
    if isnan(code_gap_ci95)
        code_label = "codeonly_local_reversal_insufficient_rows";
    elseif abs(code_gap_mean) <= code_gap_ci95
        code_label = "codeonly_local_reversal_unstable";
    elseif code_gap_mean > 0
        code_label = "codeonly_p04_better_at_3db_recheck";
    else
        code_label = "codeonly_p05_better_at_3db_recheck";
    end

    full_snr10 = T_full(abs(T_full.snr_dB - 10.0) < 1e-12, :);
    full_p05_10 = full_snr10(abs(full_snr10.p - 0.5) < 1e-12, :);
    full_p01_10 = full_snr10(abs(full_snr10.p - 0.1) < 1e-12, :);
    full_ber_gap_10 = local_nanmean(full_p01_10.BER) - local_nanmean(full_p05_10.BER);

    full_best = local_fullchain_best_summary(T_full);
    if all(full_best.p_best_goodput == 0.5)
        full_label = "fullchain_p05_best_goodput_all_seeds";
    elseif mode(full_best.p_best_goodput) == 0.5
        full_label = "fullchain_p05_best_goodput_majority_seeds";
    else
        full_label = "fullchain_goodput_requires_review";
    end

    T_summary.metric = ["codeonly_gap_p05_minus_p04_at_3db"; "fullchain_gap_p01_minus_p05_at_10db"; "fullchain_goodput_label"];
    T_summary.value = [code_gap_mean; full_ber_gap_10; nan];
    T_summary.ci95 = [code_gap_ci95; nan; nan];
    T_summary.label = [code_label; "fullchain_10db_local_gap_recorded"; full_label];
end

function T_best = local_fullchain_best_summary(T_full)
    seeds = unique(T_full.seed).';
    T_best = table();
    T_best.seed = seeds(:);
    T_best.p_best_goodput = nan(numel(seeds), 1);
    T_best.best_goodput = nan(numel(seeds), 1);
    for i = 1:numel(seeds)
        rows = T_full(T_full.seed == seeds(i), :);
        [best_val, idx] = max(rows.Goodput);
        T_best.p_best_goodput(i) = rows.p(idx);
        T_best.best_goodput(i) = best_val;
    end
end

function local_plot_codeonly(fig_dir, T_code, p_list, snr_grid)
    colors = lines(numel(p_list));
    fig = figure('Color', 'w', 'Position', [80 80 900 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        p = p_list(ip);
        mean_vals = nan(1, numel(snr_grid));
        ci_vals = nan(1, numel(snr_grid));
        theory_vals = nan(1, numel(snr_grid));
        for is = 1:numel(snr_grid)
            rows = T_code(abs(T_code.p - p) < 1e-12 & abs(T_code.snr_dB - snr_grid(is)) < 1e-12, :);
            mean_vals(is) = local_nanmean(rows.BER);
            ci_vals(is) = 1.96 * local_nanstd(rows.BER) / sqrt(height(rows));
            theory_vals(is) = local_nanmean(rows.BER_theory);
        end
        errorbar(snr_grid, mean_vals, ci_vals, '-o', 'Color', colors(ip, :), ...
            'LineWidth', 1.5, 'MarkerSize', 5, 'DisplayName', sprintf('Sim p=%.1f', p));
        semilogy(snr_grid, theory_vals, '--', 'Color', colors(ip, :), ...
            'LineWidth', 1.2, 'DisplayName', sprintf('Theory p=%.1f', p));
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Phase A Code-only Local Recheck');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'codeonly_recheck.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'codeonly_recheck.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'codeonly_recheck.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_fullchain(fig_dir, T_full, p_list, snr_grid)
    colors = lines(numel(p_list));
    fig = figure('Color', 'w', 'Position', [80 80 900 620]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        p = p_list(ip);
        mean_vals = nan(1, numel(snr_grid));
        ci_vals = nan(1, numel(snr_grid));
        for is = 1:numel(snr_grid)
            rows = T_full(abs(T_full.p - p) < 1e-12 & abs(T_full.snr_dB - snr_grid(is)) < 1e-12, :);
            mean_vals(is) = local_nanmean(rows.BER);
            ci_vals(is) = 1.96 * local_nanstd(rows.BER) / sqrt(height(rows));
        end
        errorbar(snr_grid, mean_vals, ci_vals, '-o', 'Color', colors(ip, :), ...
            'LineWidth', 1.5, 'MarkerSize', 5, 'DisplayName', sprintf('BER p=%.1f', p));
    end
    set(gca, 'YScale', 'log');
    xlabel('SNR (dB)');
    ylabel('BER');
    title('Phase A Full-chain Local Recheck');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'fullchain_recheck.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'fullchain_recheck.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'fullchain_recheck.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_write_readme(out_dir, code_p_list, code_snr_grid, code_n_rep, code_min_frames, code_max_frames, code_min_errors, full_p_list, full_snr_grid, full_seeds, full_num_frames, T_summary)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid));

    fprintf(fid, '=== Phase A Single-Carrier SC Closure Check ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/singlecarrier/run_phaseA_sc_closure_check.m'');\n\n');
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  Stage A closes under SC single-carrier口径.\n');
    fprintf(fid, '  No SCL, no rectifier model, no OFDM in this run.\n\n');
    fprintf(fid, 'CODE-ONLY RECHECK\n');
    fprintf(fid, '  Chain: polar_encoder + BPSK-AWGN + SC_decoder.\n');
    fprintf(fid, '  Theory: estimate_ber_hat_sc_dual(..., disable_geom=true).\n');
    fprintf(fid, '  p_list: %s\n', mat2str(code_p_list));
    fprintf(fid, '  snr_grid: %s\n', mat2str(code_snr_grid));
    fprintf(fid, '  n_rep: %d\n', code_n_rep);
    fprintf(fid, '  frames_min/max: %d/%d\n', code_min_frames, code_max_frames);
    fprintf(fid, '  min_total_bit_errors: %d\n\n', code_min_errors);
    fprintf(fid, 'FULL-CHAIN RECHECK\n');
    fprintf(fid, '  Chain: sim_shaped_polar_16qam, decoder=SC, snr_mode=fixed_esn0.\n');
    fprintf(fid, '  p_list: %s\n', mat2str(full_p_list));
    fprintf(fid, '  snr_grid: %s\n', mat2str(full_snr_grid));
    fprintf(fid, '  seeds: %s\n', mat2str(full_seeds));
    fprintf(fid, '  num_frames: %d\n\n', full_num_frames);
    fprintf(fid, 'SUMMARY LABELS\n');
    for i = 1:height(T_summary)
        fprintf(fid, '  %s: value=%.6e, ci95=%.6e, label=%s\n', ...
            char(T_summary.metric(i)), T_summary.value(i), T_summary.ci95(i), char(T_summary.label(i)));
    end
    fprintf(fid, '\nOUTPUT FILES\n');
    fprintf(fid, '  run_log.txt\n');
    fprintf(fid, '  progress_log.txt\n');
    fprintf(fid, '  codeonly_local_recheck.csv\n');
    fprintf(fid, '  fullchain_local_recheck.csv\n');
    fprintf(fid, '  phaseA_closure_summary.csv\n');
    fprintf(fid, '  phaseA_sc_closure_check.mat\n');
    fprintf(fid, '  figures/codeonly_recheck.*\n');
    fprintf(fid, '  figures/fullchain_recheck.*\n');
    clear cleanup_fid;
end

function m = local_nanmean(x)
    x = x(:);
    x = x(~isnan(x));
    if isempty(x)
        m = nan;
    else
        m = mean(x);
    end
end

function s = local_nanstd(x)
    x = x(:);
    x = x(~isnan(x));
    if numel(x) <= 1
        s = 0;
    else
        s = std(x, 0);
    end
end

function ci = local_ci95(x)
    x = x(:);
    x = x(~isnan(x));
    if numel(x) <= 1
        ci = nan;
    else
        ci = 1.96 * std(x, 0) / sqrt(numel(x));
    end
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
