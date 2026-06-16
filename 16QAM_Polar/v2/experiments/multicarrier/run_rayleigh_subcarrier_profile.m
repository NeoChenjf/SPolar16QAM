%% RUN_RAYLEIGH_SUBCARRIER_PROFILE
% Stage B / B2: Rayleigh OFDM subcarrier reliability profile.
%
% Scope:
%   Profile |H_k|^2, effective gamma_k, and MI proxy for Rayleigh OFDM.
%   This script does not run polar decoding or p_k optimization.

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg = config();

%% ===== Config =====
n_subcarriers = 64;
cp_ratio = 1/4;
channel_taps = 16;
num_realizations = 20;
snr_grid = 0:5:20;
seed = 42;
result_tag = 'rayleigh_subcarrier_profile';

rng(seed, 'twister');

out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' result_tag]);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

diary(fullfile(out_dir, 'run_log.txt'));
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Stage B / B2 Rayleigh Subcarrier Profile ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('n_subcarriers: %d\n', n_subcarriers);
fprintf('cp_ratio: %.4f\n', cp_ratio);
fprintf('channel_taps: %d\n', channel_taps);
fprintf('num_realizations: %d\n', num_realizations);
fprintf('snr_grid: %s\n', mat2str(snr_grid));
fprintf('seed: %d\n', seed);

%% ===== Rayleigh channel profile =====
nCp = round(n_subcarriers * cp_ratio);
if channel_taps > nCp
    warning('Channel taps (%d) exceed CP length (%d); profile still generated, but CP may be insufficient for equalized OFDM.', ...
        channel_taps, nCp);
end

nS = numel(snr_grid);
nRows = num_realizations * n_subcarriers * nS;

realization_col = zeros(nRows, 1);
subcarrier_col = zeros(nRows, 1);
snr_col = zeros(nRows, 1);
h_abs2_col = zeros(nRows, 1);
gamma_col = zeros(nRows, 1);
gamma_db_col = zeros(nRows, 1);
mi_proxy_col = zeros(nRows, 1);
rank_col = zeros(nRows, 1);
group_col = strings(nRows, 1);

H_abs2_all = zeros(n_subcarriers, num_realizations);
row_idx = 0;

for ir = 1:num_realizations
    h = local_rayleigh_channel(channel_taps);
    H = fft(h, n_subcarriers);
    H_abs2 = abs(H(:)).^2;
    H_abs2_all(:, ir) = H_abs2;

    [rank_idx, group_labels] = local_rank_and_group(H_abs2);

    for is = 1:nS
        snr_db = snr_grid(is);
        gamma_avg = 10^(snr_db / 10);
        gamma_k = gamma_avg * H_abs2;
        mi_proxy = log2(1 + gamma_k);

        span = row_idx + (1:n_subcarriers);
        realization_col(span) = ir;
        subcarrier_col(span) = (0:n_subcarriers-1).';
        snr_col(span) = snr_db;
        h_abs2_col(span) = H_abs2;
        gamma_col(span) = gamma_k;
        gamma_db_col(span) = 10 * log10(gamma_k + eps);
        mi_proxy_col(span) = mi_proxy;
        rank_col(span) = rank_idx;
        group_col(span) = group_labels;
        row_idx = row_idx + n_subcarriers;
    end
end

T = table(realization_col, subcarrier_col, snr_col, h_abs2_col, ...
    gamma_col, gamma_db_col, mi_proxy_col, rank_col, group_col, ...
    'VariableNames', {'realization', 'subcarrier', 'snr_dB', ...
    'h_abs2', 'gamma_linear', 'gamma_dB', 'mi_proxy_log2_1_plus_gamma', ...
    'reliability_rank', 'reliability_group'});
writetable(T, fullfile(out_dir, 'subcarrier_reliability.csv'));

Summary = local_make_summary(T, snr_grid);
writetable(Summary, fullfile(out_dir, 'subcarrier_reliability_summary.csv'));

save(fullfile(out_dir, 'rayleigh_subcarrier_profile.mat'), ...
    'cfg', 'n_subcarriers', 'cp_ratio', 'nCp', 'channel_taps', ...
    'num_realizations', 'snr_grid', 'seed', 'T', 'Summary', 'H_abs2_all');

%% ===== Figures =====
local_plot_gain_profile(fig_dir, H_abs2_all);
local_plot_snr_profile(fig_dir, T, snr_grid, num_realizations);
local_plot_mi_profile(fig_dir, T, snr_grid, num_realizations);
local_plot_group_profile(fig_dir, T, snr_grid, num_realizations);
local_write_readme(out_dir, n_subcarriers, cp_ratio, nCp, channel_taps, ...
    num_realizations, snr_grid, seed);

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function h = local_rayleigh_channel(channel_taps)
    h = (randn(channel_taps, 1) + 1j * randn(channel_taps, 1)) / sqrt(2 * channel_taps);
end

function [rank_idx, group_labels] = local_rank_and_group(H_abs2)
    nSub = numel(H_abs2);
    [~, order] = sort(H_abs2, 'descend');
    rank_idx = zeros(nSub, 1);
    rank_idx(order) = (1:nSub).';

    group_labels = strings(nSub, 1);
    nHigh = floor(nSub / 3);
    nMid = floor(nSub / 3);
    group_labels(order(1:nHigh)) = "high";
    group_labels(order(nHigh+1:nHigh+nMid)) = "mid";
    group_labels(order(nHigh+nMid+1:end)) = "low";
end

function Summary = local_make_summary(T, snr_grid)
    nS = numel(snr_grid);
    snr_col = zeros(nS, 1);
    h_mean = zeros(nS, 1);
    h_p10 = zeros(nS, 1);
    h_p50 = zeros(nS, 1);
    h_p90 = zeros(nS, 1);
    gamma_mean_db = zeros(nS, 1);
    gamma_p10_db = zeros(nS, 1);
    gamma_p50_db = zeros(nS, 1);
    gamma_p90_db = zeros(nS, 1);
    mi_mean = zeros(nS, 1);
    mi_p10 = zeros(nS, 1);
    mi_p50 = zeros(nS, 1);
    mi_p90 = zeros(nS, 1);

    for is = 1:nS
        snr_db = snr_grid(is);
        rows = T.snr_dB == snr_db;
        snr_col(is) = snr_db;
        h_vals = T.h_abs2(rows);
        gamma_vals = T.gamma_dB(rows);
        mi_vals = T.mi_proxy_log2_1_plus_gamma(rows);

        h_mean(is) = mean(h_vals);
        hp = prctile(h_vals, [10 50 90]);
        h_p10(is) = hp(1);
        h_p50(is) = hp(2);
        h_p90(is) = hp(3);

        gamma_mean_db(is) = mean(gamma_vals);
        gp = prctile(gamma_vals, [10 50 90]);
        gamma_p10_db(is) = gp(1);
        gamma_p50_db(is) = gp(2);
        gamma_p90_db(is) = gp(3);

        mi_mean(is) = mean(mi_vals);
        mp = prctile(mi_vals, [10 50 90]);
        mi_p10(is) = mp(1);
        mi_p50(is) = mp(2);
        mi_p90(is) = mp(3);
    end

    Summary = table(snr_col, h_mean, h_p10, h_p50, h_p90, ...
        gamma_mean_db, gamma_p10_db, gamma_p50_db, gamma_p90_db, ...
        mi_mean, mi_p10, mi_p50, mi_p90, ...
        'VariableNames', {'snr_dB', 'h_abs2_mean', 'h_abs2_p10', ...
        'h_abs2_p50', 'h_abs2_p90', 'gamma_dB_mean', 'gamma_dB_p10', ...
        'gamma_dB_p50', 'gamma_dB_p90', 'mi_proxy_mean', 'mi_proxy_p10', ...
        'mi_proxy_p50', 'mi_proxy_p90'});
end

function local_plot_gain_profile(fig_dir, H_abs2_all)
    nSub = size(H_abs2_all, 1);
    mean_gain = mean(H_abs2_all, 2);
    p10 = prctile(H_abs2_all, 10, 2);
    p90 = prctile(H_abs2_all, 90, 2);
    x = (0:nSub-1).';

    fig = figure('Color', 'w', 'Position', [80 80 960 560]);
    hold on; grid on; box on;
    fill([x; flipud(x)], [10*log10(p10 + eps); flipud(10*log10(p90 + eps))], ...
        [0.85 0.90 1.00], 'EdgeColor', 'none', 'DisplayName', '10-90 percentile');
    plot(x, 10*log10(mean_gain + eps), 'b-', 'LineWidth', 1.6, 'DisplayName', 'Mean');
    xlabel('Subcarrier index');
    ylabel('|H_k|^2 (dB)');
    title('Rayleigh Subcarrier Gain Profile');
    legend('Location', 'best');
    savefig(fig, fullfile(fig_dir, 'subcarrier_gain_profile.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'subcarrier_gain_profile.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'subcarrier_gain_profile.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_snr_profile(fig_dir, T, snr_grid, num_realizations)
    target_snr = snr_grid(end);
    rows = T.snr_dB == target_snr & T.realization == 1;
    x = T.subcarrier(rows);

    fig = figure('Color', 'w', 'Position', [80 80 960 560]);
    plot(x, T.gamma_dB(rows), '-o', 'LineWidth', 1.4, 'MarkerSize', 4);
    grid on; box on;
    xlabel('Subcarrier index');
    ylabel('\gamma_k (dB)');
    title(sprintf('Effective Subcarrier SNR, realization 1, average SNR=%g dB', target_snr));
    subtitle(sprintf('Additional %d realizations are saved in CSV/MAT.', num_realizations - 1));
    savefig(fig, fullfile(fig_dir, 'subcarrier_snr_profile.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'subcarrier_snr_profile.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'subcarrier_snr_profile.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_mi_profile(fig_dir, T, snr_grid, num_realizations)
    target_snr = snr_grid(end);
    rows = T.snr_dB == target_snr & T.realization == 1;
    x = T.subcarrier(rows);

    fig = figure('Color', 'w', 'Position', [80 80 960 560]);
    plot(x, T.mi_proxy_log2_1_plus_gamma(rows), '-o', ...
        'LineWidth', 1.4, 'MarkerSize', 4, 'Color', [0.20 0.55 0.25]);
    grid on; box on;
    xlabel('Subcarrier index');
    ylabel('MI proxy log_2(1+\gamma_k)');
    title(sprintf('Subcarrier MI Proxy, realization 1, average SNR=%g dB', target_snr));
    subtitle(sprintf('Additional %d realizations are saved in CSV/MAT.', num_realizations - 1));
    savefig(fig, fullfile(fig_dir, 'subcarrier_mi_profile.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'subcarrier_mi_profile.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'subcarrier_mi_profile.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_group_profile(fig_dir, T, snr_grid, num_realizations)
    target_snr = snr_grid(end);
    rows = T.snr_dB == target_snr & T.realization == 1;
    x = T.subcarrier(rows);
    gamma_db = T.gamma_dB(rows);
    groups = T.reliability_group(rows);

    fig = figure('Color', 'w', 'Position', [80 80 960 560]);
    hold on; grid on; box on;
    local_scatter_group(x, gamma_db, groups, "high", [0.10 0.45 0.85]);
    local_scatter_group(x, gamma_db, groups, "mid", [0.95 0.60 0.10]);
    local_scatter_group(x, gamma_db, groups, "low", [0.75 0.20 0.20]);
    xlabel('Subcarrier index');
    ylabel('\gamma_k (dB)');
    title(sprintf('Reliability Groups, realization 1, average SNR=%g dB', target_snr));
    subtitle(sprintf('Grouping is based on |H_k|^2 rank; %d realizations saved.', num_realizations));
    legend('Location', 'bestoutside');
    savefig(fig, fullfile(fig_dir, 'subcarrier_group_profile.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'subcarrier_group_profile.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'subcarrier_group_profile.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_scatter_group(x, y, groups, label, color)
    idx = groups == label;
    scatter(x(idx), y(idx), 36, color, 'filled', 'DisplayName', char(label));
end

function local_write_readme(out_dir, n_subcarriers, cp_ratio, nCp, ...
    channel_taps, num_realizations, snr_grid, seed)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid));

    fprintf(fid, '=== Stage B / B2 Rayleigh Subcarrier Profile ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/multicarrier/run_rayleigh_subcarrier_profile.m'');\n\n');
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  Rayleigh OFDM subcarrier reliability profile only.\n');
    fprintf(fid, '  No polar decoding, no BER Monte Carlo, no p_k optimization.\n\n');
    fprintf(fid, 'PARAMETERS\n');
    fprintf(fid, '  n_subcarriers: %d\n', n_subcarriers);
    fprintf(fid, '  cp_ratio: %.4f\n', cp_ratio);
    fprintf(fid, '  cp_length: %d\n', nCp);
    fprintf(fid, '  channel_taps: %d\n', channel_taps);
    fprintf(fid, '  num_realizations: %d\n', num_realizations);
    fprintf(fid, '  snr_grid: %s\n', mat2str(snr_grid));
    fprintf(fid, '  seed: %d\n\n', seed);
    fprintf(fid, 'OUTPUTS\n');
    fprintf(fid, '  subcarrier_reliability.csv\n');
    fprintf(fid, '  subcarrier_reliability_summary.csv\n');
    fprintf(fid, '  rayleigh_subcarrier_profile.mat\n');
    fprintf(fid, '  run_log.txt\n');
    fprintf(fid, '  figures/subcarrier_gain_profile.png/pdf/fig\n');
    fprintf(fid, '  figures/subcarrier_snr_profile.png/pdf/fig\n');
    fprintf(fid, '  figures/subcarrier_mi_profile.png/pdf/fig\n');
    fprintf(fid, '  figures/subcarrier_group_profile.png/pdf/fig\n\n');
    fprintf(fid, 'NOTES\n');
    fprintf(fid, '  gamma_k = gamma_avg * |H_k|^2 with normalized Rayleigh taps.\n');
    fprintf(fid, '  MI proxy is log2(1+gamma_k), not coded 16QAM mutual information.\n');
    fprintf(fid, '  Reliability groups are rank-based thirds within each channel realization.\n');
end
