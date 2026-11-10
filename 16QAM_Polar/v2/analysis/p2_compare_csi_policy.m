function output = p2_compare_csi_policy(policy,test_dir,baseline_ids)
%P2_COMPARE_CSI_POLICY Exploratory paired evaluation of an existing CSI rule.
% Policy provenance must be frozen independently before any formal evaluation.
    assert(strcmp(policy.status,'exploratory_not_formal') && iscellstr(baseline_ids) && ...
        ~isempty(baseline_ids) && numel(unique(baseline_ids))==numel(baseline_ids), ...
        'csicompare:InvalidInput','Exploratory policy and unique baseline IDs required.');
    x=load(fullfile(test_dir,'params.mat'),'cfg'); c=x.cfg;
    x=load(fullfile(policy.training_dir,'params.mat'),'cfg'); train=x.cfg;
    assert(strcmp(c.purpose,'strategy_test') && c.seed~=policy.training_seed && ...
        isequal(c.snr_grid,policy.reference_snr_db) && c.n_sc==policy.n_sc && ...
        all(cellfun(@(f) isequal(c.(f),train.(f)),{'N','n_sc','cp','taps','source_seed','source_samples'})), ...
        'csicompare:InvalidRole','Test role, seed or physical configuration mismatch.');
    p2_verify_common_snapshot(policy.training_dir); p2_verify_common_snapshot(test_dir);
    p2_audit_common_pairing(policy.training_dir); p2_audit_common_pairing(test_dir);
    T=readtable(fullfile(test_dir,'repetitions.csv')); p2_validate_common_raw_metrics(test_dir,T);
    tc=load(fullfile(policy.training_dir,'cases.mat'),'cases'); qc=load(fullfile(test_dir,'cases.mat'),'cases');
    assert(isequal(tc.cases,qc.cases),'csicompare:CasesMismatch','Training and test candidates differ.');
    train_hash=cell(train.num_channels,1);
    for ch=1:train.num_channels
        a=load(fullfile(policy.training_dir,sprintf('raw_c%d_s1_%s.mat',ch,tc.cases(1).id)),'artifact');
        train_hash{ch}=a.artifact.channel_hash;
    end
    out=cell(c.num_channels*numel(baseline_ids),8); k=0;
    for ch=1:c.num_channels
        a=load(fullfile(test_dir,sprintf('raw_c%d_s1_%s.mat',ch,qc.cases(1).id)),'artifact');
        assert(~ismember(a.artifact.channel_hash,train_hash),'csicompare:ChannelOverlap','Test channel overlaps training.');
        choice=p2_apply_csi_policy(policy,a.artifact.h);
        assert(strcmp(choice.status,'selected'),'csicompare:NoSelection','Test feature has no trained feasible candidate.');
        selected=T(T.channel==ch & strcmp(T.case_id,choice.selected_case),:);
        assert(height(selected)==1,'csicompare:InvalidRows','Expected one selected result.');
        beta2=policy.selections{choice.bin}.beta2; beta4=policy.selections{choice.bin}.beta4;
        for b=1:numel(baseline_ids)
            base=T(T.channel==ch & strcmp(T.case_id,baseline_ids{b}),:);
            assert(height(base)==1 && selected.frames==base.frames && ...
                selected.noise_complex_time_power==base.noise_complex_time_power, ...
                'csicompare:Unpaired','Baseline missing or incompatible.');
            delta=beta2*(selected.rx_envelope_m2_l4-base.rx_envelope_m2_l4)+ ...
                beta4*(selected.rx_envelope_m4_l4-base.rx_envelope_m4_l4);
            k=k+1; out(k,:)={ch,choice.gain,choice.bin,choice.selected_case,baseline_ids{b}, ...
                selected.ber-base.ber,selected.goodput_cp-base.goodput_cp,delta};
        end
    end
    output=cell2table(out,'VariableNames',{'channel','gain','bin','selected_case','baseline', ...
        'delta_ber','delta_goodput','delta_dimensionless_proxy'});
end
