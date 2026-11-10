function run_p2_v2_e1_report(seen_dir,unseen_dir)
% Report untouched test observations and prespecified accuracy/online timing.
    dirs={seen_dir,unseen_dir}; splits={'test_seen','test_unseen'}; T=[];
    for i=1:2
        t=readtable(fullfile(dirs{i},'repetitions.csv')); if isempty(T), T=t; else, T=[T;t]; end %#ok<AGROW>
    end
    R=p2_evaluate_predictions_checked(T);
    writetable(R,fullfile(seen_dir,'e1_joint_evaluation.csv'));
    f=figure('Visible','off','Position',[100 100 1100 430]);
    subplot(1,2,1); hold on;
    for i=1:2
        valid=strcmp(T.purpose,splits{i}) & T.error_count>=20 & T.ber>=1e-4 & T.ber<=.1;
        loglog(T.ber(valid),max(T.ber_predicted(valid),realmin),'.','MarkerSize',10);
    end
    loglog([1e-4 .1],[1e-4 .1],'k--'); grid on; xlabel('Observed BER'); ylabel('Predicted BER'); legend('Seen','Unseen','Equality','Location','best'); title('Eligible independent test cells');
    subplot(1,2,2); hold on;
    for i=1:2
        valid=strcmp(T.purpose,splits{i});
        plot(T.snr_db(valid),T.rate_cp(valid).*(1-T.ber_predicted(valid))-T.goodput_cp(valid),'.');
    end
    grid on; xlabel('Reference label (dB)'); ylabel('Goodput prediction error'); legend('Seen','Unseen','Location','best');
    saveas(f,fullfile(seen_dir,'e1_prediction.png')); print(f,fullfile(seen_dir,'e1_prediction.pdf'),'-dpdf','-bestfit'); close(f);
    T.predicted_goodput=T.rate_cp.*(1-T.ber_predicted);
    G=groupsummary(T,{'purpose','control','snr_db'},'mean',{'ber','ber_predicted','goodput_cp','predicted_goodput'});
    writetable(G,fullfile(seen_dir,'e1_by_control_and_reference.csv'));
    f=figure('Visible','off','Position',[100 100 1050 430]); controls={'shaped','random_s','donor_s'};
    for i=1:2
        subplot(1,2,i); hold on;
        for k=1:3
            Q=G(strcmp(G.purpose,splits{i}) & strcmp(G.control,controls{k}),:); Q=sortrows(Q,'snr_db');
            observed=Q.mean_ber; observed(observed<=0)=nan;
            semilogy(Q.snr_db,observed,'-o'); semilogy(Q.snr_db,max(Q.mean_ber_predicted,realmin),'--');
        end
        grid on; xlabel('Reference label (dB)'); ylabel('Mean BER across channels'); title(splits{i},'Interpreter','none');
        legend('Shaped data','Shaped model','Random S data','Random S model','Donor S data','Donor S model','Location','best');
    end
    saveas(f,fullfile(seen_dir,'e1_control_curves.png')); print(f,fullfile(seen_dir,'e1_control_curves.pdf'),'-dpdf','-bestfit'); close(f);
    tm=cell(2,6);
    for i=1:2
        Q=T(strcmp(T.purpose,splits{i}),:); z=load(fullfile(dirs{i},'completed.mat'),'elapsed');
        tm(i,:)={splits{i},height(Q),sum(Q.frames),sum(Q.elapsed_seconds),sum(Q.online_seconds),z.elapsed};
    end
    times=cell2table(tm,'VariableNames',{'split','cells','case_frames','simulation_seconds_excluding_measurement','online_prediction_seconds','test_wall_seconds'});
    writetable(times,fullfile(seen_dir,'e1_timing.csv'));
    cfg_data=load(fullfile(seen_dir,'params.mat'),'cfg');
    model_data=load(cfg_data.cfg.model_file,'model'); model=model_data.model;
    train_rows=readtable(fullfile(model.training_dir,'repetitions.csv'));
    fit_clock=tic; measured=p2_calibrate_model(train_rows); fit_seconds=toc(fit_clock);
    assert(isequaln(measured.parameters,model.parameters),'Recomputed calibration differs.');
    train_time=load(fullfile(model.training_dir,'completed.mat'),'elapsed');
    pmf_dir=fileparts(model.training_cfg.pmf_file); pmf_time=load(fullfile(pmf_dir,'completed.mat'),'elapsed');
    offline=table(pmf_time.elapsed,train_time.elapsed,fit_seconds, ...
        'VariableNames',{'pmf_sampling_loop_seconds','calibration_simulation_loop_seconds','two_parameter_fit_retimed_seconds'});
    writetable(offline,fullfile(seen_dir,'e1_offline_timing.csv'));
    run_p2_v2_pmf_report(pmf_dir);
    run_p2_v2_group_error_report(seen_dir);
    run_p2_v2_group_error_report(unseen_dir);
    disp(R);
end





