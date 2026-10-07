function result = sim_shaped_polar_gray_qam(M, shaping_spec, snr_dB, cfg)
%SIM_SHAPED_POLAR_GRAY_QAM Single-carrier multi-stream Gray-QAM SC simulation.
% Accepts shaping_spec.source='latent_p' or target source='energy_lambda'.
    if nargin < 4 || isempty(cfg), cfg = config(); end
    qam = build_cartesian_gray_qam(M);
    [pI, TI, pQ, TQ, shape_meta] = local_normalize_latent_spec(shaping_spec, qam);
    model = build_qam_model_pmf(qam, pI, TI, pQ, TQ);
    snr_dB = snr_dB(:).';
    if isempty(snr_dB) || any(~isfinite(snr_dB))
        error('v3:SNR', 'snr_dB must be a nonempty finite vector.');
    end
    required = {'N','num_frames','seed','snr_mode'};
    for k = 1:numel(required)
        if ~isfield(cfg, required{k}), error('v3:Config', 'cfg.%s is required.', required{k}); end
    end
    if cfg.seed > 0, rng(cfg.seed, 'twister'); end
    p_all = [pI(:); pQ(:)];
    streams = cell(qam.m, 1);
    if isfield(cfg, 'bsc_s_mode'), bsc_s_mode = cfg.bsc_s_mode; else, bsc_s_mode = 'reliable'; end
    if isfield(cfg, 'source_construction'), source_construction = cfg.source_construction; else, source_construction = 'bsc_ga'; end
    if isfield(cfg, 'source_mc_seed'), source_seed_base = cfg.source_mc_seed; else, source_seed_base = cfg.seed; end
    for k = 1:qam.m
        switch source_construction
            case 'bsc_ga'
                streams{k} = build_stream_partition_bsc_ga(cfg.N, p_all(k), 1.0, bsc_s_mode);
            case 'source_mc_ga'
                if isfield(cfg, 'source_mc_samples'), n_source = cfg.source_mc_samples; else, n_source = 300; end
                streams{k} = build_stream_partition_source_mc_ga(cfg.N, p_all(k), 1.0, n_source, source_seed_base + 1000*k);
            otherwise
                error('v3:SourceConstruction', 'cfg.source_construction must be bsc_ga or source_mc_ga.');
        end
    end
    K = cellfun(@(s) s.K, streams); S_size = cellfun(@(s) s.S_size, streams);
    F_size = cellfun(@(s) s.F_size, streams);
    R_code = sum(K) / (qam.m * cfg.N); R_bpcu = sum(K) / cfg.N;
    E_model = sum(model.psym .* abs(qam.constellation).^2);
    nSNR = numel(snr_dB); bit_errors = zeros(qam.m, nSNR); block_errors = zeros(qam.m, nSNR);
    joint_block_errors = zeros(1, nSNR); empirical_counts = zeros(qam.M, nSNR); frames = zeros(1, nSNR);
    latent_one_counts = zeros(qam.m, nSNR);
    collect_frame_pmf = isfield(cfg, 'collect_frame_pmf') && cfg.collect_frame_pmf;
    if collect_frame_pmf
        frame_psym = zeros(qam.M, cfg.num_frames, nSNR);
    else
        frame_psym = [];
    end
    for is = 1:nSNR
        sigma = local_sigma(snr_dB(is), E_model, cfg.snr_mode);
        for iframe = 1:cfg.num_frames
            z_tx = zeros(cfg.N, qam.m); payload = cell(qam.m, 1);
            for k = 1:qam.m
                payload{k} = randi([0 1], streams{k}.K, 1);
                if isfield(cfg, 'force_nonzero_payload') && cfg.force_nonzero_payload && streams{k}.K > 0
                    payload{k}(1) = 1;
                end
                [~, z_tx(:, k)] = shape_stream_sc(payload{k}, streams{k});
            end
            [tx, ~, idx] = map_latent_bits_to_qam(z_tx, qam, model);
            latent_one_counts(:, is) = latent_one_counts(:, is) + sum(z_tx, 1).';
            empirical_counts(:, is) = empirical_counts(:, is) + accumarray(idx, 1, [qam.M 1]);
            if collect_frame_pmf, frame_psym(:, iframe, is) = accumarray(idx, 1, [qam.M 1]) / cfg.N; end
            rx = tx + sigma * (randn(cfg.N, 1) + 1i * randn(cfg.N, 1));
            llr = reshape(llr_gray_qam_latent_lse(rx, qam, model, sigma), qam.m, cfg.N).';
            any_payload_error = false;
            for k = 1:qam.m
                known_mask = false(cfg.N, 1); known_bits = zeros(cfg.N, 1);
                known_mask(streams{k}.F) = true;
                u_hat = sc_decode_forced_full(llr(:, k), known_mask, known_bits);
                payload_hat = u_hat(streams{k}.I);
                nerr = sum(payload_hat ~= payload{k});
                bit_errors(k, is) = bit_errors(k, is) + nerr;
                block_errors(k, is) = block_errors(k, is) + (nerr > 0);
                any_payload_error = any_payload_error || (nerr > 0);
            end
            joint_block_errors(is) = joint_block_errors(is) + any_payload_error;
            frames(is) = frames(is) + 1;
        end
    end
    BER_per_bit = bit_errors ./ (K * frames);
    BLER_per_bit = block_errors ./ frames;
    BER = sum(bit_errors, 1) ./ (sum(K) * frames);
    BLER_joint = joint_block_errors ./ frames;
    empirical_psym = empirical_counts ./ (cfg.N * frames);
    result = struct('M', qam.M, 'm', qam.m, 'MI', qam.MI, 'MQ', qam.MQ, ...
        'mI', qam.mI, 'mQ', qam.mQ, 'constellation', qam.constellation, ...
        'labels', qam.labels, 'uniform_scale', qam.uniform_scale, ...
        'axis_I', struct('p',pI,'T',TI), 'axis_Q', struct('p',pQ,'T',TQ), ...
        'relation_I', TI, 'relation_Q', TQ, 'target_psym', shape_meta.target_psym, ...
        'model_psym', model.psym, 'empirical_psym', empirical_psym, ...
        'target_latent_p', p_all, 'empirical_latent_p', latent_one_counts ./ (cfg.N * frames), ...
        'frame_psym', frame_psym, ...
        'kl_target_model', shape_meta.kl_target_model, ...
        'tv_target_model', shape_meta.tv_target_model, ...
        'pmf_validation', shape_meta.match_status, ...
        'BER', BER, 'BLER', BLER_joint, 'BER_per_bit', BER_per_bit, ...
        'BLER_per_bit', BLER_per_bit, 'errors', bit_errors, 'frames', frames, ...
        'K', K, 'S_size', S_size, 'F_size', F_size, 'R_code', R_code, ...
        'R_bpcu', R_bpcu, 'Goodput', R_bpcu * (1 - BLER_joint), ...
        'BLER_joint', BLER_joint, 'rf_energy_proxy_model', E_model, ...
        'rf_energy_proxy_empirical', sum(bsxfun(@times, empirical_psym, abs(qam.constellation).^2), 1), ...
        'rf_energy_proxy_target', shape_meta.rf_energy_proxy_target, ...
        'lambda', shape_meta.lambda, 'snr_dB', snr_dB, 'snr_mode', cfg.snr_mode, ...
        'cfg', cfg, 'seed', cfg.seed, 'streams', {streams}, ...
        'shaping_meta', shape_meta, 'result_dir', '');
end

function [pI, TI, pQ, TQ, meta] = local_normalize_latent_spec(spec, qam)
    if ~isstruct(spec) || ~isfield(spec, 'source')
        error('v3:ShapingSpec', 'shaping_spec.source is required.');
    end
    if strcmp(spec.source, 'energy_lambda')
        if ~isfield(spec, 'lambda')
            error('v3:ShapingSpec', 'shaping_spec.lambda is required for energy_lambda.');
        end
        if isfield(spec, 'relation_I'), relation_I = spec.relation_I; else, relation_I = []; end
        if isfield(spec, 'relation_Q'), relation_Q = spec.relation_Q; else, relation_Q = []; end
        built = build_energy_lambda_spec(qam, spec.lambda, relation_I, relation_Q);
        pI = built.pI; pQ = built.pQ; TI = built.relation_I; TQ = built.relation_Q;
        meta = built;
        return;
    elseif ~strcmp(spec.source, 'latent_p')
        error('v3:ShapingSpec', 'source must be latent_p or energy_lambda.');
    end
    required = {'pI','pQ'};
    for k = 1:numel(required)
        if ~isfield(spec, required{k}), error('v3:ShapingSpec', 'shaping_spec.%s is required.', required{k}); end
    end
    pI = spec.pI(:); pQ = spec.pQ(:);
    if isfield(spec, 'relation_I'), TI = spec.relation_I; else, TI = []; end
    if isfield(spec, 'relation_Q'), TQ = spec.relation_Q; else, TQ = []; end
    if isempty(TI), TI = eye(qam.mI); end
    if isempty(TQ), TQ = eye(qam.mQ); end
    if numel(pI) ~= qam.mI || numel(pQ) ~= qam.mQ
        error('v3:ShapingSpec', 'pI/pQ lengths must equal mI/mQ.');
    end
    gf2_inverse(TI); gf2_inverse(TQ);
    model = build_qam_model_pmf(qam, pI, TI, pQ, TQ);
    meta = struct('target_psym', model.psym, 'kl_target_model', 0, ...
        'tv_target_model', 0, 'match_status', 'by-construction', ...
        'rf_energy_proxy_target', sum(model.psym .* abs(qam.constellation).^2), ...
        'lambda', NaN);
end

function sigma = local_sigma(snr, E_model, mode)
    switch mode
        case 'fixed_n0', sigma = sqrt(1 / (2 * 10^(snr / 10)));
        case 'fixed_esn0', sigma = sqrt(E_model / (2 * 10^(snr / 10)));
        otherwise, error('v3:SNRMode', 'cfg.snr_mode must be fixed_n0 or fixed_esn0.');
    end
end
