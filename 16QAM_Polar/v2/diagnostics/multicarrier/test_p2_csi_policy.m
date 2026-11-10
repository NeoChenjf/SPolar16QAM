function test_p2_csi_policy()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    d=fullfile(root,'results','20261106_170217_p2_common_env_pilot_strategy_training_b657112d');
    p=p2_train_csi_policy(d,.2,.2,1,1);
    assert(numel(p.bins{1})==1 && numel(p.bins{2})==1);
    for b=1:2
        ch=p.bins{b}(1); q=load(fullfile(d,sprintf('raw_c%d_s1_combo_01_shaped.mat',ch)),'artifact');
        result=p2_apply_csi_policy(p,q.artifact.h); assert(result.bin==b);
        assert(strcmp(result.selected_case,p.selections{b}.selected_case));
    end
    q=struct('status','exploratory_not_formal','n_sc',4,'pivot',1, ...
        'selections',{{struct('status','no_feasible','selected_case',''), ...
        struct('status','selected','selected_case','combo')}});
    out=p2_apply_csi_policy(q,1); assert(out.bin==1 && strcmp(out.status,'no_feasible') && isempty(out.selected_case));
    out=p2_apply_csi_policy(q,2); assert(out.bin==2 && strcmp(out.selected_case,'combo'));
    caught=false; try, p2_apply_csi_policy(q,nan); catch e, caught=strcmp(e.identifier,'csipolicy:InvalidInput'); end
    assert(caught);
end
