function plot_pareto(p_list, snr_dB, Goodput_matrix, E_norm_vec, snr_targets, fig_dir)
% PLOT_PARETO - 绘制 Goodput vs 归一化能量的 Pareto 前沿图
%
% 输入：
%   p_list         - p 值向量 (nP x 1)
%   snr_dB         - SNR 向量 (1 x nSNR)
%   Goodput_matrix - Goodput 矩阵 (nP x nSNR)
%   E_norm_vec     - 归一化能量向量 (nP x 1)
%   snr_targets    - 要绘制的 SNR 值
%   fig_dir        - 图表保存目录

    colors = lines(length(snr_targets));

    fig = figure('Position', [100 100 800 600], 'Visible', 'off');
    hold on;
    for is = 1:length(snr_targets)
        snr_t = snr_targets(is);
        [~, idx] = min(abs(snr_dB - snr_t));

        G_at_snr = Goodput_matrix(:, idx);

        % 绘制散点 + 连线
        plot(E_norm_vec, G_at_snr, '-o', ...
             'Color', colors(is,:), ...
             'LineWidth', 1.5, ...
             'MarkerSize', 6, ...
             'MarkerFaceColor', colors(is,:), ...
             'DisplayName', sprintf('SNR = %d dB', snr_dB(idx)));

        % 标注 p 值
        for ip = 1:length(p_list)
            text(E_norm_vec(ip)+0.01, G_at_snr(ip), ...
                 sprintf('%.2f', p_list(ip)), ...
                 'FontSize', 7, 'Color', colors(is,:));
        end
    end
    hold off;
    xlabel('归一化能量 E/E_0', 'FontSize', 12);
    ylabel('Goodput', 'FontSize', 12);
    title('Pareto 前沿：Goodput vs 能量（不同 SNR）', 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    set(gca, 'FontSize', 11);

    saveas(fig, fullfile(fig_dir, 'pareto_goodput_energy.pdf'));
    saveas(fig, fullfile(fig_dir, 'pareto_goodput_energy.png'));
    close(fig);
end
