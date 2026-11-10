function p2_validate_common_predictions(run_dir)
%P2_VALIDATE_COMMON_PREDICTIONS Recompute saved GA predictions from saved refs.
% This checks internal consistency only, not prior or channel-model correctness.
    c=load(fullfile(run_dir,'params.mat'),'cfg'); cfg=c.cfg;
    assert(cfg.predict,'predictionraw:NoPrediction','Run did not enable prediction.');
    T=readtable(fullfile(run_dir,'repetitions.csv'));
    for i=1:height(T)
        s=find(cfg.snr_grid==T.snr_db(i));
        assert(isscalar(s),'predictionraw:InvalidSNR','SNR must be unique.');
        p=fullfile(run_dir,sprintf('raw_c%d_s%d_%s.mat',T.channel(i),s,T.case_id{i}));
        a=load(p,'artifact'); a=a.artifact;
        pred=zeros(1,numel(a.states)); weights=pred;
        for g=1:numel(a.states)
            sub=mod(a.layout.locations{g}-1,cfg.n_sc)+1;
            [~,map]=ismember(sub,unique(sub));
            leaf=a.refs{g}.ga_mean(map,:);
            result=p2_predict_ga(leaf,a.states{g},cfg.calibration);
            pred(g)=result.ber_raw; weights(g)=sum(a.states{g}.K);
        end
        assert(sum(weights)>0,'predictionraw:InvalidWeights','No information bits.');
        raw=sum(pred.*weights)/sum(weights);
        clipped=min(1-1e-12,max(1e-12,raw));
        z=cfg.calibration(1)+cfg.calibration(2)*log(clipped/(1-clipped));
        adjusted=1/(1+exp(-max(-700,min(700,z))));
        assert(isfinite(raw) && isfinite(adjusted) && ...
            abs(raw-T.ber_raw(i))<1e-12 && abs(adjusted-T.ber_predicted(i))<1e-12, ...
            'predictionraw:Mismatch','Saved predictions do not match saved refs and states.');
    end
end
