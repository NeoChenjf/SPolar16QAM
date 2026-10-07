function test_unit0_noiseless_roundtrip()
%TEST_UNIT0_NOISELESS_ROUNDTRIP Small nonzero-message round trip for all M.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
    cfg = config(); cfg.N = 32; cfg.num_frames = 2; cfg.seed = 17; cfg.snr_mode = 'fixed_n0';
    cfg.force_nonzero_payload = true;
    for M = [8 16 32 64]
        qam = build_cartesian_gray_qam(M);
        spec = struct('source', 'latent_p', 'pI', 0.5 * ones(qam.mI,1), ...
            'pQ', 0.5 * ones(qam.mQ,1), 'relation_I', eye(qam.mI), 'relation_Q', eye(qam.mQ));
        result = sim_shaped_polar_gray_qam(M, spec, 120, cfg);
        assert(result.BER == 0 && result.BLER_joint == 0);
        assert(abs(sum(result.K) / cfg.N - result.R_bpcu) < 1e-12);
        fprintf('[Unit0] M=%d nonzero-message noiseless roundtrip PASS\n', M);
    end
    % Exercise actual shaping bits and non-identity relations with two seeds.
    % Exercise the registered relations used by the active energy family.
    for seed = [17 29]
        cfg.seed = seed;
        for M = [8 16 32 64]
            qam = build_cartesian_gray_qam(M);
            spec = struct('source', 'latent_p', ...
                'pI', linspace(0.65, 0.8, qam.mI).', ...
                'pQ', linspace(0.65, 0.8, qam.mQ).', ...
                'relation_I', frozen_gray_pam_relation(qam.mI), ...
                'relation_Q', frozen_gray_pam_relation(qam.mQ));
            for complement = [false true]
                run_spec = spec;
                if complement
                    run_spec.pI = 1 - spec.pI;
                    run_spec.pQ = 1 - spec.pQ;
                end
                model = build_qam_model_pmf(qam, run_spec.pI, run_spec.relation_I, ...
                    run_spec.pQ, run_spec.relation_Q);
                [tx, labels, idx] = map_latent_bits_to_qam(model.z_labels, qam, model);
                assert(isequal(idx(:), (1:M).') && isequal(labels, qam.labels));
                metric = reshape(llr_gray_qam_latent_lse(tx, qam, model, 1e-3), qam.m, M).';
                assert(all((metric(:) < 0) == model.z_labels(:)));
                result = sim_shaped_polar_gray_qam(M, run_spec, 120, cfg);
                assert(all(result.S_size > 0) && all(result.K > 0));
                assert(all(result.errors(:) == 0) && result.BLER_joint == 0);
                fprintf('[Unit0] M=%d seed=%d complement=%d shaped/relation roundtrip PASS\n', ...
                    M, seed, complement);
            end
        end
    end
end
