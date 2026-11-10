function test_p2_preflight_future_workload()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    ids={'A','B','C','D','E','F'}; purposes={'pmf','model_calibration','test_seen','test_unseen','strategy_training','strategy_test'};
    splits={'pmf_train','model_train','seen_first_v2','unseen_first_v2','strategy_train','strategy_test_v2'};
    channels=[3 10 20 20 20 20]; points=[3 3 3 3 1 1]; cases=[6 3 3 3 28 28]; frames=[80 40 40 40 40 40];
    for i=1:6
        jobs(i)=struct('job_id',ids{i},'purpose',purposes{i},'split',splits{i}, ...
            'num_channels',channels(i),'num_snr',points(i),'num_cases',cases(i),'num_frames',frames(i)); %#ok<AGROW>
    end
    controls={'shaped','random_s','donor_s'};
    A=p2_future_draft_cases([.3 .3 .3;.3 .1 .5],{'seen','unseen'},controls);
    B=p2_future_draft_cases([.3 .3 .3],{'seen'},controls);
    D=p2_future_draft_cases([.3 .1 .5],{'unseen'},controls);
    [x,y,z]=ndgrid([.1 .3 .5]); p=[x(:),y(:),z(:);.5 .3 .1];
    names=arrayfun(@(i) sprintf('combo_%02d',i),1:27,'UniformOutput',false);
    E=p2_future_draft_cases(p,[names,{'bad_channel_energy_only'}],{'shaped'});
    manifests={A,B,B,D,E,E};
    for i=1:6, jobs(i).case_manifest=manifests{i}; end
    r=p2_preflight_future_workload(jobs,67120); assert(r.total_case_frames==67120 && height(r.jobs)==6);
    bad=jobs; bad(1).case_manifest=bad(1).case_manifest(1:5); caught=false;
    try,p2_preflight_future_workload(bad,100000);catch e,caught=strcmp(e.identifier,'futurebudget:CaseMismatch');end; assert(caught);
    caught=false; try,p2_preflight_future_workload(jobs,67119);catch e,caught=strcmp(e.identifier,'futurebudget:CapExceeded');end; assert(caught);
    bad=jobs; bad(2).split=bad(1).split; caught=false;
    try,p2_preflight_future_workload(bad,100000);catch e,caught=strcmp(e.identifier,'futurebudget:Duplicate');end; assert(caught);
    bad=jobs; bad(3).split='seen_first'; caught=false;
    try,p2_preflight_future_workload(bad,100000);catch e,caught=strcmp(e.identifier,'futurebudget:RoleMismatch');end; assert(caught);
    disp('A-F count and cap/domain rejections passed; no experiment executed.');
end

