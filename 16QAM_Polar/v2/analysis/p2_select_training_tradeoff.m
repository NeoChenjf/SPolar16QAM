function result = p2_select_training_tradeoff(T, max_ber, min_goodput, beta2, beta4)
%P2_SELECT_TRAINING_TRADEOFF Exploratory finite-candidate training selection.
% Each input row is a paired channel/case result at one seed and SNR.
% J is a dimensionless candidate proxy, not calibrated DC or efficiency.
    required={'purpose','seed','channel','snr_db','case_id','control','frames', ...
        'ber','goodput_cp','rx_envelope_m2_l4','rx_envelope_m4_l4'};
    assert(istable(T) && ~isempty(T) && all(ismember(required,T.Properties.VariableNames)), ...
        'tradeoff:InvalidTable','Required training columns are missing.');
    assert(all(ismember(T.purpose,{'model_calibration','strategy_training'})) && numel(unique(T.purpose))==1 && all(strcmp(T.control,'shaped')), ...
        'tradeoff:InvalidRole','Only shaped model_calibration rows are admissible.');
    assert(numel(unique(T.seed))==1 && numel(unique(T.snr_db))==1, ...
        'tradeoff:MixedEnvironment','Select one seed and reference SNR at a time.');
    v=[max_ber,min_goodput,beta2,beta4];
    assert(isnumeric(v) && isreal(v) && numel(v)==4 && all(isfinite(v)) && ...
        max_ber>=0 && max_ber<=1 && min_goodput>=0 && min_goodput<=1 && ...
        beta2>=0 && beta4>=0 && beta2+beta4>0, ...
        'tradeoff:InvalidThreshold','Invalid thresholds or proxy coefficients.');
    numerical=[T.ber,T.goodput_cp,T.rx_envelope_m2_l4,T.rx_envelope_m4_l4,T.frames];
    assert(all(isfinite(numerical(:))) && all(T.ber>=0 & T.ber<=1) && ...
        all(T.goodput_cp>=0 & T.goodput_cp<=1) && ...
        all(T.rx_envelope_m2_l4>=0 & T.rx_envelope_m4_l4>=0) && ...
        all(T.frames>0 & T.frames==fix(T.frames)), ...
        'tradeoff:InvalidMetrics','Training metrics must be finite and valid.');
    ids=sort(unique(T.case_id)); channels=sort(unique(T.channel));
    rows=cell(numel(ids),5); expected_frames=[];
    for k=1:numel(ids)
        R=T(strcmp(T.case_id,ids{k}),:); [present,ix]=ismember(channels,R.channel);
        assert(height(R)==numel(channels) && all(present) && numel(unique(R.channel))==height(R), ...
            'tradeoff:Unpaired','Every candidate must have one row per common channel.');
        R=R(ix,:);
        if isempty(expected_frames), expected_frames=R.frames; end
        assert(isequal(expected_frames,R.frames),'tradeoff:Unpaired','Paired frame counts differ.');
        J=beta2*R.rx_envelope_m2_l4+beta4*R.rx_envelope_m4_l4;
        assert(all(isfinite(J)),'tradeoff:InvalidMetrics','Energy proxy overflow.');
        rows(k,:)={ids{k},mean(R.ber),mean(R.goodput_cp),mean(J),height(R)};
    end
    C=cell2table(rows,'VariableNames',{'case_id','mean_ber','mean_goodput','mean_proxy','channels'});
    C.feasible=C.mean_ber<=max_ber & C.mean_goodput>=min_goodput;
    C.pareto=false(height(C),1);
    for k=1:height(C)
        dominates=C.feasible & C.mean_goodput>=C.mean_goodput(k) & C.mean_proxy>=C.mean_proxy(k) & ...
            (C.mean_goodput>C.mean_goodput(k) | C.mean_proxy>C.mean_proxy(k));
        C.pareto(k)=C.feasible(k) && ~any(dominates);
    end
    result=struct('candidates',C,'selected_case','','status','no_feasible', ...
        'energy_semantics','dimensionless_proxy_not_dc','max_ber',max_ber, ...
        'min_goodput',min_goodput,'beta2',beta2,'beta4',beta4, ...
        'training_seed',T.seed(1),'reference_snr_db',T.snr_db(1));
    idx=find(C.feasible);
    if ~isempty(idx)
        [~,rank]=sortrows([-C.mean_proxy(idx),-C.mean_goodput(idx),C.mean_ber(idx)],[1,2,3]);
        result.selected_case=C.case_id{idx(rank(1))}; result.status='selected';
    end
end
