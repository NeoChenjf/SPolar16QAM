%% RUN_SUBCARRIER_STRATEGY_COMPARE
% Stage B / B3: proxy-level subcarrier strategy comparison.
%
% Scope:
%   Compare uniform p and three reliability-group strategies using B2
%   Rayleigh subcarrier profile outputs. This script does not run polar
%   encoding/decoding and does not produce BER/Goodput Monte Carlo results.

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg = config();

%% ===== Config =====
b2_result_dir = '';
result_tag = 'subcarrier_strategy_compare';
seed = 42;

uniform_p_list = [0.5, 0.3, 0.1];
strategy_names = { ...
    'uniform_p05', ...
    'uniform_p03', ...
    'uniform_p01', ...
    'good_channel_information', ...
    'good_channel_energy_shaping', ...
    'bad_channel_energy_only'};

rng(seed, 'twister');

if isempty(b2_result_dir)
    b2_result_dir = local_find_latest_result_dir(cfg.output_dir, '_rayleigh_subcarrier_profile');
end

profile_file = fullfile(b2_result_dir, 'subcarrier_reliability.csv');
if ~exist(profile_file, 'file')
    error('Missing B2 profile CSV: %s', profile_file);
end

T_profile = readtable(profile_file);

out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' result_tag]);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

diary(fullfile(out_dir, 'run_log.txt'));
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Stage B / B3 Subcarrier Strategy Compare ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('B2 profile: %s\n', profile_file);
fprintf('Strategies: %s\n', strjoin(strategy_names, ', '));

%% ===== Strategy comparison =====
T_assign = local_build_assignment_table(T_profile, strategy_names, uniform_p_list, cfg);
T_summary = local_build_summary_table(T_assign);

writetable(T_assign, fullfile(out_dir, 'subcarrier_strategy_assignment.csv'));
writetable(T_summary, fullfile(out_dir, 'subcarrier_strategy_summary.csv'));

save(fullfile(out_dir, 'subcarrier_strategy_compare.mat'), ...
    'cfg', 'b2_result_dir', 'profile_file', 'T_profile', 'T_assign', ...
    'T_summary', 'strategy_names', 'uniform_p_list', 'seed');

local_plot_strategy_summary(fig_dir, T_summary);
local_plot_strategy_by_snr(fig_dir, T_summary);
local_write_readme(out_dir, b2_result_dir, strategy_names, uniform_p_list);

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function result_dir = local_find_latest_result_dir(output_dir, suffix)
    d = dir(fullfile(output_dir, ['*' suffix]));
    if isempty(d)
        error('No result directory matching *%s under %s.', suffix, output_dir);
    end
    [~, idx] = max([d.datenum]);
    result_dir = fullfile(d(idx).folder, d(idx).name);
end

function T_assign = local_build_assignment_table(T_profile, strategy_names, uniform_p_list, cfg)
    nProfile = height(T_profile);
    nStrategies = numel(strategy_names);
    nRows = nProfile * nStrategies;

    realization_col = zeros(nRows, 1);
    subcarrier_col = zeros(nRows, 1);
    snr_col = zeros(nRows, 1);
    strategy_col = strings(nRows, 1);
    group_col = strings(nRows, 1);
    p_col = nan(nRows, 1);
    carries_info_col = false(nRows, 1);
    h_abs2_col = zeros(nRows, 1);
    gamma_col = zeros(nRows, 1);
    mi_col = zeros(nRows, 1);
    energy_symbol_col = zeros(nRows, 1);
    rx_energy_proxy_col = zeros(nRows, 1);
    info_weight_col = zeros(nRows, 1);

    row = 0;
    for istrat = 1:nStrategies
        strategy = string(strategy_names{istrat});
        for i = 1:nProfile
            group = string(T_profile.reliability_group{i});
            [p_value, carries_info] = local_strategy_rule(strategy, group, uniform_p_list);
            energy_symbol = local_energy_p(p_value, cfg);
            rx_energy_proxy = T_profile.h_abs2(i) * energy_symbol;
            info_weight = double(carries_info) * local_rate_proxy(p_value, cfg);

            row = row + 1;
            realization_col(row) = T_profile.realization(i);
            subcarrier_col(row) = T_profile.subcarrier(i);
            snr_col(row) = T_profile.snr_dB(i);
            strategy_col(row) = strategy;
            group_col(row) = group;
            p_col(row) = p_value;
            carries_info_col(row) = carries_info;
            h_abs2_col(row) = T_profile.h_abs2(i);
            gamma_col(row) = T_profile.gamma_linear(i);
            mi_col(row) = T_profile.mi_proxy_log2_1_plus_gamma(i);
            energy_symbol_col(row) = energy_symbol;
            rx_energy_proxy_col(row) = rx_energy_proxy;
            info_weight_col(row) = info_weight;
        end
    end

    T_assign = table(realization_col, subcarrier_col, snr_col, strategy_col, ...
        group_col, p_col, carries_info_col, h_abs2_col, gamma_col, mi_col, ...
        energy_symbol_col, rx_energy_proxy_col, info_weight_col, ...
        'VariableNames', {'realization', 'subcarrier', 'snr_dB', 'strategy', ...
        'reliability_group', 'p_assigned', 'carries_info', 'h_abs2', ...
        'gamma_linear', 'mi_proxy', 'e_symbol', 'rx_energy_proxy', ...
        'info_weight_proxy'});
end

function [p_value, carries_info] = local_strategy_rule(strategy, group, uniform_p_list)
    carries_info = true;
    switch strategy
        case "uniform_p05"
            p_value = uniform_p_list(1);
        case "uniform_p03"
            p_value = uniform_p_list(2);
        case "uniform_p01"
            p_value = uniform_p_list(3);
        case "good_channel_information"
            if group == "high"
                p_value = 0.5;
            elseif group == "mid"
                p_value = 0.3;
            else
                p_value = 0.1;
            end
        case "good_channel_energy_shaping"
            if group == "high"
                p_value = 0.1;
            elseif group == "mid"
                p_value = 0.3;
            else
                p_value = 0.5;
            end
        case "bad_channel_energy_only"
            if group == "low"
                p_value = 0.1;
                carries_info = false;
            elseif group == "mid"
                p_value = 0.3;
            else
                p_value = 0.5;
            end
        otherwise
            error('Unknown strategy: %s', strategy);
    end
end

function e = local_energy_p(p_value, cfg)
    e = (18 - 16 * p_value) / cfg.E_baseline;
end

function r = local_rate_proxy(p_value, cfg)
    N = cfg.N;
    p_vec = cfg.p_fixed;
    p_vec(isnan(p_vec)) = p_value;
    K_total = 0;
    for b = 1:4
        pb = p_vec(b);
        if pb > 0 && pb < 1
            hb = -pb * log2(pb) - (1 - pb) * log2(1 - pb);
        else
            hb = 0;
        end
        S = ceil(N * (1 - hb));
        K = ceil((N - S) / 2);
        K_total = K_total + K;
    end
    r = K_total / (4 * N);
end

function T_summary = local_build_summary_table(T_assign)
    keys = unique(T_assign(:, {'strategy', 'snr_dB'}), 'rows');
    nRows = height(keys);

    strategy_col = strings(nRows, 1);
    snr_col = zeros(nRows, 1);
    info_fraction = zeros(nRows, 1);
    avg_p_info = zeros(nRows, 1);
    rx_energy_proxy_mean = zeros(nRows, 1);
    rx_energy_proxy_rms = zeros(nRows, 1);
    rx_energy_proxy_info_mean = zeros(nRows, 1);
    info_mi_proxy_mean = zeros(nRows, 1);
    info_gamma_proxy_mean = zeros(nRows, 1);
    info_weight_proxy_mean = zeros(nRows, 1);
    multicarrier_goodput_proxy_sum = zeros(nRows, 1);
    high_info_fraction = zeros(nRows, 1);
    mid_info_fraction = zeros(nRows, 1);
    low_info_fraction = zeros(nRows, 1);

    for i = 1:nRows
        strategy = keys.strategy(i);
        snr_db = keys.snr_dB(i);
        rows = T_assign.strategy == strategy & T_assign.snr_dB == snr_db;
        Ti = T_assign(rows, :);
        info_rows = Ti.carries_info;

        strategy_col(i) = strategy;
        snr_col(i) = snr_db;
        info_fraction(i) = mean(info_rows);
        avg_p_info(i) = mean(Ti.p_assigned(info_rows));
        rx_energy_proxy_mean(i) = mean(Ti.rx_energy_proxy);
        rx_energy_proxy_rms(i) = sqrt(mean(Ti.rx_energy_proxy .^ 2));
        rx_energy_proxy_info_mean(i) = mean(Ti.rx_energy_proxy(info_rows));
        info_mi_proxy_mean(i) = mean(Ti.mi_proxy(info_rows));
        info_gamma_proxy_mean(i) = mean(Ti.gamma_linear(info_rows));
        info_weight_proxy_mean(i) = mean(Ti.info_weight_proxy);
        multicarrier_goodput_proxy_sum(i) = ...
            numel(unique(Ti.subcarrier)) * info_weight_proxy_mean(i);
        high_info_fraction(i) = local_group_info_fraction(Ti, "high");
        mid_info_fraction(i) = local_group_info_fraction(Ti, "mid");
        low_info_fraction(i) = local_group_info_fraction(Ti, "low");
    end

    T_summary = table(strategy_col, snr_col, info_fraction, avg_p_info, ...
        rx_energy_proxy_mean, rx_energy_proxy_rms, rx_energy_proxy_info_mean, ...
        info_mi_proxy_mean, info_gamma_proxy_mean, info_weight_proxy_mean, ...
        multicarrier_goodput_proxy_sum, high_info_fraction, mid_info_fraction, ...
        low_info_fraction, ...
        'VariableNames', {'strategy', 'snr_dB', 'info_subcarrier_fraction', ...
        'avg_p_on_info_subcarriers', 'rx_energy_proxy_mean', ...
        'rx_energy_proxy_rms', 'rx_energy_proxy_info_mean', ...
        'info_mi_proxy_mean', 'info_gamma_proxy_mean', ...
        'info_weight_proxy_mean', 'multicarrier_goodput_proxy_sum', ...
        'high_group_info_fraction', 'mid_group_info_fraction', ...
        'low_group_info_fraction'});
end

function v = local_group_info_fraction(Ti, group)
    rows = Ti.reliability_group == group;
    if any(rows)
        v = mean(Ti.carries_info(rows));
    else
        v = nan;
    end
end

function local_plot_strategy_summary(fig_dir, T_summary)
    rows = T_summary.snr_dB == max(T_summary.snr_dB);
    rows = rows & T_summary.strategy ~= "bad_channel_energy_only";
    T = local_order_summary_for_plot(T_summary(rows, :));
    display_labels = local_strategy_display_labels(T.strategy);
    x = categorical(display_labels);
    x = reordercats(x, cellstr(display_labels));

    fig = figure('Color', 'w', 'Position', [80 80 1180 740]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    bar(x, T.rx_energy_proxy_mean);
    grid on; box on;
    ylabel('Mean RX energy proxy', 'Interpreter', 'none');
    title(sprintf('Energy proxy at SNR=%g dB', max(T.snr_dB)), 'Interpreter', 'none');
    set(gca, 'TickLabelInterpreter', 'none');
    xtickangle(25);

    nexttile;
    bar(x, T.info_mi_proxy_mean);
    grid on; box on;
    ylabel('Mean info MI proxy', 'Interpreter', 'none');
    title('Reliability proxy on information subcarriers', 'Interpreter', 'none');
    set(gca, 'TickLabelInterpreter', 'none');
    xtickangle(25);

    nexttile;
    bar(x, T.info_subcarrier_fraction);
    grid on; box on;
    ylim([0 1.05]);
    ylabel('Information subcarrier fraction', 'Interpreter', 'none');
    title('Information resource fraction', 'Interpreter', 'none');
    set(gca, 'TickLabelInterpreter', 'none');
    xtickangle(25);

    nexttile;
    bar(x, T.info_weight_proxy_mean);
    grid on; box on;
    ylabel('Rate-weight proxy', 'Interpreter', 'none');
    title('Info fraction x R total(p) proxy', 'Interpreter', 'none');
    set(gca, 'TickLabelInterpreter', 'none');
    xtickangle(25);

    savefig(fig, fullfile(fig_dir, 'strategy_proxy_summary.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'strategy_proxy_summary.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'strategy_proxy_summary.pdf'), 'ContentType', 'vector');
    close(fig);
end

function T = local_order_summary_for_plot(T)
    preferred = ["uniform_p05", "uniform_p03", "uniform_p01", ...
        "good_channel_information", "good_channel_energy_shaping"];
    order = zeros(height(T), 1);
    for i = 1:height(T)
        idx = find(preferred == T.strategy(i), 1);
        if isempty(idx)
            order(i) = numel(preferred) + i;
        else
            order(i) = idx;
        end
    end
    T.plot_order = order;
    T = sortrows(T, 'plot_order');
    T.plot_order = [];
end

function local_plot_strategy_by_snr(fig_dir, T_summary)
    strategies = unique(T_summary.strategy, 'stable');
    strategies = strategies(strategies ~= "bad_channel_energy_only");
    colors = lines(numel(strategies));

    fig = figure('Color', 'w', 'Position', [80 80 1180 520]);
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    hold on; grid on; box on;
    T_reliability = local_shared_reliability_by_snr(T_summary);
    plot(T_reliability.snr_dB, T_reliability.info_mi_proxy_mean, '-o', ...
        'LineWidth', 1.8, 'Color', [0 0.4470 0.7410], ...
        'DisplayName', 'shared Rayleigh reliability');
    xlabel('Average SNR (dB)', 'Interpreter', 'none');
    ylabel('Mean info MI proxy', 'Interpreter', 'none');
    title('Shared reliability proxy vs SNR', 'Interpreter', 'none');
    set(gca, 'TickLabelInterpreter', 'none');
    legend('Location', 'best', 'Interpreter', 'none');

    nexttile;
    hold on; grid on; box on;
    for i = 1:numel(strategies)
        rows = T_summary.strategy == strategies(i);
        plot(T_summary.snr_dB(rows), T_summary.rx_energy_proxy_mean(rows), '-o', ...
            'LineWidth', 1.4, 'Color', colors(i, :), ...
            'DisplayName', local_strategy_display_label(strategies(i)));
    end
    xlabel('Average SNR (dB)', 'Interpreter', 'none');
    ylabel('Mean RX energy proxy', 'Interpreter', 'none');
    title('Energy proxy vs SNR', 'Interpreter', 'none');
    set(gca, 'TickLabelInterpreter', 'none');
    legend('Location', 'bestoutside', 'Interpreter', 'none');

    savefig(fig, fullfile(fig_dir, 'strategy_proxy_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'strategy_proxy_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'strategy_proxy_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function T_reliability = local_shared_reliability_by_snr(T_summary)
    T_info = T_summary(T_summary.strategy ~= "bad_channel_energy_only", :);
    snr_values = unique(T_info.snr_dB, 'stable');
    mi_values = zeros(numel(snr_values), 1);
    for i = 1:numel(snr_values)
        rows = T_info.snr_dB == snr_values(i);
        mi_values(i) = mean(T_info.info_mi_proxy_mean(rows), 'omitnan');
    end
    T_reliability = table(snr_values, mi_values, ...
        'VariableNames', {'snr_dB', 'info_mi_proxy_mean'});
end

function labels = local_strategy_display_labels(strategy_values)
    labels = strings(size(strategy_values));
    for i = 1:numel(strategy_values)
        labels(i) = string(local_strategy_display_label(strategy_values(i)));
    end
end

function label = local_strategy_display_label(strategy)
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
        otherwise
            label = strrep(char(strategy), '_', ' ');
    end
end

function local_write_readme(out_dir, b2_result_dir, strategy_names, uniform_p_list)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid));

    fprintf(fid, '=== Stage B / B3 Subcarrier Strategy Compare ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/multicarrier/run_subcarrier_strategy_compare.m'');\n\n');
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  Proxy-level strategy comparison using B2 Rayleigh profile outputs.\n');
    fprintf(fid, '  No polar encoding/decoding, no BER Monte Carlo, no final Goodput claim.\n\n');
    fprintf(fid, 'INPUT\n');
    fprintf(fid, '  B2 result directory: %s\n\n', b2_result_dir);
    fprintf(fid, 'STRATEGIES\n');
    for i = 1:numel(strategy_names)
        fprintf(fid, '  %s\n', strategy_names{i});
    end
    fprintf(fid, '\nPARAMETERS\n');
    fprintf(fid, '  uniform_p_list: %s\n', mat2str(uniform_p_list));
    fprintf(fid, '  energy proxy: h_abs2 * (18 - 16p)/10\n');
    fprintf(fid, '  energy RMS proxy: sqrt(mean(rx_energy_proxy.^2))\n');
    fprintf(fid, '  reliability proxy: log2(1 + gamma_k) on information subcarriers\n');
    fprintf(fid, '  multicarrier Goodput proxy sum: number_of_subcarriers * mean(info_weight_proxy)\n');
    fprintf(fid, '  pure-energy low group: carries_info=false, p=0.1 for energy proxy only\n\n');
    fprintf(fid, 'OUTPUTS\n');
    fprintf(fid, '  subcarrier_strategy_assignment.csv\n');
    fprintf(fid, '  subcarrier_strategy_summary.csv\n');
    fprintf(fid, '  subcarrier_strategy_compare.mat\n');
    fprintf(fid, '  run_log.txt\n');
    fprintf(fid, '  figures/strategy_proxy_summary.png/pdf/fig\n');
    fprintf(fid, '  figures/strategy_proxy_vs_snr.png/pdf/fig\n');
end
