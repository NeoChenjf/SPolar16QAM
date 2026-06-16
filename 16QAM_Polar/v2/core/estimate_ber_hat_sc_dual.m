function model = estimate_ber_hat_sc_dual(p, snr_dB, cfg, opts)
% ESTIMATE_BER_HAT_SC_DUAL - 双机制竞争模型估计 BER_hat(p, SNR)
%
% 机制 A（编码侧）：
%   p 改变 S/I/F 集合后，信息位 I_set 占据的虚拟信道可靠性会变化。
%   用 I_set 平均 GA 可靠性相对基线(p_ref=0.5)的比值刻画“可靠性折损”。
%
% 机制 B（调制侧）：
%   p 改变 16QAM 半径类别概率（内/中/外），从而影响几何可分性。
%   默认采用“逐点错判概率+Q函数”的严格几何比值项。
%
% 语法：
%   model = estimate_ber_hat_sc_dual(p, snr_dB, cfg)
%   model = estimate_ber_hat_sc_dual(p, snr_dB, cfg, opts)
%
% 输入：
%   p      - 整形参数（标量）
%   snr_dB - SNR 向量
%   cfg    - config() 返回结构体
%   opts   - 可选参数结构体：
%            .alpha_rel  (默认 1.0)  机制A幂指数
%            .geom_model (默认 'strict_q') 几何模型：
%                'strict_q'   严格Q口径（主模型）
%                'heuristic'  经验增益（对照模型）
%            .beta_geom  (默认 1.0, 仅 heuristic 生效) 机制B强度系数
%            .pe_floor   (默认 1e-12) 误码率下限
%            .geom_apply_mode (默认 'shaped_only') 几何项作用范围：
%                'shaped_only' 仅作用于 cfg.p_fixed 中由 p 控制的路
%                'all_bits'    作用于全部4路（兼容旧口径）
%            .geom_ref_p         (默认 0.5) 几何归一化参考p
%            .geom_dmin2         (默认 0.4) 16QAM归一化最小距离平方
%            .geom_es            (默认 1.0) 星座平均能量
%            .geom_snr_mid_db    (默认 9, 仅 heuristic 生效)  峰值中心SNR
%            .geom_snr_sigma_db  (默认 3.5, 仅 heuristic 生效)峰值宽度
%            .code_high_eta      (默认 0.8)高SNR编码惩罚增强幅度
%            .code_high_mid_db   (默认 14) 编码惩罚增强中心SNR
%            .code_high_slope_db (默认 2.0)编码惩罚增强斜率
%            .disable_geom       (默认 false) 若为 true，强制几何项R_geo=1（仅看编码侧）
%            .geom_combine_mode  (默认 'ratio_scale') 几何与编码侧合成方式：
%                'ratio_scale'       旧口径：P_code * R_geo
%                'independent_union' 诊断口径：1-(1-P_code)(1-P_geo)
%
% 输出：
%   model  - 结构体，包含：
%            .BER_hat (1 x nSNR)
%            .BER_hat_per_bit (4 x nSNR)
%            .A_rel_loss (4 x nSNR)
%            .B_geom_ratio (1 x nSNR) 几何比值项R_geo
%            .B_geom_ratio_per_bit (4 x nSNR)
%            .B_geom_q_gamma (1 x nSNR, strict_q下有效)
%            .B_geom_gain / .B_geom_gain_per_bit 为兼容字段（同ratio）
%            .K, .S_size, .R_total, .p, .snr_dB
%            .radius_prob (struct: inner/middle/outer)
%
% 说明：
%   这是用于“趋势判别/快速优化”的近似模型，不替代最终蒙特卡洛仿真。

    if nargin < 4
        opts = struct();
    end
    if ~isfield(opts, 'alpha_rel'); opts.alpha_rel = 1.0; end
    if ~isfield(opts, 'geom_model'); opts.geom_model = 'strict_q'; end
    if ~isfield(opts, 'beta_geom'); opts.beta_geom = 1.0; end
    if ~isfield(opts, 'pe_floor'); opts.pe_floor = 1e-12; end
    if ~isfield(opts, 'geom_apply_mode'); opts.geom_apply_mode = 'shaped_only'; end
    if ~isfield(opts, 'geom_ref_p'); opts.geom_ref_p = 0.5; end
    if ~isfield(opts, 'geom_dmin2'); opts.geom_dmin2 = 0.4; end
    if ~isfield(opts, 'geom_es'); opts.geom_es = 1.0; end
    if ~isfield(opts, 'geom_snr_mid_db'); opts.geom_snr_mid_db = 9.0; end
    if ~isfield(opts, 'geom_snr_sigma_db'); opts.geom_snr_sigma_db = 3.5; end
    if ~isfield(opts, 'code_high_eta'); opts.code_high_eta = 0.8; end
    if ~isfield(opts, 'code_high_mid_db'); opts.code_high_mid_db = 14.0; end
    if ~isfield(opts, 'code_high_slope_db'); opts.code_high_slope_db = 2.0; end
    if ~isfield(opts, 'disable_geom'); opts.disable_geom = false; end
    if ~isfield(opts, 'geom_combine_mode'); opts.geom_combine_mode = 'ratio_scale'; end

    snr_dB = snr_dB(:).';
    nSNR = length(snr_dB);
    N = cfg.N;

    p_vec = cfg.p_fixed;
    p_vec(isnan(p_vec)) = p;

    p_ref_vec = cfg.p_fixed;
    p_ref_vec(isnan(p_ref_vec)) = 0.5;

    shaped_mask = isnan(cfg.p_fixed);
    if strcmpi(opts.geom_apply_mode, 'all_bits')
        geom_mask = ones(1, 4);
    else
        geom_mask = double(shaped_mask);
    end

    [S_vec, K_vec] = local_get_SK(N, p_vec);
    [S_ref_vec, K_ref_vec] = local_get_SK(N, p_ref_vec);

    BER_hat_per_bit = zeros(4, nSNR);
    A_rel_loss = ones(4, nSNR);
    B_geom_ratio = ones(1, nSNR);
    B_geom_ratio_per_bit = ones(4, nSNR);
    B_geom_q_gamma = nan(1, nSNR);
    B_geom_pe_abs = zeros(1, nSNR);
    B_geom_pe_abs_per_bit = zeros(4, nSNR);

    [prob_inner, prob_middle, prob_outer] = local_radius_probabilities(p);

    for iSNR = 1:nSNR
        sigma = 10^(-snr_dB(iSNR) / 20);
        channels = GA(sigma, N);
        [~, order_desc] = sort(channels, 'descend');

        if opts.disable_geom
            geom_ratio = 1.0;
            pe_geo_p = 0.0;
            B_geom_q_gamma(iSNR) = nan;
        else
            if strcmpi(opts.geom_model, 'strict_q')
                [pe_geo_p, pe_geo_ref, q_gamma] = local_geom_pe_strict_q(p, snr_dB(iSNR), opts);
                geom_ratio = pe_geo_p / max(pe_geo_ref, eps);
                B_geom_q_gamma(iSNR) = q_gamma;
            else
                pe_geo_p = nan;
                geom_weight = exp(-0.5 * ((snr_dB(iSNR) - opts.geom_snr_mid_db) / max(opts.geom_snr_sigma_db, 1e-6))^2);
                [~, geom_gain] = local_geom_gain(prob_inner, prob_outer, opts.beta_geom * geom_weight);
                geom_ratio = 1 / max(geom_gain, 1e-12);
            end
        end
        B_geom_ratio(iSNR) = geom_ratio;
        B_geom_pe_abs(iSNR) = min(0.5, max(0, pe_geo_p));

        code_high_weight = 1 + opts.code_high_eta / (1 + exp(-(snr_dB(iSNR) - opts.code_high_mid_db) / max(opts.code_high_slope_db, 1e-6)));

        for b = 1:4
            I_set = local_get_I_set(order_desc, S_vec(b), K_vec(b));
            I_ref_set = local_get_I_set(order_desc, S_ref_vec(b), K_ref_vec(b));

            geom_ratio_b = 1 + geom_mask(b) * (geom_ratio - 1);
            B_geom_ratio_per_bit(b, iSNR) = geom_ratio_b;
            pe_geo_b = geom_mask(b) * B_geom_pe_abs(iSNR);
            B_geom_pe_abs_per_bit(b, iSNR) = pe_geo_b;

            rel_I = mean(channels(I_set));
            rel_I_ref = mean(channels(I_ref_set));

            rel_ratio = rel_I_ref / max(rel_I, eps);
            A_loss = rel_ratio ^ (opts.alpha_rel * code_high_weight);
            A_rel_loss(b, iSNR) = A_loss;

            % 三层修正机制：
            % 1. phi(u_i) 基础极化码位级误码
            % 2. A_loss 编码侧折损（可靠性比+高SNR惩罚）
            % 3. geom_ratio_b 几何侧修正（仅受控路）
            pe_phi = 0.5 * arrayfun(@phi, channels(I_set));
            pe_code_i = pe_phi * A_loss;
            switch lower(opts.geom_combine_mode)
                case 'ratio_scale'
                    pe_i = pe_code_i * geom_ratio_b;
                case 'independent_union'
                    % 诊断口径：把编码侧错误和调制几何错误视作近似独立事件。
                    % 仅用于模型敏感性分析；full-chain 定量仍以 Monte Carlo 为准。
                    pe_i = 1 - (1 - pe_code_i) .* (1 - pe_geo_b);
                otherwise
                    error('Unknown geom_combine_mode: %s', opts.geom_combine_mode);
            end
            pe_i = min(0.5, max(opts.pe_floor, pe_i));
            BER_hat_per_bit(b, iSNR) = mean(pe_i);
        end
    end

    K_total = sum(K_vec);
    BER_hat = sum(bsxfun(@times, K_vec(:), BER_hat_per_bit), 1) / K_total;

    model = struct();
    model.BER_hat = BER_hat;
    model.BER_hat_per_bit = BER_hat_per_bit;
    model.A_rel_loss = A_rel_loss;
    model.B_geom_ratio = B_geom_ratio;
    model.B_geom_ratio_per_bit = B_geom_ratio_per_bit;
    model.B_geom_q_gamma = B_geom_q_gamma;
    model.B_geom_pe_abs = B_geom_pe_abs;
    model.B_geom_pe_abs_per_bit = B_geom_pe_abs_per_bit;
    model.B_geom_gain = B_geom_ratio;
    model.B_geom_gain_per_bit = B_geom_ratio_per_bit;
    model.K = K_vec;
    model.S_size = S_vec;
    model.R_total = K_total / (4 * N);
    model.p = p;
    model.snr_dB = snr_dB;
    model.radius_prob = struct('inner', prob_inner, 'middle', prob_middle, 'outer', prob_outer);
    model.geom_mask = geom_mask;
    model.opts = opts;
end


function [S_vec, K_vec] = local_get_SK(N, p_vec)
    S_vec = zeros(1, 4);
    K_vec = zeros(1, 4);
    for b = 1:4
        pb = p_vec(b);
        if pb > 0 && pb < 1
            hb = -pb * log2(pb) - (1 - pb) * log2(1 - pb);
        else
            hb = 0;
        end
        S_vec(b) = ceil(N * (1 - hb));
        K_vec(b) = ceil((N - S_vec(b)) / 2);
    end
end


function I_set = local_get_I_set(order_desc, S_size, K_size)
    idx = order_desc(S_size + 1 : S_size + K_size);
    I_set = sort(idx, 'ascend');
end


function [prob_inner, prob_middle, prob_outer] = local_radius_probabilities(p)
% 两路由 p 控制且独立时，三类半径概率：
% 内层点：p^2，中层点：2p(1-p)，外层点：(1-p)^2
    prob_inner = p^2;
    prob_middle = 2 * p * (1 - p);
    prob_outer = (1 - p)^2;
end


function [delta_outer_inner, geom_gain] = local_geom_gain(prob_inner, prob_outer, beta_geom)
% 几何增益：外层-内层占比差越大，可分性越强
    delta_outer_inner = prob_outer - prob_inner;
    geom_gain = 1 + beta_geom * delta_outer_inner;
    geom_gain = max(0.2, geom_gain);
end


function [pe_geo_p, pe_geo_ref, q_gamma] = local_geom_pe_strict_q(p, snr_dB, opts)
% 严格几何项：
% P_e,geo(p,gamma) ≈ (2 P_out + 3 P_mid + 4 P_in) * q(gamma)
% q(gamma)=Q(sqrt(2*dmin^2/N0)), N0=Es/SNR_linear
    snr_lin = 10^(snr_dB / 10);
    N0 = opts.geom_es / max(snr_lin, eps);
    q_arg = sqrt(2 * opts.geom_dmin2 / max(N0, eps));
    q_gamma = local_Q(q_arg);

    [p_in, p_mid, p_out] = local_radius_probabilities(p);
    pe_geo_p = (2 * p_out + 3 * p_mid + 4 * p_in) * q_gamma;

    p_ref = opts.geom_ref_p;
    [p_in_r, p_mid_r, p_out_r] = local_radius_probabilities(p_ref);
    pe_geo_ref = (2 * p_out_r + 3 * p_mid_r + 4 * p_in_r) * q_gamma;
end


function y = local_Q(x)
    y = 0.5 * erfc(x / sqrt(2));
end
