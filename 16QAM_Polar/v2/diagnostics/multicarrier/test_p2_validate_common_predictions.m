function test_p2_validate_common_predictions()
% Positive and corrupted-table test using one copied real exploratory raw.
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(root); setup_paths;
    src=fullfile(root,'results','20261106_171343_p2_common_env_pilot_model_calibration_4347fed4');
    assert(isfolder(src),'predictiontest:MissingFixture','Exploratory fixture is absent.');
    dst=tempname; mkdir(dst); cleanup=onCleanup(@() rmdir(dst,'s')); %#ok<NASGU>
    copyfile(fullfile(src,'params.mat'),fullfile(dst,'params.mat'));
    cfgdata=load(fullfile(src,'params.mat'),'cfg'); cfg=cfgdata.cfg;
    T=readtable(fullfile(src,'repetitions.csv')); T=T(1,:);
    idx=find(cfg.snr_grid==T.snr_db(1));
    name=sprintf('raw_c%d_s%d_%s.mat',T.channel(1),idx,T.case_id{1});
    copyfile(fullfile(src,name),fullfile(dst,name));
    writetable(T,fullfile(dst,'repetitions.csv'));
    p2_validate_common_predictions(dst);
    T.ber_predicted(1)=T.ber_predicted(1)+.1;
    writetable(T,fullfile(dst,'repetitions.csv'));
    caught=false;
    try, p2_validate_common_predictions(dst); catch e, caught=strcmp(e.identifier,'predictionraw:Mismatch'); end
    assert(caught,'Altered table prediction must be rejected.');
end
