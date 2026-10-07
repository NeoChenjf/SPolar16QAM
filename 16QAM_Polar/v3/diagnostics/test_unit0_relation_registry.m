function test_unit0_relation_registry()
%TEST_UNIT0_RELATION_REGISTRY Validate every frozen Gray-PAM relation in use.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(root); setup_paths;
    for k = 1:3
        [T, metadata] = frozen_gray_pam_relation(k);
        assert(isequal(mod(T * gf2_inverse(T), 2), eye(k)));
        assert(isfield(metadata, 'version') && ~isempty(metadata.version));
    end
    qam16 = build_cartesian_gray_qam(16);
    for lambda = [-0.5 -0.25 0 0.25 0.5]
        built = build_energy_lambda_spec(qam16, lambda);
        assert(built.kl_target_model <= 1e-10 && built.tv_target_model <= 1e-8);
    end
    qam64 = build_cartesian_gray_qam(64);
    for lambda = [0 0.25 0.5]
        built = build_energy_lambda_spec(qam64, lambda);
        assert(~strcmp(built.match_status, 'fail'));
    end
    fprintf('[Unit0] frozen PAM2/PAM4/PAM8 relation registry PASS\n');
end
