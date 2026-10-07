function fit = fit_axis_latent_p(axis_labels, target_axis, T)
%FIT_AXIS_LATENT_P Fit independent latent Bernoulli probabilities to an axis PMF.
    target_axis = target_axis(:);
    if size(axis_labels, 1) ~= numel(target_axis) || any(~isfinite(target_axis)) || ...
            any(target_axis < 0) || sum(target_axis) <= 0
        error('v3:AxisTarget', 'target_axis must be finite, nonnegative and match axis_labels.');
    end
    target_axis = target_axis / sum(target_axis);
    k = size(axis_labels, 2);
    if isempty(T), T = eye(k); end
    gf2_inverse(T);

    lower = 1e-4; upper = 1 - lower;
    if max(target_axis) - min(target_axis) <= 1e-14
        p = 0.5 * ones(k, 1);
        [model_axis, ~] = axis_pmf_from_latent(axis_labels, p, T);
        fit = struct('p', p, 'model_axis', model_axis, 'target_axis', target_axis, ...
            'kl_target_model', local_kl(target_axis, model_axis), ...
            'tv_target_model', 0.5 * sum(abs(target_axis - model_axis)), ...
            'objective', 0, 'exitflag', 1, 'start_index', 1, 'n_starts', 1, ...
            'lower_bound', lower, 'upper_bound', upper);
        return;
    end
    starts = [zeros(k, 1), ones(k, 1), -ones(k, 1)];
    if k > 1
        starts = [starts, 0.75 * eye(k), -0.75 * eye(k)];
    end
    options = optimset('Display', 'off', 'MaxFunEvals', 5000, 'MaxIter', 2000, ...
        'TolFun', 1e-12, 'TolX', 1e-10);
    best = struct('objective', Inf, 'theta', [], 'exitflag', -Inf, 'start_index', NaN);
    for is = 1:size(starts, 2)
        [theta, objective, exitflag] = fminsearch(@local_objective, starts(:, is), options);
        if objective < best.objective
            best = struct('objective', objective, 'theta', theta, ...
                'exitflag', exitflag, 'start_index', is);
        end
    end
    p = lower + (upper - lower) ./ (1 + exp(-best.theta));
    [model_axis, ~] = axis_pmf_from_latent(axis_labels, p, T);
    kl = local_kl(target_axis, model_axis);
    tv = 0.5 * sum(abs(target_axis - model_axis));
    fit = struct('p', p, 'model_axis', model_axis, 'target_axis', target_axis, ...
        'kl_target_model', kl, 'tv_target_model', tv, 'objective', best.objective, ...
        'exitflag', best.exitflag, 'start_index', best.start_index, ...
        'n_starts', size(starts, 2), 'lower_bound', lower, 'upper_bound', upper);

    function value = local_objective(theta)
        candidate_p = lower + (upper - lower) ./ (1 + exp(-theta));
        candidate = axis_pmf_from_latent(axis_labels, candidate_p, T);
        value = local_kl(target_axis, candidate);
    end
end

function value = local_kl(target, model)
    active = target > 0;
    value = max(0, sum(target(active) .* log(target(active) ./ max(model(active), realmin))));
end
