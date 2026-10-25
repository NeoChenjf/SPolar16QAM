function out_dir = freeze_b4b_guardband_candidate(training_dir)
% Freeze a guardband strategy table using training data only.
% Default guardband is 0.02 inside the registered BER/Goodput gates.
    training_dir=char(training_dir);
    summary_path=fullfile(training_dir,'b4b_strategy_summary.csv');
    training_mat=fullfile(training_dir,'b4b_strict_ofdm_rayleigh.mat');
    if exist(summary_path,'file')~=2 || exist(training_mat,'file')~=2
        error('b4b:MissingTrainingEvidence','Missing summary or MAT in %s',training_dir);
    end
    meta=load(training_mat,'run_mode','seed','num_realizations','strategy_names','snr_grid');
    assert(strcmpi(meta.run_mode,'formal') && meta.seed==42 && ...
        meta.num_realizations==30 && numel(meta.strategy_names)==6, ...
        'Guardband candidate requires the registered seed42 30-realization six-strategy formal training run.');
    T=readtable(summary_path);
    required={'strategy','snr_dB','ber_mean','ber_ci95','goodput_cp_mean', ...
        'goodput_cp_ci95','rx_signal_power_mean'};
    assert(all(ismember(required,T.Properties.VariableNames)), ...
        'Training summary is missing required metrics.');
    ber_gate=0.10; goodput_gate=0.25; guard=0.02;
    ber_guard=ber_gate-guard; goodput_guard=goodput_gate+guard;
    snrs=sort(unique(T.snr_dB)); rows=cell(numel(snrs),7);
    assert(isequal(snrs(:).',sort(meta.snr_grid(:).')),'Training summary SNR grid mismatch.');
    for i=1:numel(snrs)
        q=T(T.snr_dB==snrs(i),:);
        assert(height(q)==6,'Expected six registered strategies per SNR.');
        ber_upper=q.ber_mean+q.ber_ci95;
        goodput_lower=q.goodput_cp_mean-q.goodput_cp_ci95;
        feasible=ber_upper<=ber_guard & goodput_lower>=goodput_guard;
        if any(feasible)
            ids=find(feasible);
            [~,j]=max(q.rx_signal_power_mean(ids)); selected=ids(j);
            reason='guardband_feasible_max_energy';
        else
            [~,selected]=max(q.goodput_cp_mean);
            reason='guardband_max_goodput_fallback';
        end
        rows(i,:)={snrs(i),char(string(q.strategy(selected))),reason,ber_upper(selected), ...
            goodput_lower(selected),q.rx_signal_power_mean(selected),sum(feasible)};
    end
    policy=cell2table(rows,'VariableNames',{'snr_dB','selected_strategy', ...
        'selection_reason','training_ber_upper95','training_goodput_lower95', ...
        'training_energy_mean','n_guardband_feasible'});
    v2_root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    out_dir=fullfile(v2_root,'results',[datestr(now,'yyyymmdd_HHMMSS') ...
        '_b4b_guardband_candidate_frozen']);
    if exist(out_dir,'dir'),error('b4b:OutputExists','Refuse overwrite.');end
    mkdir(out_dir);writetable(policy,fullfile(out_dir,'policy_selection.csv'));
    copyfile(summary_path,out_dir);copyfile(training_mat,out_dir);
    copyfile([mfilename('fullpath'),'.m'],out_dir);
    fid=fopen(fullfile(out_dir,'README.txt'),'w');assert(fid>=0);
    cleanup=onCleanup(@()fclose(fid));
    fprintf(fid,'Guardband candidate frozen from training data only; no independent validation results were read.\n');
    fprintf(fid,'Training directory: %s\n',training_dir);
    fprintf(fid,'Per SNR choose highest training rx energy among strategies with BER upper95 <= %.3f and Goodput lower95 >= %.3f. If none, choose maximum training Goodput and mark fallback.\n',ber_guard,goodput_guard);
    fprintf(fid,'Validation still evaluates the original gates BER upper95 <= %.3f and Goodput lower95 >= %.3f. The 0.02 guard is an explicit preregistered safety margin, not a fitted holdout parameter.\n',ber_gate,goodput_gate);
    fprintf(fid,'Frozen policy: policy_selection.csv\n');clear cleanup;
    files={summary_path,training_mat,fullfile(out_dir,'policy_selection.csv'),[mfilename('fullpath'),'.m']};
    write_hashes(fullfile(out_dir,'sha256_manifest.txt'),files);
    fprintf('Frozen guardband candidate: %s\n',out_dir);
end

function write_hashes(path,files)
    fid=fopen(path,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));
    for i=1:numel(files)
        f=fopen(files{i},'rb');assert(f>=0);c=onCleanup(@()fclose(f));b=fread(f,Inf,'*uint8');clear c;
        md=java.security.MessageDigest.getInstance('SHA-256');md.update(b);
        h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
        fprintf(fid,'%s  %s\n',h,files{i});
    end
end
