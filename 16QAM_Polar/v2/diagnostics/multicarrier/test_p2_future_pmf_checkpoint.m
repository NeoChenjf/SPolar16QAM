function test_p2_future_pmf_checkpoint()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    src=fullfile(root,'results','20261106_220751_p2_future_diagnostic_smoke_power_calibration_89cf8e9e');
    dst=tempname(fullfile(root,'results')); mkdir(dst); cleanup=onCleanup(@() rmdir(dst,'s')); %#ok<NASGU>
    copyfile(fullfile(src,'*'),dst);
    x=load(fullfile(dst,'checkpoint.mat'),'T','completed','raw_hashes'); T=x.T; completed=x.completed; hashes=x.raw_hashes;
    p2_validate_future_checkpoint(dst,T,completed,hashes);
    bad=T; bad.ber(1)=0; caught=false;
    try,p2_validate_future_checkpoint(dst,bad,completed,hashes);catch e,caught=strcmp(e.identifier,'futurecheckpoint:InvalidCounts');end
    assert(caught,'No-noise BER must not be represented as zero.');
    f=fullfile(dst,'raw_c1_s1_uniform_p03_shaped.mat'); a=load(f,'artifact'); artifact=a.artifact;
    v=artifact.counts(:,1,1); from=find(v>0,1); to=mod(from,16)+1;
    artifact.counts(from,1,1)=artifact.counts(from,1,1)-1;
    artifact.counts(to,1,1)=artifact.counts(to,1,1)+1;
    save(f,'artifact','-v7.3'); caught=false;
    try,p2_validate_future_checkpoint(dst,T,completed,hashes);catch e,caught=strcmp(e.identifier,'futurecheckpoint:HashMismatch');end
    assert(caught,'Total-preserving label change must fail checkpoint digest.');
    fprintf('PMF NaN and total-preserving raw change rejected\n');
end
