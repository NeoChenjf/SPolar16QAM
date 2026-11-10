function result = p2_build_future_draft(base)
%P2_BUILD_FUTURE_DRAFT Build A-F configuration proposals, never execute.
% Source templates and PMF/model assets remain unbound and unverified.
    required={'N','n_sc','cp','taps','source_seed','source_samples','quadrature_order', ...
        'mode','purpose','power_file','strategy_p','strategy_names','controls', ...
        'num_channels','num_frames','snr_grid','predict','diagnose'};
    assert(isstruct(base) && isscalar(base) && all(isfield(base,required)) && ...
        base.N==1024 && base.n_sc==64 && base.cp==16 && base.taps==16, ...
        'futuredraft:InvalidBase','Base must declare the proposed OFDM geometry.');
    ids={'A','B','C','D','E','F'};
    purposes={'pmf','model_calibration','test_seen','test_unseen','strategy_training','strategy_test'};
    splits={'pmf_train','model_train','seen_first_v2','unseen_first_v2','strategy_train','strategy_test_v2'};
    channels=[3 10 20 20 20 20]; frames=[80 40 40 40 40 40];
    controls={'shaped','random_s','donor_s'};
    [x,y,z]=ndgrid([.1 .3 .5]); combos=[x(:),y(:),z(:);.5 .3 .1];
    names=arrayfun(@(i) sprintf('combo_%02d',i),1:27,'UniformOutput',false);
    names=[names,{'bad_channel_energy_only'}];
    fields={'N','n_sc','cp','taps','source_seed','source_samples','quadrature_order', ...
        'snr_grid','strategy_p','strategy_names','controls','num_channels','num_frames','future_split','predict','diagnose'};
    cfgs=cell(1,6); jobs=cell(1,6); workload=cell(1,6);
    for k=1:6
        c=base; c.mode='draft_only'; c.power_file=''; c.purpose=purposes{k}; c.future_split=splits{k};
        c.num_channels=channels(k); c.num_frames=frames(k); c.snr_grid=[20 24 28];
        c.controls=controls; c.predict=any(k==[2 3 4]); c.diagnose=false;
        if k==1, c.strategy_p=[.3 .3 .3;.3 .1 .5]; c.strategy_names={'seen','unseen'};
        elseif k==4, c.strategy_p=[.3 .1 .5]; c.strategy_names={'unseen'};
        elseif k>=5, c.strategy_p=combos; c.strategy_names=names; c.controls={'shaped'}; c.snr_grid=24;
        else, c.strategy_p=[.3 .3 .3]; c.strategy_names={'seen'};
        end
        cases=p2_future_draft_cases(c.strategy_p,c.strategy_names,c.controls);
        j=struct('job_id',ids{k},'purpose',c.purpose,'case_manifest',cases);
        for f=1:numel(fields), j.(fields{f})=c.(fields{f}); end
        checked=p2_validate_future_job(j,c);
        w=struct('job_id',ids{k},'purpose',c.purpose,'split',c.future_split, ...
            'num_channels',c.num_channels,'num_snr',numel(c.snr_grid),'num_cases',numel(cases), ...
            'num_frames',c.num_frames,'case_manifest',cases);
        assert(checked.case_frames==prod([c.num_channels,numel(c.snr_grid),numel(cases),c.num_frames]));
        cfgs{k}=c; jobs{k}=j; workload{k}=w;
    end
    report=p2_preflight_future_workload([workload{:}],67120);
    result=struct('status','draft_only_not_authorized','configs',{cfgs},'jobs',{jobs},'workload',report);
end
