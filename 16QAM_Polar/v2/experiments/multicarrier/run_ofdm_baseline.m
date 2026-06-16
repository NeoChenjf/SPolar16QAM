%% RUN_OFDM_BASELINE
% Stage B / B1: minimal OFDM full-chain baseline.
%
% Scope:
%   Uniform p only, AWGN OFDM, SC decoder, light representative grid.

clearvars -except ofdm_baseline_overrides; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg_base = config();

%% ===== Config =====
p_list = [0.5, 0.3, 0.1];
snr_grid = [8, 12, 16, 20];
n_subcarriers = 64;
cp_ratio = 1/4;
channel_model = 'AWGN';
num_frames = 100;
seed = 42;
result_tag = 'ofdm_baseline';
run_command = 'cd(''16QAM_Polar/v2''); setup_paths; run(''experiments/multicarrier/run_ofdm_baseline.m'');';

if exist('ofdm_baseline_overrides', 'var')
    if isfield(ofdm_baseline_overrides, 'p_list'); p_list = ofdm_baseline_overrides.p_list; end
    if isfield(ofdm_baseline_overrides, 'snr_grid'); snr_grid = ofdm_baseline_overrides.snr_grid; end
    if isfield(ofdm_baseline_overrides, 'n_subcarriers'); n_subcarriers = ofdm_baseline_overrides.n_subcarriers; end
    if isfield(ofdm_baseline_overrides, 'cp_ratio'); cp_ratio = ofdm_baseline_overrides.cp_ratio; end
    if isfield(ofdm_baseline_overrides, 'channel_model'); channel_model = ofdm_baseline_overrides.channel_model; end
    if isfield(ofdm_baseline_overrides, 'num_frames'); num_frames = ofdm_baseline_overrides.num_frames; end
    if isfield(ofdm_baseline_overrides, 'seed'); seed = ofdm_baseline_overrides.seed; end
    if isfield(ofdm_baseline_overrides, 'result_tag'); result_tag = ofdm_baseline_overrides.result_tag; end
    if isfield(ofdm_baseline_overrides, 'run_command'); run_command = ofdm_baseline_overrides.run_command; end
end

cfg_local = cfg_base;
cfg_local.decoder = 'SC';
cfg_local.snr_mode = 'fixed_esn0';
cfg_local.num_frames = num_frames;
cfg_local.seed = seed;
cfg_local.p_candidates = p_list;
cfg_local.SNR_dB = snr_grid;
cfg_local.ofdm_n_subcarriers = n_subcarriers;
cfg_local.ofdm_cp_ratio = cp_ratio;
cfg_local.channel = channel_model;

rng(cfg_local.seed, 'twister');

out_dir = fullfile(cfg_local.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' result_tag]);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

log_file = fullfile(out_dir, 'run_log.txt');
diary(log_file);
diary on;
cleanup_obj = onCleanup(@() diary('off'));

fprintf('\n========== Stage B / B1 OFDM Baseline ==========\n');
fprintf('Output: %s\n', out_dir);
fprintf('Decoder: %s\n', cfg_local.decoder);
fprintf('SNR mode: %s\n', cfg_local.snr_mode);
fprintf('Channel: %s\n', cfg_local.channel);
fprintf('p_list: %s\n', mat2str(p_list));
fprintf('snr_grid: %s\n', mat2str(snr_grid));
fprintf('n_subcarriers: %d\n', n_subcarriers);
fprintf('cp_ratio: %.4f\n', cp_ratio);
fprintf('num_frames: %d\n', cfg_local.num_frames);
fprintf('seed: %d\n', cfg_local.seed);

%% ===== Main Loop =====
nP = numel(p_list);
nS = numel(snr_grid);
all_results = cell(nP, 1);

BER_matrix = nan(nP, nS);
Goodput_matrix = nan(nP, nS);
Goodput_cp_matrix = nan(nP, nS);
MI_matrix = nan(nP, nS);
E_theory_vec = nan(nP, 1);
E_norm_vec = nan(nP, 1);
R_total_vec = nan(nP, 1);
R_total_cp_vec = nan(nP, 1);
K_matrix = nan(nP, 4);

tic;
for ip = 1:nP
    p = p_list(ip);
    fprintf('\n--- OFDM baseline p=%.2f (%d/%d) ---\n', p, ip, nP);
    all_results{ip} = local_sim_shaped_polar_16qam_ofdm(p, snr_grid, cfg_local);

    r = all_results{ip};
    G = compute_goodput(r);
    G_cp = r.R_total_cp_corrected * (1 - r.BER);
    E = compute_energy(p, cfg_local);

    BER_matrix(ip, :) = r.BER;
    Goodput_matrix(ip, :) = G;
    Goodput_cp_matrix(ip, :) = G_cp;
    MI_matrix(ip, :) = r.MI_total;
    E_theory_vec(ip) = E;
    E_norm_vec(ip) = E / cfg_local.E_baseline;
    R_total_vec(ip) = r.R_total;
    R_total_cp_vec(ip) = r.R_total_cp_corrected;
    K_matrix(ip, :) = r.K;
end
elapsed = toc;
fprintf('\nElapsed: %.1f sec (%.2f min)\n', elapsed, elapsed / 60);

%% ===== CSV / MAT Outputs =====
p_col = repelem(p_list(:), nS);
snr_col = repmat(snr_grid(:), nP, 1);
BER_col = reshape(BER_matrix.', [], 1);
Goodput_col = reshape(Goodput_matrix.', [], 1);
Goodput_cp_col = reshape(Goodput_cp_matrix.', [], 1);
MI_col = reshape(MI_matrix.', [], 1);
R_col = repelem(R_total_vec, nS);
R_cp_col = repelem(R_total_cp_vec, nS);
E_col = repelem(E_theory_vec, nS);
E_norm_col = repelem(E_norm_vec, nS);
nsc_col = repmat(n_subcarriers, nP*nS, 1);
cp_col = repmat(cp_ratio, nP*nS, 1);
channel_col = repmat(string(channel_model), nP*nS, 1);
decoder_col = repmat(string(cfg_local.decoder), nP*nS, 1);
frames_col = repmat(cfg_local.num_frames, nP*nS, 1);
seed_col = repmat(cfg_local.seed, nP*nS, 1);

T = table(p_col, snr_col, BER_col, Goodput_col, Goodput_cp_col, ...
    R_col, R_cp_col, E_col, E_norm_col, MI_col, nsc_col, cp_col, ...
    channel_col, decoder_col, frames_col, seed_col, ...
    'VariableNames', {'p', 'snr_dB', 'ber', 'goodput', 'goodput_cp_corrected', ...
    'r_total', 'r_total_cp_corrected', 'e_theory', 'e_norm', 'mi_total', ...
    'n_subcarriers', 'cp_ratio', 'channel_model', 'decoder', 'num_frames', 'seed'});
writetable(T, fullfile(out_dir, 'ofdm_baseline.csv'));

save(fullfile(out_dir, 'ofdm_baseline.mat'), ...
    'cfg_local', 'p_list', 'snr_grid', 'n_subcarriers', 'cp_ratio', ...
    'all_results', 'BER_matrix', 'Goodput_matrix', 'Goodput_cp_matrix', ...
    'MI_matrix', 'E_theory_vec', 'E_norm_vec', 'R_total_vec', ...
    'R_total_cp_vec', 'K_matrix', 'elapsed');

%% ===== Figures =====
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
title('OFDM Baseline BER vs SNR');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig1, fullfile(fig_dir, 'ofdm_ber_vs_snr.fig'));
exportgraphics(fig1, fullfile(fig_dir, 'ofdm_ber_vs_snr.png'), 'Resolution', 300);
exportgraphics(fig1, fullfile(fig_dir, 'ofdm_ber_vs_snr.pdf'), 'ContentType', 'vector');
close(fig1);

fig2 = figure('Color', 'w', 'Position', [80 80 900 620]);
hold on; grid on; box on;
for ip = 1:nP
    plot(snr_grid, Goodput_cp_matrix(ip, :), '-o', ...
        'Color', colors(ip, :), 'LineWidth', 1.5, 'MarkerSize', 5, ...
        'DisplayName', sprintf('p=%.1f', p_list(ip)));
end
xlabel('SNR (dB)');
ylabel('Goodput (CP-corrected)');
title('OFDM Baseline Goodput vs SNR');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig2, fullfile(fig_dir, 'ofdm_goodput_vs_snr.fig'));
exportgraphics(fig2, fullfile(fig_dir, 'ofdm_goodput_vs_snr.png'), 'Resolution', 300);
exportgraphics(fig2, fullfile(fig_dir, 'ofdm_goodput_vs_snr.pdf'), 'ContentType', 'vector');
close(fig2);

fig3 = figure('Color', 'w', 'Position', [80 80 900 620]);
hold on; grid on; box on;
target_colors = lines(nS);
for is = 1:nS
    plot(E_norm_vec, Goodput_cp_matrix(:, is), '-o', ...
        'Color', target_colors(is, :), 'LineWidth', 1.4, 'MarkerSize', 5, ...
        'DisplayName', sprintf('SNR=%g dB', snr_grid(is)));
end
xlabel('Normalized energy E/E_0');
ylabel('Goodput (CP-corrected)');
title('OFDM Baseline Energy-Goodput View');
legend('Location', 'bestoutside', 'Interpreter', 'none');
savefig(fig3, fullfile(fig_dir, 'ofdm_energy_goodput.fig'));
exportgraphics(fig3, fullfile(fig_dir, 'ofdm_energy_goodput.png'), 'Resolution', 300);
exportgraphics(fig3, fullfile(fig_dir, 'ofdm_energy_goodput.pdf'), 'ContentType', 'vector');
close(fig3);

%% ===== README =====
[best_goodput, best_idx] = max(T.goodput_cp_corrected);

fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
if fid < 0
    error('Cannot create README.txt in %s', out_dir);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, '=== Stage B / B1 OFDM Baseline ===\n\n');
fprintf(fid, 'RUN COMMAND\n');
fprintf(fid, '  %s\n\n', run_command);
fprintf(fid, 'SCOPE\n');
fprintf(fid, '  Minimal OFDM full-chain baseline with uniform p.\n');
fprintf(fid, '  This is a light B1 baseline, not a final multicarrier conclusion.\n');
fprintf(fid, '  No Rayleigh fading, no p_k adaptation, no pure-energy subcarrier strategy.\n\n');
fprintf(fid, 'PARAMETERS\n');
fprintf(fid, '  p_list: %s\n', mat2str(p_list));
fprintf(fid, '  snr_grid: %s\n', mat2str(snr_grid));
fprintf(fid, '  n_subcarriers: %d\n', n_subcarriers);
fprintf(fid, '  cp_ratio: %.4f\n', cp_ratio);
fprintf(fid, '  channel_model: %s\n', channel_model);
fprintf(fid, '  decoder: %s\n', cfg_local.decoder);
fprintf(fid, '  snr_mode: %s\n', cfg_local.snr_mode);
fprintf(fid, '  num_frames: %d\n', cfg_local.num_frames);
fprintf(fid, '  seed: %d\n\n', cfg_local.seed);
fprintf(fid, 'CP CORRECTION\n');
fprintf(fid, '  r_total_cp_corrected = r_total * n_subcarriers/(n_subcarriers+n_cp).\n');
fprintf(fid, '  goodput_cp_corrected = r_total_cp_corrected * (1-BER).\n');
fprintf(fid, '  Main OFDM Goodput figures use CP-corrected Goodput.\n\n');
fprintf(fid, 'SUMMARY\n');
fprintf(fid, '  Best CP-corrected Goodput: p=%.2f, SNR=%.1f dB, Goodput=%.6f, BER=%.6e\n\n', ...
    T.p(best_idx), T.snr_dB(best_idx), best_goodput, T.ber(best_idx));
fprintf(fid, 'OUTPUT FILES\n');
fprintf(fid, '  ofdm_baseline.csv\n');
fprintf(fid, '  ofdm_baseline.mat\n');
fprintf(fid, '  run_log.txt\n');
fprintf(fid, '  figures/ofdm_ber_vs_snr.*\n');
fprintf(fid, '  figures/ofdm_goodput_vs_snr.*\n');
fprintf(fid, '  figures/ofdm_energy_goodput.*\n');
clear cleanup_fid;

fprintf('\n========== DONE ==========\n');
fprintf('Saved to: %s\n', out_dir);

%% ===== Local Functions =====

function result = local_sim_shaped_polar_16qam_ofdm(p, snr_dB, cfg)
    snr_dB = snr_dB(:).';
    nSNR = length(snr_dB);
    N = cfg.N;
    M = cfg.M;
    nFrames = cfg.num_frames;
    nSub = cfg.ofdm_n_subcarriers;
    nCp = round(nSub * cfg.ofdm_cp_ratio);

    if mod(N, nSub) ~= 0
        error('cfg.N (%d) must be divisible by ofdm_n_subcarriers (%d).', N, nSub);
    end
    nOfdmSymbols = N / nSub;

    if cfg.seed > 0
        rng(cfg.seed, 'twister');
    end

    p_vec = cfg.p_fixed;
    p_vec(isnan(p_vec)) = p;

    K_vec = zeros(1, 4);
    S_vec = zeros(1, 4);
    h_vec = zeros(1, 4);
    for b = 1:4
        pb = p_vec(b);
        if pb > 0 && pb < 1
            h_vec(b) = -pb*log2(pb) - (1-pb)*log2(1-pb);
        else
            h_vec(b) = 0;
        end
        S_vec(b) = ceil(N * (1 - h_vec(b)));
        K_vec(b) = ceil((N - S_vec(b)) / 2);
    end

    lambda_offset = 2.^(0:log2(N));
    llr_layer_vec = get_llr_layer(N);
    bit_layer_vec = get_bit_layer(N);

    BER_per_bit = zeros(4, nSNR);
    BLER_per_bit = zeros(4, nSNR);
    MI_per_bit = zeros(4, nSNR);
    spow_vec = zeros(1, nSNR);
    ofdm_time_power_vec = zeros(1, nSNR);

    for iSNR = 1:nSNR
        sigma = 10^(-snr_dB(iSNR) / 20);

        channels = GA(sigma, N);
        [~, channels_ordered] = sort(channels, 'descend');

        shaped_bits_pre = cell(1, 4);
        fb_dec = zeros(N, 4);
        SI_set = cell(1, 4);
        I_set = cell(1, 4);
        S_set_c = cell(1, 4);
        prior_llr_vec = cell(1, 4);

        for b = 1:4
            [shaped_bits_pre{b}, fb_dec(:,b), SI_set{b}, I_set{b}, S_set_c{b}] = ...
                local_prepare_one_bit(p_vec(b), S_vec(b), K_vec(b), N, ...
                channels_ordered, lambda_offset, llr_layer_vec, bit_layer_vec);

            prior_llr_vec{b} = zeros(N, 1);
            pb = p_vec(b);
            if pb > 0 && pb < 1 && pb ~= 0.5
                prior_llr_vec{b}(S_set_c{b}) = log((1 - pb) / pb);
            end
        end

        ber_acc = zeros(4, 1);
        bler_acc = zeros(4, 1);
        mi_acc = zeros(4, 1);
        spow_acc = 0;
        time_power_acc = 0;

        for iFrame = 1:nFrames
            xxx_enc = zeros(N, 4);
            origin = cell(1, 4);
            for b = 1:4
                code = zeros(N, 1);
                origin{b} = randi([0 1], K_vec(b), 1);
                code(I_set{b}) = origin{b};
                code(S_set_c{b}) = shaped_bits_pre{b};
                xxx_enc(:,b) = polar_encoder(code);
            end

            xxx = parallel_to_serial_bits(xxx_enc(:,1), xxx_enc(:,2), xxx_enc(:,3), xxx_enc(:,4));
            txSym = qammod(xxx, M, cfg.mapping, ...
                'InputType', 'bit', ...
                'UnitAveragePower', cfg.unit_avg_power);

            spow_frame = mean(abs(txSym).^2);
            spow_acc = spow_acc + spow_frame;

            txGrid = reshape(txSym, nSub, nOfdmSymbols);
            txTimeNoCp = ifft(txGrid, nSub, 1);
            txTimeCp = [txTimeNoCp(end-nCp+1:end, :); txTimeNoCp];
            time_power_acc = time_power_acc + mean(abs(txTimeCp(:)).^2);

            switch cfg.snr_mode
                case 'fixed_n0'
                    sigma_noise_freq = sqrt(cfg.snr_ref_power) * sigma;
                otherwise
                    sigma_noise_freq = sqrt(spow_frame) * sigma;
            end
            sigma_noise_time = sigma_noise_freq / sqrt(nSub);
            rxTimeCp = txTimeCp + sigma_noise_time * ...
                (randn(size(txTimeCp)) + 1j*randn(size(txTimeCp)));

            rxTimeNoCp = rxTimeCp(nCp+1:end, :);
            rxGrid = fft(rxTimeNoCp, nSub, 1);
            rxSym = rxGrid(:);

            if isfield(cfg, 'llr_use_legacy_noisevar') && cfg.llr_use_legacy_noisevar
                noise_var_for_llr = 2 * sigma^2;
            else
                noise_var_for_llr = 2 * sigma_noise_freq^2;
            end

            LLR_qam = qamdemod(rxSym, M, cfg.mapping, ...
                'OutputType', 'llr', ...
                'UnitAveragePower', cfg.unit_avg_power, ...
                'NoiseVariance', noise_var_for_llr);

            llr_bits = zeros(N, 4);
            for b = 1:4
                llr_bits(:,b) = LLR_qam(b:4:end);
            end

            for b = 1:4
                mi_acc(b) = mi_acc(b) + local_mutualinfo_llr(llr_bits(:,b), xxx_enc(:,b));

                switch cfg.decoder
                    case 'SCL'
                        decoded = SCL_decoder_prior(llr_bits(:,b), cfg.SCL_L, ...
                            K_vec(b)+S_vec(b), fb_dec(:,b), ...
                            lambda_offset, llr_layer_vec, bit_layer_vec, ...
                            prior_llr_vec{b});
                    case 'SCL_no_prior'
                        decoded = SCL_decoder(llr_bits(:,b), cfg.SCL_L, ...
                            K_vec(b)+S_vec(b), fb_dec(:,b), ...
                            lambda_offset, llr_layer_vec, bit_layer_vec);
                    case 'SC_prior'
                        decoded = SC_decoder_prior(llr_bits(:,b), K_vec(b)+S_vec(b), ...
                            fb_dec(:,b), lambda_offset, ...
                            llr_layer_vec, bit_layer_vec, prior_llr_vec{b});
                    otherwise
                        decoded = SC_decoder(llr_bits(:,b), K_vec(b)+S_vec(b), ...
                            fb_dec(:,b), lambda_offset, llr_layer_vec, bit_layer_vec);
                end

                code_hat = zeros(N, 1);
                code_hat(SI_set{b}) = decoded;
                info_hat = code_hat(I_set{b});

                nfails = sum(info_hat ~= origin{b});
                ber_acc(b) = ber_acc(b) + nfails;
                if nfails > 0
                    bler_acc(b) = bler_acc(b) + 1;
                end
            end
        end

        for b = 1:4
            BER_per_bit(b, iSNR) = ber_acc(b) / (K_vec(b) * nFrames);
            BLER_per_bit(b, iSNR) = bler_acc(b) / nFrames;
            MI_per_bit(b, iSNR) = mi_acc(b) / nFrames;
        end
        spow_vec(iSNR) = spow_acc / nFrames;
        ofdm_time_power_vec(iSNR) = time_power_acc / nFrames;

        K_total = sum(K_vec);
        BER_weighted = sum(K_vec .* BER_per_bit(:,iSNR)') / K_total;
        fprintf('  SNR = %+6.1f dB | BER = %.2e | MI_total = %.3f\n', ...
            snr_dB(iSNR), BER_weighted, sum(MI_per_bit(:,iSNR)));
    end

    K_total = sum(K_vec);
    result.BER = sum(bsxfun(@times, K_vec', BER_per_bit), 1) / K_total;
    result.BLER = sum(bsxfun(@times, K_vec', BLER_per_bit), 1) / K_total;
    result.BER_per_bit = BER_per_bit;
    result.BLER_per_bit = BLER_per_bit;
    result.MI = MI_per_bit;
    result.MI_total = sum(MI_per_bit, 1);
    result.spow = spow_vec;
    result.ofdm_time_power = ofdm_time_power_vec;
    result.K = K_vec;
    result.S_size = S_vec;
    result.R_total = K_total / (4 * N);
    result.R_total_cp_corrected = result.R_total * nSub / (nSub + nCp);
    result.E_theory = 18 - 16*p;
    result.p = p;
    result.snr_dB = snr_dB;
    result.ofdm_n_subcarriers = nSub;
    result.ofdm_cp_len = nCp;
    result.ofdm_cp_ratio = cfg.ofdm_cp_ratio;
    result.cfg = cfg;
end

function [shaped_bits, frozen_bits_dec, SandI_set, I_set, S_set] = ...
    local_prepare_one_bit(pb, S_size, K, N, channels_ordered, lambda_offset, llr_layer_vec, bit_layer_vec)
    S_set = sort(channels_ordered(1:S_size), 'ascend');
    I_set = sort(channels_ordered(S_size+1:S_size+K), 'ascend');
    SandI_set = sort(channels_ordered(1:S_size+K), 'ascend');

    llr_src = ones(N, 1) * log((1-pb)/pb);
    frozen_bits_src = ones(N, 1);
    frozen_bits_src(S_set) = 0;
    shaped_bits = SC_decoder(llr_src, S_size, frozen_bits_src, ...
        lambda_offset, llr_layer_vec, bit_layer_vec);

    frozen_bits_dec = ones(N, 1);
    frozen_bits_dec(I_set) = 0;
    frozen_bits_dec(S_set) = 0;
end

function I = local_mutualinfo_llr(L, x)
    L = L(:);
    x = x(:);
    s = 1 - 2*x;
    z = -s .* L;
    I = 1 - mean(log1p(exp(z))) / log(2);
end
