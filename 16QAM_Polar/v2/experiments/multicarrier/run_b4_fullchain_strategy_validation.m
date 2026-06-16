%% RUN_B4_FULLCHAIN_STRATEGY_VALIDATION
% Stage B / B4: grouped full-chain strategy validation for Rayleigh OFDM.
%
% Scope:
%   First paper-oriented validation entry after B3 proxy comparison. This
%   script keeps B1 OFDM parameters and evaluates the B3 six strategy
%   families through grouped full-chain blocks. It is not a per-subcarrier
%   polar encoder; high/mid/low groups are represented by weighted full-chain
%   blocks.

clearvars -except b4_overrides; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg_base = config();

%% ===== Config =====
run_mode = 'smoke';  % 'smoke' | 'full'
result_tag = 'b4_fullchain_strategy_validation';
seed = 42;

n_subcarriers = 64;
cp_ratio = 1/4;
channel_taps = 16;
snr_grid = 8:2:20;
strategy_names = { ...
    'uniform_p05', ...
    'uniform_p03', ...
    'uniform_p01', ...
    'good_channel_information', ...
    'good_channel_energy_shaping', ...
    'bad_channel_energy_only'};

% Full-paper defaults. Smoke mode overrides these below.
num_realizations = 50;
seed_list = 1:5;
min_frames = 100;
max_frames = 1000;
target_errors = 200;

if exist('b4_overrides', 'var')
    if isfield(b4_overrides, 'run_mode'); run_mode = b4_overrides.run_mode; end
    if isfield(b4_overrides, 'result_tag'); result_tag = b4_overrides.result_tag; end
    if isfield(b4_overrides, 'seed'); seed = b4_overrides.seed; end
    if isfield(b4_overrides, 'num_realizations'); num_realizations = b4_overrides.num_realizations; end
    if isfield(b4_overrides, 'seed_list'); seed_list = b4_overrides.seed_list; end
    if isfield(b4_overrides, 'min_frames'); min_frames = b4_overrides.min_frames; end
    if isfield(b4_overrides, 'max_frames'); max_frames = b4_overrides.max_frames; end
    if isfield(b4_overrides, 'target_errors'); target_errors = b4_overrides.target_errors; end
    if isfield(b4_overrides, 'snr_grid'); snr_grid = b4_overrides.snr_grid; end
end

if strcmpi(run_mode, 'smoke')
    num_realizations = min(num_realizations, 2);
    seed_list = seed_list(1:min(numel(seed_list), 1));
    snr_grid = snr_grid(1:min(numel(snr_grid), 2));
    min_frames = min(min_frames, 5);
    max_frames = min(max_frames, 10);
    target_errors = min(target_errors, 5);
    result_tag = [result_tag '_smoke'];
end

cfg_local = cfg_base;
cfg_local.decoder = 'SC';
cfg_local.snr_mode = 'fixed_esn0';
cfg_local.ofdm_n_subcarriers = n_subcarriers;
cfg_local.ofdm_cp_ratio = cp_ratio;
cfg_local.channel = 'Rayleigh';

rng(seed, 'twister');

out_dir = fullfile(cfg_local.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' result_tag]);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

diary(fullfile(out_dir, 'run_log.txt'));
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Stage B / B4 Full-chain Strategy Validation ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('run_mode: %s\n', run_mode);
fprintf('strategies: %s\n', strjoin(strategy_names, ', '));
fprintf('snr_grid: %s\n', mat2str(snr_grid));
fprintf('num_realizations: %d\n', num_realizations);
fprintf('seed_list: %s\n', mat2str(seed_list));
fprintf('adaptive frames: min=%d, max=%d, target_errors=%d\n', ...
    min_frames, max_frames, target_errors);

%% ===== Precompute block p metrics =====
p_values = [0.5, 0.3, 0.1];
T_block = local_simulate_p_blocks(p_values, snr_grid, seed_list, cfg_local, ...
    min_frames, max_frames, target_errors);

%% ===== Rayleigh grouped strategy aggregation =====
T_strategy = local_aggregate_strategies(T_block, strategy_names, snr_grid, ...
    num_realizations, seed, n_subcarriers, cp_ratio, channel_taps, cfg_local);

T_summary = local_summarize_strategy(T_strategy);

writetable(T_block, fullfile(out_dir, 'b4_p_block_results.csv'));
writetable(T_strategy, fullfile(out_dir, 'b4_strategy_realization_results.csv'));
writetable(T_summary, fullfile(out_dir, 'b4_strategy_summary.csv'));

save(fullfile(out_dir, 'b4_fullchain_strategy_validation.mat'), ...
    'cfg_local', 'run_mode', 'strategy_names', 'snr_grid', 'num_realizations', ...
    'seed_list', 'min_frames', 'max_frames', 'target_errors', ...
    'T_block', 'T_strategy', 'T_summary');

local_plot_ber(fig_dir, T_summary);
local_plot_goodput(fig_dir, T_summary);
local_plot_pareto(fig_dir, T_summary);
local_write_readme(out_dir, run_mode, strategy_names, snr_grid, num_realizations, ...
    seed_list, min_frames, max_frames, target_errors);

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function T_block = local_simulate_p_blocks(p_values, snr_grid, seed_list, cfg, ...
    min_frames, max_frames, target_errors)
    rows = {};
    for ip = 1:numel(p_values)
        p = p_values(ip);
        for is = 1:numel(snr_grid)
            snr_db = snr_grid(is);
            for ise = 1:numel(seed_list)
                seed = seed_list(ise);
                cfg_run = cfg;
                cfg_run.seed = seed;

                total_frames = 0;
                total_info_bits = 0;
                total_errors = 0;
                weighted_ber_acc = 0;
                r_total = nan;
                r_total_cp = nan;
                mi_total_acc = 0;
                n_batches = 0;

                while total_frames < max_frames
                    batch_frames = min(min_frames, max_frames - total_frames);
                    cfg_run.num_frames = batch_frames;
                    result = sim_shaped_polar_16qam(p, snr_db, cfg_run);
                    K_total = sum(result.K);
                    block_errors = round(result.BER * K_total * batch_frames);
                    block_bits = K_total * batch_frames;

                    total_frames = total_frames + batch_frames;
                    total_info_bits = total_info_bits + block_bits;
                    total_errors = total_errors + block_errors;
                    weighted_ber_acc = weighted_ber_acc + result.BER * block_bits;
                    mi_total_acc = mi_total_acc + result.MI_total;
                    n_batches = n_batches + 1;
                    r_total = result.R_total;
                    r_total_cp = r_total * cfg.ofdm_n_subcarriers / ...
                        (cfg.ofdm_n_subcarriers + round(cfg.ofdm_n_subcarriers * cfg.ofdm_cp_ratio));

                    if total_frames >= min_frames && total_errors >= target_errors
                        break;
                    end
                end

                ber = weighted_ber_acc / max(total_info_bits, 1);
                goodput = r_total * (1 - ber);
                goodput_cp = r_total_cp * (1 - ber);
                e_norm = (18 - 16 * p) / cfg.E_baseline;
                mi_total = mi_total_acc / max(n_batches, 1);

                rows(end+1, :) = {p, snr_db, seed, total_frames, total_errors, ...
                    total_info_bits, ber, goodput, goodput_cp, r_total, ...
                    r_total_cp, e_norm, mi_total}; %#ok<AGROW>
            end
        end
    end

    T_block = cell2table(rows, 'VariableNames', {'p', 'snr_dB', 'seed', ...
        'frames_used', 'error_count', 'info_bits', 'ber', 'goodput', ...
        'goodput_cp_corrected', 'r_total', 'r_total_cp_corrected', ...
        'e_norm', 'mi_total'});
end

function T_strategy = local_aggregate_strategies(T_block, strategy_names, snr_grid, ...
    num_realizations, seed, n_subcarriers, cp_ratio, channel_taps, cfg)
    rng(seed, 'twister');
    rows = {};
    nCp = round(n_subcarriers * cp_ratio);
    info_resource_cp_factor = n_subcarriers / (n_subcarriers + nCp);

    for ir = 1:num_realizations
        h = local_rayleigh_channel(channel_taps);
        H_abs2 = abs(fft(h, n_subcarriers)).^2;
        group_labels = local_rank_and_group(H_abs2);

        for is = 1:numel(snr_grid)
            snr_db = snr_grid(is);
            for istr = 1:numel(strategy_names)
                strategy = string(strategy_names{istr});
                [group_p, group_info] = local_strategy_group_rule(strategy);

                ber_num = 0;
                ber_den = 0;
                goodput_sum = 0;
                rate_sum = 0;
                energy_vals = zeros(n_subcarriers, 1);
                info_count = 0;

                groups = ["high", "mid", "low"];
                for ig = 1:numel(groups)
                    group = groups(ig);
                    sub_idx = group_labels == group;
                    n_group = sum(sub_idx);
                    p_group = group_p.(char(group));
                    carries_info = group_info.(char(group));
                    block = T_block(T_block.p == p_group & T_block.snr_dB == snr_db, :);

                    ber_group = mean(block.ber);
                    goodput_group = mean(block.goodput_cp_corrected);
                    r_group = mean(block.r_total_cp_corrected);
                    e_norm_group = (18 - 16 * p_group) / cfg.E_baseline;
                    energy_vals(sub_idx) = H_abs2(sub_idx) * e_norm_group;

                    if carries_info
                        info_count = info_count + n_group;
                        ber_num = ber_num + n_group * r_group * ber_group;
                        ber_den = ber_den + n_group * r_group;
                        goodput_sum = goodput_sum + n_group * goodput_group;
                        rate_sum = rate_sum + n_group * r_group;
                    end
                end

                if ber_den > 0
                    ber_strategy = ber_num / ber_den;
                else
                    ber_strategy = nan;
                end
                goodput_per_resource = goodput_sum / n_subcarriers;
                rate_per_resource = rate_sum / n_subcarriers;
                energy_mean = mean(energy_vals);
                energy_rms = sqrt(mean(energy_vals .^ 2));
                info_fraction = info_count / n_subcarriers;

                rows(end+1, :) = {char(strategy), ir, snr_db, ber_strategy, ...
                    goodput_per_resource, rate_per_resource, energy_mean, ...
                    energy_rms, info_fraction, info_resource_cp_factor}; %#ok<AGROW>
            end
        end
    end

    T_strategy = cell2table(rows, 'VariableNames', {'strategy', 'realization', ...
        'snr_dB', 'ber', 'goodput_cp_per_resource', 'rate_cp_per_resource', ...
        'energy_mean', 'energy_rms', 'info_subcarrier_fraction', ...
        'cp_resource_factor'});
end

function T_summary = local_summarize_strategy(T_strategy)
    keys = unique(T_strategy(:, {'strategy', 'snr_dB'}), 'rows');
    rows = {};
    for i = 1:height(keys)
        strategy = keys.strategy{i};
        snr_db = keys.snr_dB(i);
        idx = strcmp(T_strategy.strategy, strategy) & T_strategy.snr_dB == snr_db;
        Ti = T_strategy(idx, :);
        rows(end+1, :) = {strategy, snr_db, ...
            mean(Ti.ber, 'omitnan'), local_ci95(Ti.ber), ...
            mean(Ti.goodput_cp_per_resource, 'omitnan'), local_ci95(Ti.goodput_cp_per_resource), ...
            mean(Ti.energy_rms, 'omitnan'), local_ci95(Ti.energy_rms), ...
            mean(Ti.energy_mean, 'omitnan'), mean(Ti.info_subcarrier_fraction, 'omitnan')}; %#ok<AGROW>
    end
    T_summary = cell2table(rows, 'VariableNames', {'strategy', 'snr_dB', ...
        'ber_mean', 'ber_ci95', 'goodput_cp_mean', 'goodput_cp_ci95', ...
        'energy_rms_mean', 'energy_rms_ci95', 'energy_mean', ...
        'info_subcarrier_fraction'});
end

function h = local_rayleigh_channel(channel_taps)
    h = (randn(channel_taps, 1) + 1j * randn(channel_taps, 1)) / sqrt(2 * channel_taps);
end

function group_labels = local_rank_and_group(H_abs2)
    nSub = numel(H_abs2);
    [~, order] = sort(H_abs2, 'descend');
    group_labels = strings(nSub, 1);
    nHigh = floor(nSub / 3);
    nMid = floor(nSub / 3);
    group_labels(order(1:nHigh)) = "high";
    group_labels(order(nHigh+1:nHigh+nMid)) = "mid";
    group_labels(order(nHigh+nMid+1:end)) = "low";
end

function [group_p, group_info] = local_strategy_group_rule(strategy)
    group_info = struct('high', true, 'mid', true, 'low', true);
    switch string(strategy)
        case "uniform_p05"
            group_p = struct('high', 0.5, 'mid', 0.5, 'low', 0.5);
        case "uniform_p03"
            group_p = struct('high', 0.3, 'mid', 0.3, 'low', 0.3);
        case "uniform_p01"
            group_p = struct('high', 0.1, 'mid', 0.1, 'low', 0.1);
        case "good_channel_information"
            group_p = struct('high', 0.5, 'mid', 0.3, 'low', 0.1);
        case "good_channel_energy_shaping"
            group_p = struct('high', 0.1, 'mid', 0.3, 'low', 0.5);
        case "bad_channel_energy_only"
            group_p = struct('high', 0.5, 'mid', 0.3, 'low', 0.1);
            group_info.low = false;
        otherwise
            error('Unknown strategy: %s', strategy);
    end
end

function ci = local_ci95(x)
    x = x(~isnan(x));
    if numel(x) <= 1
        ci = 0;
    else
        ci = 1.96 * std(x) / sqrt(numel(x));
    end
end

function local_plot_ber(fig_dir, T_summary)
    strategies = unique(string(T_summary.strategy), 'stable');
    colors = lines(numel(strategies));
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for i = 1:numel(strategies)
        rows = string(T_summary.strategy) == strategies(i);
        errorbar(T_summary.snr_dB(rows), T_summary.ber_mean(rows), T_summary.ber_ci95(rows), ...
            '-o', 'Color', colors(i, :), 'LineWidth', 1.4, ...
            'DisplayName', local_display_label(strategies(i)));
    end
    set(gca, 'YScale', 'log', 'TickLabelInterpreter', 'none');
    xlabel('Average SNR (dB)', 'Interpreter', 'none');
    ylabel('BER mean with 95% CI', 'Interpreter', 'none');
    title('B4 Grouped Full-chain BER', 'Interpreter', 'none');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'b4_ber_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'b4_ber_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'b4_ber_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_goodput(fig_dir, T_summary)
    strategies = unique(string(T_summary.strategy), 'stable');
    colors = lines(numel(strategies));
    fig = figure('Color', 'w', 'Position', [80 80 980 620]);
    hold on; grid on; box on;
    for i = 1:numel(strategies)
        rows = string(T_summary.strategy) == strategies(i);
        errorbar(T_summary.snr_dB(rows), T_summary.goodput_cp_mean(rows), T_summary.goodput_cp_ci95(rows), ...
            '-o', 'Color', colors(i, :), 'LineWidth', 1.4, ...
            'DisplayName', local_display_label(strategies(i)));
    end
    set(gca, 'TickLabelInterpreter', 'none');
    xlabel('Average SNR (dB)', 'Interpreter', 'none');
    ylabel('CP-corrected Goodput per resource', 'Interpreter', 'none');
    title('B4 Grouped Full-chain Goodput', 'Interpreter', 'none');
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'b4_goodput_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'b4_goodput_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'b4_goodput_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_pareto(fig_dir, T_summary)
    rows = T_summary.snr_dB == max(T_summary.snr_dB);
    T = T_summary(rows, :);
    fig = figure('Color', 'w', 'Position', [80 80 900 620]);
    hold on; grid on; box on;
    scatter(T.energy_rms_mean, T.goodput_cp_mean, 80, 'filled');
    for i = 1:height(T)
        text(T.energy_rms_mean(i), T.goodput_cp_mean(i), ...
            ['  ' local_display_label(string(T.strategy{i}))], ...
            'Interpreter', 'none');
    end
    xlabel('Energy RMS proxy', 'Interpreter', 'none');
    ylabel('CP-corrected Goodput per resource', 'Interpreter', 'none');
    title(sprintf('B4 Goodput-Energy Pareto Proxy at %g dB', max(T.snr_dB)), ...
        'Interpreter', 'none');
    set(gca, 'TickLabelInterpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'b4_goodput_energy_pareto.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'b4_goodput_energy_pareto.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'b4_goodput_energy_pareto.pdf'), 'ContentType', 'vector');
    close(fig);
end

function label = local_display_label(strategy)
    switch string(strategy)
        case "uniform_p05"
            label = 'uniform p=0.5';
        case "uniform_p03"
            label = 'uniform p=0.3';
        case "uniform_p01"
            label = 'uniform p=0.1';
        case "good_channel_information"
            label = 'good channel information';
        case "good_channel_energy_shaping"
            label = 'good channel energy shaping';
        case "bad_channel_energy_only"
            label = 'bad channel energy only';
        otherwise
            label = strrep(char(strategy), '_', ' ');
    end
end

function local_write_readme(out_dir, run_mode, strategy_names, snr_grid, ...
    num_realizations, seed_list, min_frames, max_frames, target_errors)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid));

    fprintf(fid, '=== Stage B / B4 Grouped Full-chain Strategy Validation ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/multicarrier/run_b4_fullchain_strategy_validation.m'');\n\n');
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  Grouped block full-chain validation. This is not per-subcarrier polar encoding.\n');
    fprintf(fid, '  Strategies are aggregated over high/mid/low Rayleigh reliability groups.\n\n');
    fprintf(fid, 'PARAMETERS\n');
    fprintf(fid, '  run_mode: %s\n', run_mode);
    fprintf(fid, '  strategies: %s\n', strjoin(strategy_names, ', '));
    fprintf(fid, '  snr_grid: %s\n', mat2str(snr_grid));
    fprintf(fid, '  num_realizations: %d\n', num_realizations);
    fprintf(fid, '  seed_list: %s\n', mat2str(seed_list));
    fprintf(fid, '  adaptive frames: min=%d, max=%d, target_errors=%d\n\n', ...
        min_frames, max_frames, target_errors);
    fprintf(fid, 'OUTPUTS\n');
    fprintf(fid, '  b4_p_block_results.csv\n');
    fprintf(fid, '  b4_strategy_realization_results.csv\n');
    fprintf(fid, '  b4_strategy_summary.csv\n');
    fprintf(fid, '  b4_fullchain_strategy_validation.mat\n');
    fprintf(fid, '  run_log.txt\n');
    fprintf(fid, '  figures/b4_ber_vs_snr.*\n');
    fprintf(fid, '  figures/b4_goodput_vs_snr.*\n');
    fprintf(fid, '  figures/b4_goodput_energy_pareto.*\n');
end
