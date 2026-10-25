function state = p2_prepare_state(template, snr_db, kind, reference)
%P2_PREPARE_STATE Explicit current S/I/F; controls never silently reselect I.
% random_s/donor_s preserve the original I/S/F and receiver free-bit mask.
    if nargin < 4, reference = []; end
    assert(any(strcmp(kind, {'shaped','same_k_i','native','random_s','donor_s'})), 'Unknown control.');
    N = template.N;
    [~, order] = sort(GA(sqrt(1/(2*10^(snr_db/10))), N), 'descend');
    state = template; state.kind = kind;
    state.source_fingerprint=template.fingerprint;
    state.communication_snr_db=snr_db;
    for b = 1:4
        if strcmp(kind,'same_k_i')
            assert(~isempty(reference) && reference.N == N);
            state.S{b} = zeros(0,1); state.I{b} = reference.I{b};
            state.K(b) = numel(reference.I{b}); state.p_vec(b) = .5;
        else
            remaining = order(~ismember(order, template.S{b}));
            state.I{b} = sort(remaining(1:template.K(b))); state.I{b}=state.I{b}(:);
        end
        state.F{b} = setdiff((1:N)', [state.S{b};state.I{b}]);
        state.S_size(b) = numel(state.S{b});
        state.F_size(b) = numel(state.F{b});
        all_indices = [state.S{b};state.I{b};state.F{b}];
        assert(numel(all_indices)==N && numel(unique(all_indices))==N);
        assert(numel(state.I{b})==state.K(b));
    end
    state.decoder_free_count=state.K+state.S_size;
    state.fingerprint = sprintf('N%d_K%s_',N,sprintf('%d-',state.K));
    for b=1:4
        state.fingerprint=[state.fingerprint sprintf('b%dS%sI%s;',b, ...
            sprintf('%d,',state.S{b}),sprintf('%d,',state.I{b}))]; %#ok<AGROW>
    end
end
