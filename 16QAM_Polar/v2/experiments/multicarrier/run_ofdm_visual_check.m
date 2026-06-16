%% RUN_OFDM_VISUAL_CHECK
% Stage B / B1: OFDM PSD and constellation visual check.
%
% This is a one-frame diagnostic, not a BER/Goodput Monte Carlo run.

clear; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg = config();

%% ===== Config =====
p_list = [0.5, 0.3, 0.1];
snr_db = 20;
n_subcarriers = 64;
cp_ratio = 1/4;
seed = 42;
psd_oversample = 4;

cfg.decoder = 'SC';
cfg.snr_mode = 'fixed_esn0';
cfg.seed = seed;
cfg.ofdm_n_subcarriers = n_subcarriers;
cfg.ofdm_cp_ratio = cp_ratio;
cfg.channel = 'AWGN';

rng(seed, 'twister');

out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_ofdm_visual_check']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

diary(fullfile(out_dir, 'run_log.txt'));
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Stage B / B1 OFDM Visual Check ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('p_list: %s\n', mat2str(p_list));
fprintf('snr_db: %.1f\n', snr_db);
fprintf('n_subcarriers: %d\n', n_subcarriers);
fprintf('cp_ratio: %.4f\n', cp_ratio);
fprintf('psd_oversample: %d\n', psd_oversample);
fprintf('seed: %d\n', seed);

%% ===== Generate one diagnostic frame per p =====
nP = numel(p_list);
diag_data = struct([]);
for ip = 1:nP
    p = p_list(ip);
    fprintf('\n--- Visual check p=%.2f ---\n', p);
    diag_data(ip).p = p;
    diag_data(ip).frame = local_generate_ofdm_frame(p, snr_db, cfg, psd_oversample);
    local_plot_for_p(fig_dir, diag_data(ip).frame, p, snr_db);
end

local_plot_constellation_panel(fig_dir, diag_data, snr_db);
local_plot_frequency_panel(fig_dir, diag_data, snr_db);
local_plot_psd_panel(fig_dir, diag_data, snr_db);

save(fullfile(out_dir, 'ofdm_visual_check.mat'), ...
    'cfg', 'p_list', 'snr_db', 'n_subcarriers', 'cp_ratio', ...
    'psd_oversample', 'seed', 'diag_data');

local_write_readme(out_dir, p_list, snr_db, n_subcarriers, cp_ratio, psd_oversample, seed);

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function frame = local_generate_ofdm_frame(p, snr_db, cfg, psd_oversample)
    N = cfg.N;
    M = cfg.M;
    nSub = cfg.ofdm_n_subcarriers;
    nCp = round(nSub * cfg.ofdm_cp_ratio);
    if mod(N, nSub) ~= 0
        error('cfg.N (%d) must be divisible by ofdm_n_subcarriers (%d).', N, nSub);
    end
    nOfdmSymbols = N / nSub;

    p_vec = cfg.p_fixed;
    p_vec(isnan(p_vec)) = p;

    K_vec = zeros(1, 4);
    S_vec = zeros(1, 4);
    for b = 1:4
        pb = p_vec(b);
        if pb > 0 && pb < 1
            hb = -pb * log2(pb) - (1 - pb) * log2(1 - pb);
        else
            hb = 0;
        end
        S_vec(b) = ceil(N * (1 - hb));
        K_vec(b) = ceil((N - S_vec(b)) / 2);
    end

    sigma = 10^(-snr_db / 20);
    channels = GA(sigma, N);
    [~, channels_ordered] = sort(channels, 'descend');

    lambda_offset = 2.^(0:log2(N));
    llr_layer_vec = get_llr_layer(N);
    bit_layer_vec = get_bit_layer(N);

    xxx_enc = zeros(N, 4);
    symbol_bits = zeros(N, 4);
    for b = 1:4
        [shaped_bits, ~, ~, I_set, S_set] = local_prepare_one_bit( ...
            p_vec(b), S_vec(b), K_vec(b), N, channels_ordered, ...
            lambda_offset, llr_layer_vec, bit_layer_vec);
        code = zeros(N, 1);
        code(I_set) = randi([0 1], K_vec(b), 1);
        code(S_set) = shaped_bits;
        xxx_enc(:, b) = polar_encoder(code);
        symbol_bits(:, b) = xxx_enc(:, b);
    end

    serial_bits = parallel_to_serial_bits(symbol_bits(:, 1), symbol_bits(:, 2), ...
        symbol_bits(:, 3), symbol_bits(:, 4));
    txSym = qammod(serial_bits, M, cfg.mapping, ...
        'InputType', 'bit', 'UnitAveragePower', cfg.unit_avg_power);

    txGrid = reshape(txSym, nSub, nOfdmSymbols);
    txTimeNoCp = ifft(txGrid, nSub, 1);
    txTimeCp = [txTimeNoCp(end-nCp+1:end, :); txTimeNoCp];
    [txTimeCpPsd, psdNfftOfdm] = local_make_oversampled_ofdm_time(txGrid, nCp, psd_oversample);

    spow_frame = mean(abs(txSym).^2);
    switch cfg.snr_mode
        case 'fixed_n0'
            sigma_noise_freq = sqrt(cfg.snr_ref_power) * sigma;
        otherwise
            sigma_noise_freq = sqrt(spow_frame) * sigma;
    end
    sigma_noise_time = sigma_noise_freq / sqrt(nSub);
    rxTimeCp = txTimeCp + sigma_noise_time * ...
        (randn(size(txTimeCp)) + 1j * randn(size(txTimeCp)));
    rxTimeCpPsd = txTimeCpPsd + (sigma_noise_freq / sqrt(psdNfftOfdm)) * ...
        (randn(size(txTimeCpPsd)) + 1j * randn(size(txTimeCpPsd)));

    rxTimeNoCp = rxTimeCp(nCp+1:end, :);
    rxGrid = fft(rxTimeNoCp, nSub, 1);
    rxSym = rxGrid(:);

    frame = struct();
    frame.txSym = txSym;
    frame.rxSym = rxSym;
    frame.txGrid = txGrid;
    frame.rxGrid = rxGrid;
    frame.txTimeCp = txTimeCp;
    frame.rxTimeCp = rxTimeCp;
    frame.txTimeCpPsd = txTimeCpPsd;
    frame.rxTimeCpPsd = rxTimeCpPsd;
    frame.nSub = nSub;
    frame.nCp = nCp;
    frame.psd_oversample = psd_oversample;
    frame.psd_nfft_ofdm = psdNfftOfdm;
    frame.nOfdmSymbols = nOfdmSymbols;
    frame.snr_db = snr_db;
    frame.spow_frame = spow_frame;
    frame.sigma_noise_freq = sigma_noise_freq;
    frame.sigma_noise_time = sigma_noise_time;
end

function [txTimeCpPsd, nPsd] = local_make_oversampled_ofdm_time(txGrid, nCp, oversample)
    nSub = size(txGrid, 1);
    nSym = size(txGrid, 2);
    nPsd = nSub * oversample;
    nCpPsd = nCp * oversample;

    txGridShift = fftshift(txGrid, 1);
    txGridPsdShift = zeros(nPsd, nSym);
    startIdx = floor((nPsd - nSub) / 2) + 1;
    txGridPsdShift(startIdx:startIdx+nSub-1, :) = txGridShift;
    txGridPsd = ifftshift(txGridPsdShift, 1);

    txTimeNoCpPsd = ifft(txGridPsd, nPsd, 1) * sqrt(oversample);
    txTimeCpPsd = [txTimeNoCpPsd(end-nCpPsd+1:end, :); txTimeNoCpPsd];
end

function [shaped_bits, frozen_bits_dec, SandI_set, I_set, S_set] = ...
    local_prepare_one_bit(pb, S_size, K, N, channels_ordered, lambda_offset, llr_layer_vec, bit_layer_vec)
    S_set = sort(channels_ordered(1:S_size), 'ascend');
    I_set = sort(channels_ordered(S_size+1:S_size+K), 'ascend');
    SandI_set = sort(channels_ordered(1:S_size+K), 'ascend');

    llr_src = ones(N, 1) * log((1 - pb) / pb);
    frozen_bits_src = ones(N, 1);
    frozen_bits_src(S_set) = 0;
    shaped_bits = SC_decoder(llr_src, S_size, frozen_bits_src, ...
        lambda_offset, llr_layer_vec, bit_layer_vec);

    frozen_bits_dec = ones(N, 1);
    frozen_bits_dec(I_set) = 0;
    frozen_bits_dec(S_set) = 0;
end

function local_plot_for_p(fig_dir, frame, p, snr_db)
    fig = figure('Color', 'w', 'Position', [80 80 1180 760]);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    imagesc(20 * log10(abs(frame.txGrid) + eps));
    axis tight; colorbar;
    xlabel('OFDM symbol index');
    ylabel('Subcarrier index');
    title(sprintf('TX frequency magnitude p=%.1f', p));

    nexttile;
    imagesc(angle(frame.txGrid));
    axis tight; colorbar;
    xlabel('OFDM symbol index');
    ylabel('Subcarrier index');
    title('TX frequency phase');

    nexttile;
    plot(real(frame.txSym), imag(frame.txSym), '.', 'MarkerSize', 7);
    axis equal; grid on; box on;
    xlabel('In-phase');
    ylabel('Quadrature');
    title('TX constellation');

    nexttile;
    plot(real(frame.rxSym), imag(frame.rxSym), '.', 'MarkerSize', 7);
    axis equal; grid on; box on;
    xlabel('In-phase');
    ylabel('Quadrature');
    title(sprintf('RX constellation, SNR=%.1f dB', snr_db));

    savefig(fig, fullfile(fig_dir, sprintf('ofdm_visual_check_p%03d.fig', round(100 * p))));
    exportgraphics(fig, fullfile(fig_dir, sprintf('ofdm_visual_check_p%03d.png', round(100 * p))), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, sprintf('ofdm_visual_check_p%03d.pdf', round(100 * p))), 'ContentType', 'vector');
    close(fig);
end

function local_plot_constellation_panel(fig_dir, diag_data, snr_db)
    fig = figure('Color', 'w', 'Position', [80 80 1220 680]);
    tiledlayout(2, numel(diag_data), 'TileSpacing', 'compact', 'Padding', 'compact');
    for ip = 1:numel(diag_data)
        p = diag_data(ip).p;
        frame = diag_data(ip).frame;
        nexttile(ip);
        plot(real(frame.txSym), imag(frame.txSym), '.', 'MarkerSize', 7);
        axis equal; grid on; box on;
        xlabel('I'); ylabel('Q');
        title(sprintf('TX p=%.1f', p));
        nexttile(ip + numel(diag_data));
        plot(real(frame.rxSym), imag(frame.rxSym), '.', 'MarkerSize', 7);
        axis equal; grid on; box on;
        xlabel('I'); ylabel('Q');
        title(sprintf('RX p=%.1f, %.1f dB', p, snr_db));
    end
    savefig(fig, fullfile(fig_dir, 'ofdm_constellation_panel.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'ofdm_constellation_panel.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'ofdm_constellation_panel.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_frequency_panel(fig_dir, diag_data, snr_db)
    fig = figure('Color', 'w', 'Position', [80 80 1220 680]);
    tiledlayout(2, numel(diag_data), 'TileSpacing', 'compact', 'Padding', 'compact');
    for ip = 1:numel(diag_data)
        p = diag_data(ip).p;
        frame = diag_data(ip).frame;
        nexttile(ip);
        imagesc(20 * log10(abs(frame.txGrid) + eps));
        axis tight; colorbar;
        xlabel('OFDM symbol');
        ylabel('Subcarrier');
        title(sprintf('TX |X_k| p=%.1f', p));
        nexttile(ip + numel(diag_data));
        imagesc(20 * log10(abs(frame.rxGrid) + eps));
        axis tight; colorbar;
        xlabel('OFDM symbol');
        ylabel('Subcarrier');
        title(sprintf('RX |Y_k| p=%.1f, %.1f dB', p, snr_db));
    end
    savefig(fig, fullfile(fig_dir, 'ofdm_frequency_panel.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'ofdm_frequency_panel.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'ofdm_frequency_panel.pdf'), 'ContentType', 'vector');
    close(fig);
end

function local_plot_psd_panel(fig_dir, diag_data, snr_db)
    nfft = 4096;
    fig = figure('Color', 'w', 'Position', [80 80 1320 760]);
    tiledlayout(2, numel(diag_data), 'TileSpacing', 'compact', 'Padding', 'compact');

    for ip = 1:numel(diag_data)
        p = diag_data(ip).p;
        frame = diag_data(ip).frame;
        [freq_axis, psd_db] = local_psd_db(frame.txTimeCpPsd(:), nfft);
        nexttile(ip);
        plot(freq_axis, psd_db, 'LineWidth', 1.4);
        grid on; box on;
        xlabel('Normalized frequency');
        ylabel('PSD (dB)');
        title(sprintf('TX PSD p=%.1f', p));
    end

    for ip = 1:numel(diag_data)
        p = diag_data(ip).p;
        frame = diag_data(ip).frame;
        [freq_axis, psd_db] = local_psd_db(frame.rxTimeCpPsd(:), nfft);
        nexttile(ip + numel(diag_data));
        plot(freq_axis, psd_db, 'LineWidth', 1.4);
        grid on; box on;
        xlabel('Normalized frequency');
        ylabel('PSD (dB)');
        title(sprintf('RX PSD p=%.1f, %.1f dB', p, snr_db));
    end

    savefig(fig, fullfile(fig_dir, 'ofdm_psd_panel.fig'));
    exportgraphics(fig, fullfile(fig_dir, 'ofdm_psd_panel.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, 'ofdm_psd_panel.pdf'), 'ContentType', 'vector');
    close(fig);
end

function [freq_axis, psd_db] = local_psd_db(x, nfft)
    x = x(:);
    x = x - mean(x);
    X = fftshift(fft(x, nfft));
    psd = abs(X).^2 / max(numel(x), 1);
    psd = psd / max(psd + eps);
    psd_db = 10 * log10(psd + eps);
    freq_axis = (-nfft/2:nfft/2-1).' / nfft;
end

function local_write_readme(out_dir, p_list, snr_db, n_subcarriers, cp_ratio, psd_oversample, seed)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README.txt in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, '=== Stage B / B1 OFDM Visual Check ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/multicarrier/run_ofdm_visual_check.m'');\n\n');
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  One-frame OFDM visual diagnostic. Not a BER/Goodput Monte Carlo run.\n');
    fprintf(fid, '  Generates PSD, frequency-resource diagnostic, and TX/RX constellation plots.\n\n');
    fprintf(fid, 'PARAMETERS\n');
    fprintf(fid, '  p_list: %s\n', mat2str(p_list));
    fprintf(fid, '  snr_db: %.1f\n', snr_db);
    fprintf(fid, '  n_subcarriers: %d\n', n_subcarriers);
    fprintf(fid, '  cp_ratio: %.4f\n', cp_ratio);
    fprintf(fid, '  psd_oversample: %d\n', psd_oversample);
    fprintf(fid, '  channel_model: AWGN\n');
    fprintf(fid, '  seed: %d\n\n', seed);
    fprintf(fid, 'OUTPUTS\n');
    fprintf(fid, '  ofdm_visual_check.mat\n');
    fprintf(fid, '  run_log.txt\n');
    fprintf(fid, '  figures/ofdm_visual_check_p*.png/pdf/fig\n');
    fprintf(fid, '  figures/ofdm_constellation_panel.png/pdf/fig\n');
    fprintf(fid, '  figures/ofdm_frequency_panel.png/pdf/fig\n');
    fprintf(fid, '  figures/ofdm_psd_panel.png/pdf/fig\n');
    fprintf(fid, '\nNOTE\n');
    fprintf(fid, '  The PSD panel uses a 2-by-3 layout: columns are p=0.5/0.3/0.1, with TX on top and RX below.\n');
    fprintf(fid, '  PSD plots use zero-padded oversampled OFDM for visualization, so guard-band regions are visible.\n');
    fprintf(fid, '  This does not change the BER/Goodput simulation chain in run_ofdm_baseline.m.\n');
end
