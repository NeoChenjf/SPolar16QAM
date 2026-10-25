%% RUN_B4_STRICT_OFDM_RAYLEIGH_VALIDATION
% Stage B / B4b: strict grouped-polar OFDM-Rayleigh full-chain smoke.
%
% Three independent N=1024 polar blocks (high/mid/low reliability groups)
% are placed on one physical OFDM grid. Every frame passes through IFFT,
% CP, continuous multipath convolution, AWGN, CP removal, FFT, ZF, LLR,
% and SC decoding. This is grouped coding on real subcarriers, not 64
% independent per-subcarrier polar codes.

clearvars -except b4_strict_overrides; clc; close all;

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

cfg_base = config();

%% ===== Config =====
run_mode = 'smoke';
result_tag = 'b4_strict_ofdm_rayleigh_smoke';
seed = 42;
n_subcarriers = 64;
cp_ratio = 1/4;
channel_taps = 16;
snr_grid = [8, 14, 20];
num_realizations = 2;
num_frames = 1;
min_frames = num_frames;
target_errors = inf;
max_frames = num_frames;
formal_authorized = false;
resume_dir = '';
equalizer_floor = 1e-8;
strategy_names = { ...
    'uniform_p05', ...
    'uniform_p03', ...
    'uniform_p01', ...
    'good_channel_information', ...
    'good_channel_energy_shaping', ...
    'bad_channel_energy_only'};
strategy_scales = ones(1, numel(strategy_names));
power_mode = 'legacy';
target_time_power = 1.0;

if exist('b4_strict_overrides', 'var')
    if isfield(b4_strict_overrides, 'run_mode'); run_mode = b4_strict_overrides.run_mode; end
    if isfield(b4_strict_overrides, 'result_tag'); result_tag = b4_strict_overrides.result_tag; end
    if isfield(b4_strict_overrides, 'seed'); seed = b4_strict_overrides.seed; end
    if isfield(b4_strict_overrides, 'snr_grid'); snr_grid = b4_strict_overrides.snr_grid; end
    if isfield(b4_strict_overrides, 'num_realizations'); num_realizations = b4_strict_overrides.num_realizations; end
    if isfield(b4_strict_overrides, 'num_frames'); num_frames = b4_strict_overrides.num_frames; end
    if isfield(b4_strict_overrides, 'min_frames'); min_frames = b4_strict_overrides.min_frames; end
    if isfield(b4_strict_overrides, 'target_errors'); target_errors = b4_strict_overrides.target_errors; end
    if isfield(b4_strict_overrides, 'max_frames'); max_frames = b4_strict_overrides.max_frames; end
    if isfield(b4_strict_overrides, 'formal_authorized'); formal_authorized = b4_strict_overrides.formal_authorized; end
    if isfield(b4_strict_overrides, 'resume_dir'); resume_dir = b4_strict_overrides.resume_dir; end
    if isfield(b4_strict_overrides, 'strategy_names'); strategy_names = b4_strict_overrides.strategy_names; end
    if isfield(b4_strict_overrides, 'strategy_scales'); strategy_scales = b4_strict_overrides.strategy_scales; end
    if isfield(b4_strict_overrides, 'power_mode'); power_mode = b4_strict_overrides.power_mode; end
    if isfield(b4_strict_overrides, 'target_time_power'); target_time_power = b4_strict_overrides.target_time_power; end
end

if ~any(strcmpi(run_mode, {'smoke', 'pilot', 'formal', 'calibration'}))
    error('run_b4_strict_ofdm_rayleigh_validation: unknown run mode %s.', run_mode);
end

validateattributes(num_realizations, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(num_frames, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(snr_grid, {'numeric'}, {'vector', 'real', 'finite'});
assert(iscellstr(strategy_names) && ~isempty(strategy_names), ...
    'strategy_names must be a nonempty cell array of character vectors.');
known_strategies = {'uniform_p05', 'uniform_p03', 'uniform_p01', ...
    'good_channel_information', 'good_channel_energy_shaping', ...
    'bad_channel_energy_only'};
assert(numel(unique(strategy_names)) == numel(strategy_names), ...
    'strategy_names must not contain duplicates.');
assert(all(ismember(strategy_names, known_strategies)), ...
    'strategy_names contains an unsupported strategy.');
validateattributes(strategy_scales, {'numeric'}, {'vector','real','finite','positive'});
assert(numel(strategy_scales) == numel(strategy_names), ...
    'strategy_scales must have one positive frozen coefficient per strategy.');
assert(any(strcmp(power_mode, {'legacy','equal_time_power'})), ...
    'power_mode must be legacy or equal_time_power.');
validateattributes(target_time_power, {'numeric'}, {'scalar','real','finite','positive'});
if strcmpi(run_mode, 'smoke')
    if numel(snr_grid) > 3 || num_realizations > 2 || num_frames > 1
        error('Smoke budget exceeded: at most 3 SNRs, 2 realizations, and 1 frame.');
    end
elseif strcmpi(run_mode, 'pilot')
    if strcmp(result_tag, 'b4_strict_ofdm_rayleigh_smoke')
        result_tag = 'b4_strict_ofdm_rayleigh_pilot';
    end
    max_pilot_snr_points=4;
    if strcmp(power_mode,'equal_time_power'), max_pilot_snr_points=7; end
    if numel(snr_grid) > max_pilot_snr_points || num_realizations > 5 || num_frames > 2
        error('Pilot budget exceeded: at most %d SNRs, 5 realizations, and 2 frames.',max_pilot_snr_points);
    end
end
if strcmpi(run_mode, 'formal')
    validateattributes(formal_authorized, {'logical', 'numeric'}, {'scalar'});
    if ~logical(formal_authorized)
        error(['Formal run rejected: set formal_authorized=true only after explicit ' ...
            'user authorization for the registered long simulation.']);
    end
    validateattributes(min_frames, {'numeric'}, {'scalar', 'integer', 'positive'});
    validateattributes(max_frames, {'numeric'}, {'scalar', 'integer', 'positive'});
    validateattributes(target_errors, {'numeric'}, {'scalar', 'integer', 'positive'});
    if min_frames > max_frames
        error('Formal configuration requires min_frames <= max_frames.');
    end
    if strcmp(result_tag, 'b4_strict_ofdm_rayleigh_smoke')
        result_tag = 'b4_strict_ofdm_rayleigh_formal';
    end
end
n_cp = round(n_subcarriers * cp_ratio);
if n_cp < channel_taps - 1
    error('CP length %d is shorter than channel memory %d.', n_cp, channel_taps - 1);
end

cfg_local = cfg_base;
cfg_local.decoder = 'SC';
cfg_local.snr_mode = 'fixed_esn0';
cfg_local.ofdm_n_subcarriers = n_subcarriers;
cfg_local.ofdm_cp_ratio = cp_ratio;
cfg_local.channel = 'Rayleigh';
cfg_local.partition_mode = 'source_entropy';
cfg_local.source_samples = 200;
cfg_local.source_seed = 9001;
cfg_local.sigma_design = 10^(-20/20);
cfg_local.power_mode = power_mode;
cfg_local.strategy_scales = strategy_scales;
cfg_local.target_time_power = target_time_power;
if strcmp(power_mode,'equal_time_power')
    cfg_local.snr_mode='fixed_n0';
    cfg_local.snr_ref_power=target_time_power;
end

if strcmpi(run_mode, 'formal') && ~isempty(resume_dir)
    out_dir = char(resume_dir);
    if ~exist(out_dir, 'dir')
        error('Formal resume directory does not exist: %s', out_dir);
    end
else
    out_dir = fullfile(cfg_local.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' result_tag]);
    if exist(out_dir,'dir')
        error('Refusing to overwrite existing result directory: %s',out_dir);
    end
end
fig_dir = fullfile(out_dir, 'figures');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
cfg_params=cfg_local;
if isfield(cfg_params,'timestamp'), cfg_params=rmfield(cfg_params,'timestamp'); end
run_params=struct('run_mode',run_mode,'cfg_local',cfg_params, ...
    'strategy_names',{strategy_names},'snr_grid',snr_grid,'seed',seed, ...
    'num_realizations',num_realizations,'num_frames',num_frames, ...
    'min_frames',min_frames,'target_errors',target_errors, ...
    'max_frames',max_frames,'n_subcarriers',n_subcarriers, ...
    'cp_ratio',cp_ratio,'n_cp',n_cp,'channel_taps',channel_taps, ...
    'equalizer_floor',equalizer_floor,'formal_authorized',logical(formal_authorized), ...
    'power_mode',power_mode,'strategy_scales',strategy_scales, ...
    'target_time_power',target_time_power);
if strcmpi(run_mode,'formal') && ~isempty(resume_dir)
    params_path=fullfile(out_dir,'params.mat');
    if exist(params_path,'file')~=2
        error('B4b resume refused: original params.mat is absent.');
    end
    saved_params=load(params_path,'run_params');
    if ~isfield(saved_params,'run_params') || ~isequaln(saved_params.run_params,run_params)
        error('B4b resume refused: formal run parameters differ.');
    end
    local_assert_source_manifest(out_dir,script_dir,v2_root);
else
    save(fullfile(out_dir,'params.mat'),'run_params');
    local_snapshot_sources(out_dir,script_dir,v2_root);
end

diary(fullfile(out_dir, 'run_log.txt'));
diary on;
cleanup_diary = onCleanup(@() diary('off'));
progress_path = fullfile(out_dir, 'progress_log.txt');
if strcmpi(run_mode, 'formal') && ~isempty(resume_dir)
    progress_mode = 'a';
else
    progress_mode = 'w';
end
progress_fid = fopen(progress_path, progress_mode);
if progress_fid < 0
    error('Cannot create progress log: %s', progress_path);
end
fclose(progress_fid);

fprintf('\n========== Stage B / B4b Strict OFDM-Rayleigh %s ==========\n', upper(run_mode));
fprintf('Output: %s\n', out_dir);
fprintf('SNR grid: %s\n', mat2str(snr_grid));
if strcmpi(run_mode, 'formal')
    if strcmp(power_mode,'equal_time_power')
        fprintf('Realizations: %d | fixed frames/repetition: %d\n',num_realizations,max_frames);
    else
        fprintf('Realizations: %d | frames/repetition: adaptive %d-%d, target errors=%d\n', ...
            num_realizations, min_frames, max_frames, target_errors);
    end
else
    fprintf('Realizations: %d | frames/repetition: %d\n', num_realizations, num_frames);
end
fprintf('OFDM: Nsc=%d | CP=%d | channel taps=%d\n', ...
    n_subcarriers, n_cp, channel_taps);
fprintf('Strategies: %s\n', strjoin(strategy_names, ', '));

%% ===== Precompute polar states =====
p_values = [0.5, 0.3, 0.1];
state_cache = cell(numel(p_values), numel(snr_grid));
source_templates = cell(size(p_values));
for ip = 1:numel(p_values)
    p_vec = cfg_local.p_fixed; p_vec(isnan(p_vec)) = p_values(ip);
    source_templates{ip} = build_source_entropy_partition(cfg_local.N, p_vec, ...
        cfg_local.sigma_design, cfg_local.source_samples, cfg_local.source_seed);
end
for ip = 1:numel(p_values)
    for is = 1:numel(snr_grid)
        state_cache{ip, is} = local_prepare_polar_state( ...
            p_values(ip), snr_grid(is), cfg_local, source_templates{ip});
    end
end

%% ===== Strict OFDM-Rayleigh Monte Carlo =====
column_names = {'strategy', 'realization', 'snr_dB', 'frames', ...
    'error_count', 'info_bits', 'ber', 'bler', 'rate_cp_corrected', ...
    'goodput_cp_corrected', 'tx_qam_active_power', 'tx_grid_power', ...
    'tx_ofdm_time_power', 'rx_signal_power_pre_noise', ...
    'rx_noisy_power', 'padding_fraction', 'info_subcarrier_fraction', ...
    'n_ofdm_symbols', 'channel_gain_min', 'channel_gain_max', ...
    'payload_ones_high', 'payload_ones_mid', 'payload_ones_low', ...
    'strategy_scale','power_mode'};
partial_path = fullfile(out_dir, 'b4b_repetition_partial.csv');
if strcmpi(run_mode, 'formal') && exist(partial_path, 'file') == 2
    T = readtable(partial_path);
    fprintf('Resuming %d completed formal repetitions from %s\n', height(T), partial_path);
else
    T = table();
end
channel_rows = cell(num_realizations * n_subcarriers, 6);
channel_row_index = 0;
tic;
for ir = 1:num_realizations
    rng(local_seed(seed, ir, 0, 0, 0), 'twister');
    h = (randn(channel_taps, 1) + 1j * randn(channel_taps, 1)) / ...
        sqrt(2 * channel_taps);
    H = reshape(fft(h, n_subcarriers), [], 1);
    group_labels = local_rank_and_group(abs(H).^2);
    layout = local_build_layout(group_labels, cfg_local.N, n_subcarriers);
    for k = 1:n_subcarriers
        channel_row_index = channel_row_index + 1;
        channel_rows(channel_row_index, :) = {ir, k, real(H(k)), imag(H(k)), ...
            abs(H(k)).^2, char(group_labels(k))};
    end

    for is = 1:numel(snr_grid)
        snr_db = snr_grid(is);
        sigma = 10^(-snr_db / 20);

        for istr = 1:numel(strategy_names)
            strategy = string(strategy_names{istr});
            if ~isempty(T) && any(strcmp(T.strategy, char(strategy)) & ...
                    T.realization == ir & T.snr_dB == snr_db)
                fprintf('SKIP completed ir=%d | SNR=%g | %s\n', ir, snr_db, char(strategy));
                continue;
            end
            local_write_progress(progress_path, sprintf( ...
                'START ir=%d snr=%g strategy=%s %s', ...
                ir, snr_db, char(strategy), datestr(now, 31)));

            [group_p, group_info] = local_strategy_group_rule(strategy);
            total_errors = 0;
            total_info_bits = 0;
            total_info_blocks = 0;
            total_block_errors = 0;
            tx_qam_active_power_acc = 0;
            tx_grid_power_acc = 0;
            tx_ofdm_power_acc = 0;
            rx_signal_power_acc = 0;
            rx_noisy_power_acc = 0;
            payload_ones_per_group=zeros(1,3);

            if strcmpi(run_mode, 'formal')
                frames_to_run = max_frames;
            else
                frames_to_run = num_frames;
            end
            iframe = 0;
            while iframe < frames_to_run
                iframe = iframe + 1;
                tx_grid = zeros(n_subcarriers, layout.n_ofdm_symbols);
                blocks = cell(1, 3);
                groups = {'high', 'mid', 'low'};

                for ig = 1:3
                    group = groups{ig};
                    p_group = group_p.(group);
                    state = state_cache{local_p_index(p_values, p_group), is};
                    payload_key = istr;
                    if strcmp(power_mode,'equal_time_power'), payload_key = 0; end
                    rng(local_seed(seed, ir, is, payload_key, 10 * iframe + ig), 'twister');
                    energy_only_group = strcmpi(strategy,'bad_channel_energy_only') && ...
                        strcmp(group,'low');
                    blocks{ig} = local_generate_polar_block( ...
                        state, cfg_local, energy_only_group);
                    if energy_only_group
                        assert(all(cellfun(@(bits) ~any(bits),blocks{ig}.origin)), ...
                            'Pure-energy group must carry an all-zero payload.');
                    end
                    payload_ones_per_group(ig)=payload_ones_per_group(ig)+ ...
                        sum(cellfun(@sum,blocks{ig}.origin));
                    tx_grid(layout.locations{ig}) = blocks{ig}.tx_symbols;
                end

                tx_grid = strategy_scales(istr) .* tx_grid;
                active_symbols = tx_grid(layout.active_mask);
                tx_qam_active_power = mean(abs(active_symbols).^2);
                tx_probe = ifft(tx_grid, n_subcarriers, 1);
                tx_probe_cp = [tx_probe(end-n_cp+1:end,:); tx_probe];
                tx_power_current = mean(abs(tx_probe_cp(:)).^2);
                if strcmp(power_mode,'equal_time_power')
                    % ofdm_channel_roundtrip accepts post-FFT real-dimension sigma,
                    % then divides it by sqrt(Nsc) for time-domain noise. Choose it
                    % so the serialized time-domain complex noise power is N0.
                    sigma_noise_freq = sqrt(n_subcarriers * target_time_power / ...
                        (2 * 10^(snr_db/10)));
                elseif strcmpi(run_mode,'calibration')
                    sigma_noise_freq = 0;
                else
                    switch cfg_local.snr_mode
                        case 'fixed_n0'
                            sigma_noise_freq = sqrt(cfg_local.snr_ref_power) * sigma;
                        otherwise
                            sigma_noise_freq = sqrt(tx_qam_active_power) * sigma;
                    end
                end

                if strcmpi(run_mode,'calibration')
                    phys.rx_signal_power=0; phys.rx_noisy_power=0;
                    phys.rx_grid_equalized=[]; sigma_grid=[];
                else
                    noise_len = (n_subcarriers + n_cp) * layout.n_ofdm_symbols + ...
                        channel_taps - 1;
                    rng(local_seed(seed, ir, is, 0, iframe), 'twister');
                    noise_unit = randn(noise_len, 1) + 1j * randn(noise_len, 1);
                    phys = ofdm_channel_roundtrip(tx_grid, h, sigma_noise_freq, ...
                        n_cp, struct('equalizer_floor', equalizer_floor, ...
                        'noise_unit', noise_unit));
                    sigma_grid = repmat(phys.sigma_equalized, 1, layout.n_ofdm_symbols);
                end
                for ig = 1:3
                    group = groups{ig};
                    if group_info.(group) && ~strcmpi(run_mode,'calibration')
                        rx_symbols = phys.rx_grid_equalized(layout.locations{ig});
                        sigma_symbols = sigma_grid(layout.locations{ig});
                        n_errors = local_decode_polar_block(rx_symbols, ...
                            sigma_symbols, blocks{ig}, cfg_local,strategy_scales(istr));
                        total_errors = total_errors + n_errors;
                        total_info_bits = total_info_bits + sum(blocks{ig}.state.K);
                        total_info_blocks = total_info_blocks + 1;
                        total_block_errors = total_block_errors + (n_errors > 0);
                    end
                end

                tx_qam_active_power_acc = tx_qam_active_power_acc + tx_qam_active_power;
                tx_grid_power_acc = tx_grid_power_acc + mean(abs(tx_grid(:)).^2);
                tx_ofdm_power_acc = tx_ofdm_power_acc + tx_power_current;
                rx_signal_power_acc = rx_signal_power_acc + phys.rx_signal_power;
                rx_noisy_power_acc = rx_noisy_power_acc + phys.rx_noisy_power;
                if strcmpi(run_mode, 'formal') && ~strcmp(power_mode,'equal_time_power') && iframe >= min_frames && ...
                        total_errors >= target_errors
                    break;
                end
            end

            ber = total_errors / max(total_info_bits, 1);
            frames_used = iframe;
            info_bits_per_frame = total_info_bits / frames_used;
            rate_per_resource = info_bits_per_frame / ...
                (cfg_local.bits_per_symbol * n_subcarriers * layout.n_ofdm_symbols);
            cp_factor = n_subcarriers / (n_subcarriers + n_cp);
            rate_cp = rate_per_resource * cp_factor;
            goodput_cp = rate_cp * (1 - ber);
            info_fraction = sum([group_info.high, group_info.mid, group_info.low] .* ...
                layout.group_sizes) / n_subcarriers;

            row_values = {char(strategy), ir, snr_db, frames_used, ...
                total_errors, total_info_bits, ber, ...
                total_block_errors/max(total_info_blocks,1), rate_cp, goodput_cp, ...
                tx_qam_active_power_acc / frames_used, ...
                tx_grid_power_acc / frames_used, ...
                tx_ofdm_power_acc / frames_used, ...
                rx_signal_power_acc / frames_used, ...
                rx_noisy_power_acc / frames_used, ...
                layout.padding_fraction, info_fraction, layout.n_ofdm_symbols, ...
                min(abs(H).^2), max(abs(H).^2)};
            row_values=[row_values,num2cell(payload_ones_per_group), ...
                {strategy_scales(istr),power_mode}];
            Trow = cell2table(row_values, 'VariableNames', column_names);
            if isempty(T)
                T = Trow;
            else
                T = [T; Trow]; %#ok<AGROW> bounded by formal realization/SNR/strategy grid
            end
            if strcmpi(run_mode, 'formal')
                writetable(T, partial_path);
            end

            fprintf('ir=%d | SNR=%g | %-30s | BER=%.3e | G=%.4f | Erx=%.4g\n', ...
                ir, snr_db, char(strategy), ber, goodput_cp, ...
                rx_signal_power_acc / frames_used);
            local_write_progress(progress_path, sprintf( ...
                'DONE ir=%d snr=%g strategy=%s %s', ...
                ir, snr_db, char(strategy), datestr(now, 31)));
        end
    end
end
elapsed = toc;

T_channel = cell2table(channel_rows, 'VariableNames', {'realization', ...
    'subcarrier', 'H_real', 'H_imag', 'H_abs2', 'reliability_group'});
T_summary = local_summarize(T);

writetable(T, fullfile(out_dir, 'b4b_repetition_results.csv'));
if strcmpi(run_mode, 'formal')
    local_rebuild_progress_log(progress_path, T);
end
writetable(T_summary, fullfile(out_dir, 'b4b_strategy_summary.csv'));
writetable(T_channel, fullfile(out_dir, 'b4b_channel_realizations.csv'));
save(fullfile(out_dir, 'b4b_strict_ofdm_rayleigh.mat'), ...
    'T', 'T_summary', 'T_channel', 'cfg_local', 'strategy_names', 'snr_grid', ...
    'num_realizations', 'num_frames', 'seed', 'n_subcarriers', 'n_cp', ...
    'channel_taps', 'elapsed', 'run_mode', 'min_frames', 'target_errors', ...
    'max_frames', 'formal_authorized', 'state_cache', 'source_templates');

local_plot_results(fig_dir, T_summary, run_mode);
local_write_readme(out_dir, cfg_local, strategy_names, snr_grid, ...
    num_realizations, num_frames, seed, n_subcarriers, n_cp, ...
    channel_taps, elapsed, run_mode, min_frames, target_errors, max_frames);

fprintf('\n========== DONE ==========\n');
fprintf('Elapsed: %.1f sec (%.2f min)\n', elapsed, elapsed / 60);
fprintf('Saved to: %s\n', out_dir);

%% ===== Local functions =====
function state = local_prepare_polar_state(p, snr_db, cfg, source_template)
    N = cfg.N;
    p_vec = cfg.p_fixed;
    p_vec(isnan(p_vec)) = p;
    K = source_template.K;
    S = source_template.S_size;

    if isfield(cfg,'power_mode') && strcmp(cfg.power_mode,'equal_time_power')
        sigma = sqrt(cfg.target_time_power / (2 * 10^(snr_db/10)));
    else
        sigma = 10^(-snr_db / 20);
    end
    channels = GA(sigma, N);
    [~, ordered] = sort(channels, 'descend');
    lambda_offset = 2.^(0:log2(N));
    llr_layer_vec = get_llr_layer(N);
    bit_layer_vec = get_bit_layer(N);
    shaped_bits = cell(1, 4);
    frozen_bits = zeros(N, 4);
    SI_set = cell(1, 4);
    I_set = cell(1, 4);
    S_set = cell(1, 4);
    F_set = cell(1, 4);
    for b = 1:4
        S_set{b} = source_template.S{b};
        remain = ordered(~ismember(ordered, S_set{b}));
        I_set{b} = sort(remain(1:K(b))); I_set{b} = I_set{b}(:);
        F_set{b} = setdiff((1:N).', [S_set{b}; I_set{b}]);
        SI_set{b} = sort([S_set{b}; I_set{b}]);
        frozen_bits(:, b) = ones(N, 1);
        frozen_bits(I_set{b}, b) = 0;
        frozen_bits(S_set{b}, b) = 0;
        shaped_bits{b} = zeros(S(b), 1); % placeholder; shaping uses the current payload below
    end
    state = struct('p', p, 'p_vec', p_vec, 'N', N, 'K', K, 'S', S, ...
        'shaped_bits', {shaped_bits}, 'frozen_bits', frozen_bits, ...
        'SI_set', {SI_set}, 'I_set', {I_set}, 'S_set', {S_set}, ...
        'lambda_offset', lambda_offset, 'llr_layer_vec', llr_layer_vec, ...
        'bit_layer_vec', bit_layer_vec, 'F_set', {F_set}, ...
        'partition_fingerprint', {source_template.fingerprint});
end

function block = local_generate_polar_block(state, cfg, energy_only)
    if nargin<3, energy_only=false; end
    encoded = zeros(state.N, 4);
    origin = cell(1, 4);
    for b = 1:4
        if energy_only
            origin{b} = zeros(state.K(b),1);
        else
            origin{b} = randi([0, 1], state.K(b), 1);
        end
        stream = struct('p', state.p_vec(b), 'S_size', state.S(b), ...
            'K', state.K(b), 'F_size', numel(state.F_set{b}), ...
            'I', state.I_set{b}, 'S', state.S_set{b}, 'F', state.F_set{b});
        [~, encoded(:, b)] = shape_stream_sc(origin{b}, stream);
    end
    serial_bits = parallel_to_serial_bits(encoded(:, 1), encoded(:, 2), ...
        encoded(:, 3), encoded(:, 4));
    tx_symbols = qammod(serial_bits, cfg.M, cfg.mapping, ...
        'InputType', 'bit', 'UnitAveragePower', cfg.unit_avg_power);
    block = struct('state', state, 'encoded', encoded, ...
        'energy_only',energy_only, ...
        'origin', {origin}, 'tx_symbols', tx_symbols);
end

function n_errors = local_decode_polar_block(rx_symbols, sigma_symbols, block, cfg, amplitude_scale)
    state = block.state;
    llr_serial = llr_16qam_gray_LSE(rx_symbols, sigma_symbols, amplitude_scale);
    llr_bits = zeros(state.N, 4);
    for b = 1:4
        llr_bits(:, b) = llr_serial(b:4:end);
    end
    n_errors = 0;
    for b = 1:4
        decoded = SC_decoder(llr_bits(:, b), state.K(b) + state.S(b), ...
            state.frozen_bits(:, b), state.lambda_offset, ...
            state.llr_layer_vec, state.bit_layer_vec);
        code_hat = zeros(state.N, 1);
        code_hat(state.SI_set{b}) = decoded;
        info_hat = code_hat(state.I_set{b});
        n_errors = n_errors + sum(info_hat ~= block.origin{b});
    end
    if ~strcmpi(cfg.decoder, 'SC')
        error('B4b smoke currently supports SC decoder only.');
    end
end

function [shaped_bits, frozen_bits, SI_set, I_set, S_set] = ...
        local_prepare_one_bit(pb, S_size, K, N, ordered, ...
        lambda_offset, llr_layer_vec, bit_layer_vec)
    S_set = sort(ordered(1:S_size), 'ascend');
    I_set = sort(ordered(S_size+1:S_size+K), 'ascend');
    SI_set = sort(ordered(1:S_size+K), 'ascend');
    llr_src = ones(N, 1) * log((1 - pb) / pb);
    frozen_src = ones(N, 1);
    frozen_src(S_set) = 0;
    shaped_bits = SC_decoder(llr_src, S_size, frozen_src, ...
        lambda_offset, llr_layer_vec, bit_layer_vec);
    frozen_bits = ones(N, 1);
    frozen_bits(I_set) = 0;
    frozen_bits(S_set) = 0;
end

function labels = local_rank_and_group(gain)
    n = numel(gain);
    [~, order] = sort(gain, 'descend');
    labels = strings(n, 1);
    n_high = ceil(n / 3);
    n_mid = floor(n / 3);
    labels(order(1:n_high)) = "high";
    labels(order(n_high+1:n_high+n_mid)) = "mid";
    labels(order(n_high+n_mid+1:end)) = "low";
end

function layout = local_build_layout(labels, block_symbols, n_subcarriers)
    groups = ["high", "mid", "low"];
    group_sizes = zeros(1, 3);
    required_symbols = zeros(1, 3);
    for ig = 1:3
        group_sizes(ig) = sum(labels == groups(ig));
        if group_sizes(ig) == 0
            error('Reliability group %s is empty.', groups(ig));
        end
        required_symbols(ig) = ceil(block_symbols / group_sizes(ig));
    end
    n_ofdm_symbols = max(required_symbols);
    locations = cell(1, 3);
    active_mask = false(n_subcarriers, n_ofdm_symbols);
    for ig = 1:3
        group_mask = repmat(labels == groups(ig), 1, n_ofdm_symbols);
        candidates = find(group_mask);
        locations{ig} = candidates(1:block_symbols);
        active_mask(locations{ig}) = true;
    end
    padding_fraction = 1 - nnz(active_mask) / numel(active_mask);
    layout = struct('locations', {locations}, 'active_mask', active_mask, ...
        'n_ofdm_symbols', n_ofdm_symbols, 'group_sizes', group_sizes, ...
        'padding_fraction', padding_fraction);
end

function [group_p, group_info] = local_strategy_group_rule(strategy)
    group_info = struct('high', true, 'mid', true, 'low', true);
    switch string(strategy)
        case "uniform_p05"
            group_p = struct('high', 0.5, 'mid', 0.5, 'low', 0.5);
        case "uniform_p03"
            group_p = struct('high', 0.3, 'mid', 0.3, 'low', 0.3);
        case "uniform_p01"
            group_p = struct('high', 0.1, 'mid', 0.1, 'low', 0.1);
        case "good_channel_information"
            group_p = struct('high', 0.5, 'mid', 0.3, 'low', 0.1);
        case "good_channel_energy_shaping"
            group_p = struct('high', 0.1, 'mid', 0.3, 'low', 0.5);
        case "bad_channel_energy_only"
            group_p = struct('high', 0.5, 'mid', 0.3, 'low', 0.1);
            group_info.low = false;
        otherwise
            error('Unknown strategy: %s', strategy);
    end
end

function index = local_p_index(p_values, p)
    index = find(abs(p_values - p) < 1e-12, 1);
    if isempty(index)
        error('Unsupported p value: %g', p);
    end
end

function value = local_seed(base, realization, snr_index, strategy_index, item_index)
    value = base + 1000000 * realization + 10000 * snr_index + ...
        100 * strategy_index + item_index;
end

function T_summary = local_summarize(T)
    keys = unique(T(:, {'strategy', 'snr_dB'}), 'rows');
    rows = cell(height(keys), 17);
    for i = 1:height(keys)
        idx = strcmp(T.strategy, keys.strategy{i}) & T.snr_dB == keys.snr_dB(i);
        Ti = T(idx, :);
        zero_error_upper95 = nan;
        if sum(Ti.error_count) == 0
            zero_error_upper95 = -log(0.05) / sum(Ti.info_bits);
        end
        rows(i, :) = {keys.strategy{i}, keys.snr_dB(i), height(Ti), ...
            mean(Ti.ber), local_ci95(Ti.ber), ...
            mean(Ti.bler), local_ci95(Ti.bler), ...
            zero_error_upper95, ...
            mean(Ti.goodput_cp_corrected), local_ci95(Ti.goodput_cp_corrected), ...
            mean(Ti.rx_signal_power_pre_noise), local_ci95(Ti.rx_signal_power_pre_noise), ...
            mean(Ti.rx_noisy_power), mean(Ti.tx_qam_active_power), ...
            mean(Ti.tx_ofdm_time_power), mean(Ti.padding_fraction), ...
            mean(Ti.info_subcarrier_fraction)};
    end
    T_summary = cell2table(rows, 'VariableNames', {'strategy', 'snr_dB', ...
        'num_repetitions', 'ber_mean', 'ber_ci95','bler_mean','bler_ci95', 'ber_zero_error_upper95', 'goodput_cp_mean', ...
        'goodput_cp_ci95', 'rx_signal_power_mean', 'rx_signal_power_ci95', ...
        'rx_noisy_power_mean', 'tx_qam_active_power_mean', ...
        'tx_ofdm_time_power_mean', 'padding_fraction', ...
        'info_subcarrier_fraction'});
end

function ci = local_ci95(x)
    x = x(isfinite(x));
    n = numel(x);
    if n < 2
        ci = nan;
        return;
    end
    t_table = [nan, 12.706, 4.303, 3.182, 2.776];
    if n <= 5
        tcrit = t_table(n);
    else
        tcrit = 1.96;
    end
    ci = tcrit * std(x, 0) / sqrt(n);
end

function local_plot_results(fig_dir, T, run_mode)
    strategies = unique(string(T.strategy), 'stable');
    colors = lines(numel(strategies));

    fig = figure('Color', 'w', 'Position', [80 80 950 620]);
    hold on; grid on; box on;
    for i = 1:numel(strategies)
        idx = string(T.strategy) == strategies(i);
        ber_plot = T.ber_mean(idx);
        ber_plot(ber_plot <= 0) = nan;
        plot(T.snr_dB(idx), ber_plot, '-o', ...
            'Color', colors(i, :), 'DisplayName', local_display_label(strategies(i)));
    end
    set(gca, 'YScale', 'log');
    xlabel('Average SNR (dB)'); ylabel('BER');
    title(['B4b Strict OFDM-Rayleigh BER ' upper(run_mode)]);
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    local_save_figure(fig, fig_dir, 'b4b_ber_vs_snr');

    fig = figure('Color', 'w', 'Position', [80 80 950 620]);
    hold on; grid on; box on;
    for i = 1:numel(strategies)
        idx = string(T.strategy) == strategies(i);
        plot(T.snr_dB(idx), T.bler_mean(idx), '-o', ...
            'Color', colors(i, :), 'DisplayName', local_display_label(strategies(i)));
    end
    xlabel('SNR = target time power / complex noise power (dB)'); ylabel('Information-block error rate');
    title(['B4b Strict OFDM-Rayleigh BLER ' upper(run_mode)]);
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    local_save_figure(fig, fig_dir, 'b4b_bler_vs_snr');

    fig = figure('Color', 'w', 'Position', [80 80 950 620]);
    hold on; grid on; box on;
    for i = 1:numel(strategies)
        idx = string(T.strategy) == strategies(i);
        plot(T.snr_dB(idx), T.goodput_cp_mean(idx), '-o', ...
            'Color', colors(i, :), 'DisplayName', local_display_label(strategies(i)));
    end
    xlabel('Average SNR (dB)'); ylabel('CP/padding-corrected Goodput');
    title(['B4b Strict OFDM-Rayleigh Goodput ' upper(run_mode)]);
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    local_save_figure(fig, fig_dir, 'b4b_goodput_vs_snr');

    fig = figure('Color', 'w', 'Position', [80 80 950 620]);
    hold on; grid on; box on;
    for i = 1:numel(strategies)
        idx = string(T.strategy) == strategies(i);
        plot(T.snr_dB(idx), T.rx_signal_power_mean(idx), '-o', ...
            'Color', colors(i, :), 'DisplayName', local_display_label(strategies(i)));
    end
    xlabel('Average SNR (dB)'); ylabel('Pre-noise received signal power');
    title(['B4b Strict OFDM-Rayleigh Energy Proxy ' upper(run_mode)]);
    legend('Location', 'bestoutside', 'Interpreter', 'none');
    local_save_figure(fig, fig_dir, 'b4b_rx_energy_vs_snr');

    max_snr = max(T.snr_dB);
    idx = T.snr_dB == max_snr;
    Tp = T(idx, :);
    fig = figure('Color', 'w', 'Position', [80 80 900 620]);
    scatter(Tp.rx_signal_power_mean, Tp.goodput_cp_mean, 80, 'filled');
    grid on; box on; hold on;
    for i = 1:height(Tp)
        text(Tp.rx_signal_power_mean(i), Tp.goodput_cp_mean(i), ...
            ['  ' local_display_label(string(Tp.strategy{i}))], 'Interpreter', 'none');
    end
    xlabel('Pre-noise received signal power');
    ylabel('CP/padding-corrected Goodput');
    title(sprintf('B4b %s Tradeoff at %g dB', upper(run_mode), max_snr));
    local_save_figure(fig, fig_dir, ['b4b_goodput_energy_' lower(run_mode)]);
end

function local_save_figure(fig, fig_dir, name)
    savefig(fig, fullfile(fig_dir, [name '.fig']));
    exportgraphics(fig, fullfile(fig_dir, [name '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, [name '.pdf']), 'ContentType', 'vector');
    close(fig);
end

function label = local_display_label(strategy)
    label = strrep(char(strategy), '_', ' ');
end

function local_write_readme(out_dir, cfg, strategies, snr_grid, ...
        num_realizations, num_frames, seed, n_subcarriers, n_cp, ...
        channel_taps, elapsed, run_mode, min_frames, target_errors, max_frames)
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('Cannot create README in %s', out_dir);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, '=== B4b Strict Grouped-Polar OFDM-Rayleigh %s ===\n\n', upper(run_mode));
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  Three independent N=1024 polar blocks mapped to high/mid/low subcarriers.\n');
    fprintf(fid, '  Real IFFT/CP/multipath/AWGN/FFT/ZF/LLR/SC chain.\n');
    fprintf(fid, '  %s only: no final strategy ranking or paper-level Pareto claim.\n\n', ...
        lower(run_mode));
    fprintf(fid, 'PARAMETERS\n');
    fprintf(fid, '  snr_grid: %s\n', mat2str(snr_grid));
    if strcmpi(run_mode, 'formal')
        if strcmp(cfg.power_mode,'equal_time_power')
            fprintf(fid, '  realizations: %d\n  frames/repetition: fixed %d\n  seed: %d\n', ...
                num_realizations,max_frames,seed);
        else
            fprintf(fid, '  realizations: %d\n  frames/repetition: adaptive %d-%d, target errors=%d\n  seed: %d\n', ...
                num_realizations, min_frames, max_frames, target_errors, seed);
        end
    else
        fprintf(fid, '  realizations: %d\n  frames/repetition: %d\n  seed: %d\n', ...
            num_realizations, num_frames, seed);
    end
    fprintf(fid, '  Nsc: %d\n  CP: %d\n  channel_taps: %d\n', ...
        n_subcarriers, n_cp, channel_taps);
    fprintf(fid, '  decoder: %s\n  snr_mode: %s\n  power_mode: %s\n', ...
        cfg.decoder, cfg.snr_mode, cfg.power_mode);
    fprintf(fid, '  target_time_power: %.12g\n  strategy_scales: %s\n', ...
        cfg.target_time_power, mat2str(cfg.strategy_scales,12));
    fprintf(fid, '  strategies: %s\n\n', strjoin(strategies, ', '));
    if strcmpi(run_mode, 'formal')
        fprintf(fid, '  min_frames: %d\n  target_errors: %d\n  max_frames: %d\n\n', ...
            min_frames, target_errors, max_frames);
    end
    fprintf(fid, 'METRICS\n');
    fprintf(fid, '  Goodput denominator includes all OFDM resource elements, padding, and CP.\n');
    fprintf(fid, '  Main energy proxy: pre-noise received signal time-domain mean square.\n');
    fprintf(fid, '  Diagnostics: noisy received power, active-QAM power, OFDM transmit power.\n');
    fprintf(fid, '  Energy-only low group transmits p=0.1 shaped symbols with all-zero payload; payload one-counts are reported per group.\n\n');
    fprintf(fid, '  All-zero aggregate error points report ber_zero_error_upper95 in summary.\n\n');
    fprintf(fid, 'OUTPUTS\n');
    fprintf(fid, '  b4b_repetition_results.csv\n  b4b_strategy_summary.csv\n');
    fprintf(fid, '  b4b_channel_realizations.csv\n');
    fprintf(fid, '  b4b_strict_ofdm_rayleigh.mat\n  run_log.txt\n  progress_log.txt\n');
    fprintf(fid, '  params.mat\n  source_snapshot/\n  sha256_manifest.txt\n');
    if strcmpi(run_mode, 'formal')
        fprintf(fid, '  b4b_repetition_partial.csv (checkpoint/resume)\n');
    end
    fprintf(fid, '  figures/*.png/pdf/fig\n\n');
    fprintf(fid, 'ELAPSED_SECONDS\n  %.6f\n', elapsed);
end

function local_write_progress(progress_path, line)
    fid = fopen(progress_path, 'a');
    if fid < 0
        error('Cannot append progress log: %s', progress_path);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, '%s\n', line);
end

function local_rebuild_progress_log(progress_path, T)
    fid = fopen(progress_path, 'w');
    if fid < 0
        error('Cannot rebuild progress log: %s', progress_path);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    for i = 1:height(T)
        fprintf(fid, 'START restored ir=%d snr=%g strategy=%s\n', ...
            T.realization(i), T.snr_dB(i), T.strategy{i});
        fprintf(fid, 'DONE restored ir=%d snr=%g strategy=%s\n', ...
            T.realization(i), T.snr_dB(i), T.strategy{i});
    end
end

function sources=local_source_files(script_dir,v2_root)
    v3_polar = fullfile(v2_root, '..', 'v3', 'polar');
    sources = {fullfile(script_dir, 'run_b4_strict_ofdm_rayleigh_validation.m'), ...
        fullfile(v2_root, 'polar', 'build_source_entropy_partition.m'), ...
        fullfile(v2_root, 'polar', 'GA.m'), fullfile(v2_root, 'polar', 'SC_decoder.m'), ...
        fullfile(v2_root, 'polar', 'polar_encoder.m'), ...
        fullfile(v2_root, 'modulation', 'parallel_to_serial_bits.m'), ...
        fullfile(v2_root, 'modulation', 'llr_16qam_gray_LSE.m'), ...
        fullfile(v3_polar, 'shape_stream_sc.m'), ...
        fullfile(v3_polar, 'build_stream_partition_source_mc_ga.m'), ...
        fullfile(v3_polar, 'sc_decode_forced_full.m'), ...
        fullfile(v2_root, 'core', 'ofdm_channel_roundtrip.m')};
end

function local_snapshot_sources(out_dir,script_dir,v2_root)
    sources=local_source_files(script_dir,v2_root);
    snapshot_dir = fullfile(out_dir, 'source_snapshot'); mkdir(snapshot_dir);
    manifest_text=local_source_manifest(sources);
    manifest = fullfile(out_dir, 'sha256_manifest.txt'); fid = fopen(manifest, 'w');
    if fid < 0, error('Cannot create source hash manifest.'); end
    cleanup = onCleanup(@() fclose(fid));
    for k = 1:numel(sources)
        if exist(sources{k}, 'file') ~= 2, error('Missing source snapshot file: %s', sources{k}); end
        [~, name, ext] = fileparts(sources{k});
        copyfile(sources{k}, fullfile(snapshot_dir, [name ext]));
    end
    fprintf(fid,'%s',manifest_text);
    clear cleanup;
end

function local_assert_source_manifest(out_dir,script_dir,v2_root)
    manifest_path=fullfile(out_dir,'sha256_manifest.txt');
    if exist(manifest_path,'file')~=2
        error('B4b resume refused: source hash manifest is absent.');
    end
    sources=local_source_files(script_dir,v2_root);
    expected=local_source_manifest(sources);
    actual=fileread(manifest_path);
    actual=strrep(actual,sprintf('\r\n'),sprintf('\n'));
    if ~strcmp(actual,expected)
        error('B4b resume refused: source hashes differ from the original run.');
    end
    snapshot_dir=fullfile(out_dir,'source_snapshot');
    for k=1:numel(sources)
        [~,name,ext]=fileparts(sources{k});
        snapshot=fullfile(snapshot_dir,[name ext]);
        if exist(snapshot,'file')~=2 || ...
                ~strcmp(local_hash_file(snapshot),local_hash_file(sources{k}))
            error('B4b resume refused: source snapshot is missing or changed (%s).',snapshot);
        end
    end
end

function manifest=local_source_manifest(sources)
    manifest='';
    for k=1:numel(sources)
        manifest=[manifest local_hash_file(sources{k}) '  ' sources{k} newline]; %#ok<AGROW>
    end
end

function hex=local_hash_file(path)
    stream=fopen(path,'rb');
    if stream<0,error('Cannot read source file: %s',path);end
    cleanup=onCleanup(@()fclose(stream)); %#ok<NASGU>
    bytes=fread(stream,Inf,'*uint8');
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    digest=typecast(md.digest(),'uint8');
    hex=lower(reshape(dec2hex(digest,2)',1,[]));
end
