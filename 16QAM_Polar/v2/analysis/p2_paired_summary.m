function summary = p2_paired_summary(T, n_boot)
%P2_PAIRED_SUMMARY Within-purpose/seed/channel pairing, whole-channel bootstrap.
    if nargin<2, n_boot=2000; end
    original_rng=rng; cleanup=onCleanup(@() rng(original_rng)); %#ok<NASGU>
    columns={'purpose','seed','snr_db'}; groups=unique(T(:,columns),'rows');
    output=cell(0,10); metrics={'ber','bler','goodput_cp','rx_rf'};
    for i=1:height(groups)
        R=T(strcmp(T.purpose,groups.purpose{i}) & T.seed==groups.seed(i) & T.snr_db==groups.snr_db(i),:);
        ids=unique(R.case_id);
        for j=1:numel(ids)
            reference=regexprep(ids{j},'_(random_s|donor_s|native|same_k_i)$','_shaped');
            if strcmp(reference,ids{j}), continue; end
            A=R(strcmp(R.case_id,ids{j}),:); B=R(strcmp(R.case_id,reference),:);
            assert(~isempty(B),'Missing paired shaped reference.');
            assert(numel(unique(A.channel))==height(A) && numel(unique(B.channel))==height(B));
            [found,order]=ismember(A.channel,B.channel);
            assert(all(found) && height(A)==height(B),'Incomplete paired channel set.'); B=B(order,:);
            assert(isequal(A.frames,B.frames),'Paired frame budgets differ.');
            for k=1:numel(metrics)
                metric=metrics{k}; delta=A.(metric)-B.(metric); point=mean(delta); lo=nan; hi=nan;
                if numel(delta)>=2 && all(isfinite(delta))
                    rng(19801+i+j+k,'twister'); samples=zeros(n_boot,1);
                    for n=1:n_boot, samples(n)=mean(delta(randi(numel(delta),numel(delta),1))); end
                    interval=prctile(samples,[2.5,97.5]); lo=interval(1); hi=interval(2);
                end
                output(end+1,:)={groups.purpose{i},groups.seed(i),groups.snr_db(i),ids{j}, ...
                    reference,metric,numel(delta),point,lo,hi}; %#ok<AGROW>
            end
        end
    end
    summary=cell2table(output,'VariableNames',{'purpose','seed','snr_db','case_id','reference', ...
        'metric','channels','paired_difference','lower95','upper95'});
end
