function result = simulate_ook_shaped_polar(p, opts)
% SIMULATE_OOK_SHAPED_POLAR Reproduce legacy OOK shaped-polar chain.
%
% This function follows the core idea of ShapedPolarS/gettest.m:
% S = ceil(N*(1-h(p))), GA-based S/I/F construction, SC shaping, OOK 0/1
% transmission, Gaussian noise, and SC decoding of information bits.

    opts = local_defaults(opts);
    if opts.seed > 0
        rng(opts.seed, 'twister');
    end

    local_add_legacy_path();

    N = opts.N;
    snr_grid = opts.snr_grid(:).';
    nSNR = numel(snr_grid);

    h_p = local_binary_entropy(p);
    S_size = ceil(N * (1 - h_p));
    S_size_complementary = N - S_size;
    K = ceil(S_size_complementary / 2);
    R = K / N;

    BER = zeros(1, nSNR);
    BLER = zeros(1, nSNR);
    error_count = zeros(1, nSNR);
    block_error_count = zeros(1, nSNR);
    energy_mean = zeros(1, nSNR);
    encoded_one_fraction = zeros(1, nSNR);
    frames_used = opts.num_frames * ones(1, nSNR);

    lambda_offset = 2 .^ (0:log2(N));
    llr_layer_vec = get_llr_layer(N);
    bit_layer_vec = get_bit_layer(N);

    for iSNR = 1:nSNR
        snr_db = snr_grid(iSNR);
        sigma_design = 10 ^ (-snr_db / 20);
        channels = GA(sigma_design, N);
        [~, channels_ordered] = sort(channels, 'descend');

        S_set = sort(channels_ordered(1:S_size), 'ascend');
        I_set = sort(channels_ordered(S_size + 1:S_size + K), 'ascend');
        SandI_set = sort(channels_ordered(1:S_size + K), 'ascend');

        shape_frozen = ones(N, 1);
        shape_frozen(S_set) = 0;
        data_frozen = ones(N, 1);
        data_frozen(I_set) = 0;
        data_frozen(S_set) = 0;

        total_errors = 0;
        total_block_errors = 0;
        total_energy = 0;
        total_ones = 0;

        if ~opts.regenerate_each_frame
            [origin_data_static, tx_static, shaped_bits_static] = ...
                local_make_codeword(p, K, N, S_set, I_set, shape_frozen, ...
                lambda_offset, llr_layer_vec, bit_layer_vec);
        end

        for iFrame = 1:opts.num_frames
            if opts.regenerate_each_frame
                [origin_data, tx_bits, shaped_bits] = ...
                    local_make_codeword(p, K, N, S_set, I_set, shape_frozen, ...
                    lambda_offset, llr_layer_vec, bit_layer_vec);
            else
                origin_data = origin_data_static;
                tx_bits = tx_static;
                shaped_bits = shaped_bits_static; %#ok<NASGU>
            end

            signal_power = mean(tx_bits .^ 2);
            sigma_noise = sqrt(signal_power / (2 * 10 ^ (snr_db / 10)));
            rx = tx_bits + sigma_noise * randn(N, 1);

            llr = (1 - 2 * rx) / (2 * sigma_design ^ 2);
            decoded_sandi = SC_decoder(llr, K + S_size, data_frozen, ...
                lambda_offset, llr_layer_vec, bit_layer_vec);

            code_hat = zeros(N, 1);
            code_hat(SandI_set) = decoded_sandi;
            data_hat = code_hat(I_set);

            n_err = sum(data_hat ~= origin_data);
            total_errors = total_errors + n_err;
            total_block_errors = total_block_errors + double(n_err > 0);
            total_energy = total_energy + signal_power;
            total_ones = total_ones + mean(tx_bits);
        end

        error_count(iSNR) = total_errors;
        block_error_count(iSNR) = total_block_errors;
        BER(iSNR) = total_errors / max(K * opts.num_frames, 1);
        BLER(iSNR) = total_block_errors / opts.num_frames;
        energy_mean(iSNR) = total_energy / opts.num_frames;
        encoded_one_fraction(iSNR) = total_ones / opts.num_frames;
    end

    goodput = R * (1 - BER);
    result = struct();
    result.p = p;
    result.N = N;
    result.S_size = S_size;
    result.K = K;
    result.R = R;
    result.snr_grid = snr_grid;
    result.BER = BER;
    result.BLER = BLER;
    result.goodput = goodput;
    result.energy_mean = energy_mean;
    result.encoded_one_fraction = encoded_one_fraction;
    result.error_count = error_count;
    result.block_error_count = block_error_count;
    result.frames_used = frames_used;
    result.num_frames = opts.num_frames;
    result.seed = opts.seed;
    result.regenerate_each_frame = opts.regenerate_each_frame;
end

function opts = local_defaults(opts)
    if nargin < 1 || isempty(opts)
        opts = struct();
    end
    if ~isfield(opts, 'N'); opts.N = 1024; end
    if ~isfield(opts, 'snr_grid'); opts.snr_grid = -5:5:20; end
    if ~isfield(opts, 'num_frames'); opts.num_frames = 20; end
    if ~isfield(opts, 'seed'); opts.seed = 42; end
    if ~isfield(opts, 'regenerate_each_frame'); opts.regenerate_each_frame = true; end
end

function local_add_legacy_path()
    this_dir = fileparts(mfilename('fullpath'));
    legacy_dir = fullfile(this_dir, '..', 'ShapedPolarS');
    addpath(legacy_dir);
end

function h = local_binary_entropy(p)
    p = min(max(p, eps), 1 - eps);
    h = -p * log2(p) - (1 - p) * log2(1 - p);
end

function [origin_data, tx_bits, shaped_bits] = local_make_codeword(p, K, N, ...
    S_set, I_set, shape_frozen, lambda_offset, llr_layer_vec, bit_layer_vec)
    S_size = numel(S_set);
    prior_llr = log((1 - p) / p) * ones(N, 1);
    shaped_bits = SC_decoder(prior_llr, S_size, shape_frozen, ...
        lambda_offset, llr_layer_vec, bit_layer_vec);

    origin_data = randi([0, 1], K, 1);
    u = zeros(N, 1);
    u(I_set) = origin_data;
    u(S_set) = shaped_bits;
    tx_bits = polar_encoder(u);
end
