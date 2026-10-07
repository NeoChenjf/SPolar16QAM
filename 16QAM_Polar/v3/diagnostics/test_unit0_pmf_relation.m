function test_unit0_pmf_relation()
%TEST_UNIT0_PMF_RELATION Verify nonuniform latent PMF and 8-PAM auto relation.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
    for M = [8 16 32 64]
        qam = build_cartesian_gray_qam(M);
        pI = linspace(0.58, 0.82, qam.mI).';
        pQ = linspace(0.61, 0.79, qam.mQ).';
        TI = eye(qam.mI); TQ = eye(qam.mQ);
        model = build_qam_model_pmf(qam, pI, TI, pQ, TQ);
        assert(abs(sum(model.psym) - 1) < 1e-12 && all(model.psym > 0));
        assert(local_tv(model.psym, ones(qam.M,1) / qam.M) > 1e-4);
        for is = 1:qam.M
            z = model.z_labels(is, :);
            [~, labels, idx] = map_latent_bits_to_qam(z, qam, model);
            assert(idx == is && isequal(labels, qam.labels(is, :)));
        end
        fprintf('[Unit0] M=%d nonuniform PMF and z<->b lookup PASS\n', M);
    end
    qam64 = build_cartesian_gray_qam(64);
    selection = select_auto_gf2_relation(qam64.levelsI, qam64.labelsI);
    assert(isequal(size(selection.T), [3 3]) && selection.candidate_count == 168);
    assert(all(isfinite(selection.p_by_lambda{1})) && isfinite(selection.mean_kl));
    assert(isequal(mod(double(selection.T) * gf2_inverse(selection.T), 2), eye(3)));
    fprintf('[Unit0] 8-PAM optimized GF(2) relation search PASS | mean KL=%.3e\n', selection.mean_kl);
end

function tv = local_tv(a, b)
    tv = 0.5 * sum(abs(a(:) - b(:)));
end
