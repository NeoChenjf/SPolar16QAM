function analysis_dir = analyze_p2_mechanism(run_dirs, out_dir, n_boot)
%ANALYZE_P2_MECHANISM Auditable exploratory/formal figures with raw count tables.
    if nargin<3, n_boot=2000; end
    assert(iscell(run_dirs) && ~isempty(run_dirs));
    assert(~isfolder(out_dir),'Refusing analysis overwrite.'); mkdir(out_dir);
    analysis_dir=out_dir; fig_dir=fullfile(out_dir,'figures'); mkdir(fig_dir);
    T=table(); pmf_rows={}; power_rows={}; profiles={}; bit_rows={}; s_rows={};
    addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'..','v3','analysis'));
    labels=de2bi((0:15)',4,'left-msb');
    for d=1:numel(run_dirs)
        cfg_data=load(fullfile(run_dirs{d},'params.mat'),'cfg'); cfg=cfg_data.cfg;
        R=readtable(fullfile(run_dirs{d},'repetitions.csv'));
        if isempty(T), T=R; else, T=[T;R]; end %#ok<AGROW>
        loaded=load(fullfile(run_dirs{d},'cases.mat'),'cases'); cases=loaded.cases;
        powers=[];
        if ~isempty(cfg.power_file), fitted=load(cfg.power_file,'power'); powers=fitted.power; end
        files=dir(fullfile(run_dirs{d},'raw_*.mat'));
        for f=1:numel(files)
            raw=load(fullfile(files(f).folder,files(f).name),'artifact'); a=raw.artifact;
            token=regexp(files(f).name,'^raw_c(\d+)_s(\d+)_(.+)\.mat$','tokens','once');
            channel=str2double(token{1}); isnr=str2double(token{2}); id=token{3};
            ic=find(strcmp({cases.id},id)); rec=[a.records{:}];
            for g=1:numel(a.states)
                model=[];
                if ~isempty(powers)
                    model_index=find(strcmp({powers.case_id},id)); model=powers(model_index).pmf(:,g);
                end
                [target,reference_role,required]=p2_distribution_reference(a.states{g},model);
                frame_pmf=reshape(a.counts(:,g,:),16,[])/cfg.N;
                point=.5*sum(abs(mean(frame_pmf,2)-target)); upper=nan;
                if size(frame_pmf,2)>=2 && all(isfinite(target))
                    s=cluster_bootstrap_tv(frame_pmf,target,n_boot,19501+g);
                    upper=s.tv_upper95;
                end
                pmf_rows(end+1,:)={cfg.purpose,cfg.seed,channel,cfg.snr_grid(isnr),id,g, ...
                    size(frame_pmf,2),point,upper,isfinite(upper)&&upper<=.05, ...
                    reference_role,required,'Per-cell codeword cluster; pilot is not formal acceptance'}; %#ok<AGROW>
                group=vertcat(rec.group_tx);
                cross=[rec.tx]'-sum(group,2);
                power_rows(end+1,:)={cfg.purpose,cfg.seed,channel,cfg.snr_grid(isnr),id,g, ...
                    mean(group(:,g)),mean([rec.tx]),mean(cross),a.scale(g)}; %#ok<AGROW>
                for b=1:4
                    bit_rows(end+1,:)={cfg.purpose,cfg.seed,channel,cfg.snr_grid(isnr),id,g,b, ...
                        a.states{g}.K(b),a.stream_errors(g,b),a.info_counts(g,b), ...
                        a.oracle_errors(g,b),cfg.diagnose}; %#ok<AGROW>
                    if isfield(a,'u_ones')
                        idx=a.states{g}.S{b}; frequency=a.u_ones{g}(idx,b)/cfg.num_frames;
                        entropy=zeros(size(frequency)); nontrivial=frequency>0 & frequency<1;
                        q=frequency(nontrivial); entropy(nontrivial)=-q.*log2(q)-(1-q).*log2(1-q);
                        for j=1:numel(idx)
                            s_rows(end+1,:)={cfg.purpose,cfg.seed,channel,cfg.snr_grid(isnr),id,g,b, ...
                                idx(j),cfg.num_frames,frequency(j),entropy(j)}; %#ok<AGROW>
                        end
                    end
                end
            end
            profiles(end+1,:)={id,cfg.snr_grid(isnr),a.profile,a.H,cfg.mode}; %#ok<AGROW>
        end
    end
    keys=T(:,{'purpose','seed','channel','snr_db','case_id'});
    assert(height(unique(keys,'rows'))==height(T),'Duplicate sample keys.');
    writetable(T,fullfile(out_dir,'repetitions.csv'));
    if all(T.communication_measured)
        paired=p2_paired_summary(T,n_boot); writetable(paired,fullfile(out_dir,'paired_differences.csv'));
    end
    P=cell2table(pmf_rows,'VariableNames',{'purpose','seed','channel','snr_db','case_id', ...
        'group','frames','tv_point','tv_upper95','cell_pass','reference_role','required_target','scope'});
    W=cell2table(power_rows,'VariableNames',{'purpose','seed','channel','snr_db','case_id', ...
        'group','group_time_power','total_time_power','cross_term','scale'});
    B=cell2table(bit_rows,'VariableNames',{'purpose','seed','channel','snr_db','case_id','group', ...
        'stream','K','errors','info_bits','oracle_errors','oracle_measured'});
    writetable(P,fullfile(out_dir,'pmf_per_seed_cell.csv'));
    writetable(W,fullfile(out_dir,'power_per_group.csv'));
    writetable(B,fullfile(out_dir,'rate_error_decomposition.csv'));
    if ~isempty(s_rows)
        S=cell2table(s_rows,'VariableNames',{'purpose','seed','channel','snr_db','case_id', ...
            'group','stream','S_index','frames','p_one','marginal_entropy'});
        writetable(S,fullfile(out_dir,'S_marginal_statistics.csv'));
    end
    status='EXPLORATORY / NOT FORMAL';
    if all(ismember(T.purpose,{'test_seen','test_unseen'})), status='Independent frozen test'; end
    f=figure('Visible','off','Position',[40,40,1300,650]);
    subplot(1,2,1); local_lines(T,'tx_power'); ylabel('TX time mean square'); title(status,'Interpreter','none');
    subplot(1,2,2); boxchart(categorical(W.group),W.group_time_power); ylabel('Group component time power');
    local_save(f,fig_dir,'power_audit');
    f=figure('Visible','off','Position',[40,40,1300,650]);
    subplot(1,2,1); local_lines(T,'rx_rf'); ylabel('Pre-noise RX RF mean square');
    subplot(1,2,2); scatter(T.rx_frequency_reference,T.rx_rf,35,'filled'); hold on;
    lim=[min([T.rx_rf;T.rx_frequency_reference]),max([T.rx_rf;T.rx_frequency_reference])];
    plot(lim,lim,'k--'); xlabel('Frequency weighted reference'); ylabel('Continuous time convolution RF');
    local_save(f,fig_dir,'rf_mechanism');
    f=figure('Visible','off','Position',[40,40,1400,900]);
    names={'ber','bler','goodput_cp','rf_residual'};
    for j=1:4, subplot(2,2,j); local_lines(T,names{j}); ylabel(strrep(names{j},'_',' ')); end
    local_save(f,fig_dir,'communication_rf');
    f=figure('Visible','off','Position',[40,40,1300,650]);
    subplot(1,2,1); scatter(P.group,P.tv_point,30,'filled'); hold on; yline(.05,'k--');
    xlabel('Group'); ylabel('TV(target, empirical)'); title('Pilot counts; NOT a distribution gate pass');
    subplot(1,2,2); scatter(T.ber_raw,T.ber,35,'filled'); xlabel('Raw model BER'); ylabel('Observed BER');
    title('Pilot prediction only'); local_save(f,fig_dir,'pmf_prediction');
    f=figure('Visible','off','Position',[40,40,1300,650]);
    subplot(1,2,1); local_lines(T,'rate_cp'); ylabel('Actual design rate including CP / padding');
    subplot(1,2,2); scatter(T.rate_cp,T.rate_cp-T.goodput_cp,35,'filled');
    xlabel('Actual rate'); ylabel('Rate x BER loss'); local_save(f,fig_dir,'rate_loss');
    f=figure('Visible','off','Position',[40,40,1300,650]);
    subplot(1,2,1); scatter(T.elapsed_seconds./T.frames,T.online_seconds,35,'filled');
    xlabel('Full chain sec / frame'); ylabel('Online model sec');
    subplot(1,2,2); scatter(T.offline_seconds,T.online_seconds,35,'filled');
    xlabel('Offline quadrature sec'); ylabel('Online GA sec'); local_save(f,fig_dir,'prediction_cost');
    if strcmp(status,'Independent frozen test')
        report=p2_evaluate_predictions(T); writetable(report,fullfile(out_dir,'model_use_gate.csv'));
    end
    save(fullfile(out_dir,'analysis.mat'),'T','P','W','B','profiles','status');
    fid=fopen(fullfile(out_dir,'README.txt'),'w'); closer=onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid,'%s\n',status);
    fprintf(fid,'RF is pre-noise normalized mean square, not watts/joules/DC. Zero errors retain denominators.\n');
    fprintf(fid,'Frequency reference excludes CP/boundary/correlation effects; residual is not forced to zero.\n');
    fprintf(fid,'TV intervals are per cell/seed, entire codeword clusters. Pilot samples are not formal gate evidence.\n');
    fprintf(fid,'No calibrated model is declared valid by plotting. Online and offline timings are separate.\n');
    for d=1:numel(run_dirs), fprintf(fid,'Input: %s\n',run_dirs{d}); end
end

function local_lines(T,metric)
    ids=unique(T.case_id,'stable'); styles={'-o','--s',':^','-.d'};
    bases=regexprep(ids,'_(shaped|same_k_i|native|random_s|donor_s)$',''); strategies=unique(bases,'stable');
    controls={'shaped','random_s','donor_s','native','same_k_i'};
    styles={'-o','--s',':^','-.d','-v'}; color=lines(numel(strategies)); hold on;
    for i=1:numel(ids)
        R=T(strcmp(T.case_id,ids{i}),:); x=unique(R.snr_db); y=zeros(size(x));
        for k=1:numel(x)
            A=R(R.snr_db==x(k),:); y(k)=mean(A.(metric));
            if strcmp(metric,'ber') && sum(A.error_count)==0, y(k)=-log(.05)/sum(A.info_bits); end
            if strcmp(metric,'bler') && sum(A.block_errors)==0, y(k)=-log(.05)/sum(A.info_blocks); end
        end
        strategy=find(strcmp(strategies,bases{i}));
        control=find(cellfun(@(s) endsWith(ids{i},['_' s]),controls));
        plot(x,y,styles{control},'Color',color(strategy,:), ...
            'DisplayName',strrep(ids{i},'_',' '));
    end
    if any(strcmp(metric,{'ber','bler'}))
        set(gca,'YScale','log'); title('Zero observations: one-sided 95% upper limits');
    end
    xlabel('TX target / time complex noise (dB)'); grid on;
    legend('Location','eastoutside','FontSize',7,'Interpreter','none');
end

function local_save(f,d,name)
    exportgraphics(f,fullfile(d,[name '.png']),'Resolution',150);
    try
        exportgraphics(f,fullfile(d,[name '.pdf']),'ContentType','vector');
    catch exception
        warning('p2:VectorPDFUnavailable','Vector PDF unavailable (%s); exporting image PDF.',exception.identifier);
        exportgraphics(f,fullfile(d,[name '.pdf']),'ContentType','image','Resolution',200);
        fid=fopen(fullfile(d,'pdf_export_notes.txt'),'a');
        fprintf(fid,'%s: image PDF fallback; %s\n',name,exception.message); fclose(fid);
    end
    savefig(f,fullfile(d,[name '.fig'])); close(f);
end
