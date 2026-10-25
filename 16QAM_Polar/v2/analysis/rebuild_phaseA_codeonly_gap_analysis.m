function out_dir = rebuild_phaseA_codeonly_gap_analysis(source_dir)
% Recompute finite-repetition intervals and theory/simulation gaps from F19.
% Post-processing only: never launches Monte Carlo or edits the source run.
    v2_root=fileparts(fileparts(mfilename('fullpath')));addpath(v2_root);setup_paths();
    source_dir=char(source_dir);
    input_path=fullfile(source_dir,'codeonly_final_repetitions.csv');
    partition_path=fullfile(source_dir,'codeonly_theory_partition_indices.csv');
    run_mat=fullfile(source_dir,'phaseA_sc_final_global_curves.mat');
    if exist(input_path,'file')~=2 || exist(partition_path,'file')~=2 || exist(run_mat,'file')~=2
        error('phaseA:MissingInput','Formal code-only repetitions or partition indices are missing.');
    end
    R=readtable(input_path);
    assert(all(isfinite(R.BER)) && all(isfinite(R.BER_theory)) && ...
        all(R.BER>=0 & R.BER<=0.5) && all(R.BER_theory>0), ...
        'Unexpected nonfinite or invalid BER values.');
    pvals=sort(unique(R.p),'descend'); snrs=sort(unique(R.snr_dB));
    assert(height(R)==numel(pvals)*numel(snrs)*5, ...
        'Expected five independent repetitions at every p/SNR point.');
    run_data=load(run_mat,'cfg_local');
    validate_partition_indices(partition_path,run_data.cfg_local.N);
    rows=cell(numel(pvals)*numel(snrs),11); k=0;
    tcrit=[NaN,12.7062047364,4.30265272975,3.18244630528,2.7764451052];
    for ip=1:numel(pvals)
        for is=1:numel(snrs)
            q=R(abs(R.p-pvals(ip))<1e-12 & abs(R.snr_dB-snrs(is))<1e-12,:);
            assert(height(q)==5,'Each point must have five repetitions.');
            k=k+1; mu=mean(q.BER); se=std(q.BER,0)/sqrt(height(q));
            theory=mean(q.BER_theory);
            rows(k,:)={pvals(ip),snrs(is),mu,max(0,mu-tcrit(5)*se), ...
                min(0.5,mu+tcrit(5)*se),theory,mu/theory, ...
                sum(q.errors),sum(q.frames),min(q.BER),max(q.BER)};
        end
    end
    T=cell2table(rows,'VariableNames',{'p','snr_label_dB','BER_mean', ...
        'BER_t95_low','BER_t95_high','BER_theory','simulation_to_theory_ratio', ...
        'total_errors','total_frames','rep_min_BER','rep_max_BER'});
    out_dir=fullfile(v2_root,'results',[datestr(now,'yyyymmdd_HHMMSS') ...
        '_phaseA_codeonly_gap_analysis']);
    if exist(out_dir,'dir'),error('phaseA:OutputExists','Refuse overwrite.');end
    fig_dir=fullfile(out_dir,'figures');mkdir(out_dir);mkdir(fig_dir);
    writetable(T,fullfile(out_dir,'model_gap_summary.csv'));
    copyfile(input_path,out_dir);copyfile(partition_path,out_dir);
    copyfile(run_mat,out_dir);

    colors=lines(numel(pvals)); f=figure('Visible','off','Color','w','Position',[60 60 1100 720]);hold on;
    for ip=1:numel(pvals)
        q=T(abs(T.p-pvals(ip))<1e-12,:); y=q.BER_mean; keep=y>0;
        h=errorbar(q.snr_label_dB(keep),y(keep), ...
            y(keep)-q.BER_t95_low(keep),q.BER_t95_high(keep)-y(keep),'-o', ...
            'Color',colors(ip,:),'DisplayName',sprintf('simulation mean p=%.1f',pvals(ip)));
        semilogy(q.snr_label_dB,q.BER_theory,'--','Color',colors(ip,:), ...
            'HandleVisibility','off'); %#ok<NASGU>
    end
    plot(nan,nan,'k--','DisplayName','GA/BER estimate');
    set(gca,'YScale','log');grid on;xlabel('v2 SNR parameter (dB)');ylabel('BER');
    title('F19 code-only: SC simulation (5-repetition t intervals) and GA estimate');
    legend('Location','eastoutside');
    savefig(f,fullfile(fig_dir,'F19_codeonly_theory_vs_simulation.fig'));
    exportgraphics(f,fullfile(fig_dir,'F19_codeonly_theory_vs_simulation.png'),'Resolution',200);
    exportgraphics(f,fullfile(fig_dir,'F19_codeonly_theory_vs_simulation.pdf'),'ContentType','vector');close(f);

    gap=reshape(T.simulation_to_theory_ratio,numel(snrs),numel(pvals)).';
    f=figure('Visible','off','Color','w','Position',[60 60 1000 620]);
    imagesc(snrs,pvals,log10(gap));set(gca,'YDir','normal');
    xticks(snrs([1,3,5,7,9,10]));yticks(sort(pvals));
    cb=colorbar;cb.Label.String='log10(simulation BER / GA estimate)';
    xlabel('v2 SNR parameter (dB)');ylabel('p');
    title('F19 relative error of the existing GA/BER estimate');
    savefig(f,fullfile(fig_dir,'F19_model_gap_heatmap.fig'));
    exportgraphics(f,fullfile(fig_dir,'F19_model_gap_heatmap.png'),'Resolution',200);
    exportgraphics(f,fullfile(fig_dir,'F19_model_gap_heatmap.pdf'),'ContentType','vector');close(f);

    script_path=[mfilename('fullpath'),'.m'];copyfile(script_path,out_dir);
    fid=fopen(fullfile(out_dir,'README.txt'),'w');assert(fid>=0);
    cleanup=onCleanup(@()fclose(fid));
    fprintf(fid,'Post-processing only; no Monte Carlo was run.\nSource run: %s\n',source_dir);
    fprintf(fid,'Simulation intervals use Student t with df=4 from five independent repetitions.\n');
    fprintf(fid,'The source model uses the actual source-S indices and per-SNR GA I/F sets, but remains a reliability/BER approximation. Its error ratio is reported, not calibrated.\n');
    fprintf(fid,'The saved partition-index table was independently checked against GA top-K after removing the recorded actual S indices at every p/SNR/stream.\n');
    fprintf(fid,'The source run uses plain SC without an added source prior, held fixed to isolate the construction. This does not validate a matched-prior receiver.\n');
    fprintf(fid,'SNR parameter maps to actual Es/N0 = label - 3.0103 dB under the source run noise convention. Zero-error repetitions remain in raw counts and intervals; they are not evidence of a BER floor.\n');
    clear cleanup;
    inputs={input_path,partition_path,run_mat,script_path};
    write_manifest(fullfile(out_dir,'sha256_manifest.txt'),inputs);
end

function validate_partition_indices(path,N)
    P=readtable(path);
    assert(height(P)==5*10*4,'Unexpected p/SNR/bit-stream partition table size.');
    for i=1:height(P)
        S=parse_indices(P.S_indices(i)); I=parse_indices(P.I_indices(i));
        sigma=10^(-P.snr_dB(i)/20); [~,order]=sort(GA(sigma,N),'descend');
        remaining=order(~ismember(order,S)); expected=sort(remaining(1:P.K(i))); expected=expected(:);
        assert(numel(S)==P.S_size(i) && numel(I)==P.K(i));
        assert(isempty(intersect(S,I)) && isequal(I,expected), ...
            'Saved I indices do not equal top-K GA positions after removing actual S.');
        assert(numel(unique([S;I]))==numel(S)+numel(I));
    end
end

function indices=parse_indices(value)
    text_value=char(string(value));
    values=sscanf(regexprep(text_value,'[\[\]]',''),'%f');
    indices=values(:);
end

function write_manifest(path,inputs)
    fid=fopen(path,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));
    for i=1:numel(inputs)
        f=fopen(inputs{i},'rb');assert(f>=0);c=onCleanup(@()fclose(f));b=fread(f,Inf,'*uint8');clear c;
        md=java.security.MessageDigest.getInstance('SHA-256');md.update(b);
        h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
        fprintf(fid,'%s  %s\n',h,inputs{i});
    end
end
