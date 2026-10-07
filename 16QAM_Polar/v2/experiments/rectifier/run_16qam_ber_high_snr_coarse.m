function out = run_16qam_ber_high_snr_coarse()
%RUN_16QAM_BER_HIGH_SNR_COARSE Exploratory high-SNR BER convergence sweep.
% Uses the same SC/fixed_esn0 chain as the midterm task-2 experiment.

    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(root);
    setup_paths;

    cfg = config();
    cfg.decoder = 'SC';
    cfg.snr_mode = 'fixed_esn0';
    cfg.llr_use_legacy_noisevar = false;
    cfg.num_frames = 20;
    cfg.seed = 4242;

    ps = [0.5, 0.4, 0.3, 0.2, 0.1];
    snrs = 20:5:40;
    initial_snrs = snrs;
    all_rows = zeros(0, 11);
    per_bit = zeros(numel(ps), 4, numel(snrs));
    K_by_p = zeros(numel(ps), 4);

    stamp = datestr(now, 'yyyymmdd_HHMMSS');
    out = fullfile(cfg.output_dir, [stamp, '_16qam_ber_high_snr_coarse']);
    if exist(out, 'dir')
        error('berCoarse:OutputExists', 'Refuse to overwrite %s', out);
    end
    mkdir(out);
    mkdir(fullfile(out, 'figures'));
    diary(fullfile(out, 'run_log.txt'));
    diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>

    fprintf('Exploratory BER coarse sweep: N=%d, frames=%d, seed=%d\n', ...
        cfg.N, cfg.num_frames, cfg.seed);
    fprintf('SNR labels: %s dB; actual Es/N0 = label - 3.0103 dB\n', mat2str(snrs));

    for ip = 1:numel(ps)
        result = sim_shaped_polar_16qam(ps(ip), snrs, cfg);
        K_by_p(ip, :) = result.K;
        per_bit(ip, :, :) = reshape(result.BER_per_bit, [1, 4, numel(snrs)]);
        [rows, total_errors] = make_rows(ps(ip), result, cfg.num_frames);
        all_rows = [all_rows; rows]; %#ok<AGROW>

        if any(total_errors(end) > 0) && snrs(end) == 40
            extra_snrs = [45, 50];
            fprintf('p=%.1f still has errors at 40 dB; extending to 45 and 50 dB.\n', ps(ip));
            extra = sim_shaped_polar_16qam(ps(ip), extra_snrs, cfg);
            per_bit(ip, :, end+1:end+2) = reshape(extra.BER_per_bit, [1, 4, 2]);
            [extra_rows, ~] = make_rows(ps(ip), extra, cfg.num_frames);
            all_rows = [all_rows; extra_rows]; %#ok<AGROW>
            snrs = [snrs, extra_snrs]; %#ok<AGROW>
        end
    end

    % Rebuild a rectangular array indexed by p and SNR for plotting/reporting.
    per_bit = zeros(numel(ps), 4, numel(snrs));
    total_ber = zeros(numel(ps), numel(snrs));
    total_errors = zeros(numel(ps), numel(snrs));
    total_bits = zeros(numel(ps), numel(snrs));
    upper95 = nan(numel(ps), numel(snrs));
    for ip = 1:numel(ps)
        for is = 1:numel(snrs)
            idx = all_rows(:,1) == ps(ip) & all_rows(:,2) == snrs(is);
            row = all_rows(idx, :);
            if isempty(row), continue; end
            per_bit(ip,:,is) = row(1,5:8);
            total_errors(ip,is) = row(1,9);
            total_bits(ip,is) = row(1,10);
            total_ber(ip,is) = row(1,11);
            if total_errors(ip,is) == 0
                upper95(ip,is) = 1 - 0.05^(1 / total_bits(ip,is));
            end
        end
    end

    % Internally verify weighted BER and error/bit accounting before writing.
    for ip = 1:numel(ps)
        for is = 1:numel(snrs)
            if total_bits(ip,is) == 0, continue; end
            weighted = sum(K_by_p(ip,:) .* per_bit(ip,:,is)) / sum(K_by_p(ip,:));
            assert(abs(weighted - total_ber(ip,is)) < 1e-12, 'Weighted BER mismatch.');
            assert(abs(total_bits(ip,is) - cfg.num_frames * sum(K_by_p(ip,:))) < 1e-9);
            assert(abs(total_errors(ip,is) - round(total_ber(ip,is)*total_bits(ip,is))) < 1e-7);
        end
    end

    headers = {'p','snr_label_dB','actual_esn0_dB','frames','K1','K2','K3','K4', ...
        'ber_bit1','ber_bit2','ber_bit3','ber_bit4','errors_total','info_bits_total', ...
        'ber_total','ber_zero_error_upper95'};
    csv = fullfile(out, 'coarse_ber.csv');
    fid = fopen(csv, 'w');
    if fid < 0, error('berCoarse:WriteFailed', 'Cannot write %s', csv); end
    fprintf(fid, '%s\n', strjoin(headers, ','));
    for ip = 1:numel(ps)
        for is = 1:numel(snrs)
            if total_bits(ip,is) == 0, continue; end
            fprintf(fid, '%.1f,%.1f,%.6f,%d,%d,%d,%d,%d,%.12g,%.12g,%.12g,%.12g,%d,%d,%.12g,%.12g\n', ...
                ps(ip), snrs(is), snrs(is)-10*log10(2), cfg.num_frames, K_by_p(ip,:), ...
                per_bit(ip,:,is), total_errors(ip,is), total_bits(ip,is), total_ber(ip,is), upper95(ip,is));
        end
    end
    fclose(fid);

    fig = figure('Visible','off','Color','w');
    hold on;
    colors = lines(numel(ps));
    markers = {'o','s','^','d','v'};
    for ip = 1:numel(ps)
        y = total_ber(ip,:);
        positive = y > 0;
        if any(positive)
            semilogy(snrs(positive), y(positive), ['-', markers{ip}], ...
                'Color', colors(ip,:), 'LineWidth', 1.5, 'MarkerSize', 6, ...
                'DisplayName', sprintf('p = %.1f', ps(ip)));
        end
        zero_idx = find(total_bits(ip,:) > 0 & total_errors(ip,:) == 0);
        if ~isempty(zero_idx)
            semilogy(snrs(zero_idx), upper95(ip,zero_idx), 'x', ...
                'Color', colors(ip,:), 'MarkerSize', 9, 'LineWidth', 1.8, ...
                'HandleVisibility','off');
        end
    end
    semilogy(NaN, NaN, 'kx', 'MarkerSize', 8, 'LineWidth', 1.5, ...
        'DisplayName', 'x: zero-error 95% upper bound');
    grid on; box on;
    set(gca, 'YScale', 'log');
    xlabel('SNR label (dB)');
    ylabel('BER or 95% upper bound after zero errors');
    title('Exploratory high-SNR BER sweep (20 frames per point)');
    legend('Location','northeast','FontSize',8);
    ylim([5e-5, 0.2]);
    figdir = fullfile(out, 'figures');
    print(fig, fullfile(figdir, 'ber_high_snr_coarse.png'), '-dpng', '-r180');
    print(fig, fullfile(figdir, 'ber_high_snr_coarse.pdf'), '-dpdf', '-painters');
    close(fig);

    params = struct('cfg', cfg, 'p_values', ps, 'initial_snr_labels_dB', initial_snrs, ...
        'actual_snr_definition', 'label - 10*log10(2) dB', 'final_snr_labels_dB', snrs, ...
        'seed', cfg.seed, 'frames_per_point', cfg.num_frames, ...
        'extension_rule', 'Add 45 and 50 dB for a p when errors remain at 40 dB.');
    save(fullfile(out, 'coarse_ber.mat'), 'params', 'all_rows', 'total_ber', ...
        'total_errors', 'total_bits', 'upper95', 'per_bit', 'K_by_p');

    fid = fopen(fullfile(out, 'README.txt'), 'w');
    if fid < 0, error('berCoarse:WriteFailed', 'Cannot write README.'); end
    fprintf(fid, ['Exploratory high-SNR BER convergence check.\n', ...
        'Chain: sim_shaped_polar_16qam, SC decoder, fixed_esn0, same configuration convention as task-2 formal data.\n', ...
        'p=[0.5 0.4 0.3 0.2 0.1], initial SNR labels=[20 25 30 35 40] dB, 20 frames/point, seed=4242.\n', ...
        'If a p has any errors at 40 dB, that p is also evaluated at 45 and 50 dB.\n', ...
        'Actual Es/N0 label = label - 3.0103 dB. Zero errors means none observed in this sample, not theoretical BER=0.\n', ...
        'ber_zero_error_upper95 is the one-sided exact binomial 95%% upper bound: 1 - 0.05^(1/info_bits).\n', ...
        'This small exploratory run is not pooled with the formal three-seed, 300-frame results.\n', ...
        'Files: coarse_ber.csv, coarse_ber.mat, figures/ber_high_snr_coarse.png and .pdf, run_log.txt.\n']);
    fclose(fid);
    fprintf('Saved exploratory results to %s\n', out);

    function [rows, errors] = make_rows(p, r, nframes)
        n = numel(r.snr_dB);
        rows = zeros(n, 11);
        errors = zeros(1,n);
        for jj = 1:n
            bits = nframes * sum(r.K);
            ber = r.BER(jj);
            err = round(ber * bits);
            errors(jj) = err;
            rows(jj,:) = [p, r.snr_dB(jj), r.snr_dB(jj)-10*log10(2), nframes, ...
                r.BER_per_bit(:,jj)', err, bits, ber];
        end
    end
end
