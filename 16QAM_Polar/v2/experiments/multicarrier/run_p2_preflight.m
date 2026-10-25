function out = run_p2_preflight()
%RUN_P2_PREFLIGHT Only short authorized work. Never starts a formal experiment.
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    addpath(root); setup_paths();
    out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_p2_preflight']);
    assert(~isfolder(out)); mkdir(out);
    cfg=p2_default_config(); cfg.mode='pilot'; cfg.purpose='power_calibration';
    cfg.controls={'shaped','same_k_i','native'}; % explicitly retained historical design probe
    cfg.seed=8101; cfg.num_frames=4; cfg.snr_grid=24;
    % Reuse the exact source-MC construction used in completed P1, not a rerun.
    cfg.templates_file=fullfile(root,'results','20261010_220806_b4_equal_power_p1_formal', ...
        'b4b_strict_ofdm_rayleigh.mat');
    assert(isfile(cfg.templates_file),'Audited P1 templates missing; choose explicit source artifact.');
    dirs=cell(1,2);
    for k=1:2
        cfg.seed=8100+k; dirs{k}=run_p2_mechanism(cfg);
        save(fullfile(out,'progress.mat'),'dirs','cfg');
    end
    power_file=p2_freeze_power(dirs,out);
    cfg.purpose='pilot'; cfg.seed=8301; cfg.num_frames=1;
    cfg.snr_grid=[24,32]; cfg.power_file=power_file;
    cfg.predict=true; cfg.diagnose=true;
    pilot=run_p2_mechanism(cfg); save(fullfile(out,'pilot_path.mat'),'pilot');
    analysis=analyze_p2_mechanism({pilot},fullfile(out,'analysis'),2000);
    % Single-carrier: separate power fit and three representative p, no full sweep.
    single=cfg; single.n_sc=1; single.cp=0; single.taps=1;
    single.strategy_names={'uniform_p05','uniform_p03','uniform_p01'};
    single.strategy_p=[.5,.5,.5;.3,.3,.3;.1,.1,.1]; single.controls={'shaped'};
    single.power_file=''; single.purpose='power_calibration'; single.seed=8103;
    single.snr_grid=12; single.num_frames=4; single.predict=false; single.diagnose=false;
    single_cal=run_p2_mechanism(single);
    single_power=p2_freeze_power({single_cal},fullfile(out,'singlecarrier_power'));
    single.purpose='singlecarrier'; single.seed=8801; single.snr_grid=[8,12,16];
    single.num_frames=1; single.predict=true; single.diagnose=true; single.power_file=single_power;
    bridge=run_p2_mechanism(single);
    single_analysis=analyze_p2_mechanism({bridge},fullfile(out,'singlecarrier_analysis'),2000);
    save(fullfile(out,'preflight.mat'),'dirs','pilot','analysis','bridge','single_analysis','power_file');
    fid=fopen(fullfile(out,'README.txt'),'w'); closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'P2 preflight ONLY. No formal budget approved, no formal power/PMF/model gates passed.\n');
    fprintf(fid,'OFDM: %s\nSingle carrier: %s\n',pilot,bridge);
    fprintf('P2_PREFLIGHT: %s\n',out);
end
