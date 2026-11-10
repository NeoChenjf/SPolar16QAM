function test_p2_candidate_validation_seed()
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    rejected={'seen_first','unseen_first','strategy_test','diagnostic_a','diagnostic_b','unknown'};
    for k=1:numel(rejected)
        caught=false; try,p2_candidate_validation_seed(rejected{k},1,0,0,0,'channel');
        catch e,caught=strcmp(e.identifier,'validationseed:DisallowedSplit');end
        assert(caught,'Touched or diagnostic split was not rejected.');
    end
    fresh={'pmf_train','model_train','seen_first_v2','unseen_first_v2', ...
        'seen_retest','unseen_retest','strategy_train','strategy_test_v2'};
    v=zeros(size(fresh));
    for k=1:numel(fresh), v(k)=p2_candidate_validation_seed(fresh{k},1,0,0,0,'channel'); end
    assert(numel(unique(v))==numel(v));
    fprintf('Rejected %d touched/diagnostic splits; %d candidate domains distinct.\n',numel(rejected),numel(v));
end
