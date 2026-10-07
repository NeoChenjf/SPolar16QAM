function LLR = llr_gray_qam_latent_lse(y, qam, model, sigma)
%LLR_GRAY_QAM_LATENT_LSE Exact prior-aware MAP LLRs for latent z labels.
% LLR convention: log P(z=0|y)/P(z=1|y), order [I latent, Q latent].
    validateattributes(sigma, {'numeric'}, {'scalar','real','finite','positive'});
    y = y(:); psym = model.psym(:);
    if numel(psym) ~= qam.M || any(psym < 0) || sum(psym) <= 0
        error('v3:InvalidSymbolPMF', 'model.psym must be a nonnegative M-vector with positive sum.');
    end
    psym = psym / sum(psym);
    zlabels = model.z_labels;
    if ~isequal(size(zlabels), [qam.M, qam.m])
        error('v3:LatentLabelShape', 'model.z_labels must be M-by-log2(M).');
    end
    logp = log(max(psym, realmin));
    LLR = zeros(numel(y) * qam.m, 1);
    denom = 2 * sigma^2;
    for iy = 1:numel(y)
        metric = logp - abs(y(iy) - qam.constellation).^2 / denom;
        for k = 1:qam.m
            L0 = local_lse(metric(zlabels(:, k) == 0));
            L1 = local_lse(metric(zlabels(:, k) == 1));
            LLR((iy - 1) * qam.m + k) = L0 - L1;
        end
    end
end

function v = local_lse(a)
    amax = max(a); v = amax + log(sum(exp(a - amax)));
end
