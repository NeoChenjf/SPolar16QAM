function stream = build_stream_partition_bsc_ga(N, p, sigma_design, s_mode)
%BUILD_STREAM_PARTITION_BSC_GA BSC selects S; AWGN GA selects I/F.
    validateattributes(N, {'numeric'}, {'scalar','integer','>=',2});
    validateattributes(p, {'numeric'}, {'scalar','real','finite','>',0,'<',1});
    validateattributes(sigma_design, {'numeric'}, {'scalar','real','finite','positive'});
    if nargin < 4 || isempty(s_mode), s_mode = 'reliable'; end
    h2 = -p * log2(p) - (1-p) * log2(1-p);
    S_size = min(N, ceil(N * (1 - h2)));
    K = floor((N - S_size) / 2);
    q = min(p, 1-p);
    bsc_reliability = bsc_bhattacharyya(q, N);
    switch s_mode
        case 'reliable', [~, bsc_order] = sort(bsc_reliability, 'descend');
        case 'unreliable', [~, bsc_order] = sort(bsc_reliability, 'ascend');
        otherwise, error('v3:BSCSelection', 's_mode must be reliable or unreliable.');
    end
    S = sort(bsc_order(1:S_size));
    ga_reliability = GA(sigma_design, N).';
    [~, ga_order] = sort(ga_reliability, 'descend');
    ga_without_S = ga_order(~ismember(ga_order, S));
    I = sort(ga_without_S(1:K));
    F = sort(ga_without_S(K+1:end));
    stream = struct('p', p, 'q_bsc', q, 'h2', h2, 'S', S(:), 'I', I(:), 'F', F(:), ...
        'S_size', S_size, 'K', K, 'F_size', numel(F), ...
        'construction', ['BSC(' s_mode ')+GA'], 'sigma_design', sigma_design, ...
        'bsc_reliability', bsc_reliability, 'ga_reliability', ga_reliability);
end
