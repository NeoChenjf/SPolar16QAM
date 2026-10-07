function stream = build_stream_partition_ga(N, p, sigma_design)
%BUILD_STREAM_PARTITION_GA Approximate S/I/F partition using v2 GA ordering.
% S is selected by H_2(p); I is the next equally sized payload block.
    validateattributes(N, {'numeric'}, {'scalar','integer','>=',2});
    validateattributes(p, {'numeric'}, {'scalar','real','finite','>',0,'<',1});
    validateattributes(sigma_design, {'numeric'}, {'scalar','real','finite','positive'});
    if abs(log2(N) - round(log2(N))) > eps
        error('v3:PolarLength', 'N must be a power of two.');
    end
    h2 = -p * log2(p) - (1-p) * log2(1-p);
    S_size = min(N, ceil(N * (1 - h2)));
    K = floor((N - S_size) / 2);
    reliability = GA(sigma_design, N);
    [~, ordered] = sort(reliability, 'descend');
    S = sort(ordered(1:S_size));
    I = sort(ordered(S_size+1:S_size+K));
    F = sort(ordered(S_size+K+1:end));
    stream = struct('p', p, 'h2', h2, 'S', S(:), 'I', I(:), 'F', F(:), ...
        'S_size', S_size, 'K', K, 'F_size', numel(F), ...
        'construction', 'GA-approximate', 'sigma_design', sigma_design, ...
        'reliability', reliability(:));
end
