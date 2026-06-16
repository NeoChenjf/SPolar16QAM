%% RUN_FIND_WATERFALL_AND_REFINE
% 自动寻找 SC code-only 链路的有效瀑布区，并在该区间做局部加密复验。
%
% 口径保持与 run_sc_theory_vs_sim.m 一致：
%   Theory: estimate_ber_hat_sc_dual(..., disable_geom=true)
%   Sim:    polar_encoder + BPSK-AWGN + SC_decoder

clear; clc; close all;
script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();
cfg = config();

%% ===== 参数配置 =====
run_local_refine = true;  % 默认只做快速粗扫定位；确认窗口后再改为 true 做局部加密。
p_list = 0.5;              % 粗扫只扫基线，避免重复定位阶段过长。
local_p_list = [0.5,0.4,0.3,0.2,0.1];  % 窗口确认后，在同一瀑布区扩展全 p 局部复验。
target_ber_low = 1e-4;
target_ber_high = 1e-1;
target_ber_mid = sqrt(target_ber_low * target_ber_high);

coarse_snr_grid = -8:2:10;
coarse_num_frames_min = 50;
coarse_num_frames_max = 200;
coarse_min_total_bit_errors = 20;

local_half_width_db = 1.0;
local_step_db = 0.25;
local_n_rep = 2;
local_num_frames_min = 300;
local_num_frames_max = 1200;
local_min_total_bit_errors = 120;

cfg.decoder = 'SC';
cfg.seed = 20260520;
rng(cfg.seed, 'twister');

opts = struct();
opts.disable_geom = true;
opts.pe_floor = 1e-12;
opts.alpha_rel = 1.0;
opts.code_high_eta = 0.8;
opts.code_high_mid_db = 14.0;
opts.code_high_slope_db = 2.0;

N = cfg.N;
nP = numel(p_list);
nC = numel(coarse_snr_grid);
aux = local_make_polar_aux(N);

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_sc_waterfall_refine']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
log_file = fullfile(out_dir, 'run_log.txt');
diary(log_file);
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== SC Waterfall Finder ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('Target BER window: [%.1e, %.1e]\n', target_ber_low, target_ber_high);
fprintf('Coarse p_list: %s\n', mat2str(p_list));
fprintf('Local p_list: %s\n', mat2str(local_p_list));

%% ===== 粗扫：寻找有效瀑布区 =====
fprintf('\n========== COARSE SCAN ==========\n');
ber_theory_coarse = local_compute_theory(p_list, coarse_snr_grid, cfg, opts);
ber_sim_coarse = nan(nP, nC);
frames_coarse = nan(nP, nC);
errors_coarse = nan(nP, nC);

for ip = 1:nP
    p = p_list(ip);
    fprintf('\nCoarse p=%.2f\n', p);
    for is = 1:nC
        snr_db = coarse_snr_grid(is);
        local_append_progress(out_dir, sprintf('START coarse p=%.2f SNR=%+.2f dB', p, snr_db));
        [ber_sim_coarse(ip, is), frames_coarse(ip, is), errors_coarse(ip, is)] = ...
            local_sim_sc_point(p, snr_db, cfg, aux, coarse_num_frames_min, ...
            coarse_num_frames_max, coarse_min_total_bit_errors);
        fprintf('  SNR=%+5.2f dB | BER_sim=%.3e | BER_theory=%.3e | frames=%d | errors=%d\n', ...
            snr_db, ber_sim_coarse(ip, is), ber_theory_coarse(ip, is), ...
            frames_coarse(ip, is), errors_coarse(ip, is));
        local_write_scan_table(fullfile(out_dir, 'coarse_scan_partial.csv'), p_list, coarse_snr_grid, ...
            ber_sim_coarse, ber_theory_coarse, frames_coarse, errors_coarse, target_ber_low, target_ber_high);
        local_append_progress(out_dir, sprintf('DONE coarse p=%.2f SNR=%+.2f dB BER=%.3e frames=%d errors=%d', ...
            p, snr_db, ber_sim_coarse(ip, is), frames_coarse(ip, is), errors_coarse(ip, is)));
    end
end

[P_grid_c, S_grid_c] = ndgrid(p_list, coarse_snr_grid);
T_coarse = table();
T_coarse.p = P_grid_c(:);
T_coarse.snr_dB = S_grid_c(:);
T_coarse.ber_sim = ber_sim_coarse(:);
T_coarse.ber_theory = ber_theory_coarse(:);
T_coarse.in_target_window = T_coarse.ber_sim >= target_ber_low & T_coarse.ber_sim <= target_ber_high;
T_coarse.frames = frames_coarse(:);
T_coarse.errors = errors_coarse(:);
writetable(T_coarse, fullfile(out_dir, 'coarse_scan.csv'));

%% ===== 自动选择局部加密窗口 =====
mask_target = ber_sim_coarse >= target_ber_low & ber_sim_coarse <= target_ber_high;
idx_ref = find(abs(p_list - 0.5) < 1e-12, 1);
if isempty(idx_ref)
    error('p_list must include p=0.5 as baseline.');
end

if any(mask_target(idx_ref, :))
    selected_snr_values = coarse_snr_grid(mask_target(idx_ref, :));
    selection_reason = 'p=0.5 baseline has BER inside target window';
elseif any(mask_target(:))
    selected_snr_values = S_grid_c(mask_target);
    selection_reason = 'non-baseline p values have BER inside target window';
else
    positive_mask = ber_sim_coarse > 0;
    if any(positive_mask(:))
        log_gap = abs(log10(max(ber_sim_coarse, realmin)) - log10(target_ber_mid));
        log_gap(~positive_mask) = inf;
        [~, idx_best] = min(log_gap(:));
        selected_snr_values = S_grid_c(idx_best);
        selection_reason = 'no point inside target; selected nearest positive BER to log-mid target';
    else
        selected_snr_values = min(coarse_snr_grid);
        selection_reason = 'all coarse points are zero BER; selected lowest coarse SNR';
    end
end

waterfall_center = median(selected_snr_values);
waterfall_start = waterfall_center - local_half_width_db;
waterfall_end = waterfall_center + local_half_width_db;
local_snr_grid = waterfall_start:local_step_db:waterfall_end;
nL = numel(local_snr_grid);

T_window = table();
T_window.target_ber_low = target_ber_low;
T_window.target_ber_high = target_ber_high;
T_window.waterfall_center_dB = waterfall_center;
T_window.waterfall_start_dB = waterfall_start;
T_window.waterfall_end_dB = waterfall_end;
T_window.local_step_dB = local_step_db;
T_window.selection_reason = {selection_reason};
writetable(T_window, fullfile(out_dir, 'waterfall_window.csv'));

fprintf('\nSelected waterfall window: %.2f:%.2f:%.2f dB (%s)\n', ...
    waterfall_start, local_step_db, waterfall_end, selection_reason);

if ~run_local_refine
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    fprintf(fid, '=== SC Waterfall Finder: Coarse Stage Only ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  run_find_waterfall_and_refine;\n\n');
    fprintf(fid, 'MODE\n');
    fprintf(fid, '  run_local_refine: false\n');
    fprintf(fid, '  This run only locates a candidate waterfall window and stops before local refinement.\n\n');
    fprintf(fid, 'TARGET\n');
    fprintf(fid, '  BER window: [%.1e, %.1e]\n', target_ber_low, target_ber_high);
    fprintf(fid, '  Coarse p_list: %s\n', mat2str(p_list));
    fprintf(fid, '  Coarse SNR grid: %s\n', mat2str(coarse_snr_grid));
    fprintf(fid, '  Suggested local grid: %s\n', mat2str(local_snr_grid));
    fprintf(fid, '  Selection reason: %s\n\n', selection_reason);
    fprintf(fid, 'NEXT STEP\n');
    fprintf(fid, '  If the selected window is reasonable, set run_local_refine=true and rerun.\n');
    fprintf(fid, '  If all BER values are zero, lower coarse_snr_grid and rerun coarse mode.\n\n');
    fprintf(fid, 'OUTPUT FILES\n');
    fprintf(fid, '  run_log.txt\n');
    fprintf(fid, '  progress_log.txt\n');
    fprintf(fid, '  coarse_scan.csv\n');
    fprintf(fid, '  coarse_scan_partial.csv\n');
    fprintf(fid, '  waterfall_window.csv\n');
    fclose(fid);
    
    fprintf('\n========== COARSE MODE DONE ==========\n');
    fprintf('Suggested local grid: %s\n', mat2str(local_snr_grid));
    fprintf('Set run_local_refine=true after checking waterfall_window.csv.\n');
    fprintf('Saved to: %s\n', out_dir);
    return;
end

%% ===== 局部加密复验 =====
fprintf('\n========== LOCAL REFINED SCAN ==========\n');
nP_local = numel(local_p_list);
ber_theory_local = local_compute_theory(local_p_list, local_snr_grid, cfg, opts);
ber_sim_local_all = nan(local_n_rep, nP_local, nL);
frames_local_all = nan(local_n_rep, nP_local, nL);
errors_local_all = nan(local_n_rep, nP_local, nL);

for rep = 1:local_n_rep
    rng(cfg.seed + 1000 * rep, 'twister');
    fprintf('\n--- Local repetition %d/%d ---\n', rep, local_n_rep);
    for ip = 1:nP_local
        p = local_p_list(ip);
        fprintf('\nLocal p=%.2f\n', p);
        for is = 1:nL
            snr_db = local_snr_grid(is);
            local_append_progress(out_dir, sprintf('START local rep=%d p=%.2f SNR=%+.2f dB', rep, p, snr_db));
            [ber_sim_local_all(rep, ip, is), frames_local_all(rep, ip, is), errors_local_all(rep, ip, is)] = ...
                local_sim_sc_point(p, snr_db, cfg, aux, local_num_frames_min, ...
                local_num_frames_max, local_min_total_bit_errors);
            fprintf('  SNR=%+5.2f dB | BER_sim=%.3e | BER_theory=%.3e | frames=%d | errors=%d\n', ...
                snr_db, ber_sim_local_all(rep, ip, is), ber_theory_local(ip, is), ...
                frames_local_all(rep, ip, is), errors_local_all(rep, ip, is));
            local_write_repetition_table(fullfile(out_dir, 'local_waterfall_repetitions_partial.csv'), ...
                1:local_n_rep, local_p_list, local_snr_grid, ber_sim_local_all, frames_local_all, errors_local_all);
            local_append_progress(out_dir, sprintf('DONE local rep=%d p=%.2f SNR=%+.2f dB BER=%.3e frames=%d errors=%d', ...
                rep, p, snr_db, ber_sim_local_all(rep, ip, is), frames_local_all(rep, ip, is), errors_local_all(rep, ip, is)));
        end
    end
end

ber_sim_local_mean = zeros(nP_local, nL);
ber_sim_local_std = zeros(nP_local, nL);
for ip = 1:nP_local
    for is = 1:nL
        vals = ber_sim_local_all(:, ip, is);
        vals = vals(~isnan(vals));
        if isempty(vals)
            ber_sim_local_mean(ip, is) = nan;
            ber_sim_local_std(ip, is) = nan;
        else
            ber_sim_local_mean(ip, is) = mean(vals);
            ber_sim_local_std(ip, is) = std(vals, 0);
        end
    end
end
ci95_local = 1.96 .* ber_sim_local_std ./ sqrt(local_n_rep);
frames_local = squeeze(sum(frames_local_all, 1));
errors_local = squeeze(sum(errors_local_all, 1));

[P_grid_l, S_grid_l] = ndgrid(local_p_list, local_snr_grid);
rows_l = nP_local * nL;
T_local = table();
T_local.p = P_grid_l(:);
T_local.snr_dB = S_grid_l(:);
T_local.ber_sim_mean = reshape(ber_sim_local_mean, rows_l, 1);
T_local.ber_sim_std = reshape(ber_sim_local_std, rows_l, 1);
T_local.ber_sim_ci95 = reshape(ci95_local, rows_l, 1);
T_local.ber_theory = reshape(ber_theory_local, rows_l, 1);
T_local.gap = T_local.ber_sim_mean - T_local.ber_theory;
T_local.in_target_window = T_local.ber_sim_mean >= target_ber_low & T_local.ber_sim_mean <= target_ber_high;
T_local.frames = reshape(frames_local, rows_l, 1);
T_local.errors = reshape(errors_local, rows_l, 1);
writetable(T_local, fullfile(out_dir, 'local_waterfall_curve.csv'));

[Rep_g, P_rep_g, S_rep_g] = ndgrid(1:local_n_rep, local_p_list, local_snr_grid);
T_rep = table();
T_rep.rep_idx = Rep_g(:);
T_rep.p = P_rep_g(:);
T_rep.snr_dB = S_rep_g(:);
T_rep.ber_sim = ber_sim_local_all(:);
T_rep.frames = frames_local_all(:);
T_rep.errors = errors_local_all(:);
writetable(T_rep, fullfile(out_dir, 'local_waterfall_repetitions.csv'));

%% ===== 局部摘要 =====
summary_rows = cell(nP_local, 1);
selected_summary_snr = zeros(nP_local, 1);
for ip = 1:nP_local
    in_win = ber_sim_local_mean(ip, :) >= target_ber_low & ber_sim_local_mean(ip, :) <= target_ber_high;
    if any(in_win)
        candidate_idx = find(in_win);
        [~, local_idx] = min(abs(log10(ber_sim_local_mean(ip, candidate_idx)) - log10(target_ber_mid)));
        idx_pick = candidate_idx(local_idx);
        summary_rows{ip} = 'inside_target_window';
    else
        positive_idx = find(ber_sim_local_mean(ip, :) > 0);
        if isempty(positive_idx)
            idx_pick = 1;
            summary_rows{ip} = 'all_zero_move_window_lower';
        else
            [~, local_idx] = min(abs(log10(ber_sim_local_mean(ip, positive_idx)) - log10(target_ber_mid)));
            idx_pick = positive_idx(local_idx);
            summary_rows{ip} = 'nearest_positive_ber_to_target';
        end
    end
    selected_summary_snr(ip) = local_snr_grid(idx_pick);
end

T_summary = table();
T_summary.p = local_p_list(:);
T_summary.selected_snr_dB = selected_summary_snr;
T_summary.ber_sim_mean = zeros(nP_local, 1);
T_summary.ber_sim_ci95 = zeros(nP_local, 1);
T_summary.ber_theory = zeros(nP_local, 1);
T_summary.gap = zeros(nP_local, 1);
T_summary.conclusion = summary_rows;
for ip = 1:nP_local
    idx_pick = find(abs(local_snr_grid - selected_summary_snr(ip)) < 1e-12, 1);
    T_summary.ber_sim_mean(ip) = ber_sim_local_mean(ip, idx_pick);
    T_summary.ber_sim_ci95(ip) = ci95_local(ip, idx_pick);
    T_summary.ber_theory(ip) = ber_theory_local(ip, idx_pick);
    T_summary.gap(ip) = T_summary.ber_sim_mean(ip) - T_summary.ber_theory(ip);
end
writetable(T_summary, fullfile(out_dir, 'local_waterfall_summary.csv'));

%% ===== 绘图 =====
colors_coarse = lines(nP);
colors_local = lines(nP_local);

fig1 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:nP
    semilogy(coarse_snr_grid, ber_sim_coarse(ip, :), '-o', 'Color', colors_coarse(ip, :), ...
        'LineWidth', 1.4, 'MarkerSize', 5, 'DisplayName', sprintf('Sim p=%.1f', p_list(ip)));
    semilogy(coarse_snr_grid, ber_theory_coarse(ip, :), '--', 'Color', colors_coarse(ip, :), ...
        'LineWidth', 1.0, 'DisplayName', sprintf('Theory p=%.1f', p_list(ip)));
end
yline(target_ber_low, 'k:', 'BER=1e-4');
yline(target_ber_high, 'k:', 'BER=1e-1');
xline(waterfall_start, 'k--', 'Start');
xline(waterfall_end, 'k--', 'End');
xlabel('SNR (dB)');
ylabel('BER');
title('Coarse Scan for SC Waterfall Region');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig1, fullfile(fig_dir, 'coarse_waterfall_scan.fig'));
exportgraphics(fig1, fullfile(fig_dir, 'coarse_waterfall_scan.png'), 'Resolution', 300);
exportgraphics(fig1, fullfile(fig_dir, 'coarse_waterfall_scan.pdf'), 'ContentType', 'vector');
close(fig1);

fig2 = figure('Color', 'w', 'Position', [80 80 980 620]);
hold on; grid on; box on;
for ip = 1:nP_local
    errorbar(local_snr_grid, ber_sim_local_mean(ip, :), ci95_local(ip, :), '-o', ...
        'Color', colors_local(ip, :), 'LineWidth', 1.6, 'MarkerSize', 5, ...
        'DisplayName', sprintf('Sim mean +/-95%%CI p=%.1f', local_p_list(ip)));
    semilogy(local_snr_grid, ber_theory_local(ip, :), '--', 'Color', colors_local(ip, :), ...
        'LineWidth', 1.2, 'DisplayName', sprintf('Theory p=%.1f', local_p_list(ip)));
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

%% ===== README =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
if fid < 0
    error('Cannot create README.txt in %s', out_dir);
end
fprintf(fid, '=== SC Waterfall Finder and Local Refinement ===\n\n');
fprintf(fid, 'RUN COMMAND\n');
fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run_find_waterfall_and_refine;\n\n');
fprintf(fid, 'SCOPE\n');
fprintf(fid, '  Same code-only口径 as run_sc_theory_vs_sim.m.\n');
fprintf(fid, '  Theory: estimate_ber_hat_sc_dual(..., disable_geom=true).\n');
fprintf(fid, '  Simulation: polar_encoder + BPSK-AWGN + SC_decoder.\n\n');
fprintf(fid, 'TARGET\n');
fprintf(fid, '  BER window: [%.1e, %.1e]\n', target_ber_low, target_ber_high);
fprintf(fid, '  Coarse p_list: %s\n', mat2str(p_list));
fprintf(fid, '  Local p_list: %s\n', mat2str(local_p_list));
fprintf(fid, '  Coarse SNR grid: %s\n', mat2str(coarse_snr_grid));
fprintf(fid, '  Selected local grid: %s\n', mat2str(local_snr_grid));
fprintf(fid, '  Selection reason: %s\n\n', selection_reason);
fprintf(fid, 'LOCAL SUMMARY\n');
fprintf(fid, '  %-6s %-10s %-14s %-14s %-14s %-14s %s\n', ...
    'p', 'snr_dB', 'ber_sim_mean', 'ci95', 'ber_theory', 'gap', 'conclusion');
for ip = 1:nP_local
    fprintf(fid, '  %-6.2f %-10.2f %-14.6e %-14.6e %-14.6e %-14.6e %s\n', ...
        T_summary.p(ip), T_summary.selected_snr_dB(ip), T_summary.ber_sim_mean(ip), ...
        T_summary.ber_sim_ci95(ip), T_summary.ber_theory(ip), T_summary.gap(ip), ...
        T_summary.conclusion{ip});
end
fprintf(fid, '\nOUTPUT FILES\n');
    fprintf(fid, '  run_log.txt\n');
    fprintf(fid, '  progress_log.txt\n');
    fprintf(fid, '  coarse_scan.csv\n');
    fprintf(fid, '  coarse_scan_partial.csv\n');
fprintf(fid, '  waterfall_window.csv\n');
fprintf(fid, '  local_waterfall_curve.csv\n');
fprintf(fid, '  local_waterfall_repetitions.csv\n');
fprintf(fid, '  local_waterfall_summary.csv\n');
fprintf(fid, '  figures/coarse_waterfall_scan.*\n');
fprintf(fid, '  figures/local_waterfall_curve.*\n');
fclose(fid);

fprintf('\n========== DONE ==========\n');
fprintf('Selected local grid: %s\n', mat2str(local_snr_grid));
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

function local_write_scan_table(file_path, p_list, snr_grid, ber_sim, ber_theory, frames, errors, target_low, target_high)
    [P_grid, S_grid] = ndgrid(p_list, snr_grid);
    T = table();
    T.p = P_grid(:);
    T.snr_dB = S_grid(:);
    T.ber_sim = ber_sim(:);
    T.ber_theory = ber_theory(:);
    T.in_target_window = T.ber_sim >= target_low & T.ber_sim <= target_high;
    T.frames = frames(:);
    T.errors = errors(:);
    writetable(T, file_path);
end

function local_write_repetition_table(file_path, rep_list, p_list, snr_grid, ber_sim_all, frames_all, errors_all)
    [Rep_g, P_g, S_g] = ndgrid(rep_list, p_list, snr_grid);
    T = table();
    T.rep_idx = Rep_g(:);
    T.p = P_g(:);
    T.snr_dB = S_g(:);
    T.ber_sim = ber_sim_all(:);
    T.frames = frames_all(:);
    T.errors = errors_all(:);
    writetable(T, file_path);
end

function ber_theory = local_compute_theory(p_list, snr_grid, cfg, opts)
    nP = numel(p_list);
    ber_theory = zeros(nP, numel(snr_grid));
    for ip = 1:nP
        model = estimate_ber_hat_sc_dual(p_list(ip), snr_grid, cfg, opts);
        ber_theory(ip, :) = model.BER_hat;
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
