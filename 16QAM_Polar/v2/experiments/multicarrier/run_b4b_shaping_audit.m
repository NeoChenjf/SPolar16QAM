%% RUN_B4B_SHAPING_AUDIT
% Audit message-conditioned shaping against the frozen B4b implementation.
% Modes: static (default), smoke, pmf. No Rayleigh full-chain run.

if ~exist('b4b_audit_overrides', 'var')
    b4b_audit_overrides = struct();
end
script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
v3_root = fullfile(v2_root, '..', 'v3');
addpath(v2_root);
setup_paths();
cfg_local = config();
addpath(v3_root);
addpath(fullfile(v3_root, 'polar'));
addpath(fullfile(v3_root, 'modulation'));

if isfield(b4b_audit_overrides, 'render_result_dir')
    saved_dir = b4b_audit_overrides.render_result_dir;
    saved = load(fullfile(saved_dir, 'b4b_shaping_audit.mat'));
    variants = cellstr(unique(saved.frame_table.variant, 'stable'))';
    local_plot_pmf(fullfile(saved_dir, 'figures'), saved.p_values, ...
        saved.target_pmf, saved.frame_table, variants);
    local_plot_tv(fullfile(saved_dir,'figures'),saved.p_values,saved.pmf_table,saved.seed_pmf_table);
    fprintf('Re-rendered saved results; no simulation: %s\n', saved_dir);
    return;
end

cfg_local.N = local_override(b4b_audit_overrides, 'N', 1024);
cfg_local.M = 16;
cfg_local.mapping = 'gray';
cfg_local.unit_avg_power = true;
cfg_local.output_dir = fullfile(v2_root, 'results');
mode = local_override(b4b_audit_overrides, 'mode', 'static');
cfg_local.partition = local_override(b4b_audit_overrides, 'partition', 'B4_GA');
cfg_local.source_samples = 200; cfg_local.source_seed = 9001;
assert(any(strcmp(cfg_local.partition, {'B4_GA','source_MC_GA'})), 'Unknown partition.');
p_values = local_override(b4b_audit_overrides, 'p_values', [0.5, 0.3, 0.1]);
seed_values = 1701;
frames_per_seed = 1;
bootstrap_reps = 2000;
if strcmpi(mode, 'smoke')
    seed_values = [1701, 2903];
    frames_per_seed = 8;
elseif strcmpi(mode, 'static')
    seed_values = [1701, 2903];
    frames_per_seed = 3;
elseif strcmpi(mode, 'pmf')
    seed_values = [1701, 2903, 4127];
    frames_per_seed = 80;
elseif strcmpi(mode, 'blocklength')
    seed_values = [1701, 2903, 4127];
    frames_per_seed = 80;
elseif any(strcmpi(mode, {'frozen_compare', 'source_compare', 'formal_source'}))
    seed_values = [1701, 2903, 4127];
    frames_per_seed = 80;
end
if isfield(b4b_audit_overrides, 'seed_values')
    seed_values = b4b_audit_overrides.seed_values;
end
if isfield(b4b_audit_overrides, 'frames_per_seed')
    frames_per_seed = b4b_audit_overrides.frames_per_seed;
end
if ~any(strcmpi(mode, {'static', 'smoke', 'pmf', 'blocklength', 'frozen_compare', 'source_compare', 'formal_source'}))
    error('Mode must be static, smoke, pmf, blocklength, frozen_compare, or source_compare.');
end
if strcmpi(mode, 'blocklength') && ~ismember(cfg_local.N, [256, 1024])
    error('Blocklength mode supports the preregistered N values 256 and 1024.');
end
if strcmpi(mode, 'static') && (frames_per_seed > 3 || numel(seed_values) > 2)
    error('Static mode is limited to 3 payload cases and 2 seeds.');
elseif strcmpi(mode, 'smoke') && (frames_per_seed > 8 || numel(seed_values) > 2)
    error('Smoke mode is limited to 8 frames and 2 seeds.');
end
validateattributes(frames_per_seed, {'numeric'}, {'scalar','integer','positive'});
validateattributes(seed_values, {'numeric'}, {'vector','integer','positive'});
validateattributes(p_values, {'numeric'}, {'vector','real','finite','>',0,'<',1});
local_assert_label_roundtrip(cfg_local);
if any(strcmpi(mode, {'source_compare','formal_source'})), local_assert_exact_source(); end

mode_suffix = lower(mode);
if strcmpi(mode, 'blocklength')
    mode_suffix = sprintf('%s_N%d', mode_suffix, cfg_local.N);
elseif any(strcmpi(mode, {'frozen_compare','formal_source'}))
    mode_suffix = sprintf('%s_N%d', mode_suffix, cfg_local.N);
end
if strcmp(cfg_local.partition, 'source_MC_GA'), mode_suffix = [mode_suffix '_source_MC_GA']; end
out_dir = fullfile(cfg_local.output_dir, ...
    [datestr(now, 'yyyymmdd_HHMMSS') '_b4b_shaping_audit_' mode_suffix]);
audit_timer = tic;
fig_dir = fullfile(out_dir, 'figures');
mkdir(out_dir); mkdir(fig_dir);
local_snapshot_sources(out_dir, script_dir, v2_root, v3_root);
diary(fullfile(out_dir, 'run_log.txt')); diary on;
cleanup_diary = onCleanup(@() diary('off')); %#ok<NASGU>
fprintf('B4b shaping audit | mode=%s | N=%d | frames/seed=%d | seeds=%s\n', ...
    mode, cfg_local.N, frames_per_seed, mat2str(seed_values));

if strcmpi(mode, 'formal_source')
    strategy_variants = {'source_entropy_conditioned'};
elseif strcmpi(mode, 'source_compare')
    strategy_variants = {'fixed_frozen_zero', 'exact_map_zero', 'exact_conditional_random'};
elseif strcmpi(mode, 'frozen_compare')
    strategy_variants = {'fixed_frozen_zero', 'iid_uniform_frozen'};
else
    strategy_variants = {'legacy_fixed', 'message_conditioned'};
end
n_rows = numel(p_values) * numel(strategy_variants) * ...
    numel(seed_values) * frames_per_seed;
rows = cell(n_rows, 16);
partition_rows = cell(numel(p_values) * 4, 5);
partition_set_rows = {};
row_i = 0;
partition_i = 0;
for ip = 1:numel(p_values)
    p = p_values(ip);
    state = local_prepare_state(p, cfg_local);
    fprintf('p=%.1f | K=%s | S=%s | F=%s\n', p, mat2str(state.K), ...
        mat2str(state.S_size), mat2str(state.F_size));
    for b = 1:4
        partition_i = partition_i + 1;
        partition_rows(partition_i, :) = {p, b, state.K(b), ...
            state.S_size(b), state.F_size(b)};
        set_names={'S','I','F'}; set_values={state.S{b},state.I{b},state.F{b}};
        for iset=1:3
            for index=set_values{iset}(:).'
                partition_set_rows(end+1,:)={p,b,set_names{iset},index}; %#ok<AGROW>
            end
        end
    end
    for iv = 1:numel(strategy_variants)
        variant = strategy_variants{iv};
        legacy_shape = local_legacy_shape_bits(p, state);
        for iseed = 1:numel(seed_values)
            seed = seed_values(iseed);
            rng(seed, 'twister');
            for iframe = 1:frames_per_seed
                payload = cell(1, 4);
                payload_case = 'random';
                for b = 1:4
                    if strcmpi(mode, 'static') && iframe == 1
                        payload{b} = zeros(state.K(b), 1); payload_case = 'all_zero';
                    elseif strcmpi(mode, 'static') && iframe == 2
                        payload{b} = ones(state.K(b), 1); payload_case = 'all_one';
                    else
                        payload{b} = randi([0, 1], state.K(b), 1);
                    end
                end
                frozen_values = local_frozen_values(variant, state, seed, iframe);
                [u, x, shaped_by_stream, frozen_values] = local_encode_frame( ...
                    payload, state, variant, legacy_shape, cfg_local, frozen_values, seed + 100000 * iframe);
                [n_errors, block_errors] = local_noiseless_decode( ...
                    x, payload, state, frozen_values, variant);
                assert(n_errors == 0, ...
                    'Noiseless information-bit recovery failed (%s, p=%.2f).', variant, p);
                counts = histcounts(local_symbol_indices(x, cfg_local), -0.5:1:15.5);
                payload_fingerprint = zeros(1, 4);
                for b = 1:4
                    weights = mod((1:state.K(b))' * 7919, 1000003);
                    payload_fingerprint(b) = mod(sum(double(payload{b}) .* weights), 2147483647);
                end
                row_i = row_i + 1;
                rows(row_i, 1:11) = {p, variant, seed, iframe, n_errors, ...
                    block_errors, mean(abs(x).^2), ...
                    sum(shaped_by_stream), nnz(state.I{2}) + nnz(state.I{4}), ...
                    counts, payload_case};
                rows{row_i, 12} = sum(cellfun(@nnz, frozen_values));
                rows(row_i, 13:16) = num2cell(payload_fingerprint);
            end
        end
    end
end

% Store one row per frame with an explicit 16-symbol count vector.
frame_table = local_make_frame_table(rows(1:row_i, :), cfg_local.N);
local_assert_paired_payloads(frame_table, strategy_variants);
partition_table = cell2table(partition_rows, 'VariableNames', ...
    {'p', 'bit_stream', 'K', 'S_size', 'F_size'});
partition_table.p = cell2mat(partition_rows(:, 1));
partition_table.bit_stream = cell2mat(partition_rows(:, 2));
partition_table.K = cell2mat(partition_rows(:, 3));
partition_table.S_size = cell2mat(partition_rows(:, 4));
partition_table.F_size = cell2mat(partition_rows(:, 5));
partition_set_table=cell2table(partition_set_rows,'VariableNames', ...
    {'p','bit_stream','set_name','source_index'});
partition_set_table.p=cell2mat(partition_set_rows(:,1));
partition_set_table.bit_stream=cell2mat(partition_set_rows(:,2));
partition_set_table.source_index=cell2mat(partition_set_rows(:,4));
writetable(frame_table, fullfile(out_dir, 'frame_audit.csv'));
writetable(partition_table, fullfile(out_dir, 'partition_summary.csv'));
writetable(partition_set_table,fullfile(out_dir,'partition_indices.csv'));
[target_pmf, model_pmf] = local_target_model_pmfs(p_values, cfg_local);
pmf_table = local_make_pmf_table(p_values, target_pmf, model_pmf, frame_table, ...
    bootstrap_reps, strategy_variants);
seed_pmf_table = local_make_seed_pmf_table(p_values, target_pmf, frame_table, ...
    bootstrap_reps, strategy_variants);
conditioning_table = local_conditioning_probe(p_values, cfg_local);
writetable(pmf_table, fullfile(out_dir, 'pmf_summary.csv'));
writetable(seed_pmf_table, fullfile(out_dir, 'pmf_by_seed.csv'));
if any(strcmpi(mode, {'pmf','formal_source','blocklength'}))
    gate_table = local_make_pmf_gate(pmf_table, seed_pmf_table);
    writetable(gate_table, fullfile(out_dir, 'pmf_gate_status.csv'));
end
writetable(conditioning_table, fullfile(out_dir, 'conditioning_probe.csv'));
elapsed_seconds = toc(audit_timer);
save(fullfile(out_dir, 'b4b_shaping_audit.mat'), 'cfg_local', 'mode', ...
    'p_values', 'seed_values', 'frames_per_seed', 'frame_table', 'partition_table', ...
    'partition_set_table', ...
    'pmf_table', 'seed_pmf_table', 'conditioning_table', ...
    'target_pmf', 'model_pmf', 'elapsed_seconds');
local_write_readme(out_dir, mode, cfg_local, p_values, seed_values, ...
    frames_per_seed, frame_table, partition_table, pmf_table, seed_pmf_table, elapsed_seconds);
local_plot_pmf(fig_dir, p_values, target_pmf, frame_table, strategy_variants);
local_plot_tv(fig_dir,p_values,pmf_table,seed_pmf_table);
fprintf('Audit outputs: %s\n', out_dir);

function value = local_override(s, name, fallback)
    if isfield(s, name), value = s.(name); else, value = fallback; end
end

function local_snapshot_sources(out_dir, script_dir, v2_root, v3_root)
    sources = {fullfile(script_dir, 'run_b4b_shaping_audit.m'), ...
        fullfile(v2_root, 'polar', 'build_source_entropy_partition.m'), ...
        fullfile(v2_root, 'polar', 'GA.m'), fullfile(v2_root, 'polar', 'SC_decoder.m'), ...
        fullfile(v2_root, 'polar', 'polar_encoder.m'), ...
        fullfile(v2_root, 'modulation', 'parallel_to_serial_bits.m'), ...
        fullfile(v2_root, 'modulation', 'llr_16qam_gray_LSE.m'), ...
        fullfile(v3_root, 'polar', 'build_stream_partition_source_mc_ga.m'), ...
        fullfile(v3_root, 'polar', 'shape_stream_sc.m'), ...
        fullfile(v3_root, 'polar', 'sc_decode_forced_full.m')};
    snapshot_dir = fullfile(out_dir, 'source_snapshot'); mkdir(snapshot_dir);
    manifest = fullfile(out_dir, 'sha256_manifest.txt'); fid = fopen(manifest, 'w');
    if fid < 0, error('Cannot create source hash manifest.'); end
    cleanup = onCleanup(@() fclose(fid));
    for k = 1:numel(sources)
        if exist(sources{k}, 'file') ~= 2, error('Missing source snapshot file: %s', sources{k}); end
        [~, name, ext] = fileparts(sources{k});
        copyfile(sources{k}, fullfile(snapshot_dir, [name ext]));
        stream = fopen(sources{k}, 'rb'); bytes = fread(stream, Inf, '*uint8'); fclose(stream);
        md = java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
        digest = typecast(md.digest(), 'uint8'); hex = lower(reshape(dec2hex(digest, 2)', 1, []));
        fprintf(fid, '%s  %s\n', hex, sources{k});
    end
    clear cleanup;
end

function local_assert_label_roundtrip(cfg)
    labels = de2bi((0:cfg.M-1).', log2(cfg.M), 'left-msb');
    tx = qammod(labels(:), cfg.M, cfg.mapping, 'InputType', 'bit', ...
        'UnitAveragePower', cfg.unit_avg_power);
    rx = qamdemod(tx, cfg.M, cfg.mapping, 'OutputType', 'bit', ...
        'UnitAveragePower', cfg.unit_avg_power);
    assert(isequal(double(rx(:)), double(labels(:))), ...
        'Gray QAM label roundtrip disagrees with the target PMF label order.');
end

function local_assert_paired_payloads(T, variants)
    p_values = unique(T.p); seeds = unique(T.seed); frames = unique(T.frame);
    fields = {'payload_fp_1', 'payload_fp_2', 'payload_fp_3', 'payload_fp_4'};
    for ip = 1:numel(p_values)
        for is = 1:numel(seeds)
            for iframe = 1:numel(frames)
                base = T.p == p_values(ip) & T.seed == seeds(is) & ...
                    T.frame == frames(iframe);
                reference = base & T.variant == string(variants{1});
                assert(nnz(reference) == 1, 'Expected one row for each payload and variant.');
                for iv = 2:numel(variants)
                    paired = base & T.variant == string(variants{iv});
                    assert(nnz(paired) == 1, 'Expected one row for each payload and variant.');
                    for k = 1:numel(fields)
                        values = T.(fields{k});
                        assert(values(reference) == values(paired), ...
                            'Shaping variants used different payload samples.');
                    end
                end
            end
        end
    end
end

function state = local_prepare_state(p, cfg)
    N=cfg.N; p_vec=[0.5,p,0.5,p];
    sigma_design=10^(-20/20);
    if strcmp(cfg.partition,'source_MC_GA')
        partition=build_source_entropy_partition(N,p_vec,sigma_design,cfg.source_samples,cfg.source_seed);
    else
        partition=[];
    end
    [~,order]=sort(GA(sigma_design,N),'descend');
    K=zeros(1,4); S_size=zeros(1,4); F_size=zeros(1,4);
    S=cell(1,4); I=cell(1,4); F=cell(1,4);
    for b=1:4
        pb=p_vec(b); h=-pb*log2(pb)-(1-pb)*log2(1-pb);
        S_size(b)=ceil(N*(1-h)); K(b)=ceil((N-S_size(b))/2);
        if isempty(partition)
            S{b}=sort(order(1:S_size(b))); I{b}=sort(order(S_size(b)+1:S_size(b)+K(b)));
            F{b}=sort(order(S_size(b)+K(b)+1:end));
        else
            S{b}=partition.S{b}; I{b}=partition.I{b}; F{b}=partition.F{b};
        end
        S{b}=S{b}(:); I{b}=I{b}(:); F{b}=F{b}(:); F_size(b)=numel(F{b});
        assert(isempty(intersect(S{b},I{b})) && isempty(intersect(S{b},F{b})) ...
            && isempty(intersect(I{b},F{b})) && numel(unique([S{b};I{b};F{b}]))==N);
    end
    state=struct('N',N,'p_vec',p_vec,'K',K,'S_size',S_size,'F_size',F_size, ...
        'I',{I},'S',{S},'F',{F},'partition',partition, ...
        'lambda_offset',2.^(0:log2(N)),'llr_layer_vec',get_llr_layer(N), ...
        'bit_layer_vec',get_bit_layer(N));
end

function shaped_bits = local_legacy_shape_bits(p, state)
    shaped_bits = cell(1, 4);
    for b = 1:4
        nS = state.S_size(b);
        if nS == 0
            shaped_bits{b} = zeros(0, 1);
            continue;
        end
        source_llr = ones(state.N, 1) * log((1 - p) / p);
        frozen_source = ones(state.N, 1);
        frozen_source(state.S{b}) = 0;
        shaped_bits{b} = SC_decoder(source_llr, nS, frozen_source, ...
            state.lambda_offset, state.llr_layer_vec, state.bit_layer_vec);
    end
end

function frozen_values = local_frozen_values(variant, state, seed, frame)
    frozen_values = cell(1, 4);
    for b = 1:4
        if strcmp(variant, 'iid_uniform_frozen') && state.F_size(b) > 0
            caller_rng = rng;
            rng(seed + 100000 * frame + 1000 * b + 9100000, 'twister');
            frozen_values{b} = randi([0, 1], state.F_size(b), 1);
            rng(caller_rng);
        else
            frozen_values{b} = zeros(state.F_size(b), 1);
        end
    end
end

function [u, x, shaped_by_stream, frozen_values] = local_encode_frame(payload, state, ...
        variant, legacy_shape, cfg, frozen_values, sampling_seed)
    u = zeros(state.N, 4); shaped_by_stream = 0;
    for b = 1:4
        if any(strcmp(variant, {'exact_map_zero', 'exact_conditional_random'}))
            known_mask = false(state.N, 1); known_bits = zeros(state.N, 1);
            known_mask(state.I{b}) = true; known_bits(state.I{b}) = payload{b};
            options = struct('exact', true);
            if strcmp(variant, 'exact_map_zero')
                known_mask(state.F{b}) = true;
            else
                caller_rng = rng;
                rng(sampling_seed + 104729*b + 19000000, 'twister');
                options.uniforms = rand(state.N, 1);
                rng(caller_rng);
            end
            source_llr = ones(state.N, 1) * log((1 - state.p_vec(b)) / state.p_vec(b));
            u(:, b) = sc_decode_forced_full(source_llr, known_mask, known_bits, [], options);
            frozen_values{b} = u(state.F{b}, b);
        elseif any(strcmp(variant, {'fixed_frozen_zero', 'iid_uniform_frozen', 'exact_map_zero', 'exact_conditional_random'}))
            known_mask = false(state.N, 1); known_bits = zeros(state.N, 1);
            known_mask(state.I{b}) = true; known_bits(state.I{b}) = payload{b};
            known_mask(state.F{b}) = true; known_bits(state.F{b}) = frozen_values{b};
            source_llr = ones(state.N, 1) * log((1 - state.p_vec(b)) / state.p_vec(b));
            u(:, b) = sc_decode_forced_full(source_llr, known_mask, known_bits);
        elseif any(strcmp(variant, {'message_conditioned','source_entropy_conditioned'})) && state.S_size(b) > 0
            stream = struct('p', state.p_vec(b), 'S_size', state.S_size(b), ...
                'K', state.K(b), 'F_size', state.F_size(b), ...
                'I', state.I{b}, 'S', state.S{b}, 'F', state.F{b});
            [u(:, b), ~] = shape_stream_sc(payload{b}, stream);
        else
            u(state.I{b}, b) = payload{b};
            if strcmp(variant, 'legacy_fixed')
                u(state.S{b}, b) = legacy_shape{b};
            end
            % F is zero in the v3 contract; legacy receiver also freezes F to zero.
        end
        if ~isempty(state.F{b})
            u(state.F{b}, b) = frozen_values{b};
        end
        shaped_by_stream = shaped_by_stream + nnz(u(state.S{b}, b));
    end
    coded = zeros(state.N, 4);
    for b = 1:4, coded(:, b) = polar_encoder(u(:, b)); end
    serial_bits = parallel_to_serial_bits(coded(:, 1), coded(:, 2), ...
        coded(:, 3), coded(:, 4));
    x = qammod(serial_bits, cfg.M, cfg.mapping, 'InputType', 'bit', ...
        'UnitAveragePower', cfg.unit_avg_power);
end

function [total_errors, errors_by_stream] = local_noiseless_decode(x, ...
        payload, state, frozen_values, variant)
    sigma = 1e-4;
    llr_serial = llr_16qam_gray_LSE(x, sigma);
    llr_bits = zeros(state.N, 4);
    for b = 1:4, llr_bits(:, b) = llr_serial(b:4:end); end
    errors_by_stream = zeros(1, 4);
    for b = 1:4
        if any(strcmp(variant, {'fixed_frozen_zero', 'iid_uniform_frozen', 'exact_map_zero', 'exact_conditional_random'}))
            known_mask = false(state.N, 1); known_bits = zeros(state.N, 1);
            known_mask(state.F{b}) = true; known_bits(state.F{b}) = frozen_values{b};
            source_hat = sc_decode_forced_full(llr_bits(:, b), known_mask, known_bits);
        else
            frozen = ones(state.N, 1); frozen([state.I{b}; state.S{b}]) = 0;
            decoded = SC_decoder(llr_bits(:, b), state.K(b) + state.S_size(b), ...
                frozen, state.lambda_offset, state.llr_layer_vec, state.bit_layer_vec);
            source_hat = zeros(state.N, 1);
            active = sort([state.I{b}; state.S{b}]);
            source_hat(active) = decoded;
        end
        errors_by_stream(b) = sum(source_hat(state.I{b}) ~= payload{b});
    end
    total_errors = sum(errors_by_stream);
end

function idx = local_symbol_indices(x, cfg)
    bits = qamdemod(x(:), cfg.M, cfg.mapping, 'OutputType', 'bit', ...
        'UnitAveragePower', cfg.unit_avg_power);
    labels = reshape(bits, 4, []).';
    weights = [8; 4; 2; 1];
    idx = double(labels * weights);
end

function v = local_pmf_vector(counts)
    v = counts(:).' / sum(counts);
end

function T = local_make_frame_table(rows, N)
    n = size(rows, 1); counts = zeros(n, 16);
    for i = 1:n, counts(i, :) = rows{i, 10}; end
    T = table(cell2mat(rows(:, 1)), string(rows(:, 2)), ...
        cell2mat(rows(:, 3)), cell2mat(rows(:, 4)), cell2mat(rows(:, 5)), ...
        'VariableNames', {'p', 'variant', 'seed', 'frame', 'noiseless_info_errors'});
    for i = 1:4
        T.(sprintf('stream%d_errors', i)) = cellfun(@(v) v(i), rows(:, 6));
    end
    T.tx_symbol_power = cell2mat(rows(:, 7));
    T.shaped_one_count = cell2mat(rows(:, 8));
    T.payload_bits_per_frame = cell2mat(rows(:, 9));
    for i = 1:16, T.(sprintf('symbol_%02d_count', i-1)) = counts(:, i); end
    T.payload_case = string(rows(:, 11));
    T.frozen_one_count = cell2mat(rows(:, 12));
    for i = 1:4
        T.(sprintf('payload_fp_%d', i)) = cell2mat(rows(:, 12+i));
    end
    label_bits = de2bi((0:15).', 4, 'left-msb');
    bit_ones = counts * label_bits;
    for i = 1:4
        T.(sprintf('label_bit%d_one_rate', i)) = bit_ones(:, i) / N;
    end
end

function [target, model] = local_target_model_pmfs(p_values, cfg)
    labels = de2bi((0:cfg.M-1).', 4, 'left-msb');
    target = zeros(numel(p_values), cfg.M); model = target;
    for ip = 1:numel(p_values)
        p = p_values(ip); probs = [0.5, p, 0.5, p];
        for m = 1:cfg.M
            pm = 1;
            for b = 1:4
                if labels(m, b) == 1, pm = pm * probs(b);
                else, pm = pm * (1 - probs(b)); end
            end
            target(ip, m) = pm;
        end
        % Under independent bit-level inputs, model equals the product target.
        model(ip, :) = target(ip, :);
    end
end

function T = local_make_pmf_table(p_values, target, model, frame_table, n_boot, variants)
    rows = cell(numel(p_values) * numel(variants), 7);
    ri = 0;
    for ip = 1:numel(p_values)
        for variant = string(variants)
            ri = ri + 1;
            select = frame_table.p == p_values(ip) & frame_table.variant == variant;
            counts = zeros(nnz(select), 16);
            for k = 1:16
                counts(:, k) = frame_table{select, sprintf('symbol_%02d_count', k-1)};
            end
            empirical = mean(counts ./ sum(counts, 2), 1);
            tv = 0.5 * sum(abs(empirical - target(ip, :)));
            ci_upper = local_cluster_bootstrap_tv(counts, target(ip, :), n_boot);
            select_frame = frame_table.p == p_values(ip) & frame_table.variant == variant;
            bit2 = mean(frame_table.label_bit2_one_rate(select_frame));
            bit4 = mean(frame_table.label_bit4_one_rate(select_frame));
            rows(ri, :) = {p_values(ip), char(variant), tv, ci_upper, ...
                local_pmf_vector(round(empirical * 1e12)), bit2, bit4};
        end
    end
    T = table(cell2mat(rows(:, 1)), string(rows(:, 2)), cell2mat(rows(:, 3)), ...
        cell2mat(rows(:, 4)), 'VariableNames', ...
        {'p', 'variant', 'tv_empirical_target', 'tv_bootstrap_upper95'});
    T.bit2_one_rate = cell2mat(rows(:, 6));
    T.bit4_one_rate = cell2mat(rows(:, 7));
    for i = 1:16
        T.(sprintf('target_%02d', i-1)) = target(ceil((1:height(T)).'/numel(variants)), i);
        T.(sprintf('model_%02d', i-1)) = model(ceil((1:height(T)).'/numel(variants)), i);
        T.(sprintf('empirical_%02d', i-1)) = cellfun(@(v) v(i), rows(:, 5));
    end
end

function T = local_make_seed_pmf_table(p_values, target, frame_table, n_boot, variants)
    seeds = unique(frame_table.seed);
    rows = cell(numel(p_values) * numel(variants) * numel(seeds), 20); ri = 0;
    for ip = 1:numel(p_values)
        for iv = string(variants)
            for is = 1:numel(seeds)
                select = frame_table.p == p_values(ip) & ...
                    frame_table.variant == iv & frame_table.seed == seeds(is);
                counts = zeros(nnz(select), 16);
                for k = 1:16
                    counts(:, k) = frame_table{select, sprintf('symbol_%02d_count', k-1)};
                end
                pmf = mean(counts ./ sum(counts, 2), 1);
                ri = ri + 1;
                rows(ri, 1:4) = {p_values(ip), char(iv), seeds(is), ...
                    local_cluster_bootstrap_tv(counts, target(ip, :), n_boot)};
                rows(ri, 5:20) = num2cell(pmf);
            end
        end
    end
    T = table(cell2mat(rows(:, 1)), string(rows(:, 2)), ...
        cell2mat(rows(:, 3)), cell2mat(rows(:, 4)), 'VariableNames', ...
        {'p', 'variant', 'seed', 'tv_bootstrap_upper95'});
    % Report target and empirical PMFs per seed for reproducible reanalysis.
    for k = 1:16
        T.(sprintf('target_%02d', k-1)) = target(ceil((1:height(T)).'/ (numel(variants)*numel(seeds))), k);
        T.(sprintf('empirical_%02d', k-1)) = cell2mat(rows(:, 4+k));
    end
end

function upper = local_cluster_bootstrap_tv(counts, target, n_boot)
    caller_rng = rng;
    cleanup_rng = onCleanup(@() rng(caller_rng)); %#ok<NASGU>
    rng(7331, 'twister');
    n = size(counts, 1); tv = zeros(n_boot, 1);
    for b = 1:n_boot
        sample = randi(n, n, 1);
        pmf = mean(counts(sample, :) ./ sum(counts(sample, :), 2), 1);
        tv(b) = 0.5 * sum(abs(pmf - target));
    end
    tv = sort(tv);
    upper = tv(max(1, ceil(0.95 * n_boot)));
end

function gate = local_make_pmf_gate(pmf_table, seed_pmf_table)
    p_values = unique(pmf_table.p);
    rows = cell(numel(p_values), 6);
    for ip = 1:numel(p_values)
        p = p_values(ip);
        summary = pmf_table(pmf_table.p == p & ...
            ismember(pmf_table.variant, ["source_entropy_conditioned","message_conditioned"]), :);
        variants = unique(summary.variant);
        seeds = seed_pmf_table(seed_pmf_table.p == p & ...
            ismember(seed_pmf_table.variant, variants), :);
        max_seed = max(seeds.tv_bootstrap_upper95);
        aggregate_upper = max(summary.tv_bootstrap_upper95);
        rows(ip, :) = {p, min(summary.tv_empirical_target), aggregate_upper, ...
            max_seed, aggregate_upper <= 0.05, max_seed <= 0.05};
    end
    gate = cell2table(rows, 'VariableNames', {'p','tv_empirical_min_variant', ...
        'tv_pooled_upper95_max_variant','tv_seed_upper95_max','pooled_pass','all_seed_pass'});
    gate.gate_pass = gate.pooled_pass & gate.all_seed_pass;
end

function T = local_conditioning_probe(p_values, cfg)
    rows = cell(numel(p_values) * 2, 5); ri = 0;
    N = cfg.N; [~, order] = sort(GA(10^(-20/20), N), 'descend');
    for ip = 1:numel(p_values)
        p = p_values(ip); h2 = -p*log2(p) - (1-p)*log2(1-p);
        S_size = ceil(N * (1-h2)); K = ceil((N-S_size)/2);
        S = sort(order(1:S_size)); S = S(:);
        I = sort(order(S_size+1:S_size+K)); I = I(:);
        F = sort(order(S_size+K+1:end)); F = F(:);
        for stream_index = [2, 4]
            ri = ri + 1;
            if S_size == 0
                hamming = 0; zero_ones = 0; one_ones = 0;
            else
                stream = struct('p', p, 'S_size', S_size, 'K', K, ...
                    'F_size', numel(F), 'I', I, 'S', S, 'F', F);
                [u0, ~] = shape_stream_sc(zeros(K, 1), stream);
                [u1, ~] = shape_stream_sc(ones(K, 1), stream);
                hamming = nnz(u0(S) ~= u1(S));
                zero_ones = nnz(u0(S)); one_ones = nnz(u1(S));
                assert(all(u0(I) == 0) && all(u1(I) == 1) ...
                    && all(u0(F) == 0) && all(u1(F) == 0), ...
                    'Message-conditioned precoder violated I/F constraints.');
            end
            rows(ri, :) = {p, stream_index, hamming, zero_ones, one_ones};
        end
    end
    T = cell2table(rows, 'VariableNames', ...
        {'p', 'bit_stream', 'shape_hamming_zero_vs_one', ...
         'shape_ones_payload_zero', 'shape_ones_payload_one'});
    T.p = cell2mat(rows(:, 1)); T.bit_stream = cell2mat(rows(:, 2));
    T.shape_hamming_zero_vs_one = cell2mat(rows(:, 3));
    T.shape_ones_payload_zero = cell2mat(rows(:, 4));
    T.shape_ones_payload_one = cell2mat(rows(:, 5));
end

function local_write_readme(out_dir, mode, cfg, p_values, seeds, n_frames, ...
        frame_table, partition_table, pmf_table, seed_pmf_table, elapsed_seconds)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    c = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, 'B4b shaping mechanism audit\nMode: %s\nN: %d; p: %s\n', ...
        mode, cfg.N, mat2str(p_values));
    fprintf(fid, 'Seeds: %s; frames per seed and variant: %d\n', mat2str(seeds), n_frames);
    fprintf(fid, 'Variants: %s\n', strjoin(cellstr(unique(frame_table.variant, 'stable')), ', '));
    if strcmpi(mode, 'frozen_compare')
        fprintf(fid, 'Frozen-bit contrast: F=0 versus iid Bernoulli(0.5) per codeword; F values are assumed known at the receiver; side-information overhead is excluded.\n');
    end
    fprintf(fid, 'Partition: %s; ceil-based B4 K retained. Source construction samples=%d, seed=%d (independent of evaluation).\n', cfg.partition,cfg.source_samples,cfg.source_seed);
    if strcmp(mode,'source_compare')
        fprintf(fid, 'Exact source LLR passed N=2,4 exhaustive likelihood oracle. Random arm samples all non-I positions conditionally; actual F assumed known at receiver; side-information overhead excluded.\n');
    end
    fprintf(fid, 'Partition sizes by p and stream are in partition_summary.csv.\n');
    fprintf(fid, 'Target/model PMF is the product model from requested bit marginals; empirical PMF is clustered by whole codeword.\n');
    fprintf(fid, 'Noiseless info errors (max): %d\n', max(frame_table.noiseless_info_errors));
    fprintf(fid, 'Elapsed seconds: %.2f\n', elapsed_seconds);
    if any(strcmpi(mode, {'pmf','formal_source','blocklength'}))
        fprintf(fid, 'PMF rows with pooled TV bootstrap upper95 <= 0.05: %d / %d\n', ...
            sum(pmf_table.tv_bootstrap_upper95 <= 0.05), height(pmf_table));
        fprintf(fid, 'Per-seed upper95 values are in pmf_by_seed.csv (%d rows).\n', ...
            height(seed_pmf_table));
        gate_file = fullfile(out_dir, 'pmf_gate_status.csv');
        if exist(gate_file, 'file') == 2
            gate = readtable(gate_file);
            fprintf(fid, 'Per-p pooled and all-seed 0.05 gate: %d / %d passed.\n', ...
                sum(gate.gate_pass), height(gate));
        end
    else
        fprintf(fid, 'PMF values are smoke diagnostics only; formal 0.05 gate not evaluated.\n');
    end
    fprintf(fid, 'This audit does not establish optimality or validate RF-DC conversion.\n');
    fprintf(fid, 'P1 equal-power OFDM calibration and fixed-noise comparison are not run here.\n');
    fprintf(fid, 'Partition-summary rows: %d\n', height(partition_table));
end

function local_plot_pmf(fig_dir, p_values, target, frame_table, variants)
    f = figure('Visible', 'off', 'Position', [80 60 1050 850], 'PaperPositionMode', 'auto');
    tl = tiledlayout(numel(p_values), 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    legend_handles = gobjects(0);
    for ip = 1:numel(p_values)
        ax = nexttile; hold(ax, 'on');
        styles = {'o-', 's--', '^:'};
        for iv = 1:numel(variants)
            select = frame_table.p == p_values(ip) & frame_table.variant == string(variants{iv});
            vals = zeros(nnz(select), 16);
            for k = 1:16
                vals(:, k) = frame_table{select, sprintf('symbol_%02d_count', k-1)};
            end
            empirical = mean(vals ./ sum(vals, 2), 1);
            h = plot(ax, 0:15, empirical, styles{iv}, 'DisplayName', variants{iv});
            if ip == 1, legend_handles(end+1) = h; end %#ok<AGROW>
        end
        h = plot(ax, 0:15, target(ip, :), 'k:', 'LineWidth', 1.3, 'DisplayName', 'target/model');
        if ip == 1, legend_handles(end+1) = h; end
        title(ax, sprintf('p = %.1f', p_values(ip))); xlabel(ax, '16QAM label index');
        ylabel(ax, 'Probability'); grid(ax, 'on'); xlim(ax, [0 15]);
    end
    lgd = legend(legend_handles, 'Interpreter', 'none', 'Orientation', 'horizontal');
    lgd.Layout.Tile = 'north';
    title(tl, 'Message-conditioned source entropy construction: empirical versus target/model PMF');
    print(f, fullfile(fig_dir, 'pmf_by_variant.png'), '-dpng', '-r180');
    print(f, fullfile(fig_dir, 'pmf_by_variant.pdf'), '-dpdf', '-bestfit');
    close(f);
end

function local_plot_tv(fig_dir,p_values,summary,by_seed)
    f=figure('Visible','off','Position',[80 80 950 520],'PaperPositionMode','auto');
    ax=axes(f); hold(ax,'on'); grid(ax,'on'); gate=yline(ax,0.05,'k--','TV gate = 0.05'); gate.HandleVisibility='off';
    seed_values=unique(by_seed.seed); offsets=linspace(-0.24,0.24,numel(seed_values)+1);
    colors=lines(numel(seed_values)+1); variant=unique(summary.variant); variant=variant(1);
    legend_handles=gobjects(numel(seed_values)+1,1); legend_labels=cell(numel(seed_values)+1,1);
    for ip=1:numel(p_values)
        p=p_values(ip); s=summary(summary.p==p & summary.variant==variant,:);
        empirical_names=startsWith(s.Properties.VariableNames,'empirical_');
        target_names=startsWith(s.Properties.VariableNames,'target_');
        tv_pool=0.5*sum(abs(s{1,empirical_names} - s{1,target_names}));
        x=ip+offsets(1); upper=s.tv_bootstrap_upper95;
        plot(ax,[x x],[tv_pool upper],'-','Color',colors(1,:),'HandleVisibility','off');
        h=plot(ax,x,tv_pool,'o','Color',colors(1,:),'MarkerFaceColor',colors(1,:));
        if ip==1, legend_handles(1)=h; legend_labels{1}='pooled empirical / bootstrap upper95'; end
        for is=1:numel(seed_values)
            r=by_seed(by_seed.p==p & by_seed.seed==seed_values(is) & by_seed.variant==variant,:);
            empirical_names=startsWith(r.Properties.VariableNames,'empirical_');
            target_names=startsWith(r.Properties.VariableNames,'target_');
            tv=0.5*sum(abs(r{1,empirical_names}-r{1,target_names})); upper=r.tv_bootstrap_upper95;
            x=ip+offsets(is+1);
            plot(ax,[x x],[tv upper],'-','Color',colors(is+1,:),'HandleVisibility','off');
            h=plot(ax,x,tv,'s','Color',colors(is+1,:),'MarkerFaceColor',colors(is+1,:));
            if ip==1
                legend_handles(is+1)=h;
                legend_labels{is+1}=sprintf('seed %d empirical / upper95',seed_values(is));
            end
        end
    end
    xlim(ax,[0.5 numel(p_values)+0.5]); xticks(ax,1:numel(p_values));
    xticklabels(ax,arrayfun(@(p)sprintf('%.1f',p),p_values,'UniformOutput',false));
    xlabel(ax,'Shaping probability p'); ylabel(ax,'TV distance to target joint PMF');
    title(ax,'Whole-codeword bootstrap: empirical TV and one-sided 95% upper bounds');
    legend(ax,legend_handles,legend_labels,'Location','eastoutside','Interpreter','none');
    print(f,fullfile(fig_dir,'pmf_tv_intervals.png'),'-dpng','-r180');
    print(f,fullfile(fig_dir,'pmf_tv_intervals.pdf'),'-dpdf','-bestfit'); close(f);
end

function local_assert_exact_source()
% Exhaustive independent likelihood oracle, including all forced prefixes.
    for N = [2, 4]
        words = dec2bin(0:2^N-1, N) - '0';
        coded = zeros(size(words));
        for k = 1:size(words, 1), coded(k, :) = polar_encoder(words(k, :)')'; end
        for p = [0.1, 0.3, 0.5]
            weights = prod(p.^coded .* (1-p).^(1-coded), 2);
            for k = 1:size(words, 1)
                [~, L] = sc_decode_forced_full(ones(N,1)*log((1-p)/p), ...
                    true(N,1), words(k,:)', [], struct('exact',true));
                for i = 1:N
                    prefix = all(words(:,1:i-1) == words(k,1:i-1), 2);
                    reference = log(sum(weights(prefix & words(:,i)==0)) / ...
                        sum(weights(prefix & words(:,i)==1)));
                    assert(abs(L(i)-reference) < 1e-10, 'Exact source likelihood mismatch.');
                end
            end
        end
    end
    fprintf('Exact source LLR exhaustive oracle N=2,4: passed.\n');
end
