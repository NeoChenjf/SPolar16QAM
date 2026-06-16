%% RUN_SINGLECARRIER_SC_CLOSURE
% 轻量单载波 SC full-chain 闭环实验。
%
% 目的：
%   将 code-only 编码侧结论接回完整 16QAM full-chain，
%   对比 p 改变后的 BER / Goodput / Energy 权衡。

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg_base = config();

%% ===== 固定闭环口径 =====
p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
snr_grid = [0, 5, 10, 15, 20];

cfg_local = cfg_base;
cfg_local.decoder = 'SC';
cfg_local.snr_mode = 'fixed_esn0';
cfg_local.num_frames = 100;
cfg_local.seed = 42;
cfg_local.p_candidates = p_list;
cfg_local.SNR_dB = snr_grid;

rng(cfg_local.seed, 'twister');

out_dir = fullfile(cfg_local.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_singlecarrier_sc_closure']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

log_file = fullfile(out_dir, 'run_log.txt');
diary(log_file);
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Single-Carrier SC Closure ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('Decoder: %s\n', cfg_local.decoder);
fprintf('SNR mode: %s\n', cfg_local.snr_mode);
fprintf('p_list: %s\n', mat2str(p_list));
fprintf('snr_grid: %s\n', mat2str(snr_grid));
fprintf('num_frames: %d\n', cfg_local.num_frames);
fprintf('seed: %d\n', cfg_local.seed);

%% ===== 运行 full-chain 仿真 =====
nP = numel(p_list);
nS = numel(snr_grid);
all_results = cell(nP, 1);

BER_matrix = nan(nP, nS);
Goodput_matrix = nan(nP, nS);
MI_matrix = nan(nP, nS);
E_theory_vec = nan(nP, 1);
E_norm_vec = nan(nP, 1);
R_total_vec = nan(nP, 1);
K_matrix = nan(nP, 4);

tic;
for ip = 1:nP
    p = p_list(ip);
    fprintf('\n--- Full-chain p=%.2f (%d/%d) ---\n', p, ip, nP);
    all_results{ip} = sim_shaped_polar_16qam(p, snr_grid, cfg_local);

    r = all_results{ip};
    G = compute_goodput(r);
    E = compute_energy(p, cfg_local);

    BER_matrix(ip, :) = r.BER;
    Goodput_matrix(ip, :) = G;
    MI_matrix(ip, :) = r.MI_total;
    E_theory_vec(ip) = E;
    E_norm_vec(ip) = E / cfg_local.E_baseline;
    R_total_vec(ip) = r.R_total;
    K_matrix(ip, :) = r.K;
end
elapsed = toc;
fprintf('\nElapsed: %.1f sec (%.2f min)\n', elapsed, elapsed / 60);

%% ===== 输出 full-chain 明细 CSV =====
p_col = repelem(p_list(:), nS);
snr_col = repmat(snr_grid(:), nP, 1);
BER_col = reshape(BER_matrix.', [], 1);
Goodput_col = reshape(Goodput_matrix.', [], 1);
MI_col = reshape(MI_matrix.', [], 1);
R_col = repelem(R_total_vec, nS);
E_col = repelem(E_theory_vec, nS);
E_norm_col = repelem(E_norm_vec, nS);

T_full = table(p_col, snr_col, BER_col, Goodput_col, MI_col, R_col, E_col, E_norm_col, ...
    'VariableNames', {'p', 'snr_dB', 'BER', 'Goodput', 'MI_total', 'R_total', 'E_theory', 'E_norm'});
writetable(T_full, fullfile(out_dir, 'fullchain_sc_closure.csv'));

save(fullfile(out_dir, 'fullchain_sc_closure.mat'), ...
    'cfg_local', 'p_list', 'snr_grid', 'all_results', ...
    'BER_matrix', 'Goodput_matrix', 'MI_matrix', ...
    'E_theory_vec', 'E_norm_vec', 'R_total_vec', 'K_matrix', 'elapsed');

%% ===== 机制对比表：full-chain vs code-only =====
codeonly_file = fullfile(v2_root, 'results', '20260520_180719_sc_waterfall_refine', 'local_waterfall_summary.csv');
has_codeonly = exist(codeonly_file, 'file') == 2;
if has_codeonly
    T_code = readtable(codeonly_file);
else
    T_code = table();
end

idx_baseline = find(abs(p_list - 0.5) < 1e-12, 1);
if isempty(idx_baseline)
    error('p_list must include p=0.5 baseline.');
end

[best_goodput, idx_best_snr] = max(Goodput_matrix, [], 2);
selected_snr = snr_grid(idx_best_snr).';
selected_BER = nan(nP, 1);
selected_MI = nan(nP, 1);
for ip = 1:nP
    selected_BER(ip) = BER_matrix(ip, idx_best_snr(ip));
    selected_MI(ip) = MI_matrix(ip, idx_best_snr(ip));
end

baseline_goodput_at_best_snr = nan(nP, 1);
baseline_BER_at_best_snr = nan(nP, 1);
for ip = 1:nP
    baseline_goodput_at_best_snr(ip) = Goodput_matrix(idx_baseline, idx_best_snr(ip));
    baseline_BER_at_best_snr(ip) = BER_matrix(idx_baseline, idx_best_snr(ip));
end

delta_goodput_vs_p05 = best_goodput - baseline_goodput_at_best_snr;
delta_BER_vs_p05 = selected_BER - baseline_BER_at_best_snr;

codeonly_selected_snr = nan(nP, 1);
codeonly_BER = nan(nP, 1);
codeonly_gap = nan(nP, 1);
if has_codeonly
    for ip = 1:nP
        idx_code = find(abs(T_code.p - p_list(ip)) < 1e-12, 1);
        if ~isempty(idx_code)
            codeonly_selected_snr(ip) = T_code.selected_snr_dB(idx_code);
            codeonly_BER(ip) = T_code.ber_sim_mean(idx_code);
            codeonly_gap(ip) = T_code.gap(idx_code);
        end
    end
end

mechanism_label = strings(nP, 1);
for ip = 1:nP
    if ip == idx_baseline
        mechanism_label(ip) = "baseline";
    elseif delta_goodput_vs_p05(ip) > 0 && delta_BER_vs_p05(ip) <= 0
        mechanism_label(ip) = "geometry_gain_offsets_code_loss";
    elseif delta_goodput_vs_p05(ip) > 0
        mechanism_label(ip) = "goodput_gain_with_ber_cost";
    elseif delta_goodput_vs_p05(ip) <= 0 && delta_BER_vs_p05(ip) > 0
        mechanism_label(ip) = "code_loss_dominates";
    else
        mechanism_label(ip) = "no_fullchain_gain";
    end
end

T_mech = table(p_list(:), selected_snr, selected_BER, best_goodput, selected_MI, ...
    E_theory_vec, E_norm_vec, baseline_BER_at_best_snr, baseline_goodput_at_best_snr, ...
    delta_BER_vs_p05, delta_goodput_vs_p05, codeonly_selected_snr, codeonly_BER, codeonly_gap, mechanism_label, ...
    'VariableNames', {'p', 'fullchain_best_snr_dB', 'fullchain_BER_at_best_goodput', ...
    'fullchain_best_goodput', 'fullchain_MI_at_best_goodput', 'E_theory', 'E_norm', ...
    'p05_BER_at_same_snr', 'p05_Goodput_at_same_snr', 'delta_BER_vs_p05', ...
    'delta_Goodput_vs_p05', 'codeonly_selected_snr_dB', 'codeonly_BER_sim_mean', ...
    'codeonly_gap', 'mechanism_label'});
writetable(T_mech, fullfile(out_dir, 'mechanism_comparison.csv'));

%% ===== 图表 =====
colors = lines(nP);

fig1 = figure('Color', 'w', 'Position', [80 80 900 620]);
hold on; grid on; box on;
for ip = 1:nP
    semilogy(snr_grid, BER_matrix(ip, :), '-o', ...
        'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', sprintf('p=%.1f', p_list(ip)));
end
xlabel('SNR (dB)');
ylabel('BER');
title('Full-chain SC BER vs SNR');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig1, fullfile(fig_dir, 'fullchain_ber_vs_snr.fig'));
exportgraphics(fig1, fullfile(fig_dir, 'fullchain_ber_vs_snr.png'), 'Resolution', 300);
exportgraphics(fig1, fullfile(fig_dir, 'fullchain_ber_vs_snr.pdf'), 'ContentType', 'vector');
close(fig1);

fig2 = figure('Color', 'w', 'Position', [80 80 900 620]);
hold on; grid on; box on;
for ip = 1:nP
    plot(snr_grid, Goodput_matrix(ip, :), '-o', ...
        'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', sprintf('p=%.1f', p_list(ip)));
end
xlabel('SNR (dB)');
ylabel('Goodput');
title('Full-chain SC Goodput vs SNR');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig2, fullfile(fig_dir, 'fullchain_goodput_vs_snr.fig'));
exportgraphics(fig2, fullfile(fig_dir, 'fullchain_goodput_vs_snr.png'), 'Resolution', 300);
exportgraphics(fig2, fullfile(fig_dir, 'fullchain_goodput_vs_snr.pdf'), 'ContentType', 'vector');
close(fig2);

fig3 = figure('Color', 'w', 'Position', [80 80 900 620]);
hold on; grid on; box on;
snr_targets = snr_grid;
target_colors = lines(numel(snr_targets));
for is = 1:numel(snr_targets)
    plot(E_norm_vec, Goodput_matrix(:, is), '-o', ...
        'Color', target_colors(is, :), 'LineWidth', 1.4, 'MarkerSize', 5, ...
        'DisplayName', sprintf('SNR=%g dB', snr_targets(is)));
end
xlabel('Normalized energy E/E_0');
ylabel('Goodput');
title('Full-chain SC Goodput-Energy Pareto View');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig3, fullfile(fig_dir, 'goodput_energy_pareto.fig'));
exportgraphics(fig3, fullfile(fig_dir, 'goodput_energy_pareto.png'), 'Resolution', 300);
exportgraphics(fig3, fullfile(fig_dir, 'goodput_energy_pareto.pdf'), 'ContentType', 'vector');
close(fig3);

fig4 = figure('Color', 'w', 'Position', [80 80 980 620]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
x_pos = 1:nP;
x_labels = compose('%.1f', p_list);
nexttile;
bar(x_pos, delta_goodput_vs_p05);
grid on; box on;
xticks(x_pos);
xticklabels(x_labels);
xlabel('p');
ylabel('\Delta Goodput vs p=0.5');
title('Full-chain Goodput Difference');
nexttile;
yyaxis left;
bar(x_pos, codeonly_BER);
ylabel('Code-only BER');
yyaxis right;
plot(x_pos, selected_BER, '-o', 'LineWidth', 1.5);
ylabel('Full-chain BER at best Goodput');
grid on; box on;
xticks(x_pos);
xticklabels(x_labels);
xlabel('p');
title('Code-only Loss vs Full-chain BER');
savefig(fig4, fullfile(fig_dir, 'mechanism_summary.fig'));
exportgraphics(fig4, fullfile(fig_dir, 'mechanism_summary.png'), 'Resolution', 300);
exportgraphics(fig4, fullfile(fig_dir, 'mechanism_summary.pdf'), 'ContentType', 'vector');
close(fig4);

%% ===== README =====
best_idx_global = find(T_mech.fullchain_best_goodput == max(T_mech.fullchain_best_goodput), 1);

fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
if fid < 0
    error('Cannot create README.txt in %s', out_dir);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, '=== Single-Carrier SC Closure ===\n\n');
fprintf(fid, 'RUN COMMAND\n');
fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/singlecarrier/run_singlecarrier_sc_closure.m'');\n\n');
fprintf(fid, 'SCOPE\n');
fprintf(fid, '  Full-chain: sim_shaped_polar_16qam (16QAM + polar encoder/decoder + AWGN).\n');
fprintf(fid, '  Decoder: %s\n', cfg_local.decoder);
fprintf(fid, '  SNR mode: %s\n', cfg_local.snr_mode);
fprintf(fid, '  p_list: %s\n', mat2str(p_list));
fprintf(fid, '  snr_grid: %s\n', mat2str(snr_grid));
fprintf(fid, '  num_frames: %d\n', cfg_local.num_frames);
fprintf(fid, '  seed: %d\n\n', cfg_local.seed);
fprintf(fid, 'CODE-ONLY COMPARISON\n');
if has_codeonly
    fprintf(fid, '  Loaded: %s\n\n', codeonly_file);
else
    fprintf(fid, '  code-only comparison unavailable: %s not found\n\n', codeonly_file);
end
fprintf(fid, 'SUMMARY\n');
fprintf(fid, '  Best full-chain Goodput: p=%.2f, SNR=%.1f dB, Goodput=%.6f, BER=%.6e, E_norm=%.3f\n\n', ...
    T_mech.p(best_idx_global), T_mech.fullchain_best_snr_dB(best_idx_global), ...
    T_mech.fullchain_best_goodput(best_idx_global), ...
    T_mech.fullchain_BER_at_best_goodput(best_idx_global), ...
    T_mech.E_norm(best_idx_global));
fprintf(fid, 'MECHANISM TABLE\n');
fprintf(fid, '  p      best_snr   BER_full      G_full       dG_vs_p05    code_BER     label\n');
for ip = 1:nP
    fprintf(fid, '  %.2f   %7.1f   %.6e   %.6f   %+.6f   %.6e   %s\n', ...
        T_mech.p(ip), T_mech.fullchain_best_snr_dB(ip), ...
        T_mech.fullchain_BER_at_best_goodput(ip), T_mech.fullchain_best_goodput(ip), ...
        T_mech.delta_Goodput_vs_p05(ip), T_mech.codeonly_BER_sim_mean(ip), ...
        char(T_mech.mechanism_label(ip)));
end
fprintf(fid, '\nOUTPUT FILES\n');
fprintf(fid, '  fullchain_sc_closure.csv\n');
fprintf(fid, '  mechanism_comparison.csv\n');
fprintf(fid, '  fullchain_sc_closure.mat\n');
fprintf(fid, '  run_log.txt\n');
fprintf(fid, '  figures/fullchain_ber_vs_snr.*\n');
fprintf(fid, '  figures/fullchain_goodput_vs_snr.*\n');
fprintf(fid, '  figures/goodput_energy_pareto.*\n');
fprintf(fid, '  figures/mechanism_summary.*\n');
clear cleanup_fid;

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);
