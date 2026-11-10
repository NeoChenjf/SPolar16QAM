function test_p2_compare_csi_policy()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    d=fullfile(root,'results','20261106_170217_p2_common_env_pilot_strategy_training_b657112d');
    t=fullfile(root,'results','20261106_170258_p2_common_env_pilot_strategy_test_7d9fec20');
    p=p2_train_csi_policy(d,.2,.2,1,1); ids={'combo_27_shaped','combo_06_shaped','combo_22_shaped','bad_channel_energy_only_shaped'};
    R=p2_compare_csi_policy(p,t,ids); assert(height(R)==8 && numel(unique(R.channel))==2);
    assert(all(strcmp(R.selected_case,'combo_01_shaped')));
    caught=false; try, p2_compare_csi_policy(p,d,ids); catch e, caught=strcmp(e.identifier,'csicompare:InvalidRole'); end
    assert(caught,'Training directory must not be accepted as test.');
end
