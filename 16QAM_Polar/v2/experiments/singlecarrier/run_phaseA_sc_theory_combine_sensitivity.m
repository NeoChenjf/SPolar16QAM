%% RUN_PHASEA_SC_THEORY_COMBINE_SENSITIVITY
% 阶段 A 单载波 SC 理论 BER 合成形式敏感性检查。
%
% 目的：
%   对比旧的几何比例缩放口径 ratio_scale 与更保守的独立并集口径
%   independent_union，判断“编码侧 BER + 几何侧 BER”的合成方式是否会
%   造成纯理论 full-chain 曲线与 Monte Carlo 曲线的大偏差。

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg = config();

%% ===== 参数 =====
p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
snr_grid = 0:1:20;
combine_modes = {'ratio_scale', 'independent_union'};

opts_base = struct();
opts_base.disable_geom = false;
opts_base.geom_model = 'strict_q';
opts_base.geom_apply_mode = 'shaped_only';
opts_base.geom_ref_p = 0.5;
opts_base.pe_floor = 1e-12;
opts_base.alpha_rel = 1.0;
opts_base.code_high_eta = 0.8;
opts_base.code_high_mid_db = 14.0;
opts_base.code_high_slope_db = 2.0;

sim_summary_path = fullfile(cfg.output_dir, ...
    '20260521_150555_phaseA_sc_final_global_curves', ...
    'fullchain_final_summary.csv');

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_phaseA_sc_theory_combine_sensitivity']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

log_file = fullfile(out_dir, 'run_log.txt');
diary(log_file);
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Phase A SC Theory Combine Sensitivity ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('p_list: %s\n', mat2str(p_list));
fprintf('snr_grid: %s\n', mat2str(snr_grid));
fprintf('combine_modes: %s\n', strjoin(combine_modes, ', '));

%% ===== 理论计算 =====
nP = numel(p_list);
nS = numel(snr_grid);
nM = numel(combine_modes);

BER_hat = nan(nP, nS, nM);
Goodput_hat = nan(nP, nS, nM);
R_total = nan(nP, nM);
geom_pe_abs = nan(nP, nS, nM);
geom_ratio = nan(nP, nS, nM);

for im = 1:nM
    opts = opts_base;
    opts.geom_combine_mode = combine_modes{im};
    fprintf('\nMode=%s\n', opts.geom_combine_mode);

    for ip = 1:nP
        p = p_list(ip);
        model = estimate_ber_hat_sc_dual(p, snr_grid, cfg, opts);
        BER_hat(ip, :, im) = model.BER_hat;
        Goodput_hat(ip, :, im) = model.R_total .* (1 - model.BER_hat);
        R_total(ip, im) = model.R_total;
        geom_pe_abs(ip, :, im) = model.B_geom_pe_abs;
        geom_ratio(ip, :, im) = model.B_geom_ratio;
        fprintf('  p=%.2f | R_total=%.6f | BER@10dB=%.3e | BER@20dB=%.3e\n', ...
            p, model.R_total, model.BER_hat(snr_grid == 10), model.BER_hat(snr_grid == 20));
    end
end

%% ===== 输出 CSV =====
T = table();
for im = 1:nM
    [P_grid, S_grid] = ndgrid(p_list, snr_grid);
    nRows = nP * nS;
    T_mode = table();
    T_mode.combine_mode = repmat(string(combine_modes{im}), nRows, 1);
    T_mode.p = P_grid(:);
    T_mode.snr_dB = S_grid(:);
    T_mode.BER_hat_full_theory = reshape(BER_hat(:, :, im), nRows, 1);
    T_mode.Goodput_hat_theory = reshape(Goodput_hat(:, :, im), nRows, 1);
    T_mode.R_total = repmat(R_total(:, im), nS, 1);
    T_mode.geom_pe_abs = reshape(geom_pe_abs(:, :, im), nRows, 1);
    T_mode.geom_ratio = reshape(geom_ratio(:, :, im), nRows, 1);
    T = [T; T_mode]; %#ok<AGROW>
end
writetable(T, fullfile(out_dir, 'theory_combine_sensitivity.csv'));

%% ===== 读取 Monte Carlo 对照 =====
has_sim_summary = exist(sim_summary_path, 'file') == 2;
if has_sim_summary
    Sim = readtable(sim_summary_path);
else
    Sim = table();
end

save(fullfile(out_dir, 'theory_combine_sensitivity.mat'), ...
    'cfg', 'opts_base', 'p_list', 'snr_grid', 'combine_modes', ...
    'BER_hat', 'Goodput_hat', 'R_total', 'geom_pe_abs', 'geom_ratio', ...
    'has_sim_summary', 'sim_summary_path');

%% ===== 绘图 =====
colors = lines(nP);
line_styles = {'-', '--'};

fig1 = figure('Color', 'w', 'Position', [80 80 1080 660]);
hold on; grid on; box on;
for im = 1:nM
    for ip = 1:nP
        semilogy(snr_grid, BER_hat(ip, :, im), ...
            'LineStyle', line_styles{im}, 'Marker', 'o', ...
            'Color', colors(ip, :), 'LineWidth', 1.4, 'MarkerSize', 4, ...
            'DisplayName', sprintf('%s p=%.1f', combine_modes{im}, p_list(ip)));
    end
end
if has_sim_summary
    for ip = 1:nP
        mask = abs(Sim.p - p_list(ip)) < 1e-12;
        semilogy(Sim.snr_dB(mask), Sim.BER_mean(mask), 'x', ...
            'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 7, ...
            'DisplayName', sprintf('MC p=%.1f', p_list(ip)));
    end
end
xlabel('SNR (dB)');
ylabel('BER');
title('Theory BER Combine Sensitivity vs Monte Carlo');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig1, fullfile(fig_dir, 'theory_combine_sensitivity_ber.fig'));
exportgraphics(fig1, fullfile(fig_dir, 'theory_combine_sensitivity_ber.png'), 'Resolution', 300);
exportgraphics(fig1, fullfile(fig_dir, 'theory_combine_sensitivity_ber.pdf'), 'ContentType', 'vector');
close(fig1);

fig2 = figure('Color', 'w', 'Position', [80 80 1080 660]);
hold on; grid on; box on;
for im = 1:nM
    for ip = 1:nP
        plot(snr_grid, Goodput_hat(ip, :, im), ...
            'LineStyle', line_styles{im}, 'Marker', 'o', ...
            'Color', colors(ip, :), 'LineWidth', 1.4, 'MarkerSize', 4, ...
            'DisplayName', sprintf('%s p=%.1f', combine_modes{im}, p_list(ip)));
    end
end
if has_sim_summary
    for ip = 1:nP
        mask = abs(Sim.p - p_list(ip)) < 1e-12;
        plot(Sim.snr_dB(mask), Sim.Goodput_mean(mask), 'x', ...
            'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 7, ...
            'DisplayName', sprintf('MC p=%.1f', p_list(ip)));
    end
end
xlabel('SNR (dB)');
ylabel('Goodput');
title('Theory Goodput Combine Sensitivity vs Monte Carlo');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig2, fullfile(fig_dir, 'theory_combine_sensitivity_goodput.fig'));
exportgraphics(fig2, fullfile(fig_dir, 'theory_combine_sensitivity_goodput.png'), 'Resolution', 300);
exportgraphics(fig2, fullfile(fig_dir, 'theory_combine_sensitivity_goodput.pdf'), 'ContentType', 'vector');
close(fig2);

%% ===== README =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
if fid < 0
    error('Cannot create README.txt in %s', out_dir);
end
cleanup_fid = onCleanup(@() fclose(fid));
fprintf(fid, '=== Phase A SC Theory Combine Sensitivity ===\n\n');
fprintf(fid, 'RUN COMMAND\n');
fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/singlecarrier/run_phaseA_sc_theory_combine_sensitivity.m'');\n\n');
fprintf(fid, 'SCOPE\n');
fprintf(fid, '  Pure theory/model-sensitivity check. This is not a new Monte Carlo run.\n');
fprintf(fid, '  Compares ratio_scale against independent_union BER composition.\n');
fprintf(fid, '  Monte Carlo final summary is overlaid when available.\n\n');
fprintf(fid, 'PARAMETERS\n');
fprintf(fid, '  p_list: %s\n', mat2str(p_list));
fprintf(fid, '  snr_grid: %s\n', mat2str(snr_grid));
fprintf(fid, '  geom_model: %s\n', opts_base.geom_model);
fprintf(fid, '  geom_apply_mode: %s\n', opts_base.geom_apply_mode);
fprintf(fid, '  combine_modes: %s\n', strjoin(combine_modes, ', '));
fprintf(fid, '  sim_summary_path: %s\n', sim_summary_path);
fprintf(fid, '  sim_summary_available: %d\n\n', has_sim_summary);
fprintf(fid, 'OUTPUTS\n');
fprintf(fid, '  theory_combine_sensitivity.csv\n');
fprintf(fid, '  theory_combine_sensitivity.mat\n');
fprintf(fid, '  figures/theory_combine_sensitivity_ber.*\n');
fprintf(fid, '  figures/theory_combine_sensitivity_goodput.*\n\n');
fprintf(fid, 'INTERPRETATION\n');
fprintf(fid, '  ratio_scale uses P_code * R_geo and is a first-order relative-risk approximation.\n');
fprintf(fid, '  independent_union uses 1-(1-P_code)(1-P_geo) for a diagnostic independent-event composition.\n');
fprintf(fid, '  If both remain far from Monte Carlo, the main mismatch is likely not composition alone,\n');
fprintf(fid, '  but the GA/BPSK-equivalent code model versus the actual 16QAM LLR bit-channel.\n');
clear cleanup_fid;

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);
