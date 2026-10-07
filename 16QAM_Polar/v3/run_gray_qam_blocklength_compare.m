function summary = run_gray_qam_blocklength_compare(run_mode)
%RUN_GRAY_QAM_BLOCKLENGTH_COMPARE Compare N=256/1024 with target and model PMFs.
    root = fileparts(mfilename('fullpath')); addpath(root); setup_paths;
    if nargin < 1 || isempty(run_mode), run_mode = 'formal'; end
    params = local_parameters(run_mode);

    cfg = config();
    cfg.snr_mode = 'fixed_n0'; cfg.force_nonzero_payload = false;
    cfg.collect_frame_pmf = true; cfg.source_construction = 'source_mc_ga';
    cfg.source_mc_samples = params.source_mc_samples;
    cfg.source_mc_seed = params.source_mc_seed;
    cfg.seed = params.runtime_seed;

    run_tag = ['energy_lambda_blocklength_' run_mode];
    result_dir = fullfile(cfg.output_dir, ...
        [datestr(now, 'yyyymmdd_HHMMSS') '_' run_tag]);
    if ~exist(result_dir, 'dir'), mkdir(result_dir); end
    diary(fullfile(result_dir, 'run_log.txt')); diary on;
    diary_cleanup = onCleanup(@() diary('off'));
    progress_path = fullfile(result_dir, 'progress_log.txt');
    local_log(progress_path, sprintf('START %s mode=%s', datestr(now, 31), run_mode));

    n_rows = numel(params.Ms) * numel(params.lambdas) * numel(params.Ns);
    rows = cell(n_rows, 21); row_index = 0;
    results = cell(numel(params.Ms), numel(params.lambdas), numel(params.Ns));
    for im = 1:numel(params.Ms)
        M = params.Ms(im); qam = build_cartesian_gray_qam(M);
        for il = 1:numel(params.lambdas)
            lambda = params.lambdas(il);
            for in = 1:numel(params.Ns)
                cfg.N = params.Ns(in);
                cfg.num_frames = params.frames;
                local_log(progress_path, sprintf('START M=%d lambda=%.6g N=%d', ...
                    M, lambda, cfg.N));
                spec = struct('source', 'energy_lambda', 'lambda', lambda);
                result = sim_shaped_polar_gray_qam(M, spec, params.snr_dB, cfg);
                frame_pmf = result.frame_psym(:, :, 1);
                boot_seed = params.runtime_seed + 100000 * M + 1000 * in + il;
                stats_model = cluster_bootstrap_tv(frame_pmf, result.model_psym, ...
                    params.n_boot, boot_seed);
                stats_target = cluster_bootstrap_tv(frame_pmf, result.target_psym, ...
                    params.n_boot, boot_seed + 5000000);
                result.pmf_cluster_model = stats_model;
                result.pmf_cluster_target = stats_target;
                results{im, il, in} = result;

                local_write_pmf_csv(fullfile(result_dir, sprintf( ...
                    'M%d_lambda_%s_N%d_pmf.csv', M, local_lambda_tag(lambda), cfg.N)), ...
                    qam, result.target_psym, result.model_psym, ...
                    stats_model.empirical_psym);
                row_index = row_index + 1;
                rows(row_index, :) = {M, lambda, cfg.N, cfg.num_frames, ...
                    cfg.source_mc_samples, result.pmf_validation, ...
                    result.kl_target_model, result.tv_target_model, ...
                    result.rf_energy_proxy_target, result.rf_energy_proxy_model, ...
                    result.rf_energy_proxy_empirical, ...
                    result.rf_energy_proxy_model - result.rf_energy_proxy_target, ...
                    result.rf_energy_proxy_empirical - result.rf_energy_proxy_model, ...
                    result.rf_energy_proxy_empirical - result.rf_energy_proxy_target, ...
                    stats_model.tv_point, stats_model.tv_upper95, ...
                    stats_target.tv_point, stats_target.tv_upper95, ...
                    result.R_code, result.R_bpcu, ...
                    ~strcmp(result.pmf_validation, 'fail')};

                point_table = cell2table(rows(1:row_index, :), ...
                    'VariableNames', local_names());
                writetable(point_table, fullfile(result_dir, 'blocklength_compare_partial.csv'));
                save(fullfile(result_dir, 'checkpoint.mat'), 'results', 'cfg', ...
                    'params', 'run_mode', 'run_tag');
                local_log(progress_path, sprintf(['DONE M=%d lambda=%.6g N=%d ' ...
                    'E_target=%.6f E_model=%.6f E_emp=%.6f ' ...
                    'TV_emp_target_upper95=%.6f'], M, lambda, cfg.N, ...
                    result.rf_energy_proxy_target, result.rf_energy_proxy_model, ...
                    result.rf_energy_proxy_empirical, stats_target.tv_upper95));
                fprintf(['[blocklength compare] M=%d lambda=%.2f N=%d | ' ...
                    'E target/model/emp=%.4f/%.4f/%.4f | TV95(emp,target)=%.4f\n'], ...
                    M, lambda, cfg.N, result.rf_energy_proxy_target, ...
                    result.rf_energy_proxy_model, result.rf_energy_proxy_empirical, ...
                    stats_target.tv_upper95);
            end
        end
    end

    point_table = cell2table(rows, 'VariableNames', local_names());
    local_validate_table(point_table, params);
    writetable(point_table, fullfile(result_dir, 'blocklength_compare.csv'));
    save(fullfile(result_dir, 'results.mat'), 'results', 'cfg', 'params', ...
        'run_mode', 'run_tag', 'point_table');
    local_write_readme(result_dir, params, run_mode);
    local_plot_energy(result_dir, point_table, params);
    local_plot_tv(result_dir, point_table, params);
    local_log(progress_path, sprintf('DONE %s rows=%d', datestr(now, 31), height(point_table)));
    summary = struct('result_dir', result_dir, 'point_table', point_table, ...
        'results', {results}, 'run_mode', run_mode);
    fprintf('[run_gray_qam_blocklength_compare] saved: %s\n', result_dir);
    clear diary_cleanup;
end

function local_validate_table(point_table, params)
    expected_rows = numel(params.Ms) * numel(params.lambdas) * numel(params.Ns);
    assert(height(point_table) == expected_rows, ...
        'v3:BlocklengthRows', 'Blocklength comparison row count is incomplete.');
    keys = unique(point_table(:, {'M','lambda','N'}), 'rows');
    assert(height(keys) == expected_rows, ...
        'v3:BlocklengthKeys', 'M/lambda/N keys must be unique.');
    numeric_values = point_table{:, {'E_target','E_model','E_empirical', ...
        'TV_empirical_model_upper95','TV_empirical_target_upper95'}};
    assert(all(isfinite(numeric_values(:))), ...
        'v3:BlocklengthFinite', 'Energy and TV comparison values must be finite.');
    for im = 1:numel(params.Ms)
        for il = 1:numel(params.lambdas)
            part = point_table(point_table.M == params.Ms(im) & ...
                point_table.lambda == params.lambdas(il), :);
            assert(max(part.E_target) - min(part.E_target) <= 1e-12 && ...
                max(part.E_model) - min(part.E_model) <= 1e-12, ...
                'v3:BlocklengthTheoryChanged', ...
                'Target/model energy changed with N; controlled comparison is invalid.');
        end
    end
end

function params = local_parameters(run_mode)
    switch run_mode
        case 'smoke'
            params = struct('Ms', 8, 'lambdas', [0 0.5], ...
                'Ns', [256 1024], 'frames', 2, 'source_mc_samples', 4, ...
                'source_mc_seed', 20260916, 'runtime_seed', 20260916, ...
                'snr_dB', 120, 'n_boot', 100);
        case 'formal'
            params = struct('Ms', [8 16 32 64], 'lambdas', [0 0.25 0.5], ...
                'Ns', [256 1024], 'frames', 40, 'source_mc_samples', 200, ...
                'source_mc_seed', 20260916, 'runtime_seed', 20260916, ...
                'snr_dB', 120, 'n_boot', 2000);
        otherwise
            error('v3:BlocklengthMode', 'run_mode must be smoke or formal.');
    end
end

function names = local_names()
    names = {'M','lambda','N','frames','source_mc_samples','match_status', ...
        'KL_target_model','TV_target_model','E_target','E_model','E_empirical', ...
        'E_gap_model_target','E_gap_empirical_model','E_gap_empirical_target', ...
        'TV_empirical_model_point','TV_empirical_model_upper95', ...
        'TV_empirical_target_point','TV_empirical_target_upper95', ...
        'R_code','R_bpcu','model_fit_pass'};
end

function local_write_pmf_csv(path_name, qam, target, model, empirical)
    T = table((1:qam.M).', real(qam.constellation), imag(qam.constellation), ...
        target(:), model(:), empirical(:), 'VariableNames', ...
        {'symbol_index','I','Q','target_pmf','model_pmf','empirical_pmf'});
    writetable(T, path_name);
end

function local_write_readme(result_dir, params, run_mode)
    fid = fopen(fullfile(result_dir, 'README.txt'), 'w');
    if fid < 0, error('v3:ResultReadme', 'Cannot create result README.'); end
    fprintf(fid, 'v3 energy-lambda blocklength comparison\n');
    fprintf(fid, 'run_mode=%s\nM=%s\nlambda=%s\nN=%s\n', ...
        run_mode, mat2str(params.Ms), mat2str(params.lambdas), mat2str(params.Ns));
    fprintf(fid, ['Controlled comparison: frames, source_mc_samples, source_mc_seed, ' ...
        'runtime_seed, SNR mode and lambda grid are held fixed across N.\n']);
    fprintf(fid, 'frames=%d; source_mc_samples=%d; source_mc_seed=%d; runtime_seed=%d\n', ...
        params.frames, params.source_mc_samples, params.source_mc_seed, params.runtime_seed);
    fprintf(fid, 'snr_mode=fixed_n0; SNR=%.6g dB; cluster_bootstrap=%d\n', ...
        params.snr_dB, params.n_boot);
    fprintf(fid, ['target: ideal P_X proportional to exp(lambda*|x_scaled|^2); ' ...
        'model: fitted latent PMF; empirical: transmitted shaped-polar codewords.\n']);
    fprintf(fid, ['Primary comparisons are empirical-target energy gap and PMF TV; ' ...
        'empirical-model metrics separate finite-length loss from target-model fitting loss.\n']);
    fprintf(fid, ['This experiment evaluates PMF and transmit RF-energy proxy only. ' ...
        'It does not establish N=1024 BER ordering or rectifier efficiency.\n']);
    if strcmp(run_mode, 'smoke')
        fprintf(fid, 'Smoke data validate execution only and are not statistical evidence.\n');
    end
    fclose(fid);
end

function local_plot_energy(result_dir, point_table, params)
    figure('Visible', 'off');
    [panel_rows, panel_cols] = local_panel_grid(numel(params.Ms));
    for im = 1:numel(params.Ms)
        subplot(panel_rows, panel_cols, im); hold on;
        M = params.Ms(im); base = sortrows(point_table(point_table.M == M & ...
            point_table.N == params.Ns(1), :), 'lambda');
        plot(base.lambda, base.E_target, 'k:', 'LineWidth', 1.6, ...
            'DisplayName', 'target theory');
        plot(base.lambda, base.E_model, 'k-', 'LineWidth', 1.2, ...
            'DisplayName', 'latent model');
        colors = lines(numel(params.Ns));
        markers = {'o','s'};
        for in = 1:numel(params.Ns)
            part = sortrows(point_table(point_table.M == M & ...
                point_table.N == params.Ns(in), :), 'lambda');
            plot(part.lambda, part.E_empirical, ['--' markers{in}], ...
                'Color', colors(in, :), 'LineWidth', 1.1, ...
                'DisplayName', sprintf('empirical N=%d', params.Ns(in)));
        end
        title(sprintf('%dQAM', M)); xlabel('Energy parameter lambda');
        ylabel('Average transmit RF-energy proxy'); grid on;
        if im == 1, legend('Location', 'best'); end
    end
    saveas(gcf, fullfile(result_dir, 'energy_blocklength_compare.png'));
    saveas(gcf, fullfile(result_dir, 'energy_blocklength_compare.pdf'));
    savefig(gcf, fullfile(result_dir, 'energy_blocklength_compare.fig'));
    close(gcf);
end

function local_plot_tv(result_dir, point_table, params)
    figure('Visible', 'off');
    [panel_rows, panel_cols] = local_panel_grid(numel(params.Ms));
    for im = 1:numel(params.Ms)
        subplot(panel_rows, panel_cols, im); hold on;
        M = params.Ms(im); colors = lines(numel(params.Ns));
        markers = {'o','s'};
        for in = 1:numel(params.Ns)
            part = sortrows(point_table(point_table.M == M & ...
                point_table.N == params.Ns(in), :), 'lambda');
            plot(part.lambda, part.TV_empirical_target_upper95, ...
                ['-' markers{in}], 'Color', colors(in, :), 'LineWidth', 1.3, ...
                'DisplayName', sprintf('empirical-target N=%d', params.Ns(in)));
            plot(part.lambda, part.TV_empirical_model_upper95, ...
                ['--' markers{in}], 'Color', colors(in, :), 'LineWidth', 1.0, ...
                'DisplayName', sprintf('empirical-model N=%d', params.Ns(in)));
        end
        title(sprintf('%dQAM', M)); xlabel('Energy parameter lambda');
        ylabel('PMF TV bootstrap upper 95%'); grid on;
        if im == 1, legend('Location', 'best'); end
    end
    saveas(gcf, fullfile(result_dir, 'pmf_tv_blocklength_compare.png'));
    saveas(gcf, fullfile(result_dir, 'pmf_tv_blocklength_compare.pdf'));
    savefig(gcf, fullfile(result_dir, 'pmf_tv_blocklength_compare.fig'));
    close(gcf);
end

function [n_rows, n_cols] = local_panel_grid(n_panels)
    n_cols = min(2, n_panels);
    n_rows = ceil(n_panels / n_cols);
end

function tag = local_lambda_tag(lambda)
    tag = strrep(sprintf('%.3f', lambda), '.', 'p');
end

function local_log(path_name, message)
    fid = fopen(path_name, 'a');
    if fid < 0, error('v3:ProgressLog', 'Cannot open progress log.'); end
    fprintf(fid, '%s\n', message); fclose(fid);
end
