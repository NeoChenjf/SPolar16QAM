function output = p2_compare_rectifier_csi(policy,test_dir,baseline_ids)
%P2_COMPARE_RECTIFIER_CSI Paired exploratory test using explicit current proxy.
% A separately frozen policy and genuinely blind test are required for inference.
    assert(strcmp(policy.energy_semantics,'current_proxy_not_dc'), ...
        'rectcompare:InvalidPolicy','Current-proxy CSI policy required.');
    populated=find(cellfun(@(x) isfield(x,'volts_per_unit'),policy.selections));
    assert(~isempty(populated),'rectcompare:NoTraining','No trained physical model.');
    ref=policy.selections{populated(1)}; fields={'volts_per_unit','resistance_ohm','k2','k4','valid_power_w'};
    converted=policy;
    for k=populated
        x=policy.selections{k};
        assert(all(cellfun(@(f) isequal(x.(f),ref.(f)),fields)), ...
            'rectcompare:InconsistentModels','All trained bins must use the same model.');
        converted.selections{k}.beta2=ref.k2*ref.volts_per_unit^2/2;
        converted.selections{k}.beta4=ref.k4*3*ref.volts_per_unit^4/8;
    end
    output=p2_compare_csi_policy(converted,test_dir,baseline_ids);
    P=p2_rectifier_metrics_from_run(test_dir,ref.volts_per_unit,ref.resistance_ohm, ...
        ref.k2,ref.k4,ref.valid_power_w);
    n=height(output); status=cell(n,1); direct=nan(n,1);
    for i=1:n
        a=P(P.channel==output.channel(i) & strcmp(P.case_id,output.selected_case{i}),:);
        b=P(P.channel==output.channel(i) & strcmp(P.case_id,output.baseline{i}),:);
        assert(height(a)==1 && height(b)==1,'rectcompare:MissingRow','Missing paired proxy.');
        if strcmp(a.model_status{1},'within_supplied_range') && strcmp(b.model_status{1},'within_supplied_range')
            direct(i)=a.current_proxy_a-b.current_proxy_a;
            assert(abs(direct(i)-output.delta_dimensionless_proxy(i))<1e-12, ...
                'rectcompare:Mismatch','Direct and weighted proxy differences differ.');
            status{i}='within_supplied_range';
        else
            status{i}='out_of_range';
        end
    end
    output.delta_dimensionless_proxy=[];
    output.delta_current_proxy_a=direct; output.model_status=status;
end
