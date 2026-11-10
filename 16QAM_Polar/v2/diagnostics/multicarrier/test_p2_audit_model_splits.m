function test_p2_audit_model_splits()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    d=fullfile(root,'results','20261106_171343_p2_common_env_pilot_model_calibration_4347fed4');
    t=fullfile(root,'results','20261106_171512_p2_common_env_pilot_test_seen_4a3a8174');
    f=fullfile(d,'frozen_exploratory_model.mat'); rng(1234); before=rng;
    result=p2_audit_model_splits(f,t); after=rng;
    assert(isequal(before,after) && result.training_channels==3 && result.test_channels==3);
    caught=false;
    try, p2_audit_model_splits(f,d); catch e, caught=strcmp(e.identifier,'splitaudit:InvalidRole'); end
    assert(caught,'Calibration dataset must not serve as test.');
end
