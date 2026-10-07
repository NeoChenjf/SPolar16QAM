function comparison = run_s_construction_compare()
%RUN_S_CONSTRUCTION_COMPARE PMF-only diagnostic for S-set orientation.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
    cfg = config(); cfg.N = 64; cfg.num_frames = 80; cfg.seed = 20260828;
    cfg.snr_mode = 'fixed_n0'; cfg.collect_frame_pmf = true;
    qam = build_cartesian_gray_qam(16);
    spec = struct('source','latent_p','pI',[0.65;0.8],'pQ',[0.65;0.8], ...
        'relation_I',[1 1;0 1],'relation_Q',[1 1;0 1]);
    modes = {'reliable','unreliable'}; rows = cell(numel(modes),4); results = cell(numel(modes),1);
    for im = 1:numel(modes)
        cfg.bsc_s_mode = modes{im};
        r = sim_shaped_polar_gray_qam(16, spec, 120, cfg);
        s = cluster_bootstrap_tv(r.frame_psym(:,:,1), r.model_psym, 1000, cfg.seed + im);
        rows(im,:) = {modes{im}, s.tv_point, s.tv_upper95, r.rf_energy_proxy_empirical};
        results{im} = r;
        fprintf('[S compare] %s | TV=%.4f | upper95=%.4f | E=%.4f\n', ...
            modes{im}, s.tv_point, s.tv_upper95, r.rf_energy_proxy_empirical);
    end
    comparison = struct('table',cell2table(rows,'VariableNames',{'S_mode','TV_point','TV_upper95','E_empirical'}), ...
        'results',{results});
end
