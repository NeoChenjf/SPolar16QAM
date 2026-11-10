function test_p2_validate_common_model()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    d=fullfile(root,'results','20261106_171343_p2_common_env_pilot_model_calibration_4347fed4');
    x=load(fullfile(d,'frozen_exploratory_model.mat'),'model'); model=x.model;
    dst=tempname; mkdir(dst); cleanup=onCleanup(@() rmdir(dst,'s')); %#ok<NASGU>
    f=fullfile(dst,'model.mat'); save(f,'model'); p2_validate_common_model(f);
    model.parameters(1)=model.parameters(1)+1; save(f,'model'); caught=false;
    try, p2_validate_common_model(f); catch e, caught=strcmp(e.identifier,'modelcheck:Mismatch'); end
    assert(caught,'Altered model parameter must be rejected.');
end
