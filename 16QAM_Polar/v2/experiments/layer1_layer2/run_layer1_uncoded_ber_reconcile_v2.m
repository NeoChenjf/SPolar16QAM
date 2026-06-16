%% RUN_LAYER1_UNCODED_BER_RECONCILE_V2 - 第1层重构：无编码 BER 曲线对账（跨SNR）
%
% 目标：
% 1) 对每个 p 输出 BER-SNR 曲线（而非只看单点比值）
% 2) 在 fixed_esn0 / fixed_n0 下分别做理论-仿真对账
% 3) 输出一致性指标（单调性、相对误差）
%
% 说明：
% - 本脚本是“纯调制层”验证，不涉及极化编码译码
% - 理论 BER 使用与 qamdemod 一致的 ML 硬判决“判决区域高斯积分”：
%     BER_ml_exact(p,gamma) = E_{S,N}[ dH(b(S), b(D(S+N)))/4 ]
%   其中 D(·) 与仿真中的 qamdemod 完全一致
% - 该理论为“数值精确口径”（非近邻高SNR近似）

clear; clc; close all;

setup_paths();
cfg = config();

%% ===== 可调参数 =====
p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
snr_grid = -20:2:20;
snr_modes = {'fixed_esn0', 'fixed_n0'};

% 自适应停机：每个 (mode,p,snr) 至少累计 min_errs 个错误，否则到 max_symbols 停止
min_errs = 1000;
max_symbols = 1e6;
chunk_symbols = 10000;
seed = 20260406;

rng(seed, 'twister');

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_layer1_uncoded_ber_reconcile_v2']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

nM = numel(snr_modes);
nP = numel(p_list);
nS = numel(snr_grid);

ber_sim = nan(nM, nP, nS);
ber_theory = nan(nM, nP, nS);
used_symbols = zeros(nM, nP, nS);
used_errors = zeros(nM, nP, nS);

idx_ref = find(abs(p_list - 0.5) < 1e-12, 1);
if isempty(idx_ref)
    error('p_list 必须包含 0.5 作为归一化参考点。');
end

%% ===== 主循环 =====
for im = 1:nM
    mode_name = snr_modes{im};
    fprintf('\n=== Mode: %s ===\n', mode_name);

    for ip = 1:nP
        p = p_list(ip);
        Es_theory = (18 - 16 * p) / 10;  % 与 UnitAveragePower=true 下的非均匀平均能量一致

        for is = 1:nS
            snr_db = snr_grid(is);
            sigma = 10^(-snr_db / 20);

            total_bits = 0;
            total_err = 0;
            total_sym = 0;

            while (total_err < min_errs) && (total_sym < max_symbols)
                nSym = min(chunk_symbols, max_symbols - total_sym);
                if nSym <= 0
                    break;
                end

                % bit1/bit3 固定 0.5，bit2/bit4 由 p 控制
                b1 = rand(nSym, 1) < 0.5;
                b2 = rand(nSym, 1) < p;
                b3 = rand(nSym, 1) < 0.5;
                b4 = rand(nSym, 1) < p;
                tx_bits = double([b1, b2, b3, b4]);

                % 显式按“每4bit一个符号”串行化，避免 qammod 对矩阵输入的列优先打包偏差。
                tx_bits_col = zeros(nSym * cfg.bits_per_symbol, 1);
                tx_bits_col(1:4:end) = tx_bits(:, 1);
                tx_bits_col(2:4:end) = tx_bits(:, 2);
                tx_bits_col(3:4:end) = tx_bits(:, 3);
                tx_bits_col(4:4:end) = tx_bits(:, 4);

                tx_sym = qammod(tx_bits_col, cfg.M, cfg.mapping, ...
                                'InputType', 'bit', ...
                                'UnitAveragePower', cfg.unit_avg_power);
                tx_sym = tx_sym(:);

                switch mode_name
                    case 'fixed_n0'
                        sigma_noise = sqrt(cfg.snr_ref_power) * sigma;
                    otherwise
                        % fixed_esn0: 噪声随当前帧符号功率缩放
                        spow_frame = mean(abs(tx_sym).^2);
                        sigma_noise = sqrt(spow_frame) * sigma;
                end

                noise = sigma_noise .* (randn(nSym,1) + 1j .* randn(nSym,1));
                rx_sym = tx_sym + noise;

                rx_bits = qamdemod(rx_sym, cfg.M, cfg.mapping, ...
                                   'OutputType', 'bit', ...
                                   'UnitAveragePower', cfg.unit_avg_power);

                bit_err = sum(rx_bits(:) ~= tx_bits_col(:));
                total_err = total_err + bit_err;
                total_bits = total_bits + numel(tx_bits_col);
                total_sym = total_sym + nSym;
            end

            ber_sim(im, ip, is) = total_err / max(total_bits, 1);
            used_symbols(im, ip, is) = total_sym;
            used_errors(im, ip, is) = total_err;

            % 理论 BER（ML 数值精确口径）：
            % 使用与仿真完全一致的 qamdemod 判决器，在二维高斯噪声下积分
            % BER_ml_exact = E[dH(b, b_hat)/4]

            switch mode_name
                case 'fixed_n0'
                    sigma_theory = sqrt(cfg.snr_ref_power) * sigma;
                otherwise
                    sigma_theory = sqrt(Es_theory) * sigma;
            end

            ber_theory(im, ip, is) = local_theory_ber_ml_exact(p, sigma_theory, cfg);

            fprintf('  p=%.2f, SNR=%+5.1f dB | BER_sim=%.3e | BER_theory=%.3e | nSym=%d\n', ...
                p, snr_db, ber_sim(im, ip, is), ber_theory(im, ip, is), total_sym);
        end
    end
end

%% ===== 比值与一致性指标 =====
ratio_sim = nan(nM, nP, nS);
ratio_theory = nan(nM, nP, nS);
for im = 1:nM
    ber_ref_sim = squeeze(ber_sim(im, idx_ref, :));
    ber_ref_theory = squeeze(ber_theory(im, idx_ref, :));
    for ip = 1:nP
        ratio_sim(im, ip, :) = squeeze(ber_sim(im, ip, :)) ./ max(ber_ref_sim, eps);
        ratio_theory(im, ip, :) = squeeze(ber_theory(im, ip, :)) ./ max(ber_ref_theory, eps);
    end
end

% 一致性指标：对每个模式统计 p 方向单调违例比例（p 递减时 ratio 期望不增）
mono_violation = zeros(nM, nS);
for im = 1:nM
    for is = 1:nS
        y = squeeze(ratio_sim(im, :, is));
        % p_list 由大到小，期望 y 非增：diff(y)<=0
        v = diff(y) > 0;
        mono_violation(im, is) = mean(v);
    end
end

%% ===== 导出表格 =====
for im = 1:nM
    mode_name = snr_modes{im};

    % 长表：每个 (p, snr) 一行
    nRows = nP * nS;
    [P_grid, S_grid] = ndgrid(p_list, snr_grid);

    T = table();
    T.p = P_grid(:);
    T.snr_dB = S_grid(:);
    T.ber_sim = reshape(squeeze(ber_sim(im, :, :)), nRows, 1);
    T.ber_theory = reshape(squeeze(ber_theory(im, :, :)), nRows, 1);
    T.ratio_sim = reshape(squeeze(ratio_sim(im, :, :)), nRows, 1);
    T.ratio_theory = reshape(squeeze(ratio_theory(im, :, :)), nRows, 1);
    T.used_symbols = reshape(squeeze(used_symbols(im, :, :)), nRows, 1);
    T.used_errors = reshape(squeeze(used_errors(im, :, :)), nRows, 1);

    writetable(T, fullfile(out_dir, sprintf('layer1_v2_curves_%s.csv', mode_name)));

    Tm = table();
    Tm.snr_dB = snr_grid(:);
    Tm.monotonic_violation_ratio = mono_violation(im, :).';
    writetable(Tm, fullfile(out_dir, sprintf('layer1_v2_consistency_%s.csv', mode_name)));
end

save(fullfile(out_dir, 'layer1_uncoded_reconcile_v2.mat'), ...
    'p_list', 'snr_grid', 'snr_modes', 'ber_sim', 'ber_theory', 'ratio_sim', 'ratio_theory', ...
    'used_symbols', 'used_errors', 'mono_violation', ...
    'min_errs', 'max_symbols', 'chunk_symbols', 'seed');

%% ===== 绘图1：BER-SNR 曲线（每个 p 一条） =====
for im = 1:nM
    mode_name = snr_modes{im};
    mode_label = strrep(mode_name, 'fixed_n0', 'fixed_{n0}');
    mode_label = strrep(mode_label, 'fixed_esn0', 'fixed_{esn0}');
    fig = figure('Position', [80 80 980 560], 'Visible', 'off');
    colors = lines(nP);
    hold on;

    for ip = 1:nP
        semilogy(snr_grid, squeeze(ber_sim(im, ip, :)), '-o', ...
            'Color', colors(ip,:), 'LineWidth', 1.6, 'MarkerSize', 5, ...
            'DisplayName', sprintf('Sim p=%.1f', p_list(ip)));
        semilogy(snr_grid, squeeze(ber_theory(im, ip, :)), '--', ...
            'Color', colors(ip,:), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('Theory p=%.1f', p_list(ip)));
    end

    hold off;
    grid on;
    xlabel('SNR (dB)');
    ylabel('BER');
    title(sprintf('Layer1-v2 BER vs SNR (%s)', mode_label));
    legend('Location', 'southwest');

    exportgraphics(fig, fullfile(fig_dir, sprintf('layer1_v2_ber_curve_%s.png', mode_name)), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, sprintf('layer1_v2_ber_curve_%s.pdf', mode_name)), 'ContentType', 'vector');
    close(fig);
end

%% ===== 绘图2：相对比值（相对 p=0.5） =====
for im = 1:nM
    mode_name = snr_modes{im};
    mode_label = strrep(mode_name, 'fixed_n0', 'fixed_{n0}');
    mode_label = strrep(mode_label, 'fixed_esn0', 'fixed_{esn0}');
    fig = figure('Position', [80 80 980 560], 'Visible', 'off');
    colors = lines(nS);
    hold on;

    for is = 1:nS
        plot(p_list, squeeze(ratio_sim(im, :, is)), '-o', ...
            'Color', colors(is,:), 'LineWidth', 1.5, 'MarkerSize', 4, ...
            'DisplayName', sprintf('Sim @ %d dB', snr_grid(is)));
        plot(p_list, squeeze(ratio_theory(im, :, is)), '--', ...
            'Color', colors(is,:), 'LineWidth', 1.2, ...
            'DisplayName', sprintf('Theory @ %d dB', snr_grid(is)));
    end

    yline(1.0, 'k:', 'LineWidth', 1.2, 'DisplayName', 'ratio=1');
    hold off;
    grid on;
    xlabel('Shaping parameter p');
    ylabel('BER ratio to p=0.5');
    title(sprintf('Layer1-v2 Ratio vs p (%s)', mode_label));
    legend('Location', 'bestoutside');
    set(gca, 'XDir', 'reverse');

    exportgraphics(fig, fullfile(fig_dir, sprintf('layer1_v2_ratio_%s.png', mode_name)), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, sprintf('layer1_v2_ratio_%s.pdf', mode_name)), 'ContentType', 'vector');
    close(fig);
end

%% ===== README =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
fprintf(fid, 'Layer1-v2: uncoded BER-vs-SNR reconcile with dual SNR modes\n');
fprintf(fid, 'p_list = [0.5, 0.4, 0.3, 0.2, 0.1]\n');
fprintf(fid, 'snr_grid = %g:%g:%g dB\n', snr_grid(1), snr_grid(2)-snr_grid(1), snr_grid(end));
fprintf(fid, 'snr_modes = {fixed_esn0, fixed_n0}\n');
fprintf(fid, 'stopping rule: min_errs=%d, max_symbols=%d, chunk_symbols=%d\n', ...
    min_errs, max_symbols, chunk_symbols);
fprintf(fid, 'theory: BER_ml_exact via Gaussian-CDF integration over ML decision regions\n');
fprintf(fid, '\nMain outputs:\n');
fprintf(fid, '- layer1_v2_curves_fixed_esn0.csv\n');
fprintf(fid, '- layer1_v2_curves_fixed_n0.csv\n');
fprintf(fid, '- layer1_v2_consistency_fixed_esn0.csv\n');
fprintf(fid, '- layer1_v2_consistency_fixed_n0.csv\n');
fprintf(fid, '- figures/layer1_v2_ber_curve_*.png/pdf\n');
fprintf(fid, '- figures/layer1_v2_ratio_*.png/pdf\n');
fclose(fid);

fprintf('\n===== Layer1-v2 执行完成 =====\n');
fprintf('结果目录: %s\n', out_dir);


function ber = local_theory_ber_ml_exact(p, sigma_noise, cfg)
% LOCAL_THEORY_BER_ML_EXACT
% 采用“判决区域矩形积分”计算 qamdemod(ML) 下的无编码 BER。
% 对每个发送符号 s_i、每个判决符号 s_j，计算 P(j|i)=P(I落入区间)*P(Q落入区间)。

    M = cfg.M;
    const = qammod((0:M-1).', M, cfg.mapping, 'UnitAveragePower', cfg.unit_avg_power);
    % 关键修复：标签必须与 qamdemod 的 Gray 映射完全一致，不能用 de2bi 近似替代。
    labels_raw = qamdemod(const, M, cfg.mapping, ...
                          'OutputType', 'bit', ...
                          'UnitAveragePower', cfg.unit_avg_power);
    labels_raw = double(labels_raw);

    % 兼容不同返回形状：统一为 M x bits_per_symbol 的标签矩阵。
    k = cfg.bits_per_symbol;
    if isvector(labels_raw)
        labels = reshape(labels_raw, k, []).';
    else
        labels = labels_raw;
    end

    if size(labels,1) ~= M || size(labels,2) ~= k
        error('理论标签维度异常：size(labels)=[%d,%d], 期望=[%d,%d]', ...
              size(labels,1), size(labels,2), M, k);
    end
    xj = real(const);
    yj = imag(const);

    % 16QAM (UnitAveragePower=true) 轴向电平为 ±1/sqrt(10), ±3/sqrt(10)
    a = 1 / sqrt(10);
    b1 = -2 * a;
    b2 = 0;
    b3 = 2 * a;

    % 为每个判决点构造 I/Q 判决区间
    x_lo = zeros(M,1); x_hi = zeros(M,1);
    y_lo = zeros(M,1); y_hi = zeros(M,1);
    for j = 1:M
        [x_lo(j), x_hi(j)] = local_axis_interval(xj(j), b1, b2, b3);
        [y_lo(j), y_hi(j)] = local_axis_interval(yj(j), b1, b2, b3);
    end

    p_vec = cfg.p_fixed;
    p_vec(isnan(p_vec)) = p;
    psym = local_build_symbol_prior(p_vec, labels);

    ber = 0;
    for iSym = 1:M
        muI = real(const(iSym));
        muQ = imag(const(iSym));

        ber_cond = 0;
        for j = 1:M
            pI = local_interval_prob(x_lo(j), x_hi(j), muI, sigma_noise);
            pQ = local_interval_prob(y_lo(j), y_hi(j), muQ, sigma_noise);
            pij = pI * pQ;

            hd = sum(labels(iSym, :) ~= labels(j, :));
            ber_cond = ber_cond + pij * (hd / 4);
        end

        ber = ber + psym(iSym) * ber_cond;
    end

    ber = min(max(ber, 0), 0.5);
end


function psym = local_build_symbol_prior(p_vec, labels)
% 根据各 bit 的先验 P(bit=1) 构造 16QAM 符号先验。

    M = size(labels, 1);
    psym = zeros(M, 1);
    for m = 1:M
        pm = 1;
        for b = 1:numel(p_vec)
            if labels(m, b) == 1
                pm = pm * p_vec(b);
            else
                pm = pm * (1 - p_vec(b));
            end
        end
        psym(m) = pm;
    end
    psym = psym / sum(psym);
end


function [lo, hi] = local_axis_interval(v, b1, b2, b3)
% 根据轴值确定该判决点的轴向判决区间。

    tol = 1e-12;
    if v <= b1 + tol
        lo = -inf; hi = b1;
    elseif v <= b2 + tol
        lo = b1; hi = b2;
    elseif v <= b3 + tol
        lo = b2; hi = b3;
    else
        lo = b3; hi = inf;
    end
end


function p = local_interval_prob(lo, hi, mu, sigma)
% P(lo <= X < hi), X~N(mu, sigma^2)

    z1 = (lo - mu) / sigma;
    z2 = (hi - mu) / sigma;
    p = local_normcdf(z2) - local_normcdf(z1);
    p = min(max(p, 0), 1);
end


function y = local_normcdf(x)
    y = 0.5 * erfc(-x / sqrt(2));
end
