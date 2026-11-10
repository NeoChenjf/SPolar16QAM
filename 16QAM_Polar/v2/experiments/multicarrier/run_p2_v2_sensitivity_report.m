function out=run_p2_v2_sensitivity_report(training_dir,test_dir)
% Postprocess saved test moments; no further simulation or re-selection.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    z=load(fullfile(training_dir,'frozen_training_policy.mat'),'policy'); p=z.policy;
    q=load(fullfile(training_dir,'params.mat'),'cfg'); C=q.cfg.strategy_p;
    T=readtable(fullfile(test_dir,'test_all_candidates.csv'));
    patterns=[.1 .1 .1;.5 .3 .1;.1 .3 .5;.5 .5 .5];
    labels={'Selected','Good-channel information','Good-channel energy','Uniform','Bad-channel energy only'};
    ids=cell(1,5); for j=1:4, n=find(all(bsxfun(@eq,C(1:27,:),patterns(j,:)),2)); ids{j}=sprintf('combo_%02d_shaped',n); end
    ids{5}='bad_channel_energy_only_shaped'; levels=[-30 -25 -20]; rows=cell(15,7); k=0;
    for j=1:5
        V=T(strcmp(T.case_id,ids{j}),:); assert(height(V)==20);
        for d=1:3
            scale=sqrt(2*p.resistance*10^((levels(d)-30)/10)/p.reference_m2);
            second=mean(p.k2*scale^2*V.rx_envelope_m2_l4/2);
            fourth=mean(p.k4*3*scale^4*V.rx_envelope_m4_l4/8);
            k=k+1; rows(k,:)={labels{j},ids{j},levels(d),second,fourth,second+fourth,fourth/(second+fourth)};
        end
    end
    R=cell2table(rows,'VariableNames',{'label','case_id','reference_dbm','second_order_a','fourth_order_a','total_proxy_a','fourth_fraction'});
    out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_p2_v2_sensitivity_postprocess']); mkdir(out);
    writetable(R,fullfile(out,'sensitivity_components.csv'));
    f=figure('Visible','off','Position',[100 100 1100 450]);
    subplot(1,2,1); hold on;
    for j=1:5, t=R(strcmp(R.case_id,ids{j}),:); semilogy(t.reference_dbm,t.total_proxy_a,'-o','LineWidth',1.2); end
    xlabel('Assumed reference RF (dBm)'); ylabel('Second + fourth current proxy (A)'); grid on; legend(labels,'Location','northwest');
    subplot(1,2,2); hold on;
    for j=1:5, t=R(strcmp(R.case_id,ids{j}),:); plot(t.reference_dbm,t.fourth_fraction,'-o','LineWidth',1.2); end
    xlabel('Assumed reference RF (dBm)'); ylabel('Fourth-order share'); grid on; ylim([0 1]);
    saveas(f,fullfile(out,'sensitivity_components.png')); print(f,fullfile(out,'sensitivity_components.pdf'),'-dpdf','-bestfit'); close(f);
    save(fullfile(out,'inputs.mat'),'training_dir','test_dir','p','levels');
    fid=fopen(fullfile(out,'README.txt'),'w'); fprintf(fid,'Postprocessing only; no simulation. A single reference scale per assumption, frozen from training uniform RF; k2=0.0034 A/V^2, k4=0.3829 A/V^4, R=50 ohm. Ideal interpolation, no physical DC claim.\n'); fclose(fid);
    fprintf('E2_SENSITIVITY=%s\n',out);
end
