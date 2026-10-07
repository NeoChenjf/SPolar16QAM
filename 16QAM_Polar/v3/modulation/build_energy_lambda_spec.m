function built = build_energy_lambda_spec(qam, lambda, relation_I, relation_Q)
%BUILD_ENERGY_LAMBDA_SPEC Fit the latent-axis model to exp(lambda*|x|^2).
    validateattributes(lambda, {'numeric'}, {'scalar','real','finite'});
    if nargin < 3 || isempty(relation_I), relation_I = frozen_gray_pam_relation(qam.mI); end
    if nargin < 4 || isempty(relation_Q), relation_Q = frozen_gray_pam_relation(qam.mQ); end
    gf2_inverse(relation_I); gf2_inverse(relation_Q);

    energy_I = (qam.levelsI / qam.uniform_scale).^2;
    energy_Q = (qam.levelsQ / qam.uniform_scale).^2;
    target_I = local_boltzmann(lambda, energy_I);
    target_Q = local_boltzmann(lambda, energy_Q);
    fit_I = fit_axis_latent_p(qam.labelsI, target_I, relation_I);
    fit_Q = fit_axis_latent_p(qam.labelsQ, target_Q, relation_Q);
    model = build_qam_model_pmf(qam, fit_I.p, relation_I, fit_Q.p, relation_Q);
    target_psym = kron(target_I, target_Q);
    target_psym = target_psym / sum(target_psym);
    kl = local_kl(target_psym, model.psym);
    tv = 0.5 * sum(abs(target_psym - model.psym));
    if kl <= 1e-10 && tv <= 1e-8
        status = 'exact';
    elseif kl <= 2e-2 && tv <= 5e-2
        status = 'approximate-pass';
    else
        status = 'fail';
    end
    energy = abs(qam.constellation).^2;
    built = struct('source', 'energy_lambda', 'lambda', lambda, ...
        'pI', fit_I.p, 'pQ', fit_Q.p, 'relation_I', relation_I, ...
        'relation_Q', relation_Q, 'target_axis_I', target_I, ...
        'target_axis_Q', target_Q, 'target_psym', target_psym, ...
        'model_psym', model.psym, 'kl_target_model', kl, ...
        'tv_target_model', tv, 'match_status', status, ...
        'rf_energy_proxy_target', sum(target_psym .* energy), ...
        'rf_energy_proxy_model', sum(model.psym .* energy), ...
        'fit_I', fit_I, 'fit_Q', fit_Q);
end

function pmf = local_boltzmann(lambda, energy)
    logw = lambda * energy(:);
    logw = logw - max(logw);
    pmf = exp(logw);
    pmf = pmf / sum(pmf);
end

function value = local_kl(target, model)
    active = target > 0;
    value = max(0, sum(target(active) .* log(target(active) ./ max(model(active), realmin))));
end
