function p2_validate_common_pmf(asset_file)
%P2_VALIDATE_COMMON_PMF Recalculate exploratory PMF from its saved counts.
% Checks consistency, not authenticity or representativeness of the samples.
    x=load(asset_file,'pmf_asset'); a=x.pmf_asset; d=a.training_dir;
    p=load(fullfile(d,'params.mat'),'cfg'); c=p.cfg;
    q=load(fullfile(d,'cases.mat'),'cases'); cases=q.cases;
    assert(strcmp(a.status,'exploratory_short_run_not_formal') && ...
        strcmp(c.purpose,'power_calibration') && ~strcmp(c.mode,'formal') && ...
        isequaln(c,a.cfg) && isequaln(cases,a.cases), ...
        'pmfcheck:InvalidAsset','PMF asset and source metadata differ.');
    assert(numel(a.entries)==numel(c.snr_grid)*numel(cases), ...
        'pmfcheck:InvalidEntries','Incorrect PMF entry count.');
    p2_verify_common_snapshot(d);
    for j=1:numel(c.snr_grid)
        for k=1:numel(cases)
            ix=find(strcmp({a.entries.case_id},cases(k).id) & [a.entries.snr_db]==c.snr_grid(j));
            assert(isscalar(ix),'pmfcheck:InvalidEntries','Missing or duplicate PMF entry.');
            counts=[];
            for ch=1:c.num_channels
                f=fullfile(d,sprintf('raw_c%d_s%d_%s.mat',ch,j,cases(k).id));
                r=load(f,'artifact'); r=r.artifact;
                assert(all(r.scale==1) && size(r.counts,1)==16 && size(r.counts,3)==c.num_frames && ...
                    all(isfinite(r.counts(:))) && all(r.counts(:)>=0) && ...
                    all(r.counts(:)==fix(r.counts(:))), ...
                    'pmfcheck:InvalidCounts','Invalid raw counts or scale.');
                z=sum(r.counts,3);
                assert(all(sum(z,1)==c.N*c.num_frames),'pmfcheck:InvalidCounts','Unexpected count total.');
                if isempty(counts), counts=z; else, counts=counts+z; end
            end
            expected=bsxfun(@rdivide,counts,sum(counts,1)); e=a.entries(ix);
            assert(e.frames==c.num_channels*c.num_frames && isequal(size(e.pmf),size(expected)) && ...
                all(isfinite(e.pmf(:))) && all(abs(e.pmf(:)-expected(:))<1e-12), ...
                'pmfcheck:Mismatch','PMF does not match the saved counts.');
        end
    end
end
