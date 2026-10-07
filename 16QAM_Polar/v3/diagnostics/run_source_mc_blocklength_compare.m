function comparison = run_source_mc_blocklength_compare()
%RUN_SOURCE_MC_BLOCKLENGTH_COMPARE PMF convergence of corrected source-MC S.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
    qam = build_cartesian_gray_qam(16);
    spec = struct('source','latent_p','pI',[0.65;0.8],'pQ',[0.65;0.8], ...
        'relation_I',[1 1;0 1],'relation_Q',[1 1;0 1]);
    Ns = [64 256 1024]; frames_by_N = [80 40 20]; source_samples = [200 120 60];
    rows = cell(3,6); results = cell(3,1);
    for in = 1:3
        cfg = config(); cfg.N = Ns(in); cfg.num_frames = frames_by_N(in); cfg.seed = 20260830;
        cfg.snr_mode = 'fixed_n0'; cfg.collect_frame_pmf = true;
        cfg.source_construction = 'source_mc_ga'; cfg.source_mc_samples = source_samples(in);
        r = sim_shaped_polar_gray_qam(16, spec, 120, cfg);
        s = cluster_bootstrap_tv(r.frame_psym(:,:,1), r.model_psym, 1000, cfg.seed + Ns(in));
        rows(in,:) = {Ns(in),frames_by_N(in),source_samples(in),s.tv_point,s.tv_upper95,r.rf_energy_proxy_empirical};
        results{in}=r;
        fprintf('[source-MC N] N=%d design=%d frames=%d | TV=%.4f | upper95=%.4f | E=%.4f | p=%s\n', ...
            Ns(in),source_samples(in),frames_by_N(in),s.tv_point,s.tv_upper95, ...
            r.rf_energy_proxy_empirical,mat2str(r.empirical_latent_p(:,1).',3));
    end
    comparison = struct('table',cell2table(rows,'VariableNames', ...
        {'N','frames','source_samples','TV_point','TV_upper95','E_empirical'}),'results',{results});
end
