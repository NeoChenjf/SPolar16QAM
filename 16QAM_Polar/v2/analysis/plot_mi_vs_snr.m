function plot_mi_vs_snr(p_list, snr_dB, MI_matrix, fig_dir)
% PLOT_MI_VS_SNR - 绘制不同 p 下的总互信息 vs SNR 曲线
%
% 输入：
%   p_list    - p 值向量
%   snr_dB    - SNR 向量
%   MI_matrix - 总互信息矩阵 (nP x nSNR)
%   fig_dir   - 图表保存目录

    markers = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h', '+'};
    colors = lines(length(p_list));

    fig = figure('Position', [100 100 800 600], 'Visible', 'off');
    hold on;
    for ip = 1:length(p_list)
        mk = markers{mod(ip-1, length(markers)) + 1};
        plot(snr_dB, MI_matrix(ip,:), ['-' mk], ...
             'Color', colors(ip,:), ...
             'LineWidth', 1.5, ...
             'MarkerSize', 5, ...
             'DisplayName', sprintf('p = %.2f', p_list(ip)));
    end
    hold off;
    xlabel('SNR (dB)', 'FontSize', 12);
    ylabel('I(B;L) total (bits/symbol)', 'FontSize', 12);
    title('总互信息 vs SNR（不同整形参数 p）', 'FontSize', 14);
    legend('Location', 'southeast', 'FontSize', 9);
    grid on;
    set(gca, 'FontSize', 11);
    ylim([0, 4.5]);

    saveas(fig, fullfile(fig_dir, 'mi_vs_snr.pdf'));
    saveas(fig, fullfile(fig_dir, 'mi_vs_snr.png'));
    close(fig);
end
