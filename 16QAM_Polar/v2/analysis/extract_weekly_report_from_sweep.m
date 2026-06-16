function extract_weekly_report_from_sweep(result_dir)
% EXTRACT_WEEKLY_REPORT_FROM_SWEEP
% 从 sweep_results.mat 自动提取：
% 1) 每个 SNR 下 Goodput 最优 p
% 2) 每个 SNR 下 Goodput-Energy Pareto 前沿点
% 并输出可直接粘贴到周报的 markdown 文件。

    if nargin < 1 || isempty(result_dir)
        error('请传入结果目录，例如 ...\\v2\\results\\20260303_082329_pareto_sweep');
    end

    mat_file = fullfile(result_dir, 'sweep_results.mat');
    if ~exist(mat_file, 'file')
        error('未找到文件: %s', mat_file);
    end

    data = load(mat_file, 'p_list', 'snr_dB', 'Goodput_matrix', 'BER_matrix', 'E_norm_vec', 'E_theory_vec');

    p_list = data.p_list(:);
    snr_dB = data.snr_dB(:);
    G = data.Goodput_matrix;
    BER = data.BER_matrix;
    E_norm = data.E_norm_vec(:);
    E_theory = data.E_theory_vec(:);

    nP = length(p_list);
    nSNR = length(snr_dB);

    %% ===== 1) 每个 SNR 的最优 p（按 Goodput 最大） =====
    best_idx = zeros(nSNR, 1);
    best_p = zeros(nSNR, 1);
    best_G = zeros(nSNR, 1);
    best_BER = zeros(nSNR, 1);
    best_E_norm = zeros(nSNR, 1);
    best_E_theory = zeros(nSNR, 1);

    for i = 1:nSNR
        [best_G(i), idx] = max(G(:, i));
        best_idx(i) = idx;
        best_p(i) = p_list(idx);
        best_BER(i) = BER(idx, i);
        best_E_norm(i) = E_norm(idx);
        best_E_theory(i) = E_theory(idx);
    end

    T_best = table(snr_dB, best_p, best_G, best_BER, best_E_norm, best_E_theory, ...
                   'VariableNames', {'SNR_dB','p_opt','Goodput_opt','BER_at_p_opt','E_norm','E_theory'});
    writetable(T_best, fullfile(result_dir, 'best_p_per_snr.csv'));

    %% ===== 2) 每个 SNR 的 Pareto 前沿点（最大化 Goodput，最小化 E_norm） =====
    pareto_rows = [];
    for i = 1:nSNR
        keep = true(nP, 1);
        for a = 1:nP
            for b = 1:nP
                if a == b
                    continue;
                end
                dominate = (E_norm(b) <= E_norm(a)) && (G(b, i) >= G(a, i)) && ...
                           ((E_norm(b) < E_norm(a)) || (G(b, i) > G(a, i)));
                if dominate
                    keep(a) = false;
                    break;
                end
            end
        end

        idx_keep = find(keep);
        [~, order] = sort(E_norm(idx_keep), 'ascend');
        idx_keep = idx_keep(order);

        snr_col = repmat(snr_dB(i), numel(idx_keep), 1);
        pareto_rows = [pareto_rows; [snr_col, p_list(idx_keep), E_norm(idx_keep), E_theory(idx_keep), G(idx_keep, i), BER(idx_keep, i)]]; %#ok<AGROW>
    end

    T_pareto = array2table(pareto_rows, ...
        'VariableNames', {'SNR_dB','p','E_norm','E_theory','Goodput','BER'});
    writetable(T_pareto, fullfile(result_dir, 'pareto_points_per_snr.csv'));

    %% ===== 3) 生成周报 Markdown 片段 =====
    md_file = fullfile(result_dir, 'weekly_report_extract.md');
    fid = fopen(md_file, 'w');
    if fid < 0
        error('无法写入 markdown 文件: %s', md_file);
    end

    fprintf(fid, '## 自动提取结果（基于 sweep_results.mat）\n\n');
    fprintf(fid, '- 结果目录：`%s`\n', strrep(result_dir, '\\', '/'));
    fprintf(fid, '- 结论口径：每个 SNR 下，以 Goodput 最大对应的 p 作为最优 p。\n\n');

    fprintf(fid, '### 1) 每个 SNR 下最优 p\n\n');
    fprintf(fid, '| SNR(dB) | p_opt | Goodput_opt | BER@p_opt | E_norm | E_theory |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|---:|\n');
    for i = 1:nSNR
        fprintf(fid, '| %.0f | %.2f | %.6f | %.3e | %.3f | %.2f |\n', ...
            T_best.SNR_dB(i), T_best.p_opt(i), T_best.Goodput_opt(i), T_best.BER_at_p_opt(i), ...
            T_best.E_norm(i), T_best.E_theory(i));
    end

    fprintf(fid, '\n### 2) Pareto 前沿点（每个 SNR 单独计算）\n\n');
    fprintf(fid, '| SNR(dB) | p | E_norm | E_theory | Goodput | BER |\n');
    fprintf(fid, '|---:|---:|---:|---:|---:|---:|\n');
    for i = 1:height(T_pareto)
        fprintf(fid, '| %.0f | %.2f | %.3f | %.2f | %.6f | %.3e |\n', ...
            T_pareto.SNR_dB(i), T_pareto.p(i), T_pareto.E_norm(i), T_pareto.E_theory(i), ...
            T_pareto.Goodput(i), T_pareto.BER(i));
    end

    fclose(fid);

    fprintf('已生成: %s\n', fullfile(result_dir, 'best_p_per_snr.csv'));
    fprintf('已生成: %s\n', fullfile(result_dir, 'pareto_points_per_snr.csv'));
    fprintf('已生成: %s\n', md_file);
end
