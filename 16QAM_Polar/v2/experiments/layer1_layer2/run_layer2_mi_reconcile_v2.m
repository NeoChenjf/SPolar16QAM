%% RUN_LAYER2_MI_RECONCILE_V2 - 第2层重构：纯调制层 MI/BER 对账（matched vs mismatched）
%
% 目标：
% 1) 只验证先验对 bit-channel MI 的影响（不混入极化编码结构）
% 2) 输出 matched / mismatched 两套 BER-SNR 曲线（与Layer1口径一致）
% 3) 在 fixed_esn0 / fixed_n0 下分开对账
%
% 说明：
% - mismatched: 使用均匀先验 LLR（llr_16qam_gray_LSE）
% - matched:    使用符号先验 LLR（llr_16qam_gray_LSE_prior）

clear; clc; close all;

setup_paths();
cfg = config();

%% ===== 可调参数 =====
p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
snr_grid = 0:2:20;
snr_modes = {'fixed_esn0', 'fixed_n0'};

num_symbols_total = 6e4;   % 每个 (mode,p,snr) 的符号数
chunk_symbols = 6000;
seed = 20260406;

rng(seed, 'twister');

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_layer2_mi_reconcile_v2']);
fig_dir = fullfile(out_dir, 'figures');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

nM = numel(snr_modes);
nP = numel(p_list);
nS = numel(snr_grid);

MI_bit_mismatch = nan(nM, nP, 4, nS);
MI_bit_match = nan(nM, nP, 4, nS);
MI_total_mismatch = nan(nM, nP, nS);
MI_total_match = nan(nM, nP, nS);

BER_bit_mismatch = nan(nM, nP, 4, nS);
BER_bit_match = nan(nM, nP, 4, nS);
BER_total_mismatch = nan(nM, nP, nS);
BER_total_match = nan(nM, nP, nS);

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
        prior_b1 = 0.5;
        prior_b2 = p;
        prior_b3 = 0.5;
        prior_b4 = p;
        prior_bit1 = [prior_b1, prior_b2, prior_b3, prior_b4]; % P(bit=1)

        psym = local_build_symbol_prior(prior_bit1);

        for is = 1:nS
            snr_db = snr_grid(is);
            sigma = 10^(-snr_db / 20);

            mi_sum_mis = zeros(1, 4);
            mi_sum_mat = zeros(1, 4);
            ber_err_mis = zeros(1, 4);
            ber_err_mat = zeros(1, 4);
            ber_bits_cnt = zeros(1, 4);
            n_chunks = 0;
            total_sym = 0;

            while total_sym < num_symbols_total
                nSym = min(chunk_symbols, num_symbols_total - total_sym);
                if nSym <= 0
                    break;
                end

                b1 = rand(nSym, 1) < prior_b1;
                b2 = rand(nSym, 1) < prior_b2;
                b3 = rand(nSym, 1) < prior_b3;
                b4 = rand(nSym, 1) < prior_b4;
                tx_bits = double([b1, b2, b3, b4]);  % nSym x 4

                % 转成qammod期望的列向量：[b1_1, b2_1, b3_1, b4_1, b1_2, b2_2, ...]
                tx_bits_col = zeros(nSym*4, 1);
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
                        spow_frame = mean(abs(tx_sym).^2);
                        sigma_noise = sqrt(spow_frame) * sigma;
                end

                noise = sigma_noise .* (randn(nSym,1) + 1j .* randn(nSym,1));
                rx_sym = tx_sym + noise;

                % mismatched: 均匀先验
                llr_mis = llr_16qam_gray_LSE(rx_sym, sigma_noise);
                % matched: 符号先验
                llr_mat = llr_16qam_gray_LSE_prior(rx_sym, sigma_noise, psym);

                % 4路拆分
                llr_mis_bits = local_llr_serial_to_parallel(llr_mis);
                llr_mat_bits = local_llr_serial_to_parallel(llr_mat);

                for b = 1:4
                    x_true = tx_bits(:, b);
                    pb1 = prior_bit1(b);
                    mi_sum_mis(b) = mi_sum_mis(b) + local_mi_from_llr_general(llr_mis_bits(:, b), x_true, pb1);
                    mi_sum_mat(b) = mi_sum_mat(b) + local_mi_from_llr_general(llr_mat_bits(:, b), x_true, pb1);

                    % 基于 LLR 判决计算 BER（LLR = log(P0/P1) 时，L<0 判 1）
                    xhat_mis = double(llr_mis_bits(:, b) < 0);
                    xhat_mat = double(llr_mat_bits(:, b) < 0);
                    ber_err_mis(b) = ber_err_mis(b) + sum(xhat_mis ~= x_true);
                    ber_err_mat(b) = ber_err_mat(b) + sum(xhat_mat ~= x_true);
                    ber_bits_cnt(b) = ber_bits_cnt(b) + numel(x_true);
                end

                total_sym = total_sym + nSym;
                n_chunks = n_chunks + 1;
            end

            MI_bit_mismatch(im, ip, :, is) = mi_sum_mis / max(n_chunks, 1);
            MI_bit_match(im, ip, :, is) = mi_sum_mat / max(n_chunks, 1);
            MI_total_mismatch(im, ip, is) = sum(MI_bit_mismatch(im, ip, :, is), 3);
            MI_total_match(im, ip, is) = sum(MI_bit_match(im, ip, :, is), 3);

            BER_bit_mismatch(im, ip, :, is) = ber_err_mis ./ max(ber_bits_cnt, 1);
            BER_bit_match(im, ip, :, is) = ber_err_mat ./ max(ber_bits_cnt, 1);
            BER_total_mismatch(im, ip, is) = mean(BER_bit_mismatch(im, ip, :, is), 3);
            BER_total_match(im, ip, is) = mean(BER_bit_match(im, ip, :, is), 3);

            fprintf('  p=%.2f, SNR=%+5.1f dB | BER(mis)=%.3e | BER(mat)=%.3e | MI(mis)=%.3f | MI(mat)=%.3f\n', ...
                p, snr_db, BER_total_mismatch(im, ip, is), BER_total_match(im, ip, is), ...
                MI_total_mismatch(im, ip, is), MI_total_match(im, ip, is));
        end
    end
end

%% ===== 归一化比值（相对 p=0.5） =====
MI_ratio_mismatch = nan(nM, nP, nS);
MI_ratio_match = nan(nM, nP, nS);
for im = 1:nM
    ref_mis = squeeze(MI_total_mismatch(im, idx_ref, :));
    ref_mat = squeeze(MI_total_match(im, idx_ref, :));
    for ip = 1:nP
        MI_ratio_mismatch(im, ip, :) = squeeze(MI_total_mismatch(im, ip, :)) ./ max(ref_mis, eps);
        MI_ratio_match(im, ip, :) = squeeze(MI_total_match(im, ip, :)) ./ max(ref_mat, eps);
    end
end

%% ===== 导出表格 =====
for im = 1:nM
    mode_name = snr_modes{im};

    % 总 MI
    T_total = table();
    T_total.p = p_list(:);
    for is = 1:nS
        snr_db = snr_grid(is);
        c1 = matlab.lang.makeValidName(sprintf('MI_total_mismatch_snr_%gdB', snr_db));
        c2 = matlab.lang.makeValidName(sprintf('MI_ratio_mismatch_snr_%gdB', snr_db));
        c3 = matlab.lang.makeValidName(sprintf('MI_total_match_snr_%gdB', snr_db));
        c4 = matlab.lang.makeValidName(sprintf('MI_ratio_match_snr_%gdB', snr_db));

        T_total.(c1) = squeeze(MI_total_mismatch(im, :, is)).';
        T_total.(c2) = squeeze(MI_ratio_mismatch(im, :, is)).';
        T_total.(c3) = squeeze(MI_total_match(im, :, is)).';
        T_total.(c4) = squeeze(MI_ratio_match(im, :, is)).';
    end
    writetable(T_total, fullfile(out_dir, sprintf('layer2_v2_mi_total_%s.csv', mode_name)));

    % 总 BER
    T_ber = table();
    T_ber.p = p_list(:);
    for is = 1:nS
        snr_db = snr_grid(is);
        c1 = matlab.lang.makeValidName(sprintf('BER_total_mismatch_snr_%gdB', snr_db));
        c2 = matlab.lang.makeValidName(sprintf('BER_total_match_snr_%gdB', snr_db));
        T_ber.(c1) = squeeze(BER_total_mismatch(im, :, is)).';
        T_ber.(c2) = squeeze(BER_total_match(im, :, is)).';
    end
    writetable(T_ber, fullfile(out_dir, sprintf('layer2_v2_ber_total_%s.csv', mode_name)));

    % 分 bit MI
    rows = nP * nS;
    [P_grid, S_grid] = ndgrid(p_list, snr_grid);

    T_bit = table();
    T_bit.p = P_grid(:);
    T_bit.snr_dB = S_grid(:);

    for b = 1:4
        c_mis = matlab.lang.makeValidName(sprintf('MI_bit%d_mismatch', b));
        c_mat = matlab.lang.makeValidName(sprintf('MI_bit%d_match', b));
        T_bit.(c_mis) = reshape(squeeze(MI_bit_mismatch(im, :, b, :)), rows, 1);
        T_bit.(c_mat) = reshape(squeeze(MI_bit_match(im, :, b, :)), rows, 1);
    end

    writetable(T_bit, fullfile(out_dir, sprintf('layer2_v2_mi_per_bit_%s.csv', mode_name)));

    % 分 bit BER
    T_bit_ber = table();
    T_bit_ber.p = P_grid(:);
    T_bit_ber.snr_dB = S_grid(:);
    for b = 1:4
        c_mis = matlab.lang.makeValidName(sprintf('BER_bit%d_mismatch', b));
        c_mat = matlab.lang.makeValidName(sprintf('BER_bit%d_match', b));
        T_bit_ber.(c_mis) = reshape(squeeze(BER_bit_mismatch(im, :, b, :)), rows, 1);
        T_bit_ber.(c_mat) = reshape(squeeze(BER_bit_match(im, :, b, :)), rows, 1);
    end
    writetable(T_bit_ber, fullfile(out_dir, sprintf('layer2_v2_ber_per_bit_%s.csv', mode_name)));
end

save(fullfile(out_dir, 'layer2_mi_reconcile_v2.mat'), ...
    'p_list', 'snr_grid', 'snr_modes', ...
    'MI_bit_mismatch', 'MI_bit_match', 'MI_total_mismatch', 'MI_total_match', ...
    'BER_bit_mismatch', 'BER_bit_match', 'BER_total_mismatch', 'BER_total_match', ...
    'MI_ratio_mismatch', 'MI_ratio_match', ...
    'num_symbols_total', 'chunk_symbols', 'seed');

%% ===== 绘图1：总 BER-SNR 曲线（与Layer1口径一致） =====
for im = 1:nM
    mode_name = snr_modes{im};
    fig = figure('Position', [80 80 1040 560], 'Visible', 'off');
    t = tiledlayout(1,2);
    title(t, sprintf('Layer2-v2 BER vs SNR (%s)', mode_name));

    colors = lines(nP);

    % mismatch
    nexttile;
    hold on;
    for ip = 1:nP
        semilogy(snr_grid, squeeze(BER_total_mismatch(im, ip, :)), '-o', ...
            'Color', colors(ip,:), 'LineWidth', 1.5, 'MarkerSize', 4, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    hold off;
    grid on;
    xlabel('SNR (dB)'); ylabel('BER');
    title('Mismatched LLR');
    legend('Location', 'bestoutside');

    % match
    nexttile;
    hold on;
    for ip = 1:nP
        semilogy(snr_grid, squeeze(BER_total_match(im, ip, :)), '-o', ...
            'Color', colors(ip,:), 'LineWidth', 1.5, 'MarkerSize', 4, ...
            'DisplayName', sprintf('p=%.1f', p_list(ip)));
    end
    hold off;
    grid on;
    xlabel('SNR (dB)'); ylabel('BER');
    title('Matched LLR (with symbol prior)');
    legend('Location', 'bestoutside');

    exportgraphics(fig, fullfile(fig_dir, sprintf('layer2_v2_ber_curve_%s.png', mode_name)), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, sprintf('layer2_v2_ber_curve_%s.pdf', mode_name)), 'ContentType', 'vector');
    close(fig);
end

%% ===== 绘图2：分 bit MI（固定 SNR 切片） =====
snr_target = 10;
[~, idx_snr] = min(abs(snr_grid - snr_target));
for im = 1:nM
    mode_name = snr_modes{im};

    fig = figure('Position', [80 80 1080 620], 'Visible', 'off');
    t = tiledlayout(2,2);
    title(t, sprintf('Layer2-v2 per-bit MI @ SNR=%d dB (%s)', snr_grid(idx_snr), mode_name));

    for b = 1:4
        nexttile;
        plot(p_list, squeeze(MI_bit_mismatch(im, :, b, idx_snr)), '-o', 'LineWidth', 1.5, 'DisplayName', 'mismatch');
        hold on;
        plot(p_list, squeeze(MI_bit_match(im, :, b, idx_snr)), '--s', 'LineWidth', 1.5, 'DisplayName', 'match');
        hold off;
        grid on; set(gca, 'XDir', 'reverse');
        xlabel('p'); ylabel(sprintf('MI bit%d', b));
        title(sprintf('bit%d', b));
        legend('Location', 'best');
    end

    exportgraphics(fig, fullfile(fig_dir, sprintf('layer2_v2_mi_perbit_%s.png', mode_name)), 'Resolution', 300);
    exportgraphics(fig, fullfile(fig_dir, sprintf('layer2_v2_mi_perbit_%s.pdf', mode_name)), 'ContentType', 'vector');
    close(fig);
end

%% ===== README =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
fprintf(fid, 'Layer2-v2: modulation-only MI reconcile (matched vs mismatched)\n');
fprintf(fid, 'p_list = [0.5, 0.4, 0.3, 0.2, 0.1]\n');
fprintf(fid, 'snr_grid = 0:2:20 dB\n');
fprintf(fid, 'snr_modes = {fixed_esn0, fixed_n0}\n');
fprintf(fid, 'num_symbols_total = %d, chunk_symbols = %d\n', num_symbols_total, chunk_symbols);
fprintf(fid, '\nMain outputs:\n');
fprintf(fid, '- layer2_v2_ber_total_fixed_esn0.csv\n');
fprintf(fid, '- layer2_v2_ber_total_fixed_n0.csv\n');
fprintf(fid, '- layer2_v2_ber_per_bit_fixed_esn0.csv\n');
fprintf(fid, '- layer2_v2_ber_per_bit_fixed_n0.csv\n');
fprintf(fid, '- layer2_v2_mi_total_fixed_esn0.csv\n');
fprintf(fid, '- layer2_v2_mi_total_fixed_n0.csv\n');
fprintf(fid, '- layer2_v2_mi_per_bit_fixed_esn0.csv\n');
fprintf(fid, '- layer2_v2_mi_per_bit_fixed_n0.csv\n');
fprintf(fid, '- figures/layer2_v2_ber_curve_*.png/pdf\n');
fprintf(fid, '- figures/layer2_v2_mi_perbit_*.png/pdf\n');
fclose(fid);

fprintf('\n===== Layer2-v2 执行完成 =====\n');
fprintf('结果目录: %s\n', out_dir);


function llr_bits = local_llr_serial_to_parallel(llr_serial)
    L = llr_serial(:);
    if mod(numel(L), 4) ~= 0
        error('LLR 长度必须是4的整数倍。');
    end
    N = numel(L) / 4;
    llr_bits = zeros(N, 4);
    for b = 1:4
        llr_bits(:, b) = L(b:4:end);
    end
end


function psym = local_build_symbol_prior(prior_bit1)
% prior_bit1(b)=P(bit_b=1), bit顺序与 qammod InputType='bit' 的 left-msb 一致
    labels = de2bi((0:15).', 4, 'left-msb');
    psym = zeros(16,1);
    for m = 1:16
        p = 1;
        for b = 1:4
            if labels(m,b) == 1
                p = p * prior_bit1(b);
            else
                p = p * (1 - prior_bit1(b));
            end
        end
        psym(m) = p;
    end
    psym = psym / sum(psym);
end


function I = local_mi_from_llr_general(L, x, pb1)
% MI 估算：I(B;Y) = E[log P(B|Y) / P(B)]
%
% 使用"最大似然估计"的方式：
% 对每个LLR，尝试两种符号约定，择优。
% 
% 约定A：L = log(P(B=1|Y) / P(B=0|Y))  → p1 = sigma(L), p0 = 1-p1
% 约定B：L = log(P(B=0|Y) / P(B=1|Y))  → p0 = sigma(L), p1 = 1-p0
%
% 关键：选择能给出更多信息的约定（即能更好区分b的约定）

    L = L(:);
    x = x(:);
    
    pb1 = min(max(pb1, 1e-9), 1 - 1e-9);
    pb0 = 1 - pb1;
    
    % 防止exp溢出
    Lc = min(max(L, -60), 60);
    
    % 两种约定
    % 约定A: L = log(P1/P0)
    p1_a = 1 ./ (1 + exp(-Lc));
    p0_a = 1 - p1_a;
    I_a = local_compute_mutual_info(p0_a, p1_a, x, pb0, pb1);
    
    % 约定B: L = log(P0/P1)  
    p0_b = 1 ./ (1 + exp(-Lc));
    p1_b = 1 - p0_b;
    I_b = local_compute_mutual_info(p0_b, p1_b, x, pb0, pb1);
    
    % 取更合理的（非负且较大的）
    I = max(max(I_a, I_b), 0);
    I = min(I, 1.0);  % 上界为1 bit
end


function I = local_compute_mutual_info(p0, p1, x, pb0, pb1)
% 计算 I = E[log P(B|Y) / P(B)]
% = E[log P(B|Y)] - log P(B)  （按采样分布）
    
    eps0 = 1e-12;
    
    % 计算每个样本的 log-ratio: log(P(B=true|Y) / P(B=true))
    logp_ratio = zeros(size(x));
    
    idx0 = (x == 0);
    idx1 = ~idx0;
    
    % 当 x=0 时，P(B=0) = pb0
    logp_ratio(idx0) = log2(max(p0(idx0), eps0)) - log2(pb0);
    % 当 x=1 时，P(B=1) = pb1  
    logp_ratio(idx1) = log2(max(p1(idx1), eps0)) - log2(pb1);
    
    % 期望（平均）
    I = mean(logp_ratio);
    
    % 如果I是NaN或Inf，强制设为0
    if ~isfinite(I)
        I = 0;
    end
end
