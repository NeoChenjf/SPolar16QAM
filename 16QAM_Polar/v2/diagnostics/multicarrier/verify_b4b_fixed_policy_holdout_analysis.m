function report = verify_b4b_fixed_policy_holdout_analysis(result_dir)
% VERIFY_B4B_FIXED_POLICY_HOLDOUT_ANALYSIS Audit frozen-policy holdout outputs.
    result_dir = char(result_dir);
    V = readtable(fullfile(result_dir, 'fixed_policy_holdout_summary.csv'));
    D = load(fullfile(result_dir, 'fixed_policy_holdout_analysis.mat'));
    assert(height(V) == 6 && isequal(V.snr_dB.', [20 24 28 32 36 40]));
    assert(strcmp(V.selected_strategy{1}, 'uniform_p05'));
    assert(all(strcmp(V.selected_strategy(2:end), 'uniform_p01')));
    assert(~V.gate_required(1) && all(V.gate_required(2:end)));
    assert(all(V.holdout_ber_upper95 >= V.holdout_ber));
    assert(all(V.holdout_goodput_lower95 <= V.holdout_goodput));
    assert(V.point_pass(1), '20 dB fallback must retain maximum holdout Goodput.');
    expected_gate = V.holdout_ber_upper95 <= D.ber_limit & ...
        V.holdout_goodput_lower95 >= D.goodput_floor;
    assert(isequal(V.communication_gate_pass(2:end), expected_gate(2:end)));
    assert(isequal(D.overall_pass, all(V.point_pass)));
    assert(strcmp(D.status, 'PARTIAL') && ~D.overall_pass, ...
        'Current frozen holdout is expected to expose the 24 dB boundary failure.');
    assert(~V.point_pass(V.snr_dB == 24) && all(V.point_pass(V.snr_dB ~= 24)));
    assert(all(V.holdout_energy_gain_vs_p05(2:end) > 0));
    names = {'b4b_fixed_policy_train_vs_holdout', 'b4b_fixed_policy_gate_margins'};
    exts = {'png', 'pdf', 'fig'};
    for i = 1:numel(names)
        for j = 1:numel(exts)
            assert(exist(fullfile(result_dir, 'figures', ...
                [names{i} '.' exts{j}]), 'file') == 2, 'Missing holdout figure.');
        end
    end
    report = struct('status', 'PASS', 'analysis_status', D.status, ...
        'failed_snr', V.snr_dB(~V.point_pass));
    fid = fopen(fullfile(result_dir, 'audit.txt'), 'w');
    assert(fid >= 0); cleanup_fid = onCleanup(@() fclose(fid));
    fprintf(fid, 'B4b FIXED POLICY HOLDOUT AUDIT: PASS\n');
    fprintf(fid, 'analysis_status=%s\nfailed_snr=%s\n', D.status, ...
        mat2str(V.snr_dB(~V.point_pass).'));
    fprintf(fid, 'Checks: frozen mapping, interval identities, gate rule, fallback, energy direction, figures.\n');
end
