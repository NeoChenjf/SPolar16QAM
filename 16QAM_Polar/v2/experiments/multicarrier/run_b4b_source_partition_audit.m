%% RUN_B4B_SOURCE_PARTITION_AUDIT
% Short source-entropy diagnostic; no communication/noise sweep.
script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root); setup_paths();
addpath(fullfile(v2_root, '..', 'v3', 'polar'));
cfg_local = struct('N',1024,'p_values',[0.3,0.1], ...
    'source_samples',80,'seeds',[1701,2903,4127],'sigma_design',10^(-20/20));
out_dir = fullfile(v2_root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_b4b_source_partition_audit']);
mkdir(out_dir); diary(fullfile(out_dir,'run_log.txt'));
cleanup_log = onCleanup(@() diary('off'));
[~, ga_order] = sort(GA(cfg_local.sigma_design,cfg_local.N),'descend');
rows = cell(12,8); ri = 0; entropy_records = cell(2,3); partitions = cell(2,2);
timer = tic;
for ip = 1:2
    p = cfg_local.p_values(ip); h2 = -p*log2(p)-(1-p)*log2(1-p);
    ns = ceil(cfg_local.N*(1-h2)); K = ceil((cfg_local.N-ns)/2);
    old_S = ga_order(1:ns); old_I = ga_order(ns+1:ns+K); old_F = ga_order(ns+K+1:end);
    partitions{ip,1} = {old_S,old_I,old_F};
    for is = 1:3
        stream = build_stream_partition_source_mc_ga(cfg_local.N,p,cfg_local.sigma_design, ...
            cfg_local.source_samples,cfg_local.seeds(is),struct('exact',true));
        H = stream.source_entropy; entropy_records{ip,is} = H;
        remain = ga_order(~ismember(ga_order,stream.S));
        new_sets = {stream.S,remain(1:K),remain(K+1:end)};
        partitions{ip,2} = new_sets;
        for construction = 1:2
            if construction==1, sets = partitions{ip,1}; name = 'B4_GA';
            else, sets = new_sets; name = 'source_MC_GA'; end
            ri = ri+1;
            rows(ri,:) = {p,cfg_local.seeds(is),name,mean(H(sets{1})), ...
                mean(H(sets{2})),mean(H(sets{3})),sum(H)/cfg_local.N,h2};
        end
    end
end
summary = cell2table(rows,'VariableNames',{'p','seed','construction','mean_H_S', ...
    'mean_H_I','mean_H_F','mean_H_all','target_H2'});
writetable(summary,fullfile(out_dir,'source_entropy_summary.csv'));
elapsed_seconds=toc(timer);
save(fullfile(out_dir,'source_partition_audit.mat'),'cfg_local','summary','entropy_records','partitions','elapsed_seconds');
f=figure('Visible','off'); tiledlayout(1,2);
for ip=1:2
    nexttile; vals=zeros(2,3);
    for j=1:2
        if j==1, name='B4_GA'; else, name='source_MC_GA'; end
        select=summary.p==cfg_local.p_values(ip) & strcmp(summary.construction,name);
        vals(j,:)=mean(summary{select,4:6},1);
    end
    bar(vals'); xticklabels({'S','I','F'}); ylim([0,1]); ylabel('Source conditional entropy');
    title(sprintf('p = %.1f',cfg_local.p_values(ip))); legend({'B4 GA','source MC + GA'},'Location','best');
end
saveas(f,fullfile(out_dir,'source_entropy.png')); saveas(f,fullfile(out_dir,'source_entropy.pdf')); close(f);
fid=fopen(fullfile(out_dir,'README.txt'),'w');
fprintf(fid,'Source entropy audit: N=1024; p=[0.3,0.1]; 80 iid source samples per seed; seeds=[1701,2903,4127].\n');
fprintf(fid,'Exact sum-product SC; source entropy estimated under target P, not forced-message Q.\n');
fprintf(fid,'B4 and source-MC partitions retain identical ceil-based K and S size. No PMF/BER acceptance claim.\n');
fprintf(fid,'Construction and evaluation use the same entropy estimates: descriptive diagnosis only, not holdout validation.\n');
fprintf(fid,'Elapsed seconds: %.2f\n',elapsed_seconds); fclose(fid);
disp(summary); fprintf('Outputs: %s\n',out_dir);
