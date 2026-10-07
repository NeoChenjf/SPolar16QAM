function test_energy_tradeoff_recovery(source)
% Simulate one incomplete block, recover to NEW output, compare every row.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    original=load(fullfile(source,'results.mat'),'rep','frames');
    fixture=tempname; mkdir(fixture); cleanup=onCleanup(@() rmdir(fixture,'s'));
    copyfile(fullfile(source,'partial'),fullfile(fixture,'partial'));
    copyfile(fullfile(source,'source_snapshot'),fullfile(fixture,'source_snapshot'));
    copyfile(fullfile(source,'params.mat'),fixture);
    path=fullfile(fixture,'partial','completed_blocks.mat'); state=load(path);
    state.blocks{2,3}=[]; save(path,'-struct','state');
    out=run_16qam_energy_tradeoff('smoke',fixture); recovered=load(fullfile(out,'results.mat'),'rep','frames');
    assert(isequal(original.rep,recovered.rep)&&isequal(original.frames,recovered.frames));
    state.cfg.num_frames=99; save(path,'-struct','state');
    try
        run_16qam_energy_tradeoff('smoke',fixture);
    catch err
        assert(strcmp(err.identifier,'energy:ResumeMismatch'));
        fprintf('PASS partial-block recovery, exact rows, mismatched parameter rejection.\n'); return;
    end
    error('test:ExpectedFailure','Mismatched resume accepted.');
end
