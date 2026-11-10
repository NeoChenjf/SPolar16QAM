function test_p2_validate_common_pmf()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    p=load(fullfile(root,'results','20261106_171343_p2_common_env_pilot_model_calibration_4347fed4','params.mat'),'cfg');
    a=load(p.cfg.pmf_file,'pmf_asset'); pmf_asset=a.pmf_asset;
    dst=tempname; mkdir(dst); cleanup=onCleanup(@() rmdir(dst,'s')); %#ok<NASGU>
    path=fullfile(dst,'pmf.mat'); save(path,'pmf_asset'); p2_validate_common_pmf(path);
    pmf_asset.entries(1).pmf(1,1)=pmf_asset.entries(1).pmf(1,1)+.1;
    save(path,'pmf_asset'); caught=false;
    try, p2_validate_common_pmf(path); catch e, caught=strcmp(e.identifier,'pmfcheck:Mismatch'); end
    assert(caught,'Altered PMF must be rejected.');
end
