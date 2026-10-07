function stats = cluster_bootstrap_tv(frame_psym, model_psym, n_boot, seed)
%CLUSTER_BOOTSTRAP_TV Cluster bootstrap of TV(mean frame PMF, model PMF).
    if nargin < 3 || isempty(n_boot), n_boot = 1000; end
    if nargin >= 4 && ~isempty(seed), rng(seed, 'twister'); end
    if size(frame_psym, 1) ~= numel(model_psym)
        error('v3:ClusterPMFShape', 'frame_psym must be M-by-frames.');
    end
    n_frames = size(frame_psym, 2);
    if n_frames < 2, error('v3:ClusterPMFFrames', 'At least two independent frames are required.'); end
    model_psym = model_psym(:); model_psym = model_psym / sum(model_psym);
    empirical = mean(frame_psym, 2);
    tv_samples = zeros(n_boot, 1);
    for ib = 1:n_boot
        take = randi(n_frames, n_frames, 1);
        tv_samples(ib) = 0.5 * sum(abs(mean(frame_psym(:, take), 2) - model_psym));
    end
    tv_samples = sort(tv_samples);
    upper_index = max(1, min(n_boot, ceil(0.95 * n_boot)));
    stats = struct('empirical_psym', empirical, ...
        'tv_point', 0.5 * sum(abs(empirical - model_psym)), ...
        'tv_upper95', tv_samples(upper_index), 'n_frames', n_frames, 'n_boot', n_boot);
end
