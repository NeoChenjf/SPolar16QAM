%% RUN_B4B_FIXED_POLICY_HOLDOUT_ANALYSIS
% Evaluate the frozen B4b codebook on independent Rayleigh realizations.

clear; clc; close all;
script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root); setup_paths();
cfg = config();

training_dir = fullfile(cfg.output_dir, '20260917_215938_b4b_paired_policy_analysis');
holdout_dir = fullfile(cfg.output_dir, '20260917_221105_b4b_fixed_policy_holdout');
ber_limit = 0.1;
goodput_floor = 0.25;

TrainPolicy = readtable(fullfile(training_dir, 'policy_selection.csv'));
TrainSummary = readtable(fullfile(training_dir, 'strategy_summary_with_ci.csv'));
HoldoutSummary = readtable(fullfile(holdout_dir, 'b4b_strategy_summary.csv'));
assert(height(TrainPolicy) == 6, 'Frozen policy must contain six SNR entries.');

rows = cell(height(TrainPolicy), 21);
for i = 1:height(TrainPolicy)
    snr_db = TrainPolicy.snr_dB(i);
    strategy = TrainPolicy.selected_strategy{i};
    tr = TrainSummary(strcmp(TrainSummary.strategy, strategy) & ...
        TrainSummary.snr_dB == snr_db, :);
    va = HoldoutSummary(strcmp(HoldoutSummary.strategy, strategy) & ...
        HoldoutSummary.snr_dB == snr_db, :);
    assert(height(tr) == 1 && height(va) == 1, 'Frozen policy lookup failed.');
    ber_upper = va.ber_mean + va.ber_ci95;
    goodput_lower = va.goodput_cp_mean - va.goodput_cp_ci95;
    gate_required = strcmp(TrainPolicy.selection_reason{i}, 'feasible_max_energy');
    if gate_required
        ber_pass = ber_upper <= ber_limit;
        goodput_pass = goodput_lower >= goodput_floor;
        point_pass = ber_pass && goodput_pass;
    else
        same_snr = HoldoutSummary.snr_dB == snr_db;
        ber_pass = true;
        goodput_pass = true;
        point_pass = abs(va.goodput_cp_mean - ...
            max(HoldoutSummary.goodput_cp_mean(same_snr))) < 1e-12;
    end
    p05 = HoldoutSummary(strcmp(HoldoutSummary.strategy, 'uniform_p05') & ...
        HoldoutSummary.snr_dB == snr_db, :);
    rows(i, :) = {snr_db, strategy, TrainPolicy.selection_reason{i}, ...
        tr.ber_mean, tr.ber_ci95, va.ber_mean, va.ber_ci95, ber_upper, ...
        tr.goodput_mean, tr.goodput_ci95, va.goodput_cp_mean, ...
        va.goodput_cp_ci95, goodput_lower, tr.energy_mean, tr.energy_ci95, ...
        va.rx_signal_power_mean, va.rx_signal_power_ci95, ...
        va.rx_signal_power_mean - p05.rx_signal_power_mean, ...
        gate_required, ber_pass && goodput_pass, point_pass};
end
V = cell2table(rows, 'VariableNames', {'snr_dB', 'selected_strategy', ...
    'frozen_reason', 'train_ber', 'train_ber_ci95', 'holdout_ber', ...
    'holdout_ber_ci95', 'holdout_ber_upper95', 'train_goodput', ...
    'train_goodput_ci95', 'holdout_goodput', 'holdout_goodput_ci95', ...
    'holdout_goodput_lower95', 'train_energy', 'train_energy_ci95', ...
    'holdout_energy', 'holdout_energy_ci95', 'holdout_energy_gain_vs_p05', ...
    'gate_required', 'communication_gate_pass', 'point_pass'});

overall_pass = all(V.point_pass);
status = 'PASS';
if ~overall_pass; status = 'PARTIAL'; end
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') ...
    '_b4b_fixed_policy_holdout_analysis']);
fig_dir = fullfile(out_dir, 'figures'); mkdir(out_dir); mkdir(fig_dir);
writetable(V, fullfile(out_dir, 'fixed_policy_holdout_summary.csv'));
save(fullfile(out_dir, 'fixed_policy_holdout_analysis.mat'), 'V', ...
    'TrainPolicy', 'TrainSummary', 'HoldoutSummary', 'training_dir', ...
    'holdout_dir', 'ber_limit', 'goodput_floor', 'overall_pass', 'status');

fig = figure('Color', 'w', 'Position', [60 60 1100 900]);
fields_train = {'train_ber', 'train_goodput', 'train_energy'};
fields_holdout = {'holdout_ber', 'holdout_goodput', 'holdout_energy'};
ci_train = {'train_ber_ci95', 'train_goodput_ci95', 'train_energy_ci95'};
ci_holdout = {'holdout_ber_ci95', 'holdout_goodput_ci95', 'holdout_energy_ci95'};
ylabels = {'BER', 'Goodput', 'Receive energy'};
for j = 1:3
    subplot(3, 1, j); hold on; grid on; box on;
    errorbar(V.snr_dB, V.(fields_train{j}), V.(ci_train{j}), '-o', ...
        'DisplayName', 'training');
    errorbar(V.snr_dB, V.(fields_holdout{j}), V.(ci_holdout{j}), '-s', ...
        'DisplayName', 'independent holdout');
    ylabel(ylabels{j});
    if j == 1; title('Frozen codebook: training versus independent holdout'); end
    if j == 3; xlabel('Average SNR (dB)'); end
end
legend('Location', 'bestoutside');
local_save(fig, fig_dir, 'b4b_fixed_policy_train_vs_holdout');

fig = figure('Color', 'w', 'Position', [80 80 1000 620]);
subplot(2, 1, 1); hold on; grid on; box on;
plot(V.snr_dB, V.holdout_ber_upper95, '-o', 'LineWidth', 1.4);
yline(ber_limit, '--r', 'BER upper limit');
ylabel('Holdout BER upper 95%'); title('Frozen communication-gate margins');
subplot(2, 1, 2); hold on; grid on; box on;
plot(V.snr_dB, V.holdout_goodput_lower95, '-o', 'LineWidth', 1.4);
yline(goodput_floor, '--r', 'Goodput lower limit');
xlabel('Average SNR (dB)'); ylabel('Holdout Goodput lower 95%');
local_save(fig, fig_dir, 'b4b_fixed_policy_gate_margins');

fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
assert(fid >= 0, 'Cannot create holdout README.');
cleanup_fid = onCleanup(@() fclose(fid));
fprintf(fid, 'B4b FROZEN CODEBOOK INDEPENDENT HOLDOUT\n\n');
fprintf(fid, 'Training analysis: %s\nHoldout formal result: %s\n', training_dir, holdout_dir);
fprintf(fid, 'Frozen rule: 20 dB uniform_p05; 24-40 dB uniform_p01.\n');
fprintf(fid, 'Limits: BER upper95 <= %.6g; Goodput lower95 >= %.6g.\n', ...
    ber_limit, goodput_floor);
fprintf(fid, 'Overall status: %s\n', status);
fprintf(fid, 'Failed SNRs: %s\n', mat2str(V.snr_dB(~V.point_pass).'));
fprintf(fid, 'No policy retuning was performed on holdout data.\n');
fprintf(fid, 'Energy remains a pre-noise receive-signal proxy, not RF-DC efficiency.\n');

fprintf('Frozen policy holdout analysis: %s (%s)\n', out_dir, status);

function local_save(fig, fig_dir, name)
    savefig(fig, fullfile(fig_dir, [name '.fig']));
    exportgraphics(fig, fullfile(fig_dir, [name '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, [name '.pdf']), 'ContentType', 'vector');
    close(fig);
end
