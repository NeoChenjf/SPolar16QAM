function comparison = run_source_construction_compare()
%RUN_SOURCE_CONSTRUCTION_COMPARE Compare BSC proxy against direct source MC.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
    qam = build_cartesian_gray_qam(16);
    spec = struct('source','latent_p','pI',[0.65;0.8],'pQ',[0.65;0.8], ...
        'relation_I',[1 1;0 1],'relation_Q',[1 1;0 1]);
    modes = {'bsc_ga','source_mc_ga'}; rows = cell(2,4); results = cell(2,1);
    for im = 1:2
        cfg = config(); cfg.N = 64; cfg.num_frames = 80; cfg.seed = 20260828;
        cfg.snr_mode = 'fixed_n0'; cfg.collect_frame_pmf = true; cfg.source_construction = modes{im};
        cfg.source_mc_samples = 200;
        r = sim_shaped_polar_gray_qam(16, spec, 120, cfg);
        s = cluster_bootstrap_tv(r.frame_psym(:,:,1), r.model_psym, 1000, cfg.seed + im);
        rows(im,:) = {modes{im},s.tv_point,s.tv_upper95,r.rf_energy_proxy_empirical}; results{im}=r;
        fprintf('[source compare] %s | TV=%.4f | upper95=%.4f | E=%.4f | p=%s\n', ...
            modes{im},s.tv_point,s.tv_upper95,r.rf_energy_proxy_empirical,mat2str(r.empirical_latent_p(:,1).',3));
    end
    comparison = struct('table',cell2table(rows,'VariableNames',{'construction','TV_point','TV_upper95','E_empirical'}),'results',{results});
end
