function run_p2_v2_e1_after_pmf(pmf_dir)
% Run E1 calibration and independent seen/unseen tests, using PMF completed first.
% Budget: 18000 case-frames; shared physical seeds are selected by split.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    x=load(fullfile(pmf_dir,'params.mat'),'cfg'); base=x.cfg;
    pmf_file=fullfile(pmf_dir,'frozen_exploratory_pmf.mat'); assert(isfile(pmf_file));
    base.mode='pilot'; base.num_frames=40; base.num_channels=10; base.purpose='model_calibration';
    base.seed=8401; base.future_split='model_train'; base.strategy_p=[.3 .3 .3];
    base.strategy_names={'seen'}; base.heldout_p=[.3 .1 .5]; base.predict=true;
    base.pmf_file=pmf_file; base.model_file=''; base.resume_dir='';
    b=run_p2_v2_batch(base); model_file=p2_common_freeze_model(b);
    fprintf('E1_CALIBRATION=%s\nE1_MODEL=%s\n',b,model_file);
    assert(now < datenum(2026,11,7,15,40,0),'Analysis reserve reached before test.');
    base.num_channels=20; base.purpose='test_seen'; base.seed=8501;
    base.future_split='seen_first_v2'; base.model_file=model_file;
    c=run_p2_v2_batch(base); fprintf('E1_SEEN=%s\n',c);
    assert(now < datenum(2026,11,7,15,40,0),'Analysis reserve reached before unseen test.');
    base.purpose='test_unseen'; base.seed=8601; base.future_split='unseen_first_v2';
    base.strategy_p=[.3 .1 .5]; base.strategy_names={'unseen'};
    d=run_p2_v2_batch(base); fprintf('E1_UNSEEN=%s\n',d);
    run_p2_v2_pmf_report(pmf_dir);
    run_p2_v2_e1_report(c,d);
    for dirpath={c,d}
        T=readtable(fullfile(dirpath{1},'repetitions.csv'));
        R=p2_evaluate_predictions_checked(T); writetable(R,fullfile(dirpath{1},'prediction_evaluation.csv'));
    end
end


