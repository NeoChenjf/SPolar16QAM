function output = p2_compare_csi_policy_asset(policy,asset_file,test_dir,baseline_ids)
%P2_COMPARE_CSI_POLICY_ASSET Reconstruct policy before exploratory test audit.
% A separately trusted pre-test policy hash is still required for a blind test.
    x=load(asset_file,'asset'); a=x.asset;
    assert(strcmp(a.status,'exploratory_not_formal') && ...
        strcmp(policy.training_dir,a.training_dir),'csibound:TrainingMismatch', ...
        'Policy and frozen training asset must share their source directory.');
    f=a.selection;
    rebuilt=p2_train_csi_policy(a.training_dir,f.max_ber,f.min_goodput,f.beta2,f.beta4);
    assert(isequaln(rebuilt,policy),'csibound:PolicyMismatch', ...
        'Policy differs from reconstruction using frozen training settings.');
    p2_evaluate_strategy_asset(asset_file,test_dir,baseline_ids);
    output=p2_compare_csi_policy(policy,test_dir,baseline_ids);
end
