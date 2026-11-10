function asset_path = p2_common_freeze_pmf(training_dir)
%P2_COMMON_FREEZE_PMF Freeze exploratory independent-source PMFs, not a gate.
    p=load(fullfile(training_dir,'params.mat'),'cfg'); cfg=p.cfg;
    assert(strcmp(cfg.purpose,'power_calibration') && ~strcmp(cfg.mode,'formal'), ...
        'commonpmf:InvalidRole','Only short, independent power_calibration runs can supply this prototype.');
    loaded=load(fullfile(training_dir,'cases.mat'),'cases'); cases=loaded.cases;
    entries=struct('case_id',{},'snr_db',{},'pmf',{},'frames',{});
    for j=1:numel(cfg.snr_grid)
        for k=1:numel(cases)
            counts=[]; frames=0;
            for ir=1:cfg.num_channels
                filename=fullfile(training_dir,sprintf('raw_c%d_s%d_%s.mat',ir,j,cases(k).id));
                assert(isfile(filename),'commonpmf:MissingRaw','Missing required training raw.');
                raw=load(filename,'artifact'); a=raw.artifact;
                assert(all(a.scale==1) && size(a.counts,1)==16 && size(a.counts,3)==cfg.num_frames, ...
                    'commonpmf:InvalidRaw','Unexpected training counts or amplitude.');
                current=sum(a.counts,3);
                assert(all(sum(current,1)==cfg.N*cfg.num_frames), ...
                    'commonpmf:InvalidRaw','PMF counts do not match frame resources.');
                if isempty(counts), counts=current; else, counts=counts+current; end
                frames=frames+cfg.num_frames;
            end
            entry=struct('case_id',cases(k).id,'snr_db',cfg.snr_grid(j), ...
                'pmf',bsxfun(@rdivide,counts,sum(counts,1)),'frames',frames);
            entries(end+1)=entry; %#ok<AGROW>
        end
    end
    pmf_asset=struct('entries',entries,'cases',cases,'cfg',cfg,'training_dir',training_dir, ...
        'status','exploratory_short_run_not_formal');
    asset_path=fullfile(training_dir,'frozen_exploratory_pmf.mat');
    assert(~isfile(asset_path),'commonpmf:Exists','Refusing to overwrite PMF asset.');
    save(asset_path,'pmf_asset');
end
