%% RUN_B4B_PAIRED_POLICY_ANALYSIS
% Paired inference and low-complexity codebook selection for B4b formal data.

clearvars -except b4b_analysis_overrides; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg = config();
source_result_dir = fullfile(cfg.output_dir, ...
    '20260917_210504_b4_strict_ofdm_rayleigh_formal');
reference_strategy = 'uniform_p05';
ber_limit = 0.1;
goodput_floor = 0.25;
result_tag = 'b4b_paired_policy_analysis';
if exist('b4b_analysis_overrides', 'var')
    if isfield(b4b_analysis_overrides, 'source_result_dir')
        source_result_dir = b4b_analysis_overrides.source_result_dir;
    end
    if isfield(b4b_analysis_overrides, 'reference_strategy')
        reference_strategy = b4b_analysis_overrides.reference_strategy;
    end
    if isfield(b4b_analysis_overrides, 'ber_limit')
        ber_limit = b4b_analysis_overrides.ber_limit;
    end
    if isfield(b4b_analysis_overrides, 'goodput_floor')
        goodput_floor = b4b_analysis_overrides.goodput_floor;
    end
    if isfield(b4b_analysis_overrides, 'result_tag')
        result_tag = b4b_analysis_overrides.result_tag;
    end
end
validateattributes(ber_limit, {'numeric'}, {'scalar', 'real', 'finite', '>=', 0, '<=', 1});
validateattributes(goodput_floor, {'numeric'}, {'scalar', 'real', 'finite', '>=', 0});

source_csv = fullfile(source_result_dir, 'b4b_repetition_results.csv');
assert(exist(source_csv, 'file') == 2, 'Missing formal repetition table: %s', source_csv);
T = readtable(source_csv);
required = {'strategy', 'realization', 'snr_dB', 'ber', ...
    'goodput_cp_corrected', 'rx_signal_power_pre_noise'};
assert(all(ismember(required, T.Properties.VariableNames)), ...
    'Formal repetition table does not satisfy the analysis contract.');
assert(any(strcmp(T.strategy, reference_strategy)), ...
    'Reference strategy is absent: %s', reference_strategy);

out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' result_tag]);
fig_dir = fullfile(out_dir, 'figures');
mkdir(out_dir); mkdir(fig_dir);
diary(fullfile(out_dir, 'run_log.txt')); diary on;
cleanup_diary = onCleanup(@() diary('off'));

strategies = unique(string(T.strategy), 'stable');
snr_grid = unique(T.snr_dB).';
metrics = {'ber', 'goodput_cp_corrected', 'rx_signal_power_pre_noise'};
paired_rows = cell((numel(strategies) - 1) * numel(snr_grid) * numel(metrics), 12);
row = 0;
for is = 1:numel(snr_grid)
    snr_db = snr_grid(is);
    Tref = sortrows(T(strcmp(T.strategy, reference_strategy) & T.snr_dB == snr_db, :), ...
        'realization');
    for istr = 1:numel(strategies)
        candidate = strategies(istr);
        if candidate == string(reference_strategy); continue; end
        Tcand = sortrows(T(string(T.strategy) == candidate & T.snr_dB == snr_db, :), ...
            'realization');
        assert(isequal(Tref.realization, Tcand.realization), ...
            'Pairing key mismatch for %s at %g dB.', candidate, snr_db);
        for im = 1:numel(metrics)
            metric = metrics{im};
            delta = Tcand.(metric) - Tref.(metric);
            [delta_mean, delta_ci95, p_sign] = local_paired_summary(delta);
            row = row + 1;
            paired_rows(row, :) = {char(candidate), reference_strategy, snr_db, metric, ...
                numel(delta), delta_mean, delta_ci95, delta_mean-delta_ci95, ...
                delta_mean+delta_ci95, mean(delta > 0), mean(delta < 0), p_sign};
        end
    end
end
P = cell2table(paired_rows, 'VariableNames', {'candidate_strategy', ...
    'reference_strategy', 'snr_dB', 'metric', 'num_pairs', 'delta_mean', ...
    'delta_ci95', 'ci_low', 'ci_high', 'positive_fraction', ...
    'negative_fraction', 'two_sided_sign_p'});

S = local_strategy_summary(T);
[Policy, Pareto] = local_select_policy(S, ber_limit, goodput_floor);

writetable(P, fullfile(out_dir, 'paired_differences.csv'));
writetable(S, fullfile(out_dir, 'strategy_summary_with_ci.csv'));
writetable(Policy, fullfile(out_dir, 'policy_selection.csv'));
writetable(Pareto, fullfile(out_dir, 'pareto_points.csv'));
save(fullfile(out_dir, 'b4b_paired_policy_analysis.mat'), 'T', 'P', 'S', ...
    'Policy', 'Pareto', 'source_result_dir', 'reference_strategy', ...
    'ber_limit', 'goodput_floor');

local_plot_paired(fig_dir, P, strategies, reference_strategy);
local_plot_formal_ci(fig_dir, S, strategies);
local_plot_policy(fig_dir, Policy, strategies);
local_plot_tradeoff(fig_dir, S, Pareto, strategies);
local_write_readme(out_dir, source_result_dir, reference_strategy, ...
    ber_limit, goodput_floor, height(T), height(P), height(Policy));

fprintf('B4b paired policy analysis complete: %s\n', out_dir);

function [mu, ci95, p_sign] = local_paired_summary(delta)
    delta = delta(isfinite(delta));
    n = numel(delta);
    assert(n >= 2, 'Paired inference requires at least two finite pairs.');
    mu = mean(delta);
    ci95 = 1.96 * std(delta, 0) / sqrt(n);
    nonzero = delta(delta ~= 0);
    k = min(sum(nonzero > 0), sum(nonzero < 0));
    n_nonzero = numel(nonzero);
    if n_nonzero == 0
        p_sign = 1;
    else
        p_sign = min(1, 2 * local_binomial_cdf(k, n_nonzero));
    end
end

function p = local_binomial_cdf(k, n)
    terms = zeros(k + 1, 1);
    for i = 0:k
        terms(i + 1) = nchoosek(n, i) * 0.5^n;
    end
    p = sum(terms);
end

function S = local_strategy_summary(T)
    keys = unique(T(:, {'strategy', 'snr_dB'}), 'rows');
    rows = cell(height(keys), 14);
    for i = 1:height(keys)
        idx = strcmp(T.strategy, keys.strategy{i}) & T.snr_dB == keys.snr_dB(i);
        Ti = T(idx, :);
        [ber_mean, ber_ci] = local_mean_ci(Ti.ber);
        [goodput_mean, goodput_ci] = local_mean_ci(Ti.goodput_cp_corrected);
        [energy_mean, energy_ci] = local_mean_ci(Ti.rx_signal_power_pre_noise);
        rows(i, :) = {keys.strategy{i}, keys.snr_dB(i), height(Ti), ...
            ber_mean, ber_ci, ber_mean-ber_ci, ber_mean+ber_ci, ...
            goodput_mean, goodput_ci, energy_mean, energy_ci, ...
            mean(Ti.info_subcarrier_fraction), sum(Ti.error_count), sum(Ti.info_bits)};
    end
    S = cell2table(rows, 'VariableNames', {'strategy', 'snr_dB', 'num_repetitions', ...
        'ber_mean', 'ber_ci95', 'ber_ci_low', 'ber_ci_high', ...
        'goodput_mean', 'goodput_ci95', 'energy_mean', 'energy_ci95', ...
        'info_subcarrier_fraction', 'error_count_total', 'info_bits_total'});
    S.ber_ci_low = max(0, S.ber_ci_low);
end

function [mu, ci95] = local_mean_ci(x)
    x = x(isfinite(x));
    mu = mean(x);
    ci95 = 1.96 * std(x, 0) / sqrt(numel(x));
end

function [Policy, Pareto] = local_select_policy(S, ber_limit, goodput_floor)
    snr_grid = unique(S.snr_dB).';
    policy_rows = cell(numel(snr_grid), 10);
    pareto_rows = cell(0, 7);
    for is = 1:numel(snr_grid)
        snr_db = snr_grid(is);
        Si = S(S.snr_dB == snr_db, :);
        feasible = Si.ber_ci_high <= ber_limit & ...
            (Si.goodput_mean - Si.goodput_ci95) >= goodput_floor;
        if any(feasible)
            candidates = find(feasible);
            [~, local_index] = max(Si.energy_mean(candidates));
            selected = candidates(local_index);
            reason = 'feasible_max_energy';
        else
            [~, selected] = max(Si.goodput_mean);
            reason = 'fallback_max_goodput';
        end
        policy_rows(is, :) = {snr_db, Si.strategy{selected}, reason, ...
            Si.ber_mean(selected), Si.ber_ci95(selected), ...
            Si.goodput_mean(selected), Si.goodput_ci95(selected), ...
            Si.energy_mean(selected), Si.energy_ci95(selected), sum(feasible)};

        dominated = false(height(Si), 1);
        for i = 1:height(Si)
            for j = 1:height(Si)
                no_worse = Si.ber_mean(j) <= Si.ber_mean(i) && ...
                    Si.goodput_mean(j) >= Si.goodput_mean(i) && ...
                    Si.energy_mean(j) >= Si.energy_mean(i);
                strictly_better = Si.ber_mean(j) < Si.ber_mean(i) || ...
                    Si.goodput_mean(j) > Si.goodput_mean(i) || ...
                    Si.energy_mean(j) > Si.energy_mean(i);
                if no_worse && strictly_better
                    dominated(i) = true;
                    break;
                end
            end
        end
        keep = find(~dominated);
        for ik = 1:numel(keep)
            i = keep(ik);
            pareto_rows(end+1, :) = {snr_db, Si.strategy{i}, Si.ber_mean(i), ...
                Si.goodput_mean(i), Si.energy_mean(i), Si.ber_ci95(i), ...
                Si.goodput_ci95(i)}; %#ok<AGROW> bounded by 6 strategies x 6 SNRs
        end
    end
    Policy = cell2table(policy_rows, 'VariableNames', {'snr_dB', ...
        'selected_strategy', 'selection_reason', 'ber_mean', 'ber_ci95', ...
        'goodput_mean', 'goodput_ci95', 'energy_mean', 'energy_ci95', ...
        'num_feasible_strategies'});
    Pareto = cell2table(pareto_rows, 'VariableNames', {'snr_dB', 'strategy', ...
        'ber_mean', 'goodput_mean', 'energy_mean', 'ber_ci95', 'goodput_ci95'});
end

function local_plot_paired(fig_dir, P, strategies, reference)
    metrics = {'ber', 'goodput_cp_corrected', 'rx_signal_power_pre_noise'};
    ylabels = {'Paired BER difference', 'Paired Goodput difference', ...
        'Paired receive-energy difference'};
    fig = figure('Color', 'w', 'Position', [60 60 1100 900]);
    colors = lines(numel(strategies));
    for im = 1:3
        subplot(3, 1, im); hold on; grid on; box on;
        for istr = 1:numel(strategies)
            candidate = strategies(istr);
            if candidate == string(reference); continue; end
            idx = strcmp(P.candidate_strategy, candidate) & strcmp(P.metric, metrics{im});
            errorbar(P.snr_dB(idx), P.delta_mean(idx), P.delta_ci95(idx), '-o', ...
                'Color', colors(istr, :), 'DisplayName', local_label(candidate));
        end
        yline(0, '--k', 'HandleVisibility', 'off'); ylabel(ylabels{im});
        if im == 1; title(['Paired differences relative to ' local_label(reference)]); end
        if im == 3; xlabel('Average SNR (dB)'); end
    end
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    local_save(fig, fig_dir, 'b4b_paired_differences');
end

function local_plot_formal_ci(fig_dir, S, strategies)
    colors = lines(numel(strategies));
    fig = figure('Color', 'w', 'Position', [60 60 1100 900]);
    fields = {'ber_mean', 'goodput_mean', 'energy_mean'};
    cis = {'ber_ci95', 'goodput_ci95', 'energy_ci95'};
    ylabels = {'BER', 'CP/padding-corrected Goodput', 'Pre-noise receive energy'};
    for im = 1:3
        subplot(3, 1, im); hold on; grid on; box on;
        for istr = 1:numel(strategies)
            idx = string(S.strategy) == strategies(istr);
            y = S.(fields{im})(idx);
            e = S.(cis{im})(idx);
            if im == 1
                y(y <= 0) = nan; e(~isfinite(y)) = nan;
            end
            errorbar(S.snr_dB(idx), y, e, '-o', 'Color', colors(istr, :), ...
                'DisplayName', local_label(strategies(istr)));
        end
        if im == 1; set(gca, 'YScale', 'log'); title('Formal means with 95% intervals'); end
        ylabel(ylabels{im});
        if im == 3; xlabel('Average SNR (dB)'); end
    end
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    local_save(fig, fig_dir, 'b4b_formal_metrics_with_ci');
end

function local_plot_policy(fig_dir, Policy, strategies)
    selected = strings(height(Policy), 1);
    for i = 1:height(Policy); selected(i) = string(Policy.selected_strategy{i}); end
    indices = zeros(size(selected));
    for i = 1:numel(strategies); indices(selected == strategies(i)) = i; end
    fig = figure('Color', 'w', 'Position', [80 80 950 560]);
    stairs(Policy.snr_dB, indices, '-o', 'LineWidth', 1.5); grid on; box on;
    yticks(1:numel(strategies)); yticklabels(cellfun(@local_label, cellstr(strategies), ...
        'UniformOutput', false));
    xlabel('Average SNR (dB)'); ylabel('Selected codebook policy');
    title('Low-complexity constrained codebook selection');
    local_save(fig, fig_dir, 'b4b_low_complexity_policy');
end

function local_plot_tradeoff(fig_dir, S, Pareto, strategies)
    snr_grid = unique(S.snr_dB).';
    colors = lines(numel(strategies));
    fig = figure('Color', 'w', 'Position', [40 40 1250 720]);
    for is = 1:numel(snr_grid)
        subplot(2, 3, is); hold on; grid on; box on;
        Si = S(S.snr_dB == snr_grid(is), :);
        Pi = Pareto(Pareto.snr_dB == snr_grid(is), :);
        for istr = 1:numel(strategies)
            idx = string(Si.strategy) == strategies(istr);
            scatter(Si.energy_mean(idx), Si.goodput_mean(idx), 55, ...
                colors(istr, :), 'filled', ...
                'DisplayName', local_label(strategies(istr)));
        end
        scatter(Pi.energy_mean, Pi.goodput_mean, 160, 'ko', ...
            'LineWidth', 1.7, 'DisplayName', 'Nondominated (black ring)');
        title(sprintf('%g dB', snr_grid(is)));
        xlabel('Receive energy'); ylabel('Goodput');
        if is == 1
            legend('Location', 'southoutside', 'Interpreter', 'none');
        end
    end
    sgtitle('Goodput-energy tradeoff; black rings are 3-objective nondominated points');
    local_save(fig, fig_dir, 'b4b_tradeoff_pareto_by_snr');
end

function local_save(fig, fig_dir, name)
    savefig(fig, fullfile(fig_dir, [name '.fig']));
    exportgraphics(fig, fullfile(fig_dir, [name '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, [name '.pdf']), 'ContentType', 'vector');
    close(fig);
end

function label = local_label(strategy)
    label = strrep(char(strategy), '_', ' ');
end

function local_write_readme(out_dir, source_dir, reference, ber_limit, ...
        goodput_floor, raw_rows, paired_rows, policy_rows)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    assert(fid >= 0, 'Cannot create analysis README.');
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, 'B4b FORMAL PAIRED STATISTICS AND LOW-COMPLEXITY POLICY\n\n');
    fprintf(fid, 'Source formal result: %s\n', source_dir);
    fprintf(fid, 'Reference strategy: %s\n', reference);
    fprintf(fid, 'Raw repetition rows: %d\nPaired rows: %d\nPolicy rows: %d\n\n', ...
        raw_rows, paired_rows, policy_rows);
    fprintf(fid, 'PAIRING\nSame realization and SNR; candidate minus reference.\n');
    fprintf(fid, '95%% interval: 1.96 * sample SD of paired differences / sqrt(n).\n');
    fprintf(fid, 'Two-sided sign-test p-value is also saved as a distribution-free direction check.\n\n');
    fprintf(fid, 'POLICY\nBER upper interval <= %.6g and Goodput lower interval >= %.6g.\n', ...
        ber_limit, goodput_floor);
    fprintf(fid, 'Among feasible codebook entries, maximize pre-noise receive energy.\n');
    fprintf(fid, 'If none is feasible, fall back to maximum mean Goodput.\n');
    fprintf(fid, 'Online complexity: channel ranking O(Nsc log Nsc), codebook scan O(6).\n');
    fprintf(fid, 'Signaling: one of six policy indices, requiring ceil(log2(6)) = 3 bits/update.\n\n');
    fprintf(fid, 'LIMITS\nOffline selection on the same formal corpus is descriptive, not held-out proof.\n');
    fprintf(fid, 'Energy is a receive-signal proxy, not RF-DC conversion efficiency.\n');
end
