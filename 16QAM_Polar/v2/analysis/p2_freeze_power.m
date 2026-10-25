function artifact_path = p2_freeze_power(calibration_dirs, out_dir)
%P2_FREEZE_POWER Independent calibration only; shared group targets from shaped.
% Short-run artifacts remain exploratory. Formal validation must be independent.
    assert(iscell(calibration_dirs) && ~isempty(calibration_dirs));
    all_records=struct(); cases=[]; seed_list=[]; power_contract=struct();
    for d=1:numel(calibration_dirs)
        params=load(fullfile(calibration_dirs{d},'params.mat'),'cfg'); cfg=params.cfg;
        assert(strcmp(cfg.purpose,'power_calibration'));
        assert(isempty(cfg.power_file),'Raw power calibration must be unscaled.');
        fields={'N','n_sc','cp','taps','source_seed','source_samples'};
        for k=1:numel(fields)
            if d==1, power_contract.(fields{k})=cfg.(fields{k});
            else, assert(isequal(power_contract.(fields{k}),cfg.(fields{k})), 'Calibration contracts differ.'); end
        end
        assert(~ismember(cfg.seed,seed_list),'Duplicate calibration seed.'); seed_list(end+1)=cfg.seed; %#ok<AGROW>
        loaded=load(fullfile(calibration_dirs{d},'cases.mat'),'cases');
        if isempty(cases), cases=loaded.cases; else, assert(isequal(cases,loaded.cases)); end
        files=dir(fullfile(calibration_dirs{d},'raw_*.mat'));
        for f=1:numel(files)
            path=fullfile(files(f).folder,files(f).name); raw=load(path,'artifact'); a=raw.artifact;
            for c=1:numel(cases)
                if endsWith(files(f).name,[cases(c).id '.mat'])
                    key=cases(c).id; rec=[a.records{:}];
                    value=struct('total',[rec.tx]','group',vertcat(rec.group_tx), ...
                        'counts',sum(a.counts,3));
                    if isfield(all_records,key)
                        prev=all_records.(key); value.total=[prev.total;value.total];
                        value.group=[prev.group;value.group]; value.counts=value.counts+prev.counts;
                    end
                    all_records.(key)=value;
                end
            end
        end
    end
    power=struct('case_id',{},'scale',{},'target_group_power',{},'pmf',{}, ...
        'frozen',{},'calibration_seeds',{},'raw_total_power',{});
    for c=1:numel(cases)
        key=cases(c).id; assert(isfield(all_records,key),'Missing calibration case.');
        shaped=regexprep(key,'_(same_k_i|native|random_s|donor_s)$','_shaped');
        ref=all_records.(shaped); obs=all_records.(key);
        target=mean(ref.group,1)/mean(ref.total);
        if strcmp(cases(c).kind,'shaped')
            scale=ones(1,numel(cases(c).p))/sqrt(mean(obs.total));
        else
            scale=sqrt(target./mean(obs.group,1));
        end
        assert(all(isfinite(scale)&scale>0));
        pmf=bsxfun(@rdivide,obs.counts,sum(obs.counts,1));
        power(c)=struct('case_id',key,'scale',scale,'target_group_power',target, ...
            'pmf',pmf,'frozen',true,'calibration_seeds',seed_list, ...
            'raw_total_power',mean(obs.total));
    end
    if ~isfolder(out_dir), mkdir(out_dir); end
    artifact_path=fullfile(out_dir,'frozen_power.mat');
    assert(~isfile(artifact_path),'Frozen power cannot be overwritten.');
    save(artifact_path,'power','calibration_dirs','cases','power_contract');
end
