function selection = select_auto_gf2_relation(axis_levels, axis_labels)
%SELECT_AUTO_GF2_RELATION Exhaustive GL(k,2) selection on protocol lambda grid.
    k = size(axis_labels, 2);
    if k > 3, error('v3:AutoRelationRange', 'Unit 0 supports at most 3 axis bits.'); end
    candidates = enumerate_gf2_invertible(k);
    lambda_grid = [-0.5 -0.25 0 0.25 0.5];
    e_axis = mean(axis_levels(:).^2);
    targets = cell(numel(lambda_grid), 1);
    for il = 1:numel(lambda_grid)
        t = exp(lambda_grid(il) * axis_levels(:).^2 / e_axis);
        targets{il} = t / sum(t);
    end
    best_score = [Inf Inf Inf]; best_T = []; best_p = [];
    opts = optimset('Display', 'off', 'MaxIter', 120, 'TolX', 1e-7);
    for ic = 1:numel(candidates)
        T = candidates{ic}; kl = zeros(numel(lambda_grid), 1); p_cell = cell(numel(lambda_grid), 1);
        for il = 1:numel(lambda_grid)
            fun = @(theta) local_kl(theta, axis_labels, T, targets{il});
            theta = fminsearch(fun, zeros(k, 1), opts);
            p = min(max(1 ./ (1 + exp(-theta(:))), 1e-4), 1 - 1e-4);
            [model, ~] = axis_pmf_from_latent(axis_labels, p, T);
            kl(il) = local_kl_pmf(targets{il}, model); p_cell{il} = p;
        end
        score = [mean(kl), max(kl), ic];
        if local_less(score, best_score), best_score = score; best_T = T; best_p = p_cell; end
    end
    selection = struct('T', best_T, 'lambda_axis', lambda_grid, ...
        'p_by_lambda', {best_p}, 'mean_kl', best_score(1), ...
        'max_kl', best_score(2), 'candidate_count', numel(candidates));
end

function v = local_kl(theta, labels, T, target)
    p = min(max(1 ./ (1 + exp(-theta(:))), 1e-4), 1 - 1e-4);
    [model, ~] = axis_pmf_from_latent(labels, p, T);
    v = local_kl_pmf(target, model);
end

function v = local_kl_pmf(target, model)
    v = sum(target .* log(max(target, realmin) ./ max(model, realmin)));
end

function tf = local_less(a, b)
    tf = (a(1) < b(1) - 1e-12) || (abs(a(1)-b(1)) <= 1e-12 && ...
        (a(2) < b(2) - 1e-12 || (abs(a(2)-b(2)) <= 1e-12 && a(3) < b(3))));
end
