function stats = paired_cluster_difference_ci(frame_low, frame_high, n_boot, seed)
%PAIRED_CLUSTER_DIFFERENCE_CI One-sided paired frame-bootstrap CI for high-low.
    frame_low = frame_low(:); frame_high = frame_high(:);
    if numel(frame_low) ~= numel(frame_high) || numel(frame_low) < 2 || ...
            any(~isfinite(frame_low)) || any(~isfinite(frame_high))
        error('v3:PairedFrames', 'Inputs must be equal finite vectors with at least two frames.');
    end
    if nargin < 3 || isempty(n_boot), n_boot = 2000; end
    if nargin >= 4 && ~isempty(seed), rng(seed, 'twister'); end
    difference = frame_high - frame_low;
    n_frames = numel(difference);
    samples = zeros(n_boot, 1);
    for ib = 1:n_boot
        take = randi(n_frames, n_frames, 1);
        samples(ib) = mean(difference(take));
    end
    samples = sort(samples);
    lower_index = max(1, min(n_boot, floor(0.05 * n_boot)));
    stats = struct('mean_difference', mean(difference), ...
        'lower95', samples(lower_index), 'n_frames', n_frames, ...
        'n_boot', n_boot, 'frame_difference', difference);
end
