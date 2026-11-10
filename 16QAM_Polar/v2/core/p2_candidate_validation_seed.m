function value = p2_candidate_validation_seed(split,realization,snr_index,frame,group,role)
%P2_CANDIDATE_VALIDATION_SEED Reject namespaces touched by diagnostic RNG use.
% This is a candidate guard, not formal registration or proof of independence.
    allowed={'pmf_train','model_train','seen_first_v2','unseen_first_v2', ...
        'seen_retest','unseen_retest','strategy_train','strategy_test_v2'};
    assert(ischar(split) && isrow(split) && any(strcmp(split,allowed)), ...
        'validationseed:DisallowedSplit','Split is used by diagnostics or not proposed for validation.');
    value=p2_future_seed(split,realization,snr_index,frame,group,role);
end
