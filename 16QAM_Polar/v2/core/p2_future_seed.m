function value = p2_future_seed(split,realization,snr_index,frame,group,role)
%P2_FUTURE_SEED Candidate new namespace; not registered for formal execution.
% Candidate identities are omitted so paired schemes share their inputs.
% Distinct numeric keys alone do not prove independence of PRNG streams.
    splits={'pmf_train','model_train','seen_first','unseen_first', ...
        'seen_retest','unseen_retest','strategy_train','strategy_test','diagnostic_a','diagnostic_b','seen_first_v2','unseen_first_v2','strategy_test_v2'};
    assert(ischar(split) && isrow(split),'futureseed:InvalidSplit','Split must be a character vector.');
    stream=find(strcmp(split,splits));
    assert(isscalar(stream),'futureseed:InvalidSplit','Unknown proposed split.');
    validateattributes(realization,{'numeric'},{'scalar','real','finite','integer','>=',1,'<=',31});
    validateattributes(snr_index,{'numeric'},{'scalar','real','finite','integer','>=',0,'<=',15});
    validateattributes(frame,{'numeric'},{'scalar','real','finite','integer','>=',0,'<=',8191});
    validateattributes(group,{'numeric'},{'scalar','real','finite','integer','>=',0,'<=',3});
    assert(ischar(role) && isrow(role),'futureseed:InvalidRole','Role must be a character vector.');
    switch role
        case 'channel'
            assert(snr_index==0 && frame==0 && group==0,'futureseed:InvalidKey','Channel requires zero SNR/frame/group.'); slot=0;
        case 'noise'
            assert(snr_index>=1 && frame>=1 && group==0,'futureseed:InvalidKey','Noise requires positive SNR/frame and zero group.'); slot=1;
        case 'payload'
            assert(snr_index>=1 && frame>=1 && group>=1,'futureseed:InvalidKey','Payload requires positive SNR/frame/group.'); slot=1+group;
        case 'auxiliary'
            assert(snr_index>=1 && frame>=1 && group>=1,'futureseed:InvalidKey','Auxiliary requires positive SNR/frame/group.'); slot=4+group;
        case 'donor'
            assert(snr_index>=1 && frame>=1 && group>=1,'futureseed:InvalidKey','Donor requires positive SNR/frame/group.'); slot=7+group;
        otherwise
            error('futureseed:InvalidRole','Unknown role.');
    end
    value=3221225472 + (stream-1)*67108864 + (realization-1)*2097152 + ...
        snr_index*131072 + frame*16 + slot;
    assert(value<=2^32-1,'futureseed:Overflow','Seed outside uint32 domain.');
end



