function value = p2_paired_seed(purpose, seed, realization, snr_index, frame, group, role)
%P2_PAIRED_SEED Role-separated deterministic seed for common-environment runs.
% Candidate IDs are deliberately excluded. This defines distinct seed values,
% not a mathematical proof of statistical independence of PRNG streams.
    if ~(ischar(role) && isrow(role))
        error('pairedseed:InvalidRole','Role must be a character vector.');
    end
    if ~(isnumeric(group) && isscalar(group) && isreal(group) && isfinite(group) && group==fix(group))
        error('pairedseed:InvalidGroup','Group must be an integer.');
    end
    if strcmp(purpose,'power_validation') && any(seed==[8211,8212])
        error('pairedseed:ReservedSeed','Seeds 8211/8212 are reserved for strategy roles in this mapping.');
    end
    switch role
        case 'channel'
            if ~(group==0 && snr_index==0 && frame==0)
                error('pairedseed:InvalidKey','Channel requires group, SNR index and frame zero.');
            end
            slot=0; variant=0;
        case 'noise'
            if ~(group==0 && snr_index>=1 && frame>=1)
                error('pairedseed:InvalidKey','Noise requires group zero and positive SNR/frame.');
            end
            slot=0; variant=0;
        case {'payload','auxiliary','donor'}
            if ~(group>=1 && group<=3 && snr_index>=1 && frame>=1)
                error('pairedseed:InvalidKey','Data role requires group 1..3 and positive SNR/frame.');
            end
            if strcmp(role,'payload'), slot=group; variant=0;
            elseif strcmp(role,'auxiliary'), slot=group+3; variant=0;
            else, slot=group+3; variant=1; end
        otherwise
            error('pairedseed:InvalidRole','Unknown role.');
    end
    % Reserve disjoint slots in the inherited seed namespace for strategy roles.
    % These purpose/seed aliases are not used by existing completed P2 jobs.
    base_purpose=purpose; base_seed=seed;
    if strcmp(purpose,'strategy_training')
        assert(seed==9211,'pairedseed:InvalidRoleSeed','Unregistered strategy training seed.');
        base_purpose='power_validation'; base_seed=8211;
    elseif strcmp(purpose,'strategy_test')
        assert(seed==9212,'pairedseed:InvalidRoleSeed','Unregistered strategy test seed.');
        base_purpose='power_validation'; base_seed=8212;
    end
    value=2*double(p2_seed(base_purpose,base_seed,realization,snr_index,frame,slot))+variant;
    assert(value<=2^32-1,'pairedseed:SeedOverflow','Seed exceeds MATLAB twister range.');
end
