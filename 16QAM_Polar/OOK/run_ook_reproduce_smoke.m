%% RUN_OOK_REPRODUCE_SMOKE
% Reproduce the original OOK shaped-polar code path using a short smoke run.
%
% The script intentionally keeps the run small. Use overrides for denser
% reproduction instead of editing this file in-place.

clearvars -except ook_overrides; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
addpath(script_dir);

%% ===== Config =====
cfg = struct();
cfg.p_list = [0.5, 0.7, 0.9];
cfg.N = 1024;
cfg.snr_grid = -5:5:20;
cfg.num_frames = 20;
cfg.seed = 42;
cfg.regenerate_each_frame = true;
cfg.result_tag = 'ook_shaped_polar_smoke';

if exist('ook_overrides', 'var')
    fields = fieldnames(ook_overrides);
    for i = 1:numel(fields)
        cfg.(fields{i}) = ook_overrides.(fields{i});
    end
end

out_dir = fullfile(script_dir, 'results', ...
    [datestr(now, 'yyyymmdd_HHMMSS') '_' cfg.result_tag]);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

diary(fullfile(out_dir, 'run_log.txt'));
diary on;
cleanup_obj = onCleanup(@() diary('off')); %#ok<NASGU>

fprintf('\n========== OOK Shaped Polar Smoke ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('p_list: %s\n', mat2str(cfg.p_list));
fprintf('N: %d\n', cfg.N);
fprintf('snr_grid: %s\n', mat2str(cfg.snr_grid));
fprintf('num_frames: %d\n', cfg.num_frames);
fprintf('seed: %d\n', cfg.seed);
fprintf('regenerate_each_frame: %d\n', cfg.regenerate_each_frame);

%% ===== Run =====
all_results = cell(numel(cfg.p_list), 1);
rows = {};
for ip = 1:numel(cfg.p_list)
    p = cfg.p_list(ip);
    opts = cfg;
    opts.seed = cfg.seed + ip - 1;
    result = simulate_ook_shaped_polar(p, opts);
    all_results{ip} = result;

    for is = 1:numel(result.snr_grid)
        rows(end+1, :) = {p, result.snr_grid(is), result.BER(is), ...
            result.BLER(is), result.goodput(is), result.energy_mean(is), ...
            result.encoded_one_fraction(is), result.K, result.S_size, ...
            result.R, result.error_count(is), result.block_error_count(is), ...
            result.frames_used(is), result.seed, result.regenerate_each_frame}; %#ok<AGROW>
    end
end

T = cell2table(rows, 'VariableNames', {'p', 'snr_dB', 'ber', 'bler', ...
    'goodput', 'energy_mean', 'encoded_one_fraction', 'K', 'S_size', ...
    'rate', 'error_count', 'block_error_count', 'frames_used', 'seed', ...
    'regenerate_each_frame'});

writetable(T, fullfile(out_dir, 'ook_shaped_polar_summary.csv'));
save(fullfile(out_dir, 'ook_shaped_polar_smoke.mat'), 'cfg', 'all_results', 'T');

local_plot_ber(fig_dir, T);
local_plot_goodput(fig_dir, T);
local_plot_energy_goodput(fig_dir, T);
local_write_readme(out_dir, cfg);

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function local_plot_ber(fig_dir, T)
    p_values = unique(T.p, 'stable');
    colors = lines(numel(p_values));
    fig = figure('Color', 'w', 'Position', [80 80 920 580]);
    hold on; grid on; box on;
    for i = 1:numel(p_values)
        rows = T.p == p_values(i);
        semilogy(T.snr_dB(rows), T.ber(rows), '-o', ...
            'Color', colors(i, :), 'LineWidth', 1.4, ...
            'DisplayName', sprintf('p=%.2f', p_values(i)));
    end
    xlabel('SNR (dB)', 'Interpreter', 'none');
    ylabel('BER', 'Interpreter', 'none');
    title('OOK shaped polar BER smoke', 'Interpreter', 'none');
    legend('Location', 'best', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'ook_ber_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'ook_ber_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'ook_ber_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_goodput(fig_dir, T)
    p_values = unique(T.p, 'stable');
    colors = lines(numel(p_values));
    fig = figure('Color', 'w', 'Position', [80 80 920 580]);
    hold on; grid on; box on;
    for i = 1:numel(p_values)
        rows = T.p == p_values(i);
        plot(T.snr_dB(rows), T.goodput(rows), '-o', ...
            'Color', colors(i, :), 'LineWidth', 1.4, ...
            'DisplayName', sprintf('p=%.2f', p_values(i)));
    end
    xlabel('SNR (dB)', 'Interpreter', 'none');
    ylabel('Goodput proxy = K/N * (1-BER)', 'Interpreter', 'none');
    title('OOK shaped polar Goodput smoke', 'Interpreter', 'none');
    legend('Location', 'best', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'ook_goodput_vs_snr.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'ook_goodput_vs_snr.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'ook_goodput_vs_snr.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_energy_goodput(fig_dir, T)
    rows = T.snr_dB == max(T.snr_dB);
    T_last = T(rows, :);
    fig = figure('Color', 'w', 'Position', [80 80 820 560]);
    hold on; grid on; box on;
    scatter(T_last.energy_mean, T_last.goodput, 80, 'filled');
    for i = 1:height(T_last)
        text(T_last.energy_mean(i), T_last.goodput(i), ...
            sprintf('  p=%.2f', T_last.p(i)), 'Interpreter', 'none');
    end
    xlabel('OOK mean transmitted energy proxy', 'Interpreter', 'none');
    ylabel('Goodput proxy', 'Interpreter', 'none');
    title(sprintf('OOK energy-goodput smoke at %g dB', max(T.snr_dB)), ...
        'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, 'ook_energy_goodput.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'ook_energy_goodput.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'ook_energy_goodput.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_write_readme(out_dir, cfg)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '=== OOK Shaped Polar Smoke ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/OOK''); run(''run_ook_reproduce_smoke.m'');\n\n');
    fprintf(fid, 'REFERENCE\n');
    fprintf(fid, '  Based on 16QAM_Polar/ShapedPolarS/gettest.m.\n\n');
    fprintf(fid, 'PARAMETERS\n');
    fprintf(fid, '  p_list: %s\n', mat2str(cfg.p_list));
    fprintf(fid, '  N: %d\n', cfg.N);
    fprintf(fid, '  snr_grid: %s\n', mat2str(cfg.snr_grid));
    fprintf(fid, '  num_frames: %d\n', cfg.num_frames);
    fprintf(fid, '  seed: %d\n', cfg.seed);
    fprintf(fid, '  regenerate_each_frame: %d\n\n', cfg.regenerate_each_frame);
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  OOK 0/1 shaped polar reproduction smoke, not a paper-grade sweep.\n');
    fprintf(fid, '  Goodput is K/N*(1-BER). Energy proxy is mean transmitted 1 fraction.\n');
end
