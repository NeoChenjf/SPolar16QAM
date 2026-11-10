function run_p2_v2_pmf_report(pmf_dir)
% Compare empirical distributions among the three independent PMF source keys.
    p=load(fullfile(pmf_dir,'params.mat'),'cfg'); c=p.cfg;
    a=load(fullfile(pmf_dir,'frozen_exploratory_pmf.mat'),'pmf_asset'); e=a.pmf_asset.entries;
    rows=cell(0,7);
    for k=1:numel(e)
        j=find(c.snr_grid==e(k).snr_db);
        freq=zeros(16,size(e(k).pmf,2),c.num_channels);
        for ch=1:c.num_channels
            q=load(fullfile(pmf_dir,sprintf('raw_c%d_s%d_%s.mat',ch,j,e(k).case_id)),'artifact');
            counts=sum(q.artifact.counts,3); freq(:,:,ch)=counts/(c.N*c.num_frames);
        end
        for g=1:size(freq,2)
            tv=zeros(c.num_channels,1); maxerr=tv;
            for ch=1:c.num_channels
                d=freq(:,g,ch)-e(k).pmf(:,g); tv(ch)=sum(abs(d))/2; maxerr(ch)=max(abs(d));
            end
            rows(end+1,:)={e(k).case_id,e(k).snr_db,g,c.num_channels,c.N*c.num_frames*c.num_channels,mean(tv),max(maxerr)}; %#ok<AGROW>
        end
    end
    R=cell2table(rows,'VariableNames',{'case_id','snr_db','group','independent_source_keys','symbols_per_group','mean_tv_to_pooled','max_abs_deviation'});
    writetable(R,fullfile(pmf_dir,'pmf_between_source_variation.csv'));
end
