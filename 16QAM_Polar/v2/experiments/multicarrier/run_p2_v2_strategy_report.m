function run_p2_v2_strategy_report(training_dir,policy,f1,f2,f3)
% Independent-channel paired comparison; assumed nonlinear proxy, not DC.
    T=readtable(fullfile(f1,'repetitions.csv'));
    V=readtable(fullfile(f2,'repetitions.csv')); V.channel(:)=20; T=[T;V];
    V=readtable(fullfile(f3,'repetitions.csv')); V.channel(:)=20; T=[T;V];
    assert(height(T)==20*28 && numel(unique(T.channel))==20);
    gains=zeros(20,1);
    for ch=1:20
        if ch<=19, dirpath=f1; localch=ch; else, dirpath=f2; localch=1; end
        x=load(fullfile(dirpath,sprintf('raw_c%d_s1_combo_01_shaped.mat',localch)),'artifact');
        gains(ch)=mean(abs(fft(x.artifact.h,64)).^2);
    end
    levels=[-30,-25,-20];
    for k=1:3
        scale=sqrt(2*policy.resistance*10^((levels(k)-30)/10)/policy.reference_m2);
        T.(sprintf('proxy_m%d',-levels(k)))=policy.k2*scale^2*T.rx_envelope_m2_l4/2 + ...
            policy.k4*3*scale^4*T.rx_envelope_m4_l4/8;
    end
    T.qualified=T.ber<=policy.max_ber & T.goodput_cp>=policy.min_goodput;
    x=load(fullfile(training_dir,'params.mat'),'cfg'); combos=x.cfg.strategy_p;
    patterns=[.5 .3 .1;.1 .3 .5;.5 .5 .5]; ids=cell(1,4);
    for k=1:3
        ix=find(all(bsxfun(@eq,combos(1:27,:),patterns(k,:)),2)); ids{k}=sprintf('combo_%02d_shaped',ix);
    end
    ids{4}='bad_channel_energy_only_shaped'; labels={'good_channel_information','good_channel_energy','uniform','bad_channel_energy_only'};
    selected=cell(20,1); bins=ones(20,1)+(gains>policy.pivot);
    for ch=1:20, selected{ch}=policy.selections{bins(ch)}.selected_case; end
    rows=cell(20,1);
    for ch=1:20
        if ~isempty(selected{ch})
            ix=find(T.channel==ch & strcmp(T.case_id,selected{ch})); assert(isscalar(ix)); rows{ch}=T(ix,:);
        end
    end
    rows=rows(~cellfun(@isempty,rows)); S=[]; if ~isempty(rows), S=vertcat(rows{:}); end
    choice=table((1:20)',gains,bins,selected,'VariableNames',{'channel','channel_gain','bin','selected_case'});
    writetable(choice,fullfile(f1,'test_choices.csv')); writetable(T,fullfile(f1,'test_all_candidates.csv'));
    n_selected=numel(rows); n_qualified=0; if ~isempty(S), n_qualified=sum(S.qualified); end
    coverage=table(20,n_selected,20-n_selected,n_selected/20,n_qualified/20,'VariableNames', ...
        {'total_channels','selected_channels','no_selection_channels','selection_coverage','overall_success_rate'});
    writetable(coverage,fullfile(f1,'test_policy_coverage.csv'));
    if ~isempty(S), writetable(S,fullfile(f1,'test_selected.csv')); end
    result=cell(0,12);
    for k=1:4
        B=T(strcmp(T.case_id,ids{k}),:); [~,order]=sort(B.channel); B=B(order,:); assert(height(B)==20);
        if isempty(S), continue; end
        [~,order]=sort(S.channel); Q=S(order,:); [ok,loc]=ismember(Q.channel,B.channel); assert(all(ok)); B=B(loc,:);
        dg=Q.goodput_cp-B.goodput_cp; gp=p2_paired_channel_bootstrap(dg,2000,7300+k);
        for j=1:3
            field=sprintf('proxy_m%d',-levels(j)); de=Q.(field)-B.(field);
            ep=p2_paired_channel_bootstrap(de,2000,7400+10*k+j);
            result(end+1,:)={labels{k},levels(j),height(Q),mean(Q.qualified),mean(B.qualified), ...
                gp.mean,gp.lower95,gp.upper95,ep.mean,ep.lower95,ep.upper95,mean(Q.frames~=B.frames)}; %#ok<AGROW>
        end
    end
    R=cell2table(result,'VariableNames',{'baseline','assumed_reference_dbm','paired_channels','selected_success_rate_conditional','baseline_success_rate_on_selected_channels', ...
        'goodput_delta','goodput_ci_low','goodput_ci_high','proxy_delta','proxy_ci_low','proxy_ci_high','unequal_frame_fraction'});
    writetable(R,fullfile(f1,'paired_strategy_comparison.csv'));
    summary=groupsummary(T,'case_id','mean',{'ber','goodput_cp','rx_rf','proxy_m30','proxy_m25','proxy_m20'});
    writetable(summary,fullfile(f1,'test_candidate_summary.csv'));
    f=figure('Visible','off','Position',[100 100 1000 420]);
    subplot(1,2,1); scatter(summary.mean_goodput_cp,summary.mean_rx_rf,40,'filled'); xlabel('Goodput including CP'); ylabel('Noiseless received RF'); grid on;
    subplot(1,2,2); scatter(summary.mean_goodput_cp,summary.mean_proxy_m25,40,'filled'); xlabel('Goodput including CP'); ylabel('Current proxy (A)'); title('Assumed -25 dBm reference'); grid on;
    saveas(f,fullfile(f1,'test_tradeoffs.png')); print(f,fullfile(f1,'test_tradeoffs.pdf'),'-dpdf','-bestfit'); close(f);
    fprintf('Selected bins: %s / %s. Empty means no feasible training choice.\n',policy.selections{1}.selected_case,policy.selections{2}.selected_case);
    fprintf('Last channel energy-only case has 39 frames; other cases have 40. Proxy is not measured DC.\n'); disp(R);
end
