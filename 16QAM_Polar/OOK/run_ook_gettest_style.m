%% RUN_OOK_GETTEST_STYLE
% gettest.m-style reproduction for OOK shaped polar code.
%
% Full defaults intentionally match the legacy shape:
%   p_list = [0.5 0.7 0.9]
%   SNR = -5:0.5:10
%   num_frames = 1000
%
% This is a long run. Use ook_overrides for smoke validation.

clearvars -except ook_overrides; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
addpath(script_dir);

%% ===== Config =====
cfg = struct();
cfg.p_list = [0.5, 0.7, 0.9];
cfg.N = 1024;
cfg.snr_grid = -5:0.5:10;
cfg.num_frames = 1000;
cfg.seed = 42;
cfg.regenerate_each_frame = true;
cfg.result_tag = 'ook_gettest_style';

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

fprintf('\n========== OOK gettest-style reproduction ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('p_list: %s\n', mat2str(cfg.p_list));
fprintf('N: %d\n', cfg.N);
fprintf('snr_grid: %s\n', mat2str(cfg.snr_grid));
fprintf('num_frames: %d\n', cfg.num_frames);
fprintf('seed: %d\n', cfg.seed);

%% ===== Run =====
nP = numel(cfg.p_list);
nS = numel(cfg.snr_grid);
BER = zeros(nP, nS);
BLER = zeros(nP, nS);
Goodput = zeros(nP, nS);
Energy = zeros(nP, nS);
K_vec = zeros(nP, 1);
S_size_vec = zeros(nP, 1);
Rate_vec = zeros(nP, 1);
all_results = cell(nP, 1);
rows = {};

for ip = 1:nP
    p = cfg.p_list(ip);
    opts = cfg;
    opts.seed = cfg.seed + ip - 1;
    result = simulate_ook_shaped_polar(p, opts);
    all_results{ip} = result;

    BER(ip, :) = result.BER;
    BLER(ip, :) = result.BLER;
    Goodput(ip, :) = result.goodput;
    Energy(ip, :) = result.energy_mean;
    K_vec(ip) = result.K;
    S_size_vec(ip) = result.S_size;
    Rate_vec(ip) = result.R;

    for is = 1:nS
        rows(end+1, :) = {p, cfg.snr_grid(is), result.BER(is), ...
            result.BLER(is), result.goodput(is), result.energy_mean(is), ...
            result.encoded_one_fraction(is), result.K, result.S_size, ...
            result.R, result.error_count(is), result.block_error_count(is), ...
            result.frames_used(is), result.seed}; %#ok<AGROW>
    end
end

T = cell2table(rows, 'VariableNames', {'p', 'snr_dB', 'ber', 'bler', ...
    'goodput', 'energy_mean', 'encoded_one_fraction', 'K', 'S_size', ...
    'rate', 'error_count', 'block_error_count', 'frames_used', 'seed'});

T_ber = local_matrix_table(cfg.p_list, cfg.snr_grid, BER);
T_bler = local_matrix_table(cfg.p_list, cfg.snr_grid, BLER);

writetable(T, fullfile(out_dir, 'ook_gettest_style_long.csv'));
writetable(T_ber, fullfile(out_dir, 'ook_gettest_style_BER_matrix.csv'));
writetable(T_bler, fullfile(out_dir, 'ook_gettest_style_BLER_matrix.csv'));
save(fullfile(out_dir, 'ook_gettest_style_curves.mat'), ...
    'cfg', 'all_results', 'T', 'BER', 'BLER', 'Goodput', 'Energy', ...
    'K_vec', 'S_size_vec', 'Rate_vec');

local_plot_semilogy(fig_dir, cfg.snr_grid, cfg.p_list, BER, 'BER', ...
    'ook_gettest_style_BER');
local_plot_semilogy(fig_dir, cfg.snr_grid, cfg.p_list, BLER, 'BLER', ...
    'ook_gettest_style_BLER');
local_write_readme(out_dir, cfg);

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function Tm = local_matrix_table(p_list, snr_grid, M)
    var_names = cell(1, numel(snr_grid) + 1);
    var_names{1} = 'p';
    for i = 1:numel(snr_grid)
        var_names{i + 1} = local_snr_var_name(snr_grid(i));
    end
    Tm = array2table([p_list(:), M], 'VariableNames', var_names);
end

function name = local_snr_var_name(snr)
    if snr < 0
        prefix = 'snr_m';
    else
        prefix = 'snr_p';
    end
    val = strrep(sprintf('%.1f', abs(snr)), '.', 'p');
    name = [prefix val];
end

function local_plot_semilogy(fig_dir, snr_grid, p_list, Y, y_label, file_stem)
    colors = lines(numel(p_list));
    fig = figure('Color', 'w', 'Position', [80 80 920 580]);
    hold on; grid on; box on;
    for ip = 1:numel(p_list)
        y_plot = Y(ip, :);
        y_plot(y_plot <= 0) = 1e-5;
        semilogy(snr_grid, y_plot, '-o', 'Color', colors(ip, :), ...
            'LineWidth', 1.4, 'DisplayName', sprintf('SC p=%.1f', p_list(ip)));
    end
    xlabel('SNR (dB)', 'Interpreter', 'none');
    ylabel(y_label, 'Interpreter', 'none');
    title(sprintf('OOK gettest-style %s', y_label), 'Interpreter', 'none');
    set(gca, 'YScale', 'log', 'YTick', 10.^(-5:0));
    xlim([min(snr_grid), max(snr_grid)]);
    ylim([1e-5, 1]);
    legend('Location', 'best', 'Interpreter', 'none');
    savefig(fig, fullfile(fig_dir, [file_stem '.fig']));
    exportgraphics(fig, fullfile(fig_dir, [file_stem '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, [file_stem '.pdf']), 'ContentType', 'vector');
    close(fig);
end

function local_write_readme(out_dir, cfg)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '=== OOK gettest-style reproduction ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/OOK''); run(''run_ook_gettest_style.m'');\n\n');
    fprintf(fid, 'REFERENCE\n');
    fprintf(fid, '  Data shape follows ShapedPolarS/gettest.m: BER and BLER are p x SNR arrays.\n\n');
    fprintf(fid, 'PARAMETERS\n');
    fprintf(fid, '  p_list: %s\n', mat2str(cfg.p_list));
    fprintf(fid, '  N: %d\n', cfg.N);
    fprintf(fid, '  snr_grid: %s\n', mat2str(cfg.snr_grid));
    fprintf(fid, '  num_frames: %d\n', cfg.num_frames);
    fprintf(fid, '  seed: %d\n', cfg.seed);
    fprintf(fid, '  regenerate_each_frame: %d\n\n', cfg.regenerate_each_frame);
    fprintf(fid, 'OUTPUTS\n');
    fprintf(fid, '  ook_gettest_style_long.csv\n');
    fprintf(fid, '  ook_gettest_style_BER_matrix.csv\n');
    fprintf(fid, '  ook_gettest_style_BLER_matrix.csv\n');
    fprintf(fid, '  ook_gettest_style_curves.mat\n');
    fprintf(fid, '  figures/ook_gettest_style_BER.*\n');
    fprintf(fid, '  figures/ook_gettest_style_BLER.*\n\n');
    fprintf(fid, 'NOTE\n');
    fprintf(fid, '  Zero BER/BLER values are plotted at 1e-5 only for log-scale visibility; raw CSV/MAT keep zeros.\n');
end

