function test_p2_resume_contract()
%TEST_P2_RESUME_CONTRACT Real checkpoint skip, config rejection and artifact hashes.
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    addpath(root); setup_paths();
    fixture=tempname(fullfile(root,'results')); mkdir(fixture);
    power=struct('case_id','uniform_p05_shaped','scale',ones(1,3), ...
        'pmf',ones(16,3)/16,'frozen',true);
    cases=struct('id','uniform_p05_shaped','p',ones(1,3)*.5,'kind','shaped');
    power_path=fullfile(fixture,'power.mat'); save(power_path,'power','cases');
    cfg=p2_default_config(); cfg.N=16; cfg.snr_grid=24;
    cfg.strategy_names={'uniform_p05'}; cfg.strategy_p=ones(1,3)*.5;
    cfg.controls={'shaped'}; cfg.power_file=power_path;
    first=run_p2_mechanism(cfg); initial=readtable(fullfile(first,'repetitions.csv'));
    fid=fopen(fullfile(first,'repetitions.csv'),'w'); fprintf(fid,'interrupted CSV'); fclose(fid);
    cfg.resume_dir=first; second=run_p2_mechanism(cfg);
    after=readtable(fullfile(second,'repetitions.csv'));
    assert(height(initial)==1 && isequaln(initial,after),'Resume duplicated or changed a completed row.');
    invalid=cfg; invalid.num_frames=2; rejected=false;
    try, run_p2_mechanism(invalid); catch exception
        rejected=contains(exception.message,'configuration mismatch');
    end; assert(rejected,'Changed parameters were accepted.');
    power.scale=ones(1,3)*2; save(power_path,'power','cases'); rejected=false;
    try, run_p2_mechanism(cfg); catch exception
        rejected=contains(exception.message,'artifact changed');
    end; assert(rejected,'Changed frozen artifact was accepted.');
    % Restore this synthetic fixture, not a research artifact.
    power.scale=ones(1,3); save(power_path,'power','cases');
    fprintf('PASS test_p2_resume_contract: checkpoint skip, config guard, artifact guard.\n');
end
