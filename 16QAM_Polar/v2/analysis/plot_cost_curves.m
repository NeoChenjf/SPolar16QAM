function plot_cost_curves(p_list, snr_dB, Goodput_matrix, E_theory_vec, ...
                          idx_baseline, snr_targets, fig_dir)
% PLOT_COST_CURVES - 绘制能量-信息代价函数曲线
%
% 输入：
%   p_list          - p 值向量
%   snr_dB          - SNR 向量
%   Goodput_matrix  - Goodput 矩阵 (nP x nSNR)
%   E_theory_vec    - 理论能量向量 (nP x 1)
%   idx_baseline    - 基线 (p=0.5) 在 p_list 中的索引
%   snr_targets     - 要绘制的 SNR 值
%   fig_dir         - 图表保存目录

    G0_vec = Goodput_matrix(idx_baseline, :);  % 基线 Goodput (1 x nSNR)
    E0 = E_theory_vec(idx_baseline);

    colors = lines(length(snr_targets));

    fig = figure('Position', [100 100 800 600], 'Visible', 'off');
    hold on;
    for is = 1:length(snr_targets)
        snr_t = snr_targets(is);
        [~, idx_snr] = min(abs(snr_dB - snr_t));

        cost_vec = compute_cost(Goodput_matrix(:, idx_snr), ...
                                E_theory_vec, ...
                                G0_vec(idx_snr), E0);

        plot(p_list, cost_vec, '-o', ...
             'Color', colors(is,:), ...
             'LineWidth', 1.5, ...
             'MarkerSize', 6, ...
             'MarkerFaceColor', colors(is,:), ...
             'DisplayName', sprintf('SNR = %d dB', snr_dB(idx_snr)));
    end
    hold off;
    xlabel('整形参数 p', 'FontSize', 12);
    ylabel('cost = -\DeltaG / \DeltaE', 'FontSize', 12);
    title('能量-信息代价函数（越小越好）', 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    set(gca, 'FontSize', 11, 'XDir', 'reverse');

    saveas(fig, fullfile(fig_dir, 'cost_curves.pdf'));
    saveas(fig, fullfile(fig_dir, 'cost_curves.png'));
    close(fig);
end
