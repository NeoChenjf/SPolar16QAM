function summary = run_gray_qam(mode)
%RUN_GRAY_QAM Unified v3 entry for PMF or energy-lambda smoke validation.
    root = fileparts(mfilename('fullpath')); addpath(root); setup_paths;
    if nargin < 1 || isempty(mode), mode = 'pmf_smoke'; end
    if strcmp(mode, 'energy_smoke')
        summary = run_gray_qam_energy_smoke();
        return;
    elseif strcmp(mode, 'ber_coarse')
        summary = run_gray_qam_ber_coarse();
        return;
    elseif strcmp(mode, 'ber_refine')
        summary = run_gray_qam_ber_refine();
        return;
    elseif strcmp(mode, 'pmf_formal64')
        summary = run_gray_qam_pmf_formal64();
        return;
    elseif strcmp(mode, 'blocklength_compare')
        summary = run_gray_qam_blocklength_compare('formal');
        return;
    elseif strcmp(mode, 'blocklength_compare_smoke')
        summary = run_gray_qam_blocklength_compare('smoke');
        return;
    elseif ~strcmp(mode, 'pmf_smoke')
        error('v3:RunMode', ...
            ['mode must be pmf_smoke, energy_smoke, ber_coarse, ber_refine, ' ...
            'pmf_formal64, blocklength_compare or blocklength_compare_smoke.']);
    end
    cfg = config();
    cfg.N = 256; cfg.num_frames = 40; cfg.seed = 20260830;
    cfg.snr_mode = 'fixed_n0'; cfg.force_nonzero_payload = false;
    cfg.collect_frame_pmf = true; cfg.source_construction = 'source_mc_ga';
    cfg.source_mc_samples = 120;
    run_tag = 'pmf_smoke'; Ms = [8 16 32 64]; snr_dB = 120;
    result_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_' run_tag]);
    if ~exist(result_dir, 'dir'), mkdir(result_dir); end
    rows = cell(numel(Ms), 7); results = cell(numel(Ms), 1);
    for im = 1:numel(Ms)
        M = Ms(im); qam = build_cartesian_gray_qam(M);
        spec = local_default_spec(qam);
        result = sim_shaped_polar_gray_qam(M, spec, snr_dB, cfg);
        frame_pmf = result.frame_psym(:, :, 1);
        pmf_stats = cluster_bootstrap_tv(frame_pmf, result.model_psym, 1000, cfg.seed + M);
        result.pmf_cluster = pmf_stats; results{im} = result;
        local_write_pmf_csv(fullfile(result_dir, sprintf('M%d_pmf.csv', M)), ...
            qam, result.model_psym, pmf_stats.empirical_psym);
        rows(im, :) = {M, result.R_code, result.R_bpcu, result.rf_energy_proxy_model, ...
            result.rf_energy_proxy_empirical, pmf_stats.tv_point, pmf_stats.tv_upper95};
        fprintf('[run_gray_qam] M=%d | TV=%.4f | upper95=%.4f | E=%.4f\n', ...
            M, pmf_stats.tv_point, pmf_stats.tv_upper95, result.rf_energy_proxy_empirical);
    end
    summary_table = cell2table(rows, 'VariableNames', {'M','R_code','R_bpcu','E_model','E_empirical','TV_point','TV_upper95'});
    writetable(summary_table, fullfile(result_dir, 'summary.csv'));
    save(fullfile(result_dir, 'results.mat'), 'results', 'cfg', 'Ms', 'snr_dB', 'run_tag');
    fid = fopen(fullfile(result_dir, 'README.txt'), 'w');
    fprintf(fid, 'v3 PMF smoke\nmode=fixed_n0; SNR=120 dB; N=%d; frames=%d\n', cfg.N, cfg.num_frames);
    fprintf(fid, 'source_construction=%s; source_mc_samples=%d\n', cfg.source_construction, cfg.source_mc_samples);
    fprintf(fid, 'TV_upper95 is a cluster bootstrap upper bound over independent frames.\n'); fclose(fid);
    figure('Visible', 'off'); bar(cell2mat(rows(:, 1)), cell2mat(rows(:, 7)));
    xlabel('QAM order M'); ylabel('PMF TV upper 95%%'); grid on;
    title('v3 PMF smoke: empirical versus model');
    saveas(gcf, fullfile(result_dir, 'pmf_tv_upper95.png')); close(gcf);
    summary = struct('result_dir', result_dir, 'table', summary_table, 'results', {results});
    fprintf('[run_gray_qam] saved: %s\n', result_dir);
end

function spec = local_default_spec(qam)
    pI = linspace(0.65, 0.8, qam.mI).'; pQ = linspace(0.65, 0.8, qam.mQ).';
    spec = struct('source', 'latent_p', 'pI', pI, 'pQ', pQ, ...
        'relation_I', frozen_gray_pam_relation(qam.mI), ...
        'relation_Q', frozen_gray_pam_relation(qam.mQ));
end

function local_write_pmf_csv(path_name, qam, model, empirical)
    T = table((1:qam.M).', real(qam.constellation), imag(qam.constellation), ...
        model(:), empirical(:), 'VariableNames', {'symbol_index','I','Q','model_pmf','empirical_pmf'});
    writetable(T, path_name);
end
