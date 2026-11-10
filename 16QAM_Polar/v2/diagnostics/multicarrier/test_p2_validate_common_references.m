function test_p2_validate_common_references()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    src=fullfile(root,'results','20261106_171343_p2_common_env_pilot_model_calibration_4347fed4');
    dst=tempname; mkdir(dst); cleanup=onCleanup(@() rmdir(dst,'s')); %#ok<NASGU>
    copyfile(fullfile(src,'params.mat'),fullfile(dst,'params.mat'));
    p=load(fullfile(src,'params.mat'),'cfg'); T=readtable(fullfile(src,'repetitions.csv')); T=T(1,:);
    index=find(p.cfg.snr_grid==T.snr_db(1)); name=sprintf('raw_c%d_s%d_%s.mat',T.channel(1),index,T.case_id{1});
    a=load(fullfile(src,name),'artifact'); artifact=a.artifact; save(fullfile(dst,name),'artifact','-v7.3');
    writetable(T,fullfile(dst,'repetitions.csv')); p2_validate_common_references(dst);
    artifact.refs{1}.ga_mean(1)=artifact.refs{1}.ga_mean(1)+1;
    save(fullfile(dst,name),'artifact','-v7.3'); caught=false;
    try, p2_validate_common_references(dst); catch e, caught=strcmp(e.identifier,'refcheck:Mismatch'); end
    assert(caught,'Changed reference must be rejected.');
end
