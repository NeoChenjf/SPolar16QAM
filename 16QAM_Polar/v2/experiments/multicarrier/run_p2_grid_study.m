function study_dir=run_p2_grid_study()
% Three versus five p levels, approved 2026-11-09; no E1 or hardware.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
study_dir=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_p2_grid_study']); mkdir(study_dir);
fid=fopen(fullfile(root,'results','LATEST_P2_GRID_STUDY.txt'),'w'); fprintf(fid,'%s',study_dir); fclose(fid);
save(fullfile(study_dir,'started.mat'),'study_dir'); diary(fullfile(study_dir,'study.log')); cleanup=onCleanup(@() diary('off'));
old=fullfile(root,'results','20261107_111152_p2_v2_strategy_batch_pilot_strategy_training_f0197d58');
x=load(fullfile(old,'params.mat'),'cfg'); c=x.cfg;
c.study_root=study_dir; c.run_deadline=datenum(2026,11,9,18,48,0); c.resume_dir='';
c.predict=false; c.diagnose=false; c.pmf_file=''; c.model_file='';
a=load(fullfile(old,'templates.mat'),'templates'); probabilities=[.1,.2,.3,.4,.5]; templates=cell(1,5);
for j=1:5
    ix=find(cellfun(@(t) abs(t.p_vec(2)-probabilities(j))<1e-10,a.templates));
    if isempty(ix), templates{j}=build_source_entropy_partition(c.N,[.5 probabilities(j) .5 probabilities(j)],.1,c.source_samples,c.source_seed);
    else, templates{j}=a.templates{ix}; end
end
c.template_probabilities=probabilities;
c.templates_file=fullfile(study_dir,'five_level_templates.mat'); save(c.templates_file,'templates');
[x,y,z]=ndgrid(probabilities); P=[x(:),y(:),z(:)];
[a,b,d]=ndgrid([.1 .3 .5]); oldP=[a(:),b(:),d(:)];
[isold,oldix]=ismember(P,oldP,'rows'); names=cell(1,125);
for i=1:125
    if isold(i), names{i}=sprintf('combo_%02d',oldix(i)); else, names{i}=sprintf('grid_%03d',i); end
end
requirements=(.26:.005:.35)'; tolerance=.05; max_ber=.2;
save(fullfile(study_dir,'protocol.mat'),'P','names','isold','requirements','tolerance','max_ber','c');
fid=fopen(fullfile(study_dir,'README.txt'),'w');
fprintf(fid,'User approved 8 hours / 10 GiB / 178800 case-frames. Development 78400; confirmation 100000; smoke <=400.\n');
fprintf(fid,'Fixed amplitude, true-H sorted groups, label24, N1024. Mean-G requirements .26:.005:.35, BER<=.2 illustrative guard. Primary proxy uses old training global -25dBm scale.\n');
fprintf(fid,'Practical tolerance 5%% relative to three-level proxy. Paired new-channel uncertainty; inconclusive allowed. No DC or real service guarantee.\n'); fclose(fid);
% One smoke batch, all combinations, separate diagnostic environment.
s=c; s.strategy_p=P; s.strategy_names=names; s.num_channels=1; s.num_frames=1; s.future_split='diagnostic_a';
smoke_dir=run_p2_grid_batch(s);
S=readtable(fullfile(smoke_dir,'repetitions.csv')); assert(height(S)==125 && all(isfinite(S.ber)) && all(S.goodput_cp<=S.rate_cp+eps));
for i=1:125
    q=load(fullfile(smoke_dir,sprintf('raw_c1_s1_%s_shaped.mat',names{i})),'artifact');
    for g=1:3
        st=q.artifact.states{g};
        for b=1:4, assert(isempty(intersect(st.I{b},st.S{b})) && isempty(intersect(st.I{b},st.F{b})) && numel(st.I{b})==st.K(b)); end
    end
end
fprintf('SMOKE_PASS 125 configurations, actual partitions and metrics checked\n');
c.strategy_p=P(~isold,:); c.strategy_names=names(~isold); c.num_channels=20; c.num_frames=40; c.future_split='strategy_train';
training_dir=run_p2_grid_batch(c);
A=readtable(fullfile(old,'repetitions.csv')); A=A(startsWith(A.case_id,'combo_'),:);
B=readtable(fullfile(training_dir,'repetitions.csv')); T=[A;B]; assert(height(T)==2500);
writetable(T,fullfile(study_dir,'development_candidates.csv'));
v=load(fullfile(old,'frozen_training_policy.mat'),'policy'); policy=v.policy;
beta2=policy.k2*policy.scale_25dbm^2/2; beta4=policy.k4*3*policy.scale_25dbm^4/8;
coarse=startsWith(T.case_id,'combo_'); selected3=cell(numel(requirements),1); selected5=selected3;
for i=1:numel(requirements)
    a=p2_select_training_tradeoff(T(coarse,:),max_ber,requirements(i),beta2,beta4);
    b=p2_select_training_tradeoff(T,max_ber,requirements(i),beta2,beta4);
    selected3{i}=a.selected_case; selected5{i}=b.selected_case;
end
frozen=table(requirements,selected3,selected5); writetable(frozen,fullfile(study_dir,'frozen_choices.csv'));
save(fullfile(study_dir,'frozen_policy.mat'),'frozen','policy','beta2','beta4','training_dir');
fprintf('POLICY_FROZEN; beginning new independent confirmation domain\n');
c.strategy_p=P; c.strategy_names=names; c.future_split='strategy_test_v2'; c.purpose='strategy_test'; c.seed=8902; c.seed_roles.strategy_test=8902;
test_dir=run_p2_grid_batch(c);
save(fullfile(study_dir,'data_complete.mat'),'training_dir','test_dir','smoke_dir');
fprintf('DATA_COMPLETE %s\n',study_dir);
end
