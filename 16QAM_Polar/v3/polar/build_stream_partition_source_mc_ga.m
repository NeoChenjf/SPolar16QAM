function stream = build_stream_partition_source_mc_ga(N, p, sigma_design, n_samples, seed)
%BUILD_STREAM_PARTITION_SOURCE_MC_GA Estimate source-polar entropies for S.
    if nargin < 4 || isempty(n_samples), n_samples = 300; end
    if nargin >= 5 && ~isempty(seed)
        caller_rng = rng;
        rng_cleanup = onCleanup(@() rng(caller_rng));
        rng(seed, 'twister');
    end
    h2 = -p * log2(p) - (1-p) * log2(1-p);
    S_size = min(N, ceil(N * (1 - h2))); K = floor((N - S_size) / 2);
    if S_size == 0
        source_entropy = ones(N, 1);
    else
        source_llr = ones(N, 1) * log((1-p) / p);
        entropy_acc = zeros(N, 1); known_mask = true(N, 1);
        for is = 1:n_samples
            x = rand(N, 1) < p; u = polar_encoder(double(x));
            [~, L] = sc_decode_forced_full(source_llr, known_mask, u);
            prob1 = 1 ./ (1 + exp(max(min(L, 700), -700)));
            prob1 = min(max(prob1, eps), 1-eps);
            entropy_acc = entropy_acc - prob1 .* log2(prob1) - (1-prob1) .* log2(1-prob1);
        end
        source_entropy = entropy_acc / n_samples;
    end
    % |S| = N(1-H2(p)) counts the low-entropy, SC-predictable positions.
    [~, source_order] = sort(source_entropy, 'ascend'); S = sort(source_order(1:S_size));
    ga_reliability = GA(sigma_design, N).'; [~, ga_order] = sort(ga_reliability, 'descend');
    remain = ga_order(~ismember(ga_order, S)); I = sort(remain(1:K)); F = sort(remain(K+1:end));
    stream = struct('p',p,'h2',h2,'S',S(:),'I',I(:),'F',F(:),'S_size',S_size, ...
        'K',K,'F_size',numel(F),'construction','source-MC+GA','sigma_design',sigma_design, ...
        'source_entropy',source_entropy,'source_samples',n_samples);
    if exist('rng_cleanup', 'var'), clear rng_cleanup; end
end
