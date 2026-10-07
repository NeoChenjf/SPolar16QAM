function summary = run_gray_qam_energy_smoke()
%RUN_GRAY_QAM_ENERGY_SMOKE Validate lambda-to-energy monotonicity for all v3 QAM orders.
    root = fileparts(mfilename('fullpath')); addpath(root); setup_paths;
    cfg = config();
    cfg.N = 256; cfg.num_frames = 40; cfg.seed = 20260902;
    cfg.snr_mode = 'fixed_n0'; cfg.force_nonzero_payload = false;
    cfg.collect_frame_pmf = true; cfg.source_construction = 'source_mc_ga';
    cfg.source_mc_samples = 120;
    Ms = [8 16 32 64]; lambdas = [0 0.25 0.5]; snr_dB = 120;
    n_boot = 2000; run_tag = 'energy_lambda_smoke';
    result_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' run_tag]);
    if ~exist(result_dir, 'dir'), mkdir(result_dir); end
    diary(fullfile(result_dir, 'run_log.txt')); diary on;
    diary_cleanup = onCleanup(@() diary('off'));
    progress_path = fullfile(result_dir, 'progress_log.txt');
    local_log(progress_path, sprintf('START %s', datestr(now, 31)));

    preflight_rows = cell(numel(Ms) * numel(lambdas), 7); preflight_index = 0;
    for im = 1:numel(Ms)
        qam = build_cartesian_gray_qam(Ms(im)); previous_energy = -Inf;
        for il = 1:numel(lambdas)
            built = build_energy_lambda_spec(qam, lambdas(il));
            preflight_index = preflight_index + 1;
            monotonic_from_previous = il == 1 || built.rf_energy_proxy_model > previous_energy;
            preflight_rows(preflight_index, :) = {Ms(im), lambdas(il), built.match_status, ...
                built.kl_target_model, built.tv_target_model, ...
                built.rf_energy_proxy_model, monotonic_from_previous};
            if strcmp(built.match_status, 'fail') || ~monotonic_from_previous
                error('v3:EnergyPreflight', ...
                    'Energy model preflight failed for M=%d lambda=%.6g.', Ms(im), lambdas(il));
            end
            previous_energy = built.rf_energy_proxy_model;
        end
    end
    preflight_table = cell2table(preflight_rows, 'VariableNames', ...
        {'M','lambda','match_status','KL_target_model','TV_target_model', ...
        'E_model','monotonic_from_previous'});
    writetable(preflight_table, fullfile(result_dir, 'model_preflight.csv'));

    results = cell(numel(Ms), numel(lambdas));
    rows = cell(numel(Ms) * numel(lambdas), 19); row_index = 0;
    for im = 1:numel(Ms)
        M = Ms(im); qam = build_cartesian_gray_qam(M);
        for il = 1:numel(lambdas)
            lambda = lambdas(il);
            local_log(progress_path, sprintf('START M=%d lambda=%.6g', M, lambda));
            spec = struct('source', 'energy_lambda', 'lambda', lambda);
            result = sim_shaped_polar_gray_qam(M, spec, snr_dB, cfg);
            result.result_dir = result_dir;
            pmf_stats = cluster_bootstrap_tv(result.frame_psym(:, :, 1), ...
                result.model_psym, 1000, cfg.seed + 100 * M + il);
            result.pmf_cluster = pmf_stats;
            results{im, il} = result;
            local_write_pmf_csv(fullfile(result_dir, ...
                sprintf('M%d_lambda_%s_pmf.csv', M, local_lambda_tag(lambda))), ...
                qam, result.target_psym, result.model_psym, pmf_stats.empirical_psym);
            row_index = row_index + 1;
            rows(row_index, :) = {M, lambda, result.pmf_validation, ...
                result.kl_target_model, result.tv_target_model, ...
                result.rf_energy_proxy_target, result.rf_energy_proxy_model, ...
                result.rf_energy_proxy_empirical, pmf_stats.tv_point, ...
                pmf_stats.tv_upper95, result.R_code, result.R_bpcu, ...
                local_vector_text(result.axis_I.p), local_vector_text(result.axis_Q.p), ...
                result.shaping_meta.fit_I.exitflag, result.shaping_meta.fit_Q.exitflag, ...
                result.shaping_meta.fit_I.objective, result.shaping_meta.fit_Q.objective, ...
                pmf_stats.tv_upper95 <= 0.10};
            local_log(progress_path, sprintf(['DONE M=%d lambda=%.6g status=%s ' ...
                'KL=%.4g TV=%.4g E_model=%.6f E_emp=%.6f'], M, lambda, ...
                result.pmf_validation, result.kl_target_model, result.tv_target_model, ...
                result.rf_energy_proxy_model, result.rf_energy_proxy_empirical));
            point_table = cell2table(rows(1:row_index, :), 'VariableNames', local_point_names());
            writetable(point_table, fullfile(result_dir, 'point_summary_partial.csv'));
            save(fullfile(result_dir, 'checkpoint.mat'), 'results', 'cfg', 'Ms', ...
                'lambdas', 'snr_dB', 'n_boot', 'run_tag');
            fprintf(['[energy smoke] M=%d lambda=%.2f | %s | target-model TV=%.4g ' ...
                '| empirical TV upper95=%.4f | E=%.4f\n'], M, lambda, ...
                result.pmf_validation, result.tv_target_model, pmf_stats.tv_upper95, ...
                result.rf_energy_proxy_empirical);
        end
    end

    point_table = cell2table(rows, 'VariableNames', local_point_names());
    difference_rows = cell(numel(Ms) * (numel(lambdas) - 1), 9);
    difference_index = 0; overall_pass = true;
    for im = 1:numel(Ms)
        model_energies = cellfun(@(r) r.rf_energy_proxy_model, results(im, :));
        model_monotonic = all(diff(model_energies) > 0);
        overall_pass = overall_pass && model_monotonic;
        for il = 1:(numel(lambdas) - 1)
            low = results{im, il}; high = results{im, il + 1};
            qam = build_cartesian_gray_qam(Ms(im));
            symbol_energy = abs(qam.constellation).^2;
            frame_low = symbol_energy.' * low.frame_psym(:, :, 1);
            frame_high = symbol_energy.' * high.frame_psym(:, :, 1);
            paired = paired_cluster_difference_ci(frame_low, frame_high, n_boot, ...
                cfg.seed + 10000 * Ms(im) + il);
            empirical_pass = paired.lower95 > 0;
            fit_pass = ~strcmp(low.pmf_validation, 'fail') && ...
                ~strcmp(high.pmf_validation, 'fail');
            pair_pass = empirical_pass && fit_pass && model_monotonic;
            overall_pass = overall_pass && pair_pass;
            difference_index = difference_index + 1;
            difference_rows(difference_index, :) = {Ms(im), lambdas(il), lambdas(il + 1), ...
                high.rf_energy_proxy_model - low.rf_energy_proxy_model, ...
                paired.mean_difference, paired.lower95, model_monotonic, ...
                empirical_pass, pair_pass};
        end
    end
    difference_table = cell2table(difference_rows, 'VariableNames', ...
        {'M','lambda_low','lambda_high','model_energy_difference', ...
        'empirical_energy_difference','empirical_lower95','model_monotonic', ...
        'empirical_pass','pair_pass'});
    overall_pass = overall_pass && all(~strcmp(point_table.match_status, 'fail')) && ...
        all(point_table.pmf_smoke_pass);
    writetable(point_table, fullfile(result_dir, 'point_summary.csv'));
    writetable(difference_table, fullfile(result_dir, 'energy_difference.csv'));
    save(fullfile(result_dir, 'results.mat'), 'results', 'cfg', 'Ms', 'lambdas', ...
        'snr_dB', 'n_boot', 'run_tag', 'point_table', 'difference_table', 'overall_pass');
    local_write_readme(result_dir, cfg, Ms, lambdas, snr_dB, n_boot, overall_pass);
    local_plot_energy(result_dir, results, Ms, lambdas);
    local_log(progress_path, sprintf('DONE %s overall_pass=%d', datestr(now, 31), overall_pass));
    summary = struct('result_dir', result_dir, 'point_table', point_table, ...
        'difference_table', difference_table, 'overall_pass', overall_pass, ...
        'results', {results});
    fprintf('[run_gray_qam_energy_smoke] overall_pass=%d\n', overall_pass);
    fprintf('[run_gray_qam_energy_smoke] saved: %s\n', result_dir);
    clear diary_cleanup;
end

function names = local_point_names()
    names = {'M','lambda','match_status','KL_target_model','TV_target_model', ...
        'E_target','E_model','E_empirical','TV_empirical_point', ...
        'TV_empirical_upper95','R_code','R_bpcu','pI','pQ', ...
        'solver_exit_I','solver_exit_Q','solver_objective_I','solver_objective_Q', ...
        'pmf_smoke_pass'};
end

function local_write_pmf_csv(path_name, qam, target, model, empirical)
    T = table((1:qam.M).', real(qam.constellation), imag(qam.constellation), ...
        target(:), model(:), empirical(:), 'VariableNames', ...
        {'symbol_index','I','Q','target_pmf','model_pmf','empirical_pmf'});
    writetable(T, path_name);
end

function text = local_vector_text(value)
    text = strtrim(sprintf('%.12g ', value(:)));
end

function tag = local_lambda_tag(lambda)
    tag = strrep(sprintf('%.3f', lambda), '.', 'p');
end

function local_log(path_name, message)
    fid = fopen(path_name, 'a');
    if fid < 0, error('v3:ProgressLog', 'Cannot open progress log.'); end
    fprintf(fid, '%s\n', message); fclose(fid);
end

function local_write_readme(result_dir, cfg, Ms, lambdas, snr_dB, n_boot, overall_pass)
    fid = fopen(fullfile(result_dir, 'README.txt'), 'w');
    fprintf(fid, 'v3 energy-lambda smoke\n');
    fprintf(fid, 'M=%s\nlambda=%s\n', mat2str(Ms), mat2str(lambdas));
    fprintf(fid, ['target P_X proportional to exp(lambda*|x_scaled|^2); ' ...
        'positive lambda favors outer points.\n']);
    fprintf(fid, 'uniform constellation scaling is fixed; no shaped-PMF renormalization.\n');
    fprintf(fid, 'snr_mode=%s; SNR=%.6g dB; N=%d; frames=%d; seed=%d\n', ...
        cfg.snr_mode, snr_dB, cfg.N, cfg.num_frames, cfg.seed);
    fprintf(fid, 'source_construction=%s; source_mc_samples=%d; paired_bootstrap=%d\n', ...
        cfg.source_construction, cfg.source_mc_samples, n_boot);
    fprintf(fid, ['Pair acceptance: model energy strictly increases and paired independent-frame ' ...
        'bootstrap lower95(high-low)>0.\n']);
    fprintf(fid, ['Target-model acceptance: exact KL<=1e-10 and TV<=1e-8; approximate-pass ' ...
        'KL<=0.02 nat and TV<=0.05.\n']);
    fprintf(fid, 'Empirical PMF smoke acceptance: cluster-bootstrap TV upper95<=0.10.\n');
    fprintf(fid, 'Energy is average transmit RF-energy proxy, not rectifier harvested energy.\n');
    fprintf(fid, 'overall_pass=%d\n', overall_pass);
    fclose(fid);
end

function local_plot_energy(result_dir, results, Ms, lambdas)
    colors = lines(numel(Ms));
    figure('Visible', 'off'); hold on;
    for im = 1:numel(Ms)
        model_energy = cellfun(@(r) r.rf_energy_proxy_model, results(im, :));
        empirical_energy = cellfun(@(r) r.rf_energy_proxy_empirical, results(im, :));
        plot(lambdas, model_energy, '-', 'Color', colors(im, :), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('%dQAM model', Ms(im)));
        plot(lambdas, empirical_energy, 'o--', 'Color', colors(im, :), ...
            'LineWidth', 1.0, 'DisplayName', sprintf('%dQAM empirical', Ms(im)));
    end
    xlabel('Energy parameter lambda'); ylabel('Average transmit RF-energy proxy');
    title('v3 energy-lambda smoke'); grid on; legend('Location', 'best');
    saveas(gcf, fullfile(result_dir, 'energy_vs_lambda.png'));
    saveas(gcf, fullfile(result_dir, 'energy_vs_lambda.pdf'));
    savefig(gcf, fullfile(result_dir, 'energy_vs_lambda.fig'));
    close(gcf);
end
