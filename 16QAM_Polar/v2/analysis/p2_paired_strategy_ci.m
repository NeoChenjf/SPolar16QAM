function intervals = p2_paired_strategy_ci(asset_file, test_dir, baseline_ids, n_boot, seed)
%P2_PAIRED_STRATEGY_CI Descriptive intervals after frozen paired audit.
% Resamples independent channel-level deltas; never an acceptance decision.
    p2_evaluate_strategy_asset(asset_file,test_dir,baseline_ids);
    a=load(asset_file,'asset'); f=a.asset.selection;
    T=readtable(fullfile(test_dir,'repetitions.csv'));
    T=T(strcmp(T.control,'shaped'),:);
    chosen=T(strcmp(T.case_id,f.selected_case),:);
    [channels,ix]=sort(chosen.channel); chosen=chosen(ix,:);
    rows=cell(numel(baseline_ids)*3,7); k=0;
    for j=1:numel(baseline_ids)
        base=T(strcmp(T.case_id,baseline_ids{j}),:);
        [present,ix]=ismember(channels,base.channel);
        assert(all(present) && height(base)==numel(channels),'pairedci:Unpaired','Channel pairing changed.');
        base=base(ix,:);
        d={chosen.ber-base.ber,chosen.goodput_cp-base.goodput_cp, ...
           f.beta2*(chosen.rx_envelope_m2_l4-base.rx_envelope_m2_l4)+ ...
           f.beta4*(chosen.rx_envelope_m4_l4-base.rx_envelope_m4_l4)};
        names={'ber','goodput_cp','dimensionless_proxy'};
        for m=1:3
            x=p2_paired_channel_bootstrap(d{m},n_boot,seed); k=k+1;
            rows(k,:)={baseline_ids{j},names{m},x.channels,x.mean,x.lower95,x.upper95,x.status};
        end
    end
    intervals=cell2table(rows,'VariableNames',{'baseline','metric','channels','mean_delta','lower95','upper95','status'});
end
