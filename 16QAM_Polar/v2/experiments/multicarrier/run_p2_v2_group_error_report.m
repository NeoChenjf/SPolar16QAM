function run_p2_v2_group_error_report(run_dir)
% Independent test group error counts and information-bit denominators.
    x=load(fullfile(run_dir,'params.mat'),'cfg'); cfg=x.cfg;
    T=readtable(fullfile(run_dir,'repetitions.csv')); rows=cell(0,8);
    for i=1:height(T)
        j=find(cfg.snr_grid==T.snr_db(i));
        q=load(fullfile(run_dir,sprintf('raw_c%d_s%d_%s.mat',T.channel(i),j,T.case_id{i})),'artifact');
        for g=1:numel(q.artifact.states)
            e=sum(q.artifact.stream_errors(g,:)); n=sum(q.artifact.info_counts(g,:));
            rows(end+1,:)={T.channel(i),T.snr_db(i),T.case_id{i},T.control{i},g,e,n,e/n}; %#ok<AGROW>
        end
    end
    R=cell2table(rows,'VariableNames',{'channel','snr_db','case_id','control','group','errors','info_bits','ber'});
    writetable(R,fullfile(run_dir,'group_error_counts.csv'));
end
