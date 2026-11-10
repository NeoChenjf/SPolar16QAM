function run_p2_grid_continue(study_dir)
% Approved additional six hours; preserve all previously committed cells.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
if nargin<1, study_dir=strtrim(fileread(fullfile(root,'results','LATEST_P2_GRID_STUDY.txt'))); end
assert(~isfile(fullfile(study_dir,'extension_started.mat')),'Continuation already started; inspect state before retry.');
started=now; budget_start=datenum(2026,11,9,21,34,0); run_deadline=budget_start+5/24; hard_deadline=budget_start+6/24;
assert(now<run_deadline); save(fullfile(study_dir,'extension_started.mat'),'started','budget_start','run_deadline','hard_deadline');
a=load(fullfile(study_dir,'protocol.mat')); c=a.c; c.run_deadline=run_deadline; c.resume_dir='';
c.num_frames=40; c.num_channels=1; c.future_split='strategy_train';
previous=fullfile(study_dir,'20261109_115237_p2_v2_strategy_batch_pilot_strategy_training_4d7664df');
B=readtable(fullfile(previous,'repetitions.csv')); assert(height(B)==953 && all(B.frames==40));
assert(all(arrayfun(@(ch) sum(B.channel==ch)==98,1:9)) && sum(B.channel==10)==71);
assert(~any(B.channel>10));
fullnames=strcat(a.names(~a.isold),'_shaped');
assert(numel(unique(fullnames))==98 && all(ismember(B.case_id,fullnames)));
missing=~ismember(strcat(a.names,'_shaped'),B.case_id(B.channel==10)) & ~a.isold';
missing=missing(:); assert(sum(missing)==27);
c.strategy_p=a.P(missing,:); c.strategy_names=a.names(missing); c.realization_offset=9;
segment10=run_p2_grid_batch(c);
D=readtable(fullfile(segment10,'repetitions.csv')); assert(height(D)==27); D.channel=D.channel+9;
c.strategy_p=a.P(~a.isold,:); c.strategy_names=a.names(~a.isold); c.num_channels=10; c.realization_offset=10;
segment11_20=run_p2_grid_batch(c);
E=readtable(fullfile(segment11_20,'repetitions.csv')); assert(height(E)==980); E.channel=E.channel+10;
old=fullfile(root,'results','20261107_111152_p2_v2_strategy_batch_pilot_strategy_training_f0197d58');
A=readtable(fullfile(old,'repetitions.csv')); A=A(startsWith(A.case_id,'combo_'),:);
T=[A;B;D;E]; assert(height(T)==2500 && height(unique(T(:,{'channel','case_id'})))==2500);
assert(all(arrayfun(@(ch) sum(T.channel==ch)==125,1:20)));
writetable(T,fullfile(study_dir,'development_candidates.csv'));
training_segments={previous,segment10,segment11_20}; training_offsets=[0,9,10];
save(fullfile(study_dir,'training_segments.mat'),'training_segments','training_offsets');
v=load(fullfile(old,'frozen_training_policy.mat'),'policy'); policy=v.policy;
beta2=policy.k2*policy.scale_25dbm^2/2; beta4=policy.k4*3*policy.scale_25dbm^4/8;
requirements=a.requirements; max_ber=a.max_ber; coarse=startsWith(T.case_id,'combo_');
selected3=cell(numel(requirements),1); selected5=selected3;
for i=1:numel(requirements)
    u=p2_select_training_tradeoff(T(coarse,:),max_ber,requirements(i),beta2,beta4);
    v=p2_select_training_tradeoff(T,max_ber,requirements(i),beta2,beta4);
    assert(strcmp(u.status,'selected') && strcmp(v.status,'selected'));
    selected3{i}=u.selected_case; selected5{i}=v.selected_case;
end
frozen=table(requirements,selected3,selected5); writetable(frozen,fullfile(study_dir,'frozen_choices.csv'));
training_dir=study_dir; save(fullfile(study_dir,'frozen_policy.mat'),'frozen','policy','beta2','beta4','training_dir');
fprintf('POLICY_FROZEN; continuation training complete; new independent confirmation begins\n');
c.strategy_p=a.P; c.strategy_names=a.names; c.future_split='strategy_test_v2'; c.purpose='strategy_test'; c.seed=8902; c.seed_roles.strategy_test=8902;
c.num_channels=20; c.realization_offset=0;
test_dir=run_p2_grid_batch(c);
smoke_dir=fullfile(study_dir,'20261109_115209_p2_v2_strategy_batch_pilot_strategy_training_b3f21310');
save(fullfile(study_dir,'data_complete.mat'),'training_dir','test_dir','smoke_dir');
fprintf('DATA_COMPLETE %s\n',study_dir);
end
