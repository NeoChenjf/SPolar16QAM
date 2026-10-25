function out = run_p2_auxiliary_preflight()
%RUN_P2_AUXILIARY_PREFLIGHT Short random-S/donor-S probes; no formal permission implied.
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    addpath(root); setup_paths();
    out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_p2_auxiliary_preflight']);
    assert(~isfolder(out)); mkdir(out);
    cfg=p2_default_config(); cfg.mode='pilot'; cfg.purpose='power_calibration';
    cfg.num_frames=4; cfg.snr_grid=28;
    cfg.templates_file=fullfile(root,'results','20261010_220806_b4_equal_power_p1_formal','b4b_strict_ofdm_rayleigh.mat');
    dirs=cell(1,2);
    for i=1:2
        cfg.seed=8100+i; dirs{i}=run_p2_mechanism(cfg);
        save(fullfile(out,'progress.mat'),'dirs');
    end
    power_file=p2_freeze_power(dirs,out);
    cfg.power_file=power_file; cfg.purpose='pilot'; cfg.seed=8301;
    cfg.num_frames=2; cfg.snr_grid=[24,28,32]; cfg.predict=true; cfg.diagnose=true;
    pilot=run_p2_mechanism(cfg); save(fullfile(out,'pilot_path.mat'),'pilot');
    % Distribution/S marginals are probed with independent seeds and 8 frames
    % each. This is intentionally smaller than 3x80 formal PMF acceptance.
    pmf_dirs=cell(1,3); cfg.predict=false; cfg.diagnose=false;
    cfg.purpose='pmf'; cfg.num_frames=8; cfg.snr_grid=28;
    for i=1:3
        cfg.seed=8700+i; pmf_dirs{i}=run_p2_mechanism(cfg);
        save(fullfile(out,'pmf_progress.mat'),'pmf_dirs');
    end
    analysis=analyze_p2_mechanism({pilot},fullfile(out,'analysis'),2000);
    pmf_analysis=analyze_p2_mechanism(pmf_dirs,fullfile(out,'pmf_analysis'),2000);
    save(fullfile(out,'preflight.mat'),'dirs','pilot','analysis','pmf_dirs','pmf_analysis','power_file');
    fid=fopen(fullfile(out,'README.txt'),'w'); closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'Random-S and donor-S preflight; not a formal scientific acceptance.\n');
    fprintf(fid,'Pilot %s\nPMF/S statistics %s\n',pilot,pmf_analysis);
    fprintf(fid,'Fair random S is a uniform target; donor S is a diagnostic distribution, not a uniform target.\n');
    fprintf('P2_AUXILIARY_PREFLIGHT: %s\n',out);
end
