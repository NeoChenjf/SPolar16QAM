function report = verify_b4b_strict_smoke(result_dir)
% VERIFY_B4B_STRICT_SMOKE Audit B4b smoke outputs and metric identities.

    validateattributes(result_dir, {'char', 'string'}, {'scalartext'});
    result_dir = char(result_dir);
    required = {'b4b_repetition_results.csv', 'b4b_strategy_summary.csv', ...
        'b4b_channel_realizations.csv', ...
        'b4b_strict_ofdm_rayleigh.mat', 'README.txt', 'run_log.txt', ...
        'progress_log.txt'};
    for i = 1:numel(required)
        assert(exist(fullfile(result_dir, required{i}), 'file') == 2, ...
            'Missing required output: %s', required{i});
    end

    T = readtable(fullfile(result_dir, 'b4b_repetition_results.csv'));
    S = readtable(fullfile(result_dir, 'b4b_strategy_summary.csv'));
    C = readtable(fullfile(result_dir, 'b4b_channel_realizations.csv'));
    meta = load(fullfile(result_dir, 'b4b_strict_ofdm_rayleigh.mat'), ...
        'strategy_names', 'snr_grid', 'num_realizations', 'num_frames', ...
        'n_subcarriers', 'n_cp', 'cfg_local');
    mat_path = fullfile(result_dir, 'b4b_strict_ofdm_rayleigh.mat');
    saved_variables = whos('-file', mat_path);
    has_run_mode = any(strcmp({saved_variables.name}, 'run_mode'));
    if has_run_mode
        saved_mode = load(mat_path, 'run_mode');
        meta.run_mode = saved_mode.run_mode;
    else
        meta.run_mode = 'smoke';
    end

    expected_rows = numel(meta.strategy_names) * numel(meta.snr_grid) * ...
        meta.num_realizations;
    assert(height(T) == expected_rows, ...
        'Repetition row count mismatch: expected %d, got %d.', expected_rows, height(T));
    assert(height(S) == numel(meta.strategy_names) * numel(meta.snr_grid), ...
        'Summary row count mismatch.');
    assert(height(C) == meta.num_realizations * meta.n_subcarriers, ...
        'Channel realization row count mismatch.');

    keys = strcat(string(T.strategy), "|", string(T.realization), "|", string(T.snr_dB));
    assert(numel(unique(keys)) == height(T), 'Duplicate strategy/realization/SNR key.');
    assert(all(isfinite(T.ber)) && all(T.ber >= 0 & T.ber <= 1));
    assert(all(isfinite(T.goodput_cp_corrected)) && all(T.goodput_cp_corrected >= 0));
    assert(all(isfinite(T.rx_signal_power_pre_noise)) && ...
        all(T.rx_signal_power_pre_noise > 0));
    assert(all(isfinite(T.rx_noisy_power)) && all(T.rx_noisy_power > 0));
    assert(all(isfinite(T.tx_qam_active_power)) && all(T.tx_qam_active_power > 0));
    assert(all(T.info_bits > 0) && all(T.error_count >= 0));
    assert(all(isfinite(C.H_real)) && all(isfinite(C.H_imag)) && ...
        all(isfinite(C.H_abs2)) && all(C.H_abs2 >= 0));
    channel_keys = strcat(string(C.realization), "|", string(C.subcarrier));
    assert(numel(unique(channel_keys)) == height(C), ...
        'Duplicate realization/subcarrier channel key.');
    expected_groups = [ceil(meta.n_subcarriers/3), floor(meta.n_subcarriers/3), ...
        meta.n_subcarriers-ceil(meta.n_subcarriers/3)-floor(meta.n_subcarriers/3)];
    for ir = 1:meta.num_realizations
        Ci = C(C.realization == ir, :);
        actual_groups = [sum(strcmp(Ci.reliability_group, 'high')), ...
            sum(strcmp(Ci.reliability_group, 'mid')), ...
            sum(strcmp(Ci.reliability_group, 'low'))];
        assert(isequal(actual_groups, expected_groups), ...
            'Reliability group counts mismatch for realization %d.', ir);
    end

    expected_rate = (T.info_bits ./ T.frames) ./ ...
        (meta.cfg_local.bits_per_symbol .* meta.n_subcarriers .* T.n_ofdm_symbols) .* ...
        meta.n_subcarriers ./ (meta.n_subcarriers + meta.n_cp);
    assert(max(abs(expected_rate - T.rate_cp_corrected)) < 1e-12, ...
        'CP/padding-corrected rate identity failed.');
    expected_goodput = T.rate_cp_corrected .* (1 - T.ber);
    assert(max(abs(expected_goodput - T.goodput_cp_corrected)) < 1e-12, ...
        'Goodput identity failed.');
    expected_padding = 1 - 3 * meta.cfg_local.N ./ ...
        (meta.n_subcarriers .* T.n_ofdm_symbols);
    assert(max(abs(expected_padding - T.padding_fraction)) < 1e-12, ...
        'Padding fraction identity failed.');
    if ismember('ber_zero_error_upper95', S.Properties.VariableNames)
        for i = 1:height(S)
            idx = strcmp(T.strategy, S.strategy{i}) & T.snr_dB == S.snr_dB(i);
            Ti = T(idx, :);
            if sum(Ti.error_count) == 0
                expected_upper = -log(0.05) / sum(Ti.info_bits);
                assert(abs(S.ber_zero_error_upper95(i) - expected_upper) < 1e-12, ...
                    'Zero-error upper-bound identity failed.');
            else
                assert(isnan(S.ber_zero_error_upper95(i)), ...
                    'Nonzero-error summary must not report a zero-error upper bound.');
            end
        end
    end

    energy_only = strcmp(T.strategy, 'bad_channel_energy_only');
    assert(all(abs(T.info_subcarrier_fraction(energy_only) - 43/64) < 1e-12), ...
        'Energy-only information-subcarrier fraction mismatch.');
    assert(all(abs(T.info_subcarrier_fraction(~energy_only) - 1) < 1e-12), ...
        'Information fraction mismatch for non-energy-only strategies.');

    progress = fileread(fullfile(result_dir, 'progress_log.txt'));
    n_start = numel(regexp(progress, '(?m)^START ', 'match'));
    n_done = numel(regexp(progress, '(?m)^DONE ', 'match'));
    assert(n_start == expected_rows && n_done == expected_rows, ...
        'Progress log START/DONE mismatch.');

    figure_names = {'b4b_ber_vs_snr', 'b4b_goodput_vs_snr', ...
        'b4b_rx_energy_vs_snr', ['b4b_goodput_energy_' lower(meta.run_mode)]};
    extensions = {'png', 'pdf', 'fig'};
    for i = 1:numel(figure_names)
        for j = 1:numel(extensions)
            path = fullfile(result_dir, 'figures', ...
                [figure_names{i} '.' extensions{j}]);
            assert(exist(path, 'file') == 2, 'Missing figure: %s', path);
        end
    end
    if has_run_mode
        ber_fig = openfig(fullfile(result_dir, 'figures', 'b4b_ber_vs_snr.fig'), ...
            'invisible');
        cleanup_figure = onCleanup(@() close(ber_fig));
        ber_axes = get(ber_fig, 'CurrentAxes');
        assert(~isempty(ber_axes) && strcmp(get(ber_axes, 'YScale'), 'log'), ...
            'BER figure must use a logarithmic Y axis.');
    end

    report = struct('status', 'PASS', 'rows', height(T), ...
        'summary_rows', height(S), 'start_count', n_start, ...
        'done_count', n_done, 'padding_fraction', unique(T.padding_fraction), ...
        'n_ofdm_symbols', unique(T.n_ofdm_symbols));

    audit_path = fullfile(result_dir, 'audit.txt');
    fid = fopen(audit_path, 'w');
    if fid < 0
        error('Cannot create audit file: %s', audit_path);
    end
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, 'B4b STRICT OFDM-RAYLEIGH %s AUDIT: PASS\n', upper(meta.run_mode));
    fprintf(fid, 'rows=%d\nsummary_rows=%d\nchannel_rows=%d\n', ...
        report.rows, report.summary_rows, height(C));
    fprintf(fid, 'progress_start=%d\nprogress_done=%d\n', n_start, n_done);
    fprintf(fid, 'n_ofdm_symbols=%s\n', mat2str(report.n_ofdm_symbols.'));
    fprintf(fid, 'padding_fraction=%s\n', mat2str(report.padding_fraction.'));
    fprintf(fid, 'Checks: unique keys, channel table/groups, finite/range metrics, ');
    fprintf(fid, 'rate identity, Goodput identity, padding identity, ');
    if has_run_mode
        fprintf(fid, 'information fractions, figures, BER log axis.\n');
    else
        fprintf(fid, 'information fractions, figures, legacy-figure compatibility.\n');
    end
end
