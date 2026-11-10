function summary = p2_summarize_csi_pairs(T,n_boot,seed)
%P2_SUMMARIZE_CSI_PAIRS Summarize paired channel deltas, descriptively only.
% Caller must establish provenance and channel independence before calling.
    required={'channel','gain','bin','selected_case','baseline','delta_ber', ...
        'delta_goodput','delta_dimensionless_proxy'};
    assert(istable(T) && ~isempty(T) && all(ismember(required,T.Properties.VariableNames)), ...
        'csisummary:InvalidTable','Required paired comparison columns are missing.');
    channels=sort(unique(T.channel)); baselines=sort(unique(T.baseline));
    assert(height(T)==numel(channels)*numel(baselines), ...
        'csisummary:Incomplete','Every baseline must have one row per channel.');
    for i=1:numel(channels)
        R=T(T.channel==channels(i),:);
        assert(height(R)==numel(baselines) && numel(unique(R.baseline))==numel(baselines) && ...
            numel(unique(R.selected_case))==1 && numel(unique(R.gain))==1 && numel(unique(R.bin))==1, ...
            'csisummary:Unpaired','Channel rows or selected strategy do not match.');
    end
    fields={'delta_ber','delta_goodput','delta_dimensionless_proxy'};
    rows=cell(numel(baselines)*numel(fields),7); k=0;
    for b=1:numel(baselines)
        R=T(strcmp(T.baseline,baselines{b}),:); [found,ix]=ismember(channels,R.channel);
        assert(all(found),'csisummary:Incomplete','Baseline misses a channel.'); R=R(ix,:);
        for j=1:numel(fields)
            x=p2_paired_channel_bootstrap(R.(fields{j}),n_boot,seed); k=k+1;
            rows(k,:)={baselines{b},fields{j},x.channels,x.mean,x.lower95,x.upper95,x.status};
        end
    end
    summary=cell2table(rows,'VariableNames',{'baseline','metric','channels','mean_delta','lower95','upper95','status'});
end
