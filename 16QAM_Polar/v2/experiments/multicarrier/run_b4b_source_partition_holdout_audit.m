%% RUN_B4B_SOURCE_PARTITION_HOLDOUT_AUDIT
% Independently evaluate source conditional entropy on frozen legacy/new S/I/F sets.
script_dir=fileparts(mfilename('fullpath')); v2_root=fullfile(script_dir,'..','..');
v3_root=fullfile(v2_root,'..','v3'); addpath(v2_root); setup_paths;
addpath(fullfile(v3_root,'polar'));
N=1024; p_values=[0.5 0.4 0.3 0.2 0.1]; construction_seed=9001;
construction_samples=200; evaluation_seeds=[12001 22001 32001]; evaluation_samples=200;
sigma_design=10^(-20/20); out_dir=fullfile(v2_root,'results', ...
    [datestr(now,'yyyymmdd_HHMMSS') '_b4b_source_partition_holdout_audit']);
mkdir(out_dir); mkdir(fullfile(out_dir,'figures')); mkdir(fullfile(out_dir,'source_snapshot'));
diary(fullfile(out_dir,'run_log.txt')); cleanup_diary=onCleanup(@()diary('off'));
summary_rows={}; position_rows={}; set_rows={};
[~,ga_order]=sort(GA(sigma_design,N),'descend'); timer=tic;
for ip=1:numel(p_values)
    p=p_values(ip); p_vec=[0.5 p 0.5 p];
    new_partition=build_source_entropy_partition(N,p_vec,sigma_design, ...
        construction_samples,construction_seed);
    b=2; S_size=new_partition.S_size(b); K=new_partition.K(b);
    old.S=sort(ga_order(1:S_size)); old.I=sort(ga_order(S_size+1:S_size+K));
    old.F=sort(ga_order(S_size+K+1:end));
    fresh.S=new_partition.S{b}; fresh.I=new_partition.I{b}; fresh.F=new_partition.F{b};
    for iseed=1:numel(evaluation_seeds)
        seed=evaluation_seeds(iseed);
        holdout=build_stream_partition_source_mc_ga(N,p,sigma_design, ...
            evaluation_samples,seed,struct('exact',true));
        H=holdout.source_entropy(:);
        labels=zeros(N,1); labels(old.S)=1; labels(old.I)=2; labels(old.F)=3;
        labels(fresh.S)=4; labels(fresh.I)=5; labels(fresh.F)=6;
        for j=1:N
            position_rows(end+1,:)={p,seed,j,H(j),labels(j)}; %#ok<AGROW>
        end
        categories={'S','I','F'}; sets={old.S,old.I,old.F,fresh.S,fresh.I,fresh.F};
        names={'legacy_GA','legacy_GA','legacy_GA','source_entropy_GA','source_entropy_GA','source_entropy_GA'};
        for k=1:6
            value=mean(H(sets{k})); category=categories{mod(k-1,3)+1};
            summary_rows(end+1,:)={p,seed,names{k},category,numel(sets{k}),value}; %#ok<AGROW>
            for idx=sets{k}(:).'
                set_rows(end+1,:)={p,seed,names{k},category,idx}; %#ok<AGROW>
            end
        end
    end
end
summary=cell2table(summary_rows,'VariableNames',{'p','evaluation_seed','construction','set','set_size','mean_source_conditional_entropy'});
positions=cell2table(position_rows,'VariableNames',{'p','evaluation_seed','source_index','holdout_conditional_entropy','set_code'});
sets=cell2table(set_rows,'VariableNames',{'p','evaluation_seed','construction','set','source_index'});
writetable(summary,fullfile(out_dir,'independent_entropy_summary.csv'));
writetable(positions,fullfile(out_dir,'independent_entropy_by_position.csv'));
writetable(sets,fullfile(out_dir,'set_indices.csv'));
elapsed=toc(timer); save(fullfile(out_dir,'holdout_audit.mat'),'N','p_values', ...
    'construction_seed','construction_samples','evaluation_seeds','evaluation_samples', ...
    'sigma_design','summary','positions','sets','elapsed');
local_plot(summary,p_values,fullfile(out_dir,'figures'));
local_snapshot(out_dir,script_dir,v2_root,v3_root);
fid=fopen(fullfile(out_dir,'README.txt'),'w'); c=onCleanup(@()fclose(fid));
fprintf(fid,'Independent source conditional entropy evaluation of legacy GA and source-entropy S sets.\n');
fprintf(fid,'N=%d; p=%s; construction samples=%d seed=%d; independent evaluation samples=%d seeds=%s.\n', ...
    N,mat2str(p_values),construction_samples,construction_seed,evaluation_samples,mat2str(evaluation_seeds));
fprintf(fid,'The independent evaluation samples are separate from those used to select S. K and |S| are retained; only S selection differs, while I/F are GA-ranked in the remaining positions.\n');
fprintf(fid,'Files: independent_entropy_summary.csv, independent_entropy_by_position.csv, set_indices.csv, holdout_audit.mat, figures/source_entropy_holdout.png/pdf.\n');
fprintf(fid,'This is a source-model diagnostic, not a communication performance or PMF gate. Elapsed seconds: %.2f.\n',elapsed);
fprintf('Independent source partition audit saved: %s\n',out_dir);

function local_plot(T,p_values,fig_dir)
f=figure('Visible','off','Position',[80 60 1000 900]); tl=tiledlayout(numel(p_values),1,'TileSpacing','compact','Padding','compact');
for ip=1:numel(p_values)
    ax=nexttile; p=p_values(ip); vals=zeros(3,2); errs=zeros(3,2);
    for c=1:2
        if c==1, name='legacy_GA'; else, name='source_entropy_GA'; end
        for j=1:3
            setname={'S','I','F'}; q=T.p==p & strcmp(T.construction,name) & strcmp(T.set,setname{j});
            per_seed=groupsummary(T(q,:),{'evaluation_seed'},'mean','mean_source_conditional_entropy');
            vals(j,c)=mean(per_seed.mean_mean_source_conditional_entropy);
            errs(j,c)=std(per_seed.mean_mean_source_conditional_entropy,0)/sqrt(height(per_seed));
        end
    end
    bar(ax,vals); hold(ax,'on');
    ng=size(vals,1); nb=size(vals,2); groupwidth=min(0.8,nb/(nb+1.5));
    for j=1:nb
        x=(1:ng)-groupwidth/2+(2*j-1)*groupwidth/(2*nb);
        errorbar(ax,x,vals(:,j),errs(:,j),'k.','LineWidth',1);
    end
    ylabel(ax,'Mean holdout H(U_i|U^{i-1})'); title(ax,sprintf('p = %.1f',p));
    xticks(ax,1:3); xticklabels(ax,{'S','I','F'}); ylim(ax,[0 1]); grid(ax,'on');
    if ip==1, legend(ax,{'Legacy GA prefix sets','Source-entropy S + GA I/F'},'Location','northeast'); end
end
title(tl,'Independent source-entropy holdout: same K and |S|');
set(f,'PaperPositionMode','auto');
print(f,fullfile(fig_dir,'source_entropy_holdout.png'),'-dpng','-r180');
print(f,fullfile(fig_dir,'source_entropy_holdout.pdf'),'-dpdf','-bestfit'); close(f);
end

function local_snapshot(out_dir,script_dir,v2_root,v3_root)
files={fullfile(script_dir,'run_b4b_source_partition_holdout_audit.m'), ...
    fullfile(v2_root,'polar','build_source_entropy_partition.m'), ...
    fullfile(v2_root,'polar','GA.m'),fullfile(v2_root,'polar','polar_encoder.m'), ...
    fullfile(v3_root,'polar','build_stream_partition_source_mc_ga.m'), ...
    fullfile(v3_root,'polar','sc_decode_forced_full.m')};
fid=fopen(fullfile(out_dir,'sha256_manifest.txt'),'w'); c=onCleanup(@()fclose(fid));
for i=1:numel(files)
    [~,n,e]=fileparts(files{i}); copyfile(files{i},fullfile(out_dir,'source_snapshot',[n e]));
    f=fopen(files{i},'rb'); bytes=fread(f,Inf,'*uint8'); fclose(f);
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    digest=typecast(md.digest(),'uint8'); hex=lower(reshape(dec2hex(digest,2)',1,[]));
    fprintf(fid,'%s  %s\n',hex,files{i});
end
end
