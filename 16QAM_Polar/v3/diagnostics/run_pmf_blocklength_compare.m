function comparison = run_pmf_blocklength_compare()
%RUN_PMF_BLOCKLENGTH_COMPARE Test whether BSC+GA PMF mismatch is short-block loss.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
    qam = build_cartesian_gray_qam(16);
    spec = struct('source','latent_p','pI',[0.65;0.8],'pQ',[0.65;0.8], ...
        'relation_I',[1 1;0 1],'relation_Q',[1 1;0 1]);
    Ns = [64 256 1024]; frames_by_N = [80 40 20]; rows = cell(numel(Ns),5); results = cell(numel(Ns),1);
    for in = 1:numel(Ns)
        cfg = config(); cfg.N = Ns(in); cfg.num_frames = frames_by_N(in); cfg.seed = 20260828;
        cfg.snr_mode = 'fixed_n0'; cfg.collect_frame_pmf = true; cfg.bsc_s_mode = 'reliable';
        r = sim_shaped_polar_gray_qam(16, spec, 120, cfg);
        s = cluster_bootstrap_tv(r.frame_psym(:,:,1), r.model_psym, 1000, cfg.seed + Ns(in));
        rows(in,:) = {Ns(in), frames_by_N(in), s.tv_point, s.tv_upper95, r.rf_energy_proxy_empirical};
        results{in} = r;
        fprintf('[N compare] N=%d frames=%d | TV=%.4f | upper95=%.4f | E=%.4f\n', ...
            Ns(in), frames_by_N(in), s.tv_point, s.tv_upper95, r.rf_energy_proxy_empirical);
        fprintf('            target p=%s | empirical p=%s\n', ...
            mat2str(r.target_latent_p.',3), mat2str(r.empirical_latent_p(:,1).',3));
    end
    comparison = struct('table',cell2table(rows,'VariableNames', ...
        {'N','frames','TV_point','TV_upper95','E_empirical'}),'results',{results});
end
