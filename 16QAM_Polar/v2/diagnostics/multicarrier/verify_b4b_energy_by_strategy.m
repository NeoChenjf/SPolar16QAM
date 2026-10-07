function report = verify_b4b_energy_by_strategy(result_dir)
% Verify the SNR-collapsed receive-energy strategy figure.
    result_dir = char(result_dir);
    D = readtable(fullfile(result_dir, 'energy_by_strategy_realization.csv'));
    S = readtable(fullfile(result_dir, 'energy_by_strategy_summary.csv'));
    assert(height(D) == 180, 'Expected 6 strategies x 30 realizations.');
    assert(height(S) == 6 && all(S.num_realizations == 30));
    assert(all(D.num_snr_points == 6));
    assert(all(isfinite(D.energy_mean_across_snr)) & ...
        all(D.energy_mean_across_snr > 0));
    for i = 1:height(S)
        x = D.energy_mean_across_snr(strcmp(D.strategy, S.strategy{i}));
        assert(abs(mean(x) - S.energy_mean(i)) < 1e-12);
        expected_ci = 1.96 * std(x, 0) / sqrt(numel(x));
        assert(abs(expected_ci - S.energy_ci95(i)) < 1e-12);
    end
    [~, highest] = max(S.energy_mean);
    [~, lowest] = min(S.energy_mean);
    assert(strcmp(S.strategy{highest}, 'uniform_p01'));
    assert(strcmp(S.strategy{lowest}, 'uniform_p05'));
    for ext = {'png', 'pdf', 'fig'}
        assert(exist(fullfile(result_dir, 'figures', ...
            ['b4b_energy_by_strategy.' ext{1}]), 'file') == 2);
    end
    report = struct('status', 'PASS', 'detail_rows', height(D), ...
        'summary_rows', height(S));
    fid = fopen(fullfile(result_dir, 'audit.txt'), 'w'); assert(fid >= 0);
    cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, 'B4b ENERGY-BY-STRATEGY AUDIT: PASS\n');
    fprintf(fid, 'detail_rows=%d\nsummary_rows=%d\n', height(D), height(S));
    fprintf(fid, 'Checks: complete SNR collapse, realization-level CI, extrema, figures.\n');
end
