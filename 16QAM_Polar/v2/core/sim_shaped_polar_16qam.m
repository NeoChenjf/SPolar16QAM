function result = sim_shaped_polar_16qam(p, snr_dB, cfg)
% SIM_SHAPED_POLAR_16QAM - 16QAM 概率整形极化码端到端仿真（统一版）
%
% 语法：result = sim_shaped_polar_16qam(p, snr_dB, cfg)
%
% 输入参数：
%   p      - 整形参数（标量），控制 cfg.p_fixed 中 NaN 位置的比特概率
%   snr_dB - SNR 向量（dB）
%   cfg    - config() 返回的参数结构体
%
% 输出参数：
%   result - 结构体，包含：
%     .BER       - 加权 BER 向量 (1 x nSNR)
%     .BLER      - 加权 BLER 向量 (1 x nSNR)
%     .BER_per_bit  - 4路分别的 BER (4 x nSNR)
%     .BLER_per_bit - 4路分别的 BLER (4 x nSNR)
%     .MI        - 4路互信息 (4 x nSNR)
%     .MI_total  - 总互信息 (1 x nSNR)
%     .spow      - 平均符号功率 (1 x nSNR)
%     .K         - 4路信息位数 [K1 K2 K3 K4]
%     .S_size    - 4路整形位数 [S1 S2 S3 S4]
%     .R_total   - 总码率 sum(K) / (4*N)
%     .E_theory  - 理论符号能量 E(p)
%     .p         - 使用的整形参数
%     .snr_dB    - 使用的 SNR 向量
%     .cfg       - 使用的完整配置（用于复现）
%
% 合并了原 get_16test / get_16test_customSNR / gettest_MI 的全部功能。
% 修复了原 get_16test 中 frozen_bits 引用 bug。

    snr_dB = snr_dB(:).';  % 确保行向量
    nSNR = length(snr_dB);
    N = cfg.N;
    M = cfg.M;
    nFrames = cfg.num_frames;

    % 设置随机种子
    if cfg.seed > 0
        rng(cfg.seed, 'twister');
    end

    %% ===== 解析 4 路整形参数 =====
    p_vec = cfg.p_fixed;
    p_vec(isnan(p_vec)) = p;  % NaN 位置由 p 控制

    %% ===== 预计算：每路的 S/I/F 集合大小 =====
    K_vec   = zeros(1, 4);
    S_vec   = zeros(1, 4);
    h_vec   = zeros(1, 4);
    for b = 1:4
        pb = p_vec(b);
        if pb > 0 && pb < 1
            h_vec(b) = -pb*log2(pb) - (1-pb)*log2(1-pb);
        else
            h_vec(b) = 0;  % p=0 或 p=1 时熵为 0
        end
        S_vec(b) = ceil(N * (1 - h_vec(b)));
        S_comp = N - S_vec(b);
        K_vec(b) = ceil(S_comp / 2);
    end

    %% ===== 预计算：译码辅助结构 =====
    lambda_offset = 2.^(0:log2(N));
    llr_layer_vec = get_llr_layer(N);
    bit_layer_vec = get_bit_layer(N);

    %% ===== 初始化输出数组 =====
    BER_per_bit  = zeros(4, nSNR);
    BLER_per_bit = zeros(4, nSNR);
    MI_per_bit   = zeros(4, nSNR);
    spow_vec     = zeros(1, nSNR);

    %% ===== 主仿真循环 =====
    for iSNR = 1:nSNR
        sigma = 10^(-snr_dB(iSNR) / 20);

        % GA 信道可靠性排序（所有 4 路共用同一信道条件）
        channels = GA(sigma, N);
        [~, channels_ordered] = sort(channels, 'descend');

        % --- 预计算：4 路的 S/I/F 集合与整形位（每个 SNR 只需一次）---
        shaped_bits_pre = cell(1, 4);   % 整形位（确定性，不随帧变化）
        fb_dec   = zeros(N, 4);         % 信道译码用 frozen_bits
        SI_set   = cell(1, 4);
        I_set    = cell(1, 4);
        S_set_c  = cell(1, 4);
        prior_llr_vec = cell(1, 4);     % SCL 先验 LLR（整形位非零）

        for b = 1:4
            [shaped_bits_pre{b}, fb_dec(:,b), SI_set{b}, I_set{b}, S_set_c{b}] = ...
                prepare_one_bit(p_vec(b), S_vec(b), K_vec(b), N, ...
                                channels_ordered, lambda_offset, llr_layer_vec, bit_layer_vec);

            % 构造先验 LLR 向量：整形位 ln((1-p)/p)，信息位 0，冻结位无关
            prior_llr_vec{b} = zeros(N, 1);
            pb = p_vec(b);
            if pb > 0 && pb < 1 && pb ~= 0.5
                prior_llr_vec{b}(S_set_c{b}) = log((1 - pb) / pb);
            end
        end

        % --- 蒙特卡洛帧循环 ---
        ber_acc  = zeros(4, 1);
        bler_acc = zeros(4, 1);
        mi_acc   = zeros(4, 1);
        spow_acc = 0;

        for iFrame = 1:nFrames
            % ===== 每帧生成新信息位 → 编码 → 调制 =====
            xxx_enc = zeros(N, 4);
            origin  = cell(1, 4);
            for b = 1:4
                code = zeros(N, 1);
                origin{b} = randi([0 1], K_vec(b), 1);
                code(I_set{b})    = origin{b};
                code(S_set_c{b})  = shaped_bits_pre{b};
                xxx_enc(:,b) = polar_encoder(code);
            end

            xxx = parallel_to_serial_bits(xxx_enc(:,1), xxx_enc(:,2), xxx_enc(:,3), xxx_enc(:,4));
            txSym = qammod(xxx, M, cfg.mapping, ...
                           'InputType', 'bit', ...
                           'UnitAveragePower', cfg.unit_avg_power);

            % 计算实际符号功率
            spow_frame = sum(abs(txSym).^2) / N;
            spow_acc = spow_acc + spow_frame;

            % AWGN 信道
            switch cfg.snr_mode
                case 'fixed_n0'
                    sigma_noise = sqrt(cfg.snr_ref_power) * sigma;
                otherwise  % 'fixed_esn0'
                    sigma_noise = sqrt(spow_frame) * sigma;
            end
            rxSym = txSym + sigma_noise * (randn(N,1) + 1j*randn(N,1));

            % 16QAM 软解调 → LLR
            if isfield(cfg, 'llr_use_legacy_noisevar') && cfg.llr_use_legacy_noisevar
                noise_var_for_llr = 2 * sigma^2;
            else
                noise_var_for_llr = 2 * sigma_noise^2;
            end

            LLR_qam = qamdemod(rxSym, M, cfg.mapping, ...
                               'OutputType', 'llr', ...
                               'UnitAveragePower', cfg.unit_avg_power, ...
                               'NoiseVariance', noise_var_for_llr);

            % 串行 LLR 转 4 路并行
            llr_bits = zeros(N, 4);
            for b = 1:4
                llr_bits(:,b) = LLR_qam(b:4:end);
            end

            % 4 路独立译码 + 统计
            for b = 1:4
                % 互信息估计
                mi_acc(b) = mi_acc(b) + mutualinfo_llr(llr_bits(:,b), xxx_enc(:,b));

                % 选择译码器
                % 支持: 'SC', 'SC_prior', 'SCL', 'SCL_prior'
                % 注意: 'SCL' 默认带先验（向后兼容）
                switch cfg.decoder
                    case 'SCL'
                        decoded = SCL_decoder_prior(llr_bits(:,b), cfg.SCL_L, ...
                                              K_vec(b)+S_vec(b), fb_dec(:,b), ...
                                              lambda_offset, llr_layer_vec, bit_layer_vec, ...
                                              prior_llr_vec{b});
                    case 'SCL_no_prior'
                        decoded = SCL_decoder(llr_bits(:,b), cfg.SCL_L, ...
                                              K_vec(b)+S_vec(b), fb_dec(:,b), ...
                                              lambda_offset, llr_layer_vec, bit_layer_vec);
                    case 'SC_prior'
                        decoded = SC_decoder_prior(llr_bits(:,b), K_vec(b)+S_vec(b), ...
                                             fb_dec(:,b), lambda_offset, ...
                                             llr_layer_vec, bit_layer_vec, ...
                                             prior_llr_vec{b});
                    otherwise  % 'SC'
                        decoded = SC_decoder(llr_bits(:,b), K_vec(b)+S_vec(b), ...
                                             fb_dec(:,b), lambda_offset, ...
                                             llr_layer_vec, bit_layer_vec);
                end

                % 提取信息位
                code_hat = zeros(N, 1);
                code_hat(SI_set{b}) = decoded;
                info_hat = code_hat(I_set{b});

                % BER / BLER
                nfails = sum(info_hat ~= origin{b});
                ber_acc(b) = ber_acc(b) + nfails;
                if nfails > 0
                    bler_acc(b) = bler_acc(b) + 1;
                end
            end
        end

        % --- 归一化统计量 ---
        for b = 1:4
            BER_per_bit(b, iSNR)  = ber_acc(b) / (K_vec(b) * nFrames);
            BLER_per_bit(b, iSNR) = bler_acc(b) / nFrames;
            MI_per_bit(b, iSNR)   = mi_acc(b) / nFrames;
        end
        spow_vec(iSNR) = spow_acc / nFrames;

        % 进度显示
        K_total = sum(K_vec);
        BER_weighted = sum(K_vec .* BER_per_bit(:,iSNR)') / K_total;
        fprintf('  SNR = %+6.1f dB | BER = %.2e | MI_total = %.3f\n', ...
                snr_dB(iSNR), BER_weighted, sum(MI_per_bit(:,iSNR)));
    end

    %% ===== 组装输出结构体 =====
    K_total = sum(K_vec);
    result.BER       = sum(bsxfun(@times, K_vec', BER_per_bit), 1) / K_total;
    result.BLER      = sum(bsxfun(@times, K_vec', BLER_per_bit), 1) / K_total;
    result.BER_per_bit  = BER_per_bit;
    result.BLER_per_bit = BLER_per_bit;
    result.MI        = MI_per_bit;
    result.MI_total  = sum(MI_per_bit, 1);
    result.spow      = spow_vec;
    result.K         = K_vec;
    result.S_size    = S_vec;
    result.R_total   = K_total / (4 * N);
    result.E_theory  = 18 - 16*p;  % 解析能量公式（归一化前）
    result.p         = p;
    result.snr_dB    = snr_dB;
    result.cfg       = cfg;

end


%% ========================================================================
%  内部子函数
%  ========================================================================

function [shaped_bits, frozen_bits_dec, SandI_set, I_set, S_set] = ...
    prepare_one_bit(pb, S_size, K, N, channels_ordered, lambda_offset, llr_layer_vec, bit_layer_vec)
% PREPARE_ONE_BIT - 预计算单路比特的集合划分与整形位
%
% 说明：整形位由 SC 解码器确定性生成，只依赖 p 和 S_set，不随帧变化。
%       信息位的生成和极化编码移至帧循环内，确保每帧使用不同码字。
%
% 输出：
%   shaped_bits      - 整形位 (S_size x 1)，确定性
%   frozen_bits_dec  - 信道译码用 frozen_bits (N x 1)
%   SandI_set        - S∪I 集合索引
%   I_set            - I 集合索引
%   S_set            - S 集合索引

    % S/I/F 集合划分
    S_set    = sort(channels_ordered(1:S_size), 'ascend');
    I_set    = sort(channels_ordered(S_size+1 : S_size+K), 'ascend');
    SandI_set = sort(channels_ordered(1 : S_size+K), 'ascend');

    % 源极化整形：用 SC 解码器生成整形位（确定性，只需算一次）
    llr_src = ones(N, 1) * log((1-pb)/pb);
    frozen_bits_src = ones(N, 1);
    frozen_bits_src(S_set) = 0;
    shaped_bits = SC_decoder(llr_src, S_size, frozen_bits_src, ...
                             lambda_offset, llr_layer_vec, bit_layer_vec);

    % 信道译码用 frozen_bits（I 和 S 都是非冻结位）
    frozen_bits_dec = ones(N, 1);
    frozen_bits_dec(I_set) = 0;
    frozen_bits_dec(S_set) = 0;
end


function I = mutualinfo_llr(L, x)
% MUTUALINFO_LLR - 用 LLR + 真值 bit 估计互信息 I(B;L)
%
% I = 1 - E[log2(1 + exp(-s*L))]，其中 s = 1-2*x
%
% 输入：
%   L - LLR 向量
%   x - 对应的发送比特 (0/1)
%
% 输出：
%   I - 互信息（bits）

    L = L(:);
    x = x(:);
    s = 1 - 2*x;       % x=0 → +1, x=1 → -1
    z = -s .* L;        % z = -sL
    I = 1 - mean(log1p(exp(z))) / log(2);
end
