function test_unit0_finite_noise_llr()
%TEST_UNIT0_FINITE_NOISE_LLR Compare stable latent LLRs with direct enumeration.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(root); setup_paths;
    sigma = 0.45;
    for M = [8 16 32 64]
        qam = build_cartesian_gray_qam(M);
        spec = build_energy_lambda_spec(qam, 0.5);
        model = build_qam_model_pmf(qam, spec.pI, spec.relation_I, ...
            spec.pQ, spec.relation_Q);
        y = [qam.constellation(1); qam.constellation(ceil(M/2)); ...
            0.17 + 0.23i; -0.41 + 0.09i];
        actual = reshape(llr_gray_qam_latent_lse(y, qam, model, sigma), qam.m, []).';
        reference = local_direct_llr(y, qam, model, sigma);
        assert(max(abs(actual(:) - reference(:))) < 1e-11);
        fprintf('[Unit0] M=%d finite-noise latent LLR reference PASS\n', M);
    end
end

function llr = local_direct_llr(y, qam, model, sigma)
    y = y(:); llr = zeros(numel(y), qam.m);
    for iy = 1:numel(y)
        metric = log(model.psym(:)) - ...
            abs(y(iy) - qam.constellation(:)).^2 / (2 * sigma^2);
        for k = 1:qam.m
            llr(iy, k) = local_lse(metric(model.z_labels(:, k) == 0)) - ...
                local_lse(metric(model.z_labels(:, k) == 1));
        end
    end
end

function value = local_lse(input)
    maximum = max(input);
    value = maximum + log(sum(exp(input - maximum)));
end
