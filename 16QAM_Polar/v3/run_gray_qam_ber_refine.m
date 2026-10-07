function summary = run_gray_qam_ber_refine()
%RUN_GRAY_QAM_BER_REFINE Dense repeated BER validation around coarse waterfalls.
    root = fileparts(mfilename('fullpath')); addpath(root); setup_paths;
    cfg = config();
    cfg.N = 256; cfg.num_frames = 30; cfg.snr_mode = 'fixed_n0';
    cfg.force_nonzero_payload = false; cfg.collect_frame_pmf = false;
    cfg.source_construction = 'source_mc_ga'; cfg.source_mc_samples = 120;
    cfg.source_mc_seed = 20260903;
    Ms = [8 16 32 64]; lambdas = [0 0.25 0.5];
    centers = [8 10 14 16]; offsets = -0.5:0.25:1.0;
    min_repetitions = 3; max_repetitions = 10; min_errors = 100;
    target_ber = [1e-4 1e-1]; run_tag = 'ber_refine';
    result_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' run_tag]);
    if ~exist(result_dir, 'dir'), mkdir(result_dir); end
    diary(fullfile(result_dir, 'run_log.txt')); diary on;
    diary_cleanup = onCleanup(@() diary('off'));
    progress_path = fullfile(result_dir, 'progress_log.txt');
    local_log(progress_path, sprintf('START %s', datestr(now, 31)));

    raw_results = cell(numel(Ms), numel(lambdas), max_repetitions);
    repetition_rows = cell(numel(Ms) * numel(lambdas) * max_repetitions * numel(offsets), 10);
    repetition_index = 0;
    aggregate_rows = cell(numel(Ms) * numel(lambdas) * numel(offsets), 18);
    aggregate_index = 0;
    for im = 1:numel(Ms)
        snr_grid = centers(im) + offsets;
        for il = 1:numel(lambdas)
            M = Ms(im); lambda = lambdas(il); n_snr = numel(snr_grid);
            accumulated_errors = [];
            accumulated_blocks = [];
            accumulated_joint_blocks = zeros(1, n_snr);
            accumulated_frames = zeros(1, n_snr);
            accumulated_energy = zeros(1, n_snr);
            reference_K = []; reference_R_code = NaN; reference_R_bpcu = NaN;
            repetition = 0; enough = false;
            while repetition < max_repetitions && ~enough
                repetition = repetition + 1;
                cfg_run = cfg;
                cfg_run.seed = 20260903 + 100000 * im + 1000 * il + repetition;
                spec = struct('source', 'energy_lambda', 'lambda', lambda);
                local_log(progress_path, sprintf('START M=%d lambda=%.6g repetition=%d seed=%d', ...
                    M, lambda, repetition, cfg_run.seed));
                result = sim_shaped_polar_gray_qam(M, spec, snr_grid, cfg_run);
                result.result_dir = result_dir;
                raw_results{im, il, repetition} = result;
                if isempty(reference_K)
                    reference_K = result.K;
                    reference_R_code = result.R_code;
                    reference_R_bpcu = result.R_bpcu;
                    accumulated_errors = zeros(size(result.errors));
                    accumulated_blocks = zeros(size(result.BLER_per_bit));
                else
                    assert(isequal(result.K, reference_K), 'v3:RefineConstructionChanged', ...
                        'Fixed source_mc_seed must produce identical K across repetitions.');
                end
                accumulated_errors = accumulated_errors + result.errors;
                accumulated_blocks = accumulated_blocks + round(bsxfun(@times, ...
                    result.BLER_per_bit, result.frames));
                accumulated_joint_blocks = accumulated_joint_blocks + ...
                    round(result.BLER_joint .* result.frames);
                accumulated_frames = accumulated_frames + result.frames;
                accumulated_energy = accumulated_energy + ...
                    result.rf_energy_proxy_empirical .* result.frames;
                for is = 1:n_snr
                    repetition_index = repetition_index + 1;
                    repetition_errors = sum(result.errors(:, is));
                    repetition_bits = sum(result.K) * result.frames(is);
                    repetition_rows(repetition_index, :) = {M, lambda, repetition, ...
                        cfg_run.seed, snr_grid(is), result.BER(is), repetition_errors, ...
                        repetition_bits, result.frames(is), ...
                        local_vector_text(result.errors(:, is))};
                end
                [aggregate_ber, aggregate_error_total] = local_aggregate_ber( ...
                    accumulated_errors, reference_K, accumulated_frames);
                valid = aggregate_ber >= target_ber(1) & aggregate_ber <= target_ber(2) & ...
                    aggregate_error_total >= min_errors;
                enough = repetition >= min_repetitions && sum(valid) >= 2;
                local_log(progress_path, sprintf(['DONE M=%d lambda=%.6g repetition=%d ' ...
                    'valid_points=%d'], M, lambda, repetition, sum(valid)));
                partial = cell2table(repetition_rows(1:repetition_index, :), ...
                    'VariableNames', local_repetition_names());
                writetable(partial, fullfile(result_dir, 'ber_refine_repetitions_partial.csv'));
                save(fullfile(result_dir, 'checkpoint.mat'), 'raw_results', 'cfg', 'Ms', ...
                    'lambdas', 'centers', 'offsets', 'min_repetitions', ...
                    'max_repetitions', 'min_errors', 'target_ber', 'run_tag');
            end

            [aggregate_ber, aggregate_error_total, aggregate_bits] = local_aggregate_ber( ...
                accumulated_errors, reference_K, accumulated_frames);
            aggregate_bler = accumulated_joint_blocks ./ accumulated_frames;
            aggregate_energy = accumulated_energy ./ accumulated_frames;
            valid_count = sum(aggregate_ber >= target_ber(1) & ...
                aggregate_ber <= target_ber(2) & aggregate_error_total >= min_errors);
            for is = 1:n_snr
                valid_point = aggregate_ber(is) >= target_ber(1) && ...
                    aggregate_ber(is) <= target_ber(2) && ...
                    aggregate_error_total(is) >= min_errors;
                aggregate_index = aggregate_index + 1;
                aggregate_rows(aggregate_index, :) = {M, lambda, snr_grid(is), ...
                    aggregate_ber(is), aggregate_bler(is), aggregate_error_total(is), ...
                    aggregate_bits(is), accumulated_frames(is), repetition, ...
                    local_vector_text(accumulated_errors(:, is)), ...
                    local_float_vector_text(accumulated_blocks(:, is) ./ accumulated_frames(is)), ...
                    reference_R_code, ...
                    reference_R_bpcu, reference_R_bpcu * (1 - aggregate_bler(is)), ...
                    result.rf_energy_proxy_model, aggregate_energy(is), valid_point, ...
                    aggregate_error_total(is) == 0};
            end
            fprintf('[BER refine] M=%d lambda=%.2f | repetitions=%d valid_points=%d\n', ...
                M, lambda, repetition, valid_count);
        end
    end

    repetition_table = cell2table(repetition_rows(1:repetition_index, :), ...
        'VariableNames', local_repetition_names());
    aggregate_table = cell2table(aggregate_rows(1:aggregate_index, :), ...
        'VariableNames', local_aggregate_names());
    validation_table = local_validation_table(aggregate_table, Ms, lambdas);
    overall_pass = all(validation_table.pass);
    writetable(repetition_table, fullfile(result_dir, 'ber_refine_repetitions.csv'));
    writetable(aggregate_table, fullfile(result_dir, 'ber_refine_aggregate.csv'));
    writetable(validation_table, fullfile(result_dir, 'ber_refine_validation.csv'));
    save(fullfile(result_dir, 'results.mat'), 'raw_results', 'cfg', 'Ms', 'lambdas', ...
        'centers', 'offsets', 'min_repetitions', 'max_repetitions', 'min_errors', ...
        'target_ber', 'run_tag', 'repetition_table', 'aggregate_table', ...
        'validation_table', 'overall_pass');
    local_write_readme(result_dir, cfg, Ms, lambdas, centers, offsets, ...
        min_repetitions, max_repetitions, min_errors, target_ber, overall_pass);
    local_plot_ber(result_dir, aggregate_table, Ms, lambdas);
    local_log(progress_path, sprintf('DONE %s overall_pass=%d', datestr(now, 31), overall_pass));
    summary = struct('result_dir', result_dir, 'repetition_table', repetition_table, ...
        'aggregate_table', aggregate_table, 'validation_table', validation_table, ...
        'overall_pass', overall_pass, 'results', {raw_results});
    fprintf('[run_gray_qam_ber_refine] overall_pass=%d\n', overall_pass);
    fprintf('[run_gray_qam_ber_refine] saved: %s\n', result_dir);
    clear diary_cleanup;
end

function [ber, error_total, bits_total] = local_aggregate_ber(errors, K, frames)
    error_total = sum(errors, 1);
    bits_total = sum(K) * frames;
    ber = error_total ./ bits_total;
end

function table_out = local_validation_table(points, Ms, lambdas)
    rows = cell(numel(Ms) * numel(lambdas), 9); index = 0;
    for im = 1:numel(Ms)
        for il = 1:numel(lambdas)
            take = points.M == Ms(im) & abs(points.lambda - lambdas(il)) < 1e-12;
            subset = points(take, :); valid = subset.valid_D_point;
            index = index + 1;
            if any(valid)
                snr_valid = subset.snr_dB(valid);
                snr_low = min(snr_valid); snr_high = max(snr_valid);
                min_errors_valid = min(subset.error_total(valid));
                min_ber = min(subset.BER(valid)); max_ber = max(subset.BER(valid));
            else
                snr_low = NaN; snr_high = NaN; min_errors_valid = 0;
                min_ber = NaN; max_ber = NaN;
            end
            n_valid = sum(valid); pass = n_valid >= 2;
            rows(index, :) = {Ms(im), lambdas(il), n_valid, snr_low, snr_high, ...
                min_ber, max_ber, min_errors_valid, pass};
        end
    end
    table_out = cell2table(rows, 'VariableNames', {'M','lambda','n_valid_points', ...
        'snr_low','snr_high','BER_min','BER_max','min_errors_at_valid','pass'});
end

function names = local_repetition_names()
    names = {'M','lambda','repetition','seed','snr_dB','BER','error_total', ...
        'bits_total','frames','errors_per_stream'};
end

function names = local_aggregate_names()
    names = {'M','lambda','snr_dB','BER','BLER_joint','error_total','bits_total', ...
        'frames','repetitions','errors_per_stream','BLER_per_stream', ...
        'R_code','R_bpcu','Goodput', ...
        'E_model','E_empirical','valid_D_point','zero_errors'};
end

function local_write_readme(result_dir, cfg, Ms, lambdas, centers, offsets, ...
        min_repetitions, max_repetitions, min_errors, target_ber, overall_pass)
    fid = fopen(fullfile(result_dir, 'README.txt'), 'w');
    fprintf(fid, 'v3 BER local refinement with independent runtime seeds\n');
    fprintf(fid, 'M=%s; lambda=%s; centers=%s; offsets=%s\n', ...
        mat2str(Ms), mat2str(lambdas), mat2str(centers), mat2str(offsets));
    fprintf(fid, 'N=%d; frames_per_repetition=%d; source_mc_samples=%d\n', ...
        cfg.N, cfg.num_frames, cfg.source_mc_samples);
    fprintf(fid, 'source_mc_seed=%d; snr_mode=%s\n', cfg.source_mc_seed, cfg.snr_mode);
    fprintf(fid, 'min_repetitions=%d; max_repetitions=%d\n', ...
        min_repetitions, max_repetitions);
    fprintf(fid, 'D gate: at least two points with BER in [%g,%g] and >=%d errors each.\n', ...
        target_ber(1), target_ber(2), min_errors);
    fprintf(fid, ['Source construction is frozen by source_mc_seed; repetition seeds change ' ...
        'payload and AWGN only.\n']);
    fprintf(fid, ['This validates finite-SNR execution and waterfall coverage. Stable lambda ' ...
        'ordering still requires confidence analysis before a paper claim.\n']);
    fprintf(fid, 'Zero-error points are retained in CSV and omitted from semilogy.\n');
    fprintf(fid, 'overall_pass=%d\n', overall_pass);
    fclose(fid);
end

function local_plot_ber(result_dir, points, Ms, lambdas)
    colors = lines(numel(lambdas));
    figure('Visible', 'off');
    for im = 1:numel(Ms)
        subplot(2, 2, im); hold on;
        for il = 1:numel(lambdas)
            take = points.M == Ms(im) & abs(points.lambda - lambdas(il)) < 1e-12;
            subset = sortrows(points(take, :), 'snr_dB');
            ber = subset.BER; ber(subset.zero_errors) = NaN;
            semilogy(subset.snr_dB, ber, 'o-', 'Color', colors(il, :), ...
                'LineWidth', 1.2, 'DisplayName', sprintf('lambda = %.2f', lambdas(il)));
        end
        xlabel('SNR (dB)'); ylabel('BER'); grid on;
        title(sprintf('%dQAM', Ms(im))); legend('Location', 'best');
    end
    saveas(gcf, fullfile(result_dir, 'ber_refine.png'));
    saveas(gcf, fullfile(result_dir, 'ber_refine.pdf'));
    savefig(gcf, fullfile(result_dir, 'ber_refine.fig'));
    close(gcf);
end

function text = local_vector_text(value)
    text = strtrim(sprintf('%d ', value(:)));
end

function text = local_float_vector_text(value)
    text = strtrim(sprintf('%.12g ', value(:)));
end

function local_log(path_name, message)
    fid = fopen(path_name, 'a');
    if fid < 0, error('v3:ProgressLog', 'Cannot open progress log.'); end
    fprintf(fid, '%s\n', message); fclose(fid);
end
