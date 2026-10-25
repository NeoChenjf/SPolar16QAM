%% REBUILD_B4B_BLOCKLENGTH_COMPARISON
% Reanalyze held-out shaped-word PMF and transmitted energy for N=256/1024.
if ~exist('blocklength_result_dirs','var') || numel(blocklength_result_dirs)~=2
    error('Set blocklength_result_dirs={N256_dir,N1024_dir} before running.');
end
script_dir=fileparts(mfilename('fullpath')); v2_root=fullfile(script_dir,'..','..');
addpath(v2_root); setup_paths; cfg=config();
Ns=[256 1024]; rows={};
for ni=1:2
    d=blocklength_result_dirs{ni};
    P=readtable(fullfile(d,'pmf_summary.csv')); Q=readtable(fullfile(d,'pmf_by_seed.csv'));
    F=readtable(fullfile(d,'frame_audit.csv'));
    p_values=unique(P.p).';
    for p=p_values
        variant='message_conditioned';
        q=P(P.p==p & strcmp(P.variant,variant),:);
        assert(height(q)==1,'Expected one message-conditioned PMF row per p.');
        qseed=Q(Q.p==p & strcmp(Q.variant,variant),:);
        max_seed_upper=max(qseed.tv_bootstrap_upper95);
        gate_pass=q.tv_bootstrap_upper95<=0.05 && max_seed_upper<=0.05;
        energy=F(F.p==p & strcmp(F.variant,variant),:);
        seeds=unique(energy.seed); e_by_seed=zeros(numel(seeds),1);
        for k=1:numel(seeds), e_by_seed(k)=mean(energy.tx_symbol_power(energy.seed==seeds(k))); end
        tx=mean(e_by_seed); se=std(e_by_seed,0)/sqrt(numel(e_by_seed));
        rows(end+1,:)={Ns(ni),p,q.tv_empirical_target,q.tv_bootstrap_upper95, ...
            max_seed_upper,gate_pass,tx,se}; %#ok<AGROW>
    end
end
T=cell2table(rows,'VariableNames',{'N','p','tv_empirical','tv_pooled_upper95', ...
    'tv_max_seed_upper95','pmf_gate_pass','tx_symbol_power_mean','tx_symbol_power_se'});
T.tx_energy_relative_to_p05=nan(height(T),1); T.tx_energy_relative_se=nan(height(T),1);
for n=Ns
    idx=T.N==n; base=T.tx_symbol_power_mean(idx & T.p==0.5);
    T.tx_energy_relative_to_p05(idx)=T.tx_symbol_power_mean(idx)/base;
    T.tx_energy_relative_se(idx)=T.tx_symbol_power_se(idx)/base;
end
T=sortrows(T,{'p','N'});
out=fullfile(cfg.output_dir,[datestr(now,'yyyymmdd_HHMMSS') '_b4b_blocklength_comparison']);
mkdir(out); mkdir(fullfile(out,'figures')); mkdir(fullfile(out,'source_snapshot'));
writetable(T,fullfile(out,'blocklength_comparison.csv'));
save(fullfile(out,'blocklength_comparison.mat'),'T','Ns','blocklength_result_dirs');
f=figure('Visible','off','Color','w','Position',[80 80 1100 520]); tiledlayout(1,2,'TileSpacing','compact');
ax=nexttile; hold(ax,'on'); grid(ax,'on'); gate_line=yline(ax,0.05,'k--','Gate 0.05'); gate_line.HandleVisibility='off';
colors=lines(numel(unique(T.p))); ps=sort(unique(T.p),'descend'); h_pmf=gobjects(numel(ps),1); h_energy=gobjects(numel(ps),1);
for ip=1:numel(ps)
    r=sortrows(T(T.p==ps(ip),:),'N'); h_pmf(ip)=plot(ax,r.N,r.tv_empirical,'-o','Color',colors(ip,:), ...
        'DisplayName',sprintf('p=%.1f',ps(ip)));
    for k=1:height(r), plot(ax,[r.N(k) r.N(k)],[r.tv_empirical(k) r.tv_pooled_upper95(k)], ...
            '-','Color',colors(ip,:),'LineWidth',1.3,'HandleVisibility','off'); end
end
set(ax,'XScale','log','XTick',Ns,'XTickLabel',string(Ns)); xlabel(ax,'Polar block length N');
ylabel(ax,'TV(empirical, target)'); title(ax,'Joint symbol PMF; bars extend to pooled one-sided 95% upper bound');
legend(ax,h_pmf,'Location','best');
ax=nexttile; hold(ax,'on'); grid(ax,'on');
for ip=1:numel(ps)
    r=sortrows(T(T.p==ps(ip),:),'N'); h_energy(ip)=errorbar(ax,r.N,r.tx_energy_relative_to_p05, ...
        r.tx_energy_relative_se,'-o', ...
        'Color',colors(ip,:),'DisplayName',sprintf('p=%.1f',ps(ip)));
end
set(ax,'XScale','log','XTick',Ns,'XTickLabel',string(Ns)); energy_base=yline(ax,1,'k:'); energy_base.HandleVisibility='off';
xlabel(ax,'Polar block length N'); ylabel(ax,'Mean transmitted symbol power / p=0.5');
title(ax,'Energy proxy from actual transmitted symbols'); legend(ax,h_energy,'Location','best');
exportgraphics(f,fullfile(out,'figures','b4b_blocklength_pmf_energy.png'),'Resolution',220);
exportgraphics(f,fullfile(out,'figures','b4b_blocklength_pmf_energy.pdf'),'ContentType','vector'); close(f);
fid=fopen(fullfile(out,'README.txt'),'w'); c=onCleanup(@()fclose(fid));
fprintf(fid,'N=256/1024 source-entropy S + GA I/F blocklength comparison.\nInput result directories:\n%s\n%s\n',blocklength_result_dirs{1},blocklength_result_dirs{2});
fprintf(fid,'Only message_conditioned rows enter the PMF/energy comparison; legacy_fixed is retained as a diagnostic comparator. PMF gate is evaluated against target with whole-codeword bootstrap. Energy is actual mean QAM symbol power normalized to p=0.5 at the same N.\n');
fprintf(fid,'No causal claim that block length alone explains all residual PMF error; the finite construction and forced-zero F boundary remain part of the method.\n');
fprintf(fid,'Output: blocklength_comparison.csv, MAT, PNG and PDF.\n');
files={fullfile(script_dir,'rebuild_b4b_blocklength_comparison.m')};
for i=1:numel(blocklength_result_dirs)
    files{end+1}=fullfile(blocklength_result_dirs{i},'pmf_summary.csv'); %#ok<AGROW>
    files{end+1}=fullfile(blocklength_result_dirs{i},'pmf_by_seed.csv'); %#ok<AGROW>
    files{end+1}=fullfile(blocklength_result_dirs{i},'frame_audit.csv'); %#ok<AGROW>
end
hashfid=fopen(fullfile(out,'sha256_manifest.txt'),'w'); hashcleanup=onCleanup(@()fclose(hashfid));
for i=1:numel(files)
    if endsWith(files{i},'.m'), copyfile(files{i},fullfile(out,'source_snapshot','rebuild_b4b_blocklength_comparison.m')); end
    stream=fopen(files{i},'rb'); bytes=fread(stream,Inf,'*uint8'); fclose(stream);
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    digest=typecast(md.digest(),'uint8'); hex=lower(reshape(dec2hex(digest,2)',1,[]));
    fprintf(hashfid,'%s  %s\n',hex,files{i});
end
clear hashcleanup;
fprintf('Blocklength comparison written: %s\n',out);
