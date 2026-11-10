function test_p2_future_draft_cases()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    controls={'shaped','random_s','donor_s'};
    A=p2_future_draft_cases([.3 .3 .3;.3 .1 .5],{'seen','unseen'},controls); assert(numel(A)==6);
    B=p2_future_draft_cases([.3 .3 .3],{'seen'},controls); assert(numel(B)==3);
    [x,y,z]=ndgrid([.1 .3 .5]); p=[x(:),y(:),z(:)]; names=arrayfun(@(i) sprintf('combo_%02d',i),1:27,'UniformOutput',false);
    p=[p;.5 .3 .1]; names=[names,{'bad_channel_energy_only'}];
    E=p2_future_draft_cases(p,names,{'shaped'}); assert(numel(E)==28);
    d=fullfile(root,'results','20261106_170217_p2_common_env_pilot_strategy_training_b657112d');
    prior=load(fullfile(d,'cases.mat'),'cases'); assert(isequal(E,prior.cases), ...
        'Draft 27 combinations and energy-only baseline must match existing case IDs and p vectors.');
    U=p2_future_draft_cases([.5 .5 .5],{'uniform'},controls); assert(numel(U)==1 && strcmp(U(1).kind,'shaped'));
    caught=false; try,p2_future_draft_cases([.3 .3 .3],{'x'},{'random_s','shaped'});
    catch e,caught=strcmp(e.identifier,'draftcases:InvalidControls'); end; assert(caught);
    fprintf('A=%d B/C/D=%d E/F=%d, uniform dedup and control-order checks passed\n',numel(A),numel(B),numel(E));
end

