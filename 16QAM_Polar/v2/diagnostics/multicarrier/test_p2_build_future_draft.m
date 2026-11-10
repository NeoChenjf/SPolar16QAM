function test_p2_build_future_draft()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    base=p2_default_config(); r=p2_build_future_draft(base);
    assert(strcmp(r.status,'draft_only_not_authorized') && r.workload.total_case_frames==67120);
    assert(isequal(r.workload.jobs.case_frames',[4320 3600 7200 7200 22400 22400]));
    assert(all(cellfun(@(c) strcmp(c.mode,'draft_only') && isempty(c.power_file),r.configs)));
    bad=base; bad.N=256; caught=false;
    try,p2_build_future_draft(bad);catch e,caught=strcmp(e.identifier,'futuredraft:InvalidBase');end; assert(caught);
    cfg=r.configs{3}; cfg.snr_grid(1)=19; caught=false;
    try,p2_validate_future_job(r.jobs{3},cfg);catch e,caught=strcmp(e.identifier,'futurejob:Mismatch');end; assert(caught);
    disp('A-F draft configurations matched 67120 case-frames; no job executed');
end
