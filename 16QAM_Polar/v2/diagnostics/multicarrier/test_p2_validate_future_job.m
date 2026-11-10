function test_p2_validate_future_job()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    cfg=p2_default_config(); cfg.mode='draft_only'; cfg.purpose='model_calibration'; cfg.future_split='model_train';
    cfg.snr_grid=[20 24 28]; cfg.strategy_p=[.3 .3 .3]; cfg.strategy_names={'seen'};
    cfg.controls={'shaped','random_s','donor_s'}; cfg.num_channels=10; cfg.num_frames=40;
    fields={'N','n_sc','cp','taps','source_seed','source_samples','quadrature_order', ...
        'snr_grid','strategy_p','strategy_names','controls','num_channels','num_frames','future_split','predict','diagnose'};
    job=struct('job_id','B','purpose',cfg.purpose,'case_manifest', ...
        p2_future_draft_cases(cfg.strategy_p,cfg.strategy_names,cfg.controls));
    for k=1:numel(fields), job.(fields{k})=cfg.(fields{k}); end
    r=p2_validate_future_job(job,cfg); assert(r.case_count==3 && r.case_frames==3600);
    bad=cfg; bad.cp=bad.cp+1; caught=false;
    try,p2_validate_future_job(job,bad);catch e,caught=strcmp(e.identifier,'futurejob:Mismatch');end;assert(caught);
    bad=cfg; bad.mode='formal'; caught=false;
    try,p2_validate_future_job(job,bad);catch e,caught=strcmp(e.identifier,'futurejob:InvalidMode');end;assert(caught);
    bad=job; bad.case_manifest(1).p(1)=.1; caught=false;
    try,p2_validate_future_job(bad,cfg);catch e,caught=strcmp(e.identifier,'futurejob:CasesMismatch');end;assert(caught);
    disp('draft B contract and configuration mismatch checks passed; no experiment executed');
end

