function test_p2_future_resume()
% Resume a temporary copy after dropping one completed case, never original data.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    src=fullfile(root,'results','20261106_220749_p2_future_diagnostic_smoke_pilot_c147dd0b');
    assert(isfolder(src),'futureresume:MissingFixture','Diagnostic fixture absent.');
    dst=tempname(fullfile(root,'results')); mkdir(dst); cleanup=onCleanup(@() rmdir(dst,'s')); %#ok<NASGU>
    copyfile(fullfile(src,'*'),dst);
    p=load(fullfile(dst,'params.mat'),'cfg'); cfg=p.cfg;
    s=load(fullfile(dst,'checkpoint.mat'),'T','completed','raw_hashes'); T=s.T; completed=s.completed; raw_hashes=s.raw_hashes;
    assert(height(T)==3 && numel(completed)==3);
    last=T(end,:); index=find(cfg.snr_grid==last.snr_db);
    name=sprintf('raw_c%d_s%d_%s.mat',last.channel,index,last.case_id{1});
    original=load(fullfile(src,name),'artifact');
    partial=T; partial(end,:)=[]; partial_completed=completed; partial_completed(end)=[]; partial_hashes=raw_hashes; partial_hashes(end)=[];
    caught=false; try,p2_validate_future_checkpoint(dst,partial,partial_completed,partial_hashes);
    catch e,caught=strcmp(e.identifier,'futurecheckpoint:Mismatch');end
    assert(caught,'Orphan raw file must be rejected.');
    delete(fullfile(dst,name)); caught=false;
    try,p2_validate_future_checkpoint(dst,T,completed,raw_hashes);
    catch e,caught=strcmp(e.identifier,'futurecheckpoint:Mismatch');end
    assert(caught,'Completed entry without raw file must be rejected.');
    broken=cfg; broken.resume_dir=dst; caught=false;
    try,run_p2_future_diagnostic(broken);catch e,caught=strcmp(e.identifier,'futurecheckpoint:Mismatch');end
    assert(caught,'Runner must reject completed entry without raw.');
    T=partial; completed=partial_completed; raw_hashes=partial_hashes;
    save(fullfile(dst,'checkpoint.mat'),'T','completed','raw_hashes','-v7.3');
    cfg.resume_dir=dst; bad=cfg; bad.num_frames=2; caught=false;
    try,run_p2_future_diagnostic(bad);catch e,caught=contains(e.message,'Resume configuration mismatch');end
    assert(caught,'Changed resume configuration must be rejected.');
    out=run_p2_future_diagnostic(cfg); assert(strcmp(out,dst));
    resumed=load(fullfile(dst,name),'artifact'); a=original.artifact; b=resumed.artifact;
    assert(isequaln(a.h,b.h) && isequaln(a.frame_hashes,b.frame_hashes) && ...
        isequaln(a.stream_errors,b.stream_errors) && isequaln(a.info_counts,b.info_counts) && ...
        isequaln(a.counts,b.counts),'Resumed case must reproduce original inputs and counts.');
    result=readtable(fullfile(dst,'repetitions.csv')); assert(height(result)==3);
    p2_audit_common_pairing(dst); p2_validate_common_raw_metrics(dst,result);
    fprintf('resumed final diagnostic case with identical inputs and counts\n');
end






