function run_p2_v2_strategy_test(training_dir,policy_file)
% Blind F test: 19 full channels and one split channel, 22399 case-frames.
% One energy-only comparison has 39 frames to include the earlier smoke in cap.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    a=load(fullfile(training_dir,'params.mat'),'cfg'); c=a.cfg;
    q=load(policy_file,'policy'); policy=q.policy;
    c.purpose='strategy_test'; c.seed=8902; c.seed_roles.strategy_test=8902;
    c.future_split='strategy_test_v2'; c.num_channels=19; c.num_frames=40; c.realization_offset=0;
    f1=run_p2_v2_strategy_batch(c);
    assert(now<datenum(2026,11,7,15,40,0),'Analysis reserve reached; retain completed test data.');
    all_p=c.strategy_p; all_names=c.strategy_names;
    c.num_channels=1; c.realization_offset=19; c.strategy_p=all_p(1:27,:); c.strategy_names=all_names(1:27);
    f2=run_p2_v2_strategy_batch(c);
    c.num_frames=39; c.strategy_p=all_p(28,:); c.strategy_names=all_names(28);
    f3=run_p2_v2_strategy_batch(c);
    run_p2_v2_strategy_report(training_dir,policy,f1,f2,f3);
    fprintf('E2_TEST=%s\nE2_TEST_LAST=%s\nE2_TEST_ENERGY=%s\n',f1,f2,f3);
end
