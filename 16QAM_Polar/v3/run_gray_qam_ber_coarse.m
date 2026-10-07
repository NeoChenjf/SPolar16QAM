function summary = run_gray_qam_ber_coarse()
%RUN_GRAY_QAM_BER_COARSE Locate finite-SNR BER waterfall candidates for all M/lambda.
    root = fileparts(mfilename('fullpath')); addpath(root); setup_paths;
    cfg = config();
    cfg.N = 256; cfg.num_frames = 30; cfg.seed = 20260903;
    cfg.snr_mode = 'fixed_n0'; cfg.force_nonzero_payload = false;
    cfg.collect_frame_pmf = false; cfg.source_construction = 'source_mc_ga';
    cfg.source_mc_samples = 120;
    Ms = [8 16 32 64]; lambdas = [0 0.25 0.5]; snr_dB = 0:2:18;
    run_tag = 'ber_coarse';
    result_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' run_tag]);
    if ~exist(result_dir, 'dir'), mkdir(result_dir); end
    diary(fullfile(result_dir, 'run_log.txt')); diary on;
    diary_cleanup = onCleanup(@() diary('off'));
    progress_path = fullfile(result_dir, 'progress_log.txt');
    local_log(progress_path, sprintf('START %s', datestr(now, 31)));

    results = cell(numel(Ms), numel(lambdas));
    n_rows = numel(Ms) * numel(lambdas) * numel(snr_dB);
    rows = cell(n_rows, 16); row_index = 0;
    for im = 1:numel(Ms)
        for il = 1:numel(lambdas)
            M = Ms(im); lambda = lambdas(il);
            local_log(progress_path, sprintf('START M=%d lambda=%.6g', M, lambda));
            spec = struct('source', 'energy_lambda', 'lambda', lambda);
            result = sim_shaped_polar_gray_qam(M, spec, snr_dB, cfg);
            result.result_dir = result_dir; results{im, il} = result;
            for is = 1:numel(snr_dB)
                error_total = sum(result.errors(:, is));
                bits_total = sum(result.K) * result.frames(is);
                in_waterfall = result.BER(is) >= 1e-4 && result.BER(is) <= 1e-1;
                row_index = row_index + 1;
                rows(row_index, :) = {M, lambda, snr_dB(is), result.BER(is), ...
                    result.BLER_joint(is), error_total, bits_total, result.frames(is), ...
                    local_vector_text(result.errors(:, is)), result.R_code, result.R_bpcu, ...
                    result.Goodput(is), result.rf_energy_proxy_model, ...
                    result.rf_energy_proxy_empirical(is), in_waterfall, error_total == 0};
            end
            point_table = cell2table(rows(1:row_index, :), 'VariableNames', local_point_names());
            writetable(point_table, fullfile(result_dir, 'ber_coarse_partial.csv'));
            save(fullfile(result_dir, 'checkpoint.mat'), 'results', 'cfg', 'Ms', ...
                'lambdas', 'snr_dB', 'run_tag');
            local_log(progress_path, sprintf(['DONE M=%d lambda=%.6g minBER=%.4g ' ...
                'maxBER=%.4g totalErrors=%d'], M, lambda, min(result.BER), ...
                max(result.BER), sum(result.errors(:))));
            fprintf('[BER coarse] M=%d lambda=%.2f | BER range %.4g ... %.4g\n', ...
                M, lambda, min(result.BER), max(result.BER));
        end
    end

    point_table = cell2table(rows, 'VariableNames', local_point_names());
    window_table = local_window_candidates(point_table, Ms, lambdas);
    writetable(point_table, fullfile(result_dir, 'ber_coarse.csv'));
    writetable(window_table, fullfile(result_dir, 'window_candidates.csv'));
    save(fullfile(result_dir, 'results.mat'), 'results', 'cfg', 'Ms', 'lambdas', ...
        'snr_dB', 'run_tag', 'point_table', 'window_table');
    local_write_readme(result_dir, cfg, Ms, lambdas, snr_dB);
    local_plot_ber(result_dir, results, Ms, lambdas, snr_dB);
    local_log(progress_path, sprintf('DONE %s', datestr(now, 31)));
    summary = struct('result_dir', result_dir, 'point_table', point_table, ...
        'window_table', window_table, 'results', {results});
    fprintf('[run_gray_qam_ber_coarse] saved: %s\n', result_dir);
    clear diary_cleanup;
end

function names = local_point_names()
    names = {'M','lambda','snr_dB','BER','BLER_joint','error_total','bits_total', ...
        'frames','errors_per_stream','R_code','R_bpcu','Goodput', ...
        'E_model','E_empirical','in_waterfall','zero_errors'};
end

function table_out = local_window_candidates(points, Ms, lambdas)
    rows = cell(numel(Ms) * numel(lambdas), 8); index = 0;
    for im = 1:numel(Ms)
        for il = 1:numel(lambdas)
            take = points.M == Ms(im) & abs(points.lambda - lambdas(il)) < 1e-12;
            subset = points(take, :); informative = subset.in_waterfall;
            stable = informative & subset.error_total >= 20;
            index = index + 1;
            if any(stable)
                chosen = stable; status = 'candidate-with-20-errors';
            elseif any(informative)
                chosen = informative; status = 'candidate-sparse-errors';
            else
                chosen = false(height(subset), 1); status = 'no-candidate';
            end
            if any(chosen)
                selected_snr = subset.snr_dB(chosen);
                low_snr = min(selected_snr); high_snr = max(selected_snr);
                min_ber = min(subset.BER(chosen)); max_ber = max(subset.BER(chosen));
                n_points = sum(chosen);
            else
                low_snr = NaN; high_snr = NaN; min_ber = NaN; max_ber = NaN; n_points = 0;
            end
            rows(index, :) = {Ms(im), lambdas(il), status, low_snr, high_snr, ...
                min_ber, max_ber, n_points};
        end
    end
    table_out = cell2table(rows, 'VariableNames', {'M','lambda','status', ...
        'snr_low','snr_high','BER_min','BER_max','n_candidate_points'});
end

function local_write_readme(result_dir, cfg, Ms, lambdas, snr_dB)
    fid = fopen(fullfile(result_dir, 'README.txt'), 'w');
    fprintf(fid, 'v3 finite-SNR BER coarse scan\n');
    fprintf(fid, 'M=%s\nlambda=%s\nSNR_dB=%s\n', ...
        mat2str(Ms), mat2str(lambdas), mat2str(snr_dB));
    fprintf(fid, 'N=%d; frames=%d; seed=%d; snr_mode=%s\n', ...
        cfg.N, cfg.num_frames, cfg.seed, cfg.snr_mode);
    fprintf(fid, 'source_construction=%s; source_mc_samples=%d\n', ...
        cfg.source_construction, cfg.source_mc_samples);
    fprintf(fid, ['Purpose: locate BER roughly in [1e-4,1e-1]. This sparse, single-seed ' ...
        'coarse scan is not a final BER ordering claim.\n']);
    fprintf(fid, ['Candidate-with-20-errors requires both the BER window and at least 20 ' ...
        'aggregate payload errors. Sparse candidates require local reruns.\n']);
    fprintf(fid, 'Zero-error points are preserved in CSV and omitted from semilogy curves.\n');
    fprintf(fid, 'Energy uses fixed uniform constellation scaling and is an RF-energy proxy.\n');
    fclose(fid);
end

function local_plot_ber(result_dir, results, Ms, lambdas, snr_dB)
    colors = lines(numel(lambdas));
    figure('Visible', 'off');
    for im = 1:numel(Ms)
        subplot(2, 2, im); hold on;
        for il = 1:numel(lambdas)
            ber = results{im, il}.BER;
            ber(sum(results{im, il}.errors, 1) == 0) = NaN;
            semilogy(snr_dB, ber, 'o-', 'Color', colors(il, :), ...
                'LineWidth', 1.2, 'DisplayName', sprintf('lambda = %.2f', lambdas(il)));
        end
        xlabel('SNR (dB)'); ylabel('BER'); grid on;
        title(sprintf('%dQAM', Ms(im))); legend('Location', 'best');
    end
    saveas(gcf, fullfile(result_dir, 'ber_coarse.png'));
    saveas(gcf, fullfile(result_dir, 'ber_coarse.pdf'));
    savefig(gcf, fullfile(result_dir, 'ber_coarse.fig'));
    close(gcf);
end

function text = local_vector_text(value)
    text = strtrim(sprintf('%d ', value(:)));
end

function local_log(path_name, message)
    fid = fopen(path_name, 'a');
    if fid < 0, error('v3:ProgressLog', 'Cannot open progress log.'); end
    fprintf(fid, '%s\n', message); fclose(fid);
end
