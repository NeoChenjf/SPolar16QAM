function result = p2_select_rectifier_tradeoff(run_dir,max_ber,min_goodput,volts_per_unit,resistance_ohm,k2,k4,valid_power_w,training_channels)
%P2_SELECT_RECTIFIER_TRADEOFF Exploratory training selection using current proxy.
% No measured DC claim; test data are not accepted as training.
    p=load(fullfile(run_dir,'params.mat'),'cfg'); c=p.cfg;
    assert(strcmp(c.purpose,'strategy_training') && ~strcmp(c.mode,'formal') && numel(c.snr_grid)==1, ...
        'rectselect:InvalidRole','Only short strategy training at one SNR is supported.');
    assert(isnumeric(max_ber) && isscalar(max_ber) && isfinite(max_ber) && max_ber>=0 && max_ber<=1 && ...
        isnumeric(min_goodput) && isscalar(min_goodput) && isfinite(min_goodput) && min_goodput>=0 && min_goodput<=1, ...
        'rectselect:InvalidThreshold','Thresholds must be finite within [0,1].');
    P=p2_rectifier_metrics_from_run(run_dir,volts_per_unit,resistance_ohm,k2,k4,valid_power_w);
    T=readtable(fullfile(run_dir,'repetitions.csv'));
    keys={'purpose','seed','channel','snr_db','case_id','frames'};
    assert(isequal(T(:,keys),P(:,keys)),'rectselect:RowsMismatch','Proxy and communication rows differ.');
    if nargin<9, training_channels=(1:c.num_channels)'; end
    assert(isnumeric(training_channels) && isvector(training_channels) && ~isempty(training_channels) && ...
        all(isfinite(training_channels)) && all(training_channels==fix(training_channels)) && ...
        all(training_channels>=1 & training_channels<=c.num_channels) && ...
        numel(unique(training_channels))==numel(training_channels), ...
        'rectselect:InvalidChannels','Training channel subset is invalid.');
    use=strcmp(T.control,'shaped') & startsWith(T.case_id,'combo_') & ismember(T.channel,training_channels);
    T=T(use,:); P=P(use,:);
    ids=sort(unique(T.case_id)); channels=sort(unique(T.channel));
    assert(~isempty(ids) && ~isempty(channels),'rectselect:MissingCandidates','No candidate rows.');
    rows=cell(numel(ids),7);
    for k=1:numel(ids)
        ix=strcmp(T.case_id,ids{k}); R=T(ix,:); Q=P(ix,:);
        assert(height(R)==numel(channels) && isequal(sort(R.channel),channels) && ...
            numel(unique(R.channel))==height(R),'rectselect:Unpaired','Each candidate must cover each channel once.');
        within=all(strcmp(Q.model_status,'within_supplied_range'));
        J=nan; if within, J=mean(Q.current_proxy_a); end
        meanber=mean(R.ber); meanrate=mean(R.goodput_cp);
        valid=within && isfinite(J) && meanber<=max_ber && meanrate>=min_goodput;
        rows(k,:)={ids{k},height(R),meanber,meanrate,J,within,valid};
    end
    C=cell2table(rows,'VariableNames',{'case_id','channels','mean_ber','mean_goodput', ...
        'mean_current_proxy_a','within_supplied_range','feasible'});
    result=struct('status','no_feasible','selected_case','','candidates',C, ...
        'scope','exploratory_current_proxy_not_dc','valid_power_w',valid_power_w, ...
        'max_ber',max_ber,'min_goodput',min_goodput,'volts_per_unit',volts_per_unit, ...
        'resistance_ohm',resistance_ohm,'k2',k2,'k4',k4,'training_seed',c.seed, ...
        'training_channels',sort(training_channels(:))); 
    ix=find(C.feasible);
    if ~isempty(ix)
        [~,rank]=sortrows([-C.mean_current_proxy_a(ix),-C.mean_goodput(ix),C.mean_ber(ix)],[1,2,3]);
        result.selected_case=C.case_id{ix(rank(1))}; result.status='selected';
    end
end

