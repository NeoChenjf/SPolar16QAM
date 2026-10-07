%% RUN_B4B_ENERGY_BY_STRATEGY_FIGURE
% Collapse the SNR dimension and compare receive energy by strategy.

clear; clc; close all;
script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root); setup_paths();
cfg = config();

source_dir = fullfile(cfg.output_dir, ...
    '20260917_210504_b4_strict_ofdm_rayleigh_formal');
T = readtable(fullfile(source_dir, 'b4b_repetition_results.csv'));
strategies = unique(string(T.strategy), 'stable');
realizations = unique(T.realization).';
expected_snr = unique(T.snr_dB).';

detail_rows = cell(numel(strategies) * numel(realizations), 4);
summary_rows = cell(numel(strategies), 6);
row = 0;
for is = 1:numel(strategies)
    strategy = strategies(is);
    values = zeros(numel(realizations), 1);
    for ir = 1:numel(realizations)
        idx = string(T.strategy) == strategy & T.realization == realizations(ir);
        Ti = T(idx, :);
        assert(isequal(sort(Ti.snr_dB).', expected_snr), ...
            'Incomplete SNR coverage for %s realization %d.', strategy, realizations(ir));
        values(ir) = mean(Ti.rx_signal_power_pre_noise);
        row = row + 1;
        detail_rows(row, :) = {char(strategy), realizations(ir), ...
            height(Ti), values(ir)};
    end
    mu = mean(values);
    ci95 = 1.96 * std(values, 0) / sqrt(numel(values));
    summary_rows(is, :) = {char(strategy), numel(values), mu, ci95, ...
        mu-ci95, mu+ci95};
end

D = cell2table(detail_rows, 'VariableNames', {'strategy', 'realization', ...
    'num_snr_points', 'energy_mean_across_snr'});
S = cell2table(summary_rows, 'VariableNames', {'strategy', ...
    'num_realizations', 'energy_mean', 'energy_ci95', 'ci_low', 'ci_high'});

out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') ...
    '_b4b_energy_by_strategy']);
fig_dir = fullfile(out_dir, 'figures'); mkdir(out_dir); mkdir(fig_dir);
writetable(D, fullfile(out_dir, 'energy_by_strategy_realization.csv'));
writetable(S, fullfile(out_dir, 'energy_by_strategy_summary.csv'));
save(fullfile(out_dir, 'energy_by_strategy.mat'), 'D', 'S', 'source_dir', ...
    'expected_snr');

[~, order] = sort(S.energy_mean, 'ascend');
Splot = S(order, :);
fig = figure('Color', 'w', 'Position', [80 80 1100 620]);
bar(1:height(Splot), Splot.energy_mean, 0.68, ...
    'FaceColor', [0.25 0.55 0.82]);
hold on; grid on; box on;
errorbar(1:height(Splot), Splot.energy_mean, Splot.energy_ci95, ...
    'k.', 'LineWidth', 1.4, 'CapSize', 12);
xticks(1:height(Splot));
xticklabels(cellfun(@local_label, Splot.strategy, 'UniformOutput', false));
xtickangle(18);
ylabel('Pre-noise received signal power');
xlabel('Subcarrier allocation / shaping strategy');
title('Receive-energy proxy by strategy (30 Rayleigh realizations)');
ylim([0, max(Splot.ci_high) * 1.12]);
savefig(fig, fullfile(fig_dir, 'b4b_energy_by_strategy.fig'));
exportgraphics(fig, fullfile(fig_dir, 'b4b_energy_by_strategy.png'), ...
    'Resolution', 300);
exportgraphics(fig, fullfile(fig_dir, 'b4b_energy_by_strategy.pdf'), ...
    'ContentType', 'vector');
close(fig);

fid = fopen(fullfile(out_dir, 'README.txt'), 'w'); assert(fid >= 0);
cleanup_fid = onCleanup(@() fclose(fid));
fprintf(fid, 'B4b RECEIVE ENERGY BY STRATEGY\n\n');
fprintf(fid, 'Source: %s\n', source_dir);
fprintf(fid, 'The SNR dimension is removed before inference.\n');
fprintf(fid, 'For each strategy and Rayleigh realization, energy is first averaged across %d SNR points.\n', ...
    numel(expected_snr));
fprintf(fid, 'The plotted mean and 95%% interval use the resulting %d independent realization-level values.\n', ...
    numel(realizations));
fprintf(fid, 'Metric: pre-noise receive-signal time-domain mean square; not RF-DC efficiency.\n');
fprintf('Energy-by-strategy figure saved to %s\n', out_dir);

function label = local_label(strategy)
    label = strrep(char(strategy), '_', ' ');
end
