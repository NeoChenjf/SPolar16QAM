function test_p2_common_pmf_guards()
% Verify rejected roles, missing assets and incompatible configuration.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    tmp=tempname; mkdir(tmp); cleanup=onCleanup(@() rmdir(tmp,'s')); %#ok<NASGU>
    cfg=p2_default_config(); cfg.mode='smoke'; cfg.purpose='pilot'; cfg.N=32;
    cfg.snr_grid=24; cfg.num_channels=1; cfg.num_frames=1;
    cfg.strategy_names={'uniform_p03'}; cfg.strategy_p=[.3 .3 .3];
    cfg.controls={'shaped','random_s','donor_s'}; cfg.predict=true;
    fails(@() run_p2_common_environment(cfg),'commonenv:MissingPMF');
    cfg.mode='formal'; fails(@() run_p2_common_environment(cfg),'commonenv:FormalUnavailable');
    cfg.mode='smoke'; save(fullfile(tmp,'params.mat'),'cfg');
    fails(@() p2_common_freeze_pmf(tmp),'commonpmf:InvalidRole');
    training=cfg; training.purpose='power_calibration'; training.seed=8101; training.N=64;
    pmf_asset=struct('status','exploratory_short_run_not_formal','cfg',training);
    file=fullfile(tmp,'incompatible.mat'); save(file,'pmf_asset'); cfg.pmf_file=file;
    fails(@() run_p2_common_environment(cfg),'commonenv:PMFContract');
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
