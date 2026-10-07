function [p_axis, z_labels] = axis_pmf_from_latent(axis_labels, p_latent, T)
%AXIS_PMF_FROM_LATENT Enumerate PMF induced by z~prod Bernoulli(p), b=Tz.
    k = size(axis_labels, 2);
    p_latent = p_latent(:);
    if numel(p_latent) ~= k || any(~isfinite(p_latent)) || any(p_latent <= 0 | p_latent >= 1)
        error('v3:InvalidLatentP', 'p_latent must have one entry in (0,1) per axis bit.');
    end
    if isempty(T), T = eye(k); end
    Tinv = gf2_inverse(T);
    nlevels = size(axis_labels, 1);
    z_labels = zeros(nlevels, k);
    p_axis = zeros(nlevels, 1);
    for idx = 1:nlevels
        z = mod(Tinv * axis_labels(idx, :).', 2);
        z_labels(idx, :) = z.';
        p_axis(idx) = prod((p_latent .^ z) .* ((1 - p_latent) .^ (1 - z)));
    end
    p_axis = p_axis / sum(p_axis);
end
