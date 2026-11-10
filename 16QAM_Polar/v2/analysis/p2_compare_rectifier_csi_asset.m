function output = p2_compare_rectifier_csi_asset(policy,training_asset,test_dir,baseline_ids)
%P2_COMPARE_RECTIFIER_CSI_ASSET Rebuild physical policy before paired test.
% This is a retrospective consistency check, not proof of pre-test freezing.
    a=load(training_asset,'asset'); a=a.asset;
    assert(strcmp(a.status,'exploratory_not_formal') && strcmp(policy.training_dir,a.training_dir), ...
        'rectbound:TrainingMismatch','Policy and training asset differ.');
    j=find(cellfun(@(x) isfield(x,'volts_per_unit'),policy.selections),1);
    assert(~isempty(j),'rectbound:NoTraining','No trained physical bin.');
    v=policy.selections{j};
    rebuilt=p2_train_rectifier_csi_policy(a.training_dir,v.max_ber,v.min_goodput, ...
        v.volts_per_unit,v.resistance_ohm,v.k2,v.k4,v.valid_power_w);
    assert(isequaln(rebuilt,policy),'rectbound:PolicyMismatch','Policy differs from trained reconstruction.');
    p2_evaluate_strategy_asset(training_asset,test_dir,baseline_ids);
    output=p2_compare_rectifier_csi(policy,test_dir,baseline_ids);
end
