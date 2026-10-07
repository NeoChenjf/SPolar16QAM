function summary = run_gray_qam_pmf_formal64()
%RUN_GRAY_QAM_PMF_FORMAL64 Targeted N=1024 formal PMF gate for 64QAM.
    root = fileparts(mfilename('fullpath')); addpath(root); setup_paths;
    cfg = config();
    cfg.N = 1024; cfg.num_frames = 80; cfg.seed = 20260904;
    cfg.snr_mode = 'fixed_n0'; cfg.force_nonzero_payload = false;
    cfg.collect_frame_pmf = true; cfg.source_construction = 'source_mc_ga';
    cfg.source_mc_samples = 200; cfg.source_mc_seed = 20260904;
    M = 64; lambdas = [0 0.25 0.5]; snr_dB = 120; n_boot = 2000;
    run_tag = 'pmf_formal64';
    result_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' run_tag]);
    if ~exist(result_dir, 'dir'), mkdir(result_dir); end
    diary(fullfile(result_dir, 'run_log.txt')); diary on;
    diary_cleanup = onCleanup(@() diary('off'));
    progress_path = fullfile(result_dir, 'progress_log.txt');
    local_log(progress_path, sprintf('START %s', datestr(now, 31)));

    qam = build_cartesian_gray_qam(M);
    results = cell(numel(lambdas), 1); rows = cell(numel(lambdas), 14);
    for il = 1:numel(lambdas)
        lambda = lambdas(il);
        local_log(progress_path, sprintf('START M=%d lambda=%.6g', M, lambda));
        spec = struct('source', 'energy_lambda', 'lambda', lambda);
        result = sim_shaped_polar_gray_qam(M, spec, snr_dB, cfg);
        result.result_dir = result_dir;
        stats = cluster_bootstrap_tv(result.frame_psym(:, :, 1), ...
            result.model_psym, n_boot, cfg.seed + il);
        result.pmf_cluster = stats; results{il} = result;
        formal_pass = stats.tv_upper95 <= 0.05 && ...
            ~strcmp(result.pmf_validation, 'fail');
        rows(il, :) = {M, lambda, result.pmf_validation, ...
            result.kl_target_model, result.tv_target_model, stats.tv_point, ...
            stats.tv_upper95, formal_pass, result.rf_energy_proxy_target, ...
            result.rf_energy_proxy_model, result.rf_energy_proxy_empirical, ...
            result.R_code, result.R_bpcu, local_vector_text(result.target_latent_p)};
        local_write_pmf_csv(fullfile(result_dir, ...
            sprintf('M64_lambda_%s_pmf.csv', local_lambda_tag(lambda))), ...
            qam, result.target_psym, result.model_psym, stats.empirical_psym);
        partial_table = cell2table(rows(1:il, :), 'VariableNames', local_names());
        writetable(partial_table, fullfile(result_dir, 'pmf_formal64_partial.csv'));
        save(fullfile(result_dir, 'checkpoint.mat'), 'results', 'cfg', 'M', ...
            'lambdas', 'snr_dB', 'n_boot', 'run_tag');
        local_log(progress_path, sprintf(['DONE M=%d lambda=%.6g TV=%.6f ' ...
            'upper95=%.6f formal_pass=%d'], M, lambda, stats.tv_point, ...
            stats.tv_upper95, formal_pass));
        fprintf('[PMF formal64] lambda=%.2f | TV=%.4f upper95=%.4f pass=%d\n', ...
            lambda, stats.tv_point, stats.tv_upper95, formal_pass);
    end
    result_table = cell2table(rows, 'VariableNames', local_names());
    overall_pass = all(result_table.formal_pass);
    writetable(result_table, fullfile(result_dir, 'pmf_formal64.csv'));
    save(fullfile(result_dir, 'results.mat'), 'results', 'cfg', 'M', 'lambdas', ...
        'snr_dB', 'n_boot', 'run_tag', 'result_table', 'overall_pass');
    local_write_readme(result_dir, cfg, lambdas, snr_dB, n_boot, overall_pass);
    local_plot(result_dir, result_table);
    local_log(progress_path, sprintf('DONE %s overall_pass=%d', datestr(now, 31), overall_pass));
    summary = struct('result_dir', result_dir, 'table', result_table, ...
        'overall_pass', overall_pass, 'results', {results});
    fprintf('[run_gray_qam_pmf_formal64] overall_pass=%d\n', overall_pass);
    fprintf('[run_gray_qam_pmf_formal64] saved: %s\n', result_dir);
    clear diary_cleanup;
end

function names = local_names()
    names = {'M','lambda','match_status','KL_target_model','TV_target_model', ...
        'TV_empirical_point','TV_empirical_upper95','formal_pass','E_target', ...
        'E_model','E_empirical','R_code','R_bpcu','latent_p'};
end

function local_write_pmf_csv(path_name, qam, target, model, empirical)
    T = table((1:qam.M).', real(qam.constellation), imag(qam.constellation), ...
        target(:), model(:), empirical(:), 'VariableNames', ...
        {'symbol_index','I','Q','target_pmf','model_pmf','empirical_pmf'});
    writetable(T, path_name);
end

function local_write_readme(result_dir, cfg, lambdas, snr_dB, n_boot, overall_pass)
    fid = fopen(fullfile(result_dir, 'README.txt'), 'w');
    fprintf(fid, 'v3 targeted formal PMF gate for 64QAM\n');
    fprintf(fid, 'lambda=%s; N=%d; frames=%d; seed=%d\n', ...
        mat2str(lambdas), cfg.N, cfg.num_frames, cfg.seed);
    fprintf(fid, 'source_mc_samples=%d; source_mc_seed=%d\n', ...
        cfg.source_mc_samples, cfg.source_mc_seed);
    fprintf(fid, 'snr_mode=%s; SNR=%.6g dB; cluster_bootstrap=%d\n', ...
        cfg.snr_mode, snr_dB, n_boot);
    fprintf(fid, ['Formal PMF gate: target-model status is not fail and independent-frame ' ...
        'cluster-bootstrap TV upper95<=0.05.\n']);
    fprintf(fid, ['8/16/32QAM already met this threshold in ' ...
        '20260902_224303_energy_lambda_smoke and are not rerun here.\n']);
    fprintf(fid, 'overall_pass=%d\n', overall_pass);
    fclose(fid);
end

function local_plot(result_dir, result_table)
    figure('Visible', 'off');
    bar(result_table.lambda, result_table.TV_empirical_upper95, 0.5); hold on;
    plot([min(result_table.lambda)-0.05, max(result_table.lambda)+0.05], ...
        [0.05 0.05], 'r--', 'LineWidth', 1.2, 'DisplayName', 'formal threshold');
    xlabel('Energy parameter lambda'); ylabel('Empirical PMF TV upper 95%');
    title('64QAM formal PMF gate'); grid on; legend('Location', 'best');
    saveas(gcf, fullfile(result_dir, 'pmf_formal64.png'));
    saveas(gcf, fullfile(result_dir, 'pmf_formal64.pdf'));
    savefig(gcf, fullfile(result_dir, 'pmf_formal64.fig'));
    close(gcf);
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
