function report = verify_b4b_paired_policy_analysis(result_dir)
% VERIFY_B4B_PAIRED_POLICY_ANALYSIS Audit paired and policy outputs.

    validateattributes(result_dir, {'char', 'string'}, {'scalartext'});
    result_dir = char(result_dir);
    required = {'paired_differences.csv', 'strategy_summary_with_ci.csv', ...
        'policy_selection.csv', 'pareto_points.csv', ...
        'b4b_paired_policy_analysis.mat', 'README.txt', 'run_log.txt'};
    for i = 1:numel(required)
        assert(exist(fullfile(result_dir, required{i}), 'file') == 2, ...
            'Missing analysis output: %s', required{i});
    end
    P = readtable(fullfile(result_dir, 'paired_differences.csv'));
    S = readtable(fullfile(result_dir, 'strategy_summary_with_ci.csv'));
    L = readtable(fullfile(result_dir, 'policy_selection.csv'));
    D = load(fullfile(result_dir, 'b4b_paired_policy_analysis.mat'), ...
        'T', 'reference_strategy', 'ber_limit', 'goodput_floor');

    assert(height(P) == 90, 'Expected 5 candidates x 6 SNRs x 3 metrics.');
    assert(height(S) == 36, 'Expected 6 strategies x 6 SNRs.');
    assert(height(L) == 6, 'Expected one policy choice per SNR.');
    assert(all(P.num_pairs == 30), 'Every paired comparison must use 30 realizations.');
    assert(all(isfinite(P.delta_mean)) && all(isfinite(P.delta_ci95)));
    assert(all(P.ci_low <= P.delta_mean & P.delta_mean <= P.ci_high));
    assert(all(P.two_sided_sign_p >= 0 & P.two_sided_sign_p <= 1));
    assert(all(isfinite(S.ber_mean)) && all(S.ber_mean >= 0 & S.ber_mean <= 1));
    assert(all(isfinite(S.goodput_mean)) && all(S.goodput_mean >= 0));
    assert(all(isfinite(S.energy_mean)) && all(S.energy_mean > 0));

    for i = 1:height(P)
        ref = sortrows(D.T(strcmp(D.T.strategy, D.reference_strategy) & ...
            D.T.snr_dB == P.snr_dB(i), :), 'realization');
        cand = sortrows(D.T(strcmp(D.T.strategy, P.candidate_strategy{i}) & ...
            D.T.snr_dB == P.snr_dB(i), :), 'realization');
        assert(isequal(ref.realization, cand.realization), 'Pairing key mismatch.');
        delta = cand.(P.metric{i}) - ref.(P.metric{i});
        assert(abs(mean(delta) - P.delta_mean(i)) < 1e-12, ...
            'Paired mean identity failed.');
    end

    for i = 1:height(L)
        idx = strcmp(S.strategy, L.selected_strategy{i}) & S.snr_dB == L.snr_dB(i);
        assert(sum(idx) == 1, 'Selected strategy is absent from summary.');
        feasible = S.ber_ci_high <= D.ber_limit & ...
            (S.goodput_mean - S.goodput_ci95) >= D.goodput_floor & ...
            S.snr_dB == L.snr_dB(i);
        if any(feasible)
            max_energy = max(S.energy_mean(feasible));
            assert(abs(S.energy_mean(idx) - max_energy) < 1e-12, ...
                'Feasible policy did not maximize receive energy.');
        else
            same_snr = S.snr_dB == L.snr_dB(i);
            assert(abs(S.goodput_mean(idx) - max(S.goodput_mean(same_snr))) < 1e-12, ...
                'Fallback policy did not maximize Goodput.');
        end
    end

    figure_names = {'b4b_paired_differences', 'b4b_formal_metrics_with_ci', ...
        'b4b_low_complexity_policy', 'b4b_tradeoff_pareto_by_snr'};
    extensions = {'png', 'pdf', 'fig'};
    for i = 1:numel(figure_names)
        for j = 1:numel(extensions)
            assert(exist(fullfile(result_dir, 'figures', ...
                [figure_names{i} '.' extensions{j}]), 'file') == 2, ...
                'Missing analysis figure.');
        end
    end
    report = struct('status', 'PASS', 'paired_rows', height(P), ...
        'summary_rows', height(S), 'policy_rows', height(L));
    fid = fopen(fullfile(result_dir, 'audit.txt'), 'w');
    assert(fid >= 0, 'Cannot create analysis audit.');
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, 'B4b PAIRED POLICY ANALYSIS AUDIT: PASS\n');
    fprintf(fid, 'paired_rows=%d\nsummary_rows=%d\npolicy_rows=%d\n', ...
        height(P), height(S), height(L));
    fprintf(fid, 'Checks: dimensions, finite/range values, pairing keys, paired means, selection rule, figures.\n');
end
