function test_unit0_gray_qam()
%TEST_UNIT0_GRAY_QAM Static Unit 0 checks; no Monte Carlo BER sweep.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(root); setup_paths;
    Ms = [8 16 32 64];
    for M = Ms
        qam = build_cartesian_gray_qam(M);
        assert(numel(qam.constellation) == M && size(unique(qam.labels, 'rows'), 1) == M);
        assert(abs(mean(abs(qam.constellation).^2) - 1) < 1e-12);
        local_check_gray(qam.labelsI); local_check_gray(qam.labelsQ);
        TI = eye(qam.mI); TQ = eye(qam.mQ);
        model = build_qam_model_pmf(qam, 0.5 * ones(qam.mI,1), TI, 0.5 * ones(qam.mQ,1), TQ);
        assert(abs(sum(model.psym) - 1) < 1e-12 && all(model.psym > 0));
        for is = 1:M
            llr = llr_gray_qam_latent_lse(qam.constellation(is), qam, model, 1e-3);
            expected = model.z_labels(is, :).';
            assert(all((expected == 0 & llr > 0) | (expected == 1 & llr < 0)));
        end
        fprintf('[Unit0] M=%d constellation/Gray/latent-LLR PASS\n', M);
    end
    assert(numel(enumerate_gf2_invertible(1)) == 1);
    assert(numel(enumerate_gf2_invertible(2)) == 6);
    assert(numel(enumerate_gf2_invertible(3)) == 168);
    fprintf('[Unit0] GL(1,2)/GL(2,2)/GL(3,2) counts PASS\n');
end

function local_check_gray(labels)
    for i = 1:(size(labels, 1) - 1)
        assert(sum(labels(i, :) ~= labels(i + 1, :)) == 1);
    end
end
