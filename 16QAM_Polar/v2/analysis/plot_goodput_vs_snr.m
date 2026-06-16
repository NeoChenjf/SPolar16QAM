function plot_goodput_vs_snr(p_list, snr_dB, Goodput_matrix, fig_dir)
% PLOT_GOODPUT_VS_SNR - 绘制不同 p 下的 Goodput vs SNR 曲线
%
% 输入：
%   p_list          - p 值向量
%   snr_dB          - SNR 向量
%   Goodput_matrix  - Goodput 矩阵 (nP x nSNR)
%   fig_dir         - 图表保存目录

    markers = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h', '+'};
    colors = lines(length(p_list));

    fig = figure('Position', [100 100 800 600], 'Visible', 'off');
    hold on;
    for ip = 1:length(p_list)
        mk = markers{mod(ip-1, length(markers)) + 1};
        plot(snr_dB, Goodput_matrix(ip,:), ['-' mk], ...
             'Color', colors(ip,:), ...
             'LineWidth', 1.5, ...
             'MarkerSize', 5, ...
             'DisplayName', sprintf('p = %.2f', p_list(ip)));
    end
    hold off;
    xlabel('SNR (dB)', 'FontSize', 12);
    ylabel('Goodput', 'FontSize', 12);
    title('Goodput vs SNR（不同整形参数 p）', 'FontSize', 14);
    legend('Location', 'southeast', 'FontSize', 9);
    grid on;
    set(gca, 'FontSize', 11);

    saveas(fig, fullfile(fig_dir, 'goodput_vs_snr.pdf'));
    saveas(fig, fullfile(fig_dir, 'goodput_vs_snr.png'));
    close(fig);
end
