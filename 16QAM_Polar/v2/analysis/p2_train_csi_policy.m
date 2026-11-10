function policy = p2_train_csi_policy(run_dir,max_ber,min_goodput,beta2,beta4)
%P2_TRAIN_CSI_POLICY Train exploratory two-bin channel-gain policy.
% Not a formal/validated adaptive strategy; no test outcomes are consulted.
    x=load(fullfile(run_dir,'params.mat'),'cfg'); c=x.cfg;
    assert(strcmp(c.purpose,'strategy_training') && ~strcmp(c.mode,'formal') && ...
        numel(c.snr_grid)==1 && c.num_channels>=2, ...
        'csipolicy:InvalidTraining','A short strategy-training run at one SNR is required.');
    p2_verify_common_snapshot(run_dir); p2_audit_common_pairing(run_dir);
    T=readtable(fullfile(run_dir,'repetitions.csv'));
    p2_validate_common_raw_metrics(run_dir,T);
    T=T(strcmp(T.control,'shaped') & startsWith(T.case_id,'combo_'),:);
    assert(~isempty(T),'csipolicy:NoCandidates','No grouped-p candidate rows.');
    q=load(fullfile(run_dir,'cases.mat'),'cases'); gains=zeros(c.num_channels,1);
    for ch=1:c.num_channels
        p=fullfile(run_dir,sprintf('raw_c%d_s1_%s.mat',ch,q.cases(1).id));
        x=load(p,'artifact'); h=x.artifact.h;
        gains(ch)=mean(abs(fft(h,c.n_sc)).^2);
    end
    assert(all(isfinite(gains)) && all(gains>=0),'csipolicy:InvalidFeature','Invalid CSI gain.');
    pivot=median(gains); bins={find(gains<=pivot),find(gains>pivot)};
    selections=cell(1,2);
    for b=1:2
        if isempty(bins{b})
            selections{b}=struct('status','no_training_coverage','selected_case','');
        else
            R=T(ismember(T.channel,bins{b}),:);
            selections{b}=p2_select_training_tradeoff(R,max_ber,min_goodput,beta2,beta4);
        end
    end
    policy=struct('status','exploratory_not_formal','feature','mean_fft_channel_gain', ...
        'pivot',pivot,'n_sc',c.n_sc,'training_dir',run_dir,'training_seed',c.seed, ...
        'reference_snr_db',c.snr_grid(1),'training_gains',gains,'bins',{bins}, ...
        'selections',{selections},'energy_semantics','dimensionless_proxy_not_dc');
end
