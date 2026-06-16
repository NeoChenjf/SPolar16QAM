function polar_info_esti = SCL_decoder_prior(llr, L, K, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec, prior_llr)
%SCL_DECODER_PRIOR - LLR-based SCL decoder with non-uniform prior support.
%
% 与 SCL_decoder 完全相同的算法，唯一区别：
% 在非冻结位的路径度量(PM)更新中，使用 L_eff = L_channel + prior_llr(phi+1)
% 替代原始 L_channel，从而支持概率整形场景下整形位的非均匀先验。
%
% 输入：
%   llr            - 信道 LLR 向量 (N x 1)
%   L              - 列表大小
%   K              - 非冻结位总数 (|S| + |I|)
%   frozen_bits    - 冻结位标记 (N x 1), 1=frozen, 0=unfrozen
%   lambda_offset  - 偏移量向量
%   llr_layer_vec  - LLR 层向量
%   bit_layer_vec  - bit 层向量
%   prior_llr      - 先验 LLR 向量 (N x 1)
%                    prior_llr(i) = ln(P(u_i=0)/P(u_i=1))
%                    信息位: 0, 整形位: ln((1-p)/p), 冻结位: 无用(被 frozen_bits 处理)
%                    若空/缺省则等价于标准 SCL（全零先验）
%
% 输出：
%   polar_info_esti - 非冻结位估计值 (K x 1)

%const
N = length(llr);
m = log2(N);

% 先验 LLR 缺省处理
if nargin < 8 || isempty(prior_llr)
    prior_llr = zeros(N, 1);
end

%memory declared
lazy_copy = zeros(m, L);
P = zeros(N - 1, L);
C = zeros(N - 1, 2 * L);
u = zeros(K, L);
PM = zeros(L, 1);
activepath = zeros(L, 1);
cnt_u = 1;

%initialize
activepath(1) = 1;
lazy_copy(:, 1) = 1;

%decoding starts
for phi = 0 : N - 1
    layer = llr_layer_vec(phi + 1);
    phi_mod_2 = mod(phi, 2);
    for l_index = 1 : L
        if activepath(l_index) == 0
            continue;
        end
        switch phi
            case 0
                index_1 = lambda_offset(m);
                for beta = 0 : index_1 - 1
                    P(beta + index_1, l_index) = sign(llr(beta + 1)) * sign(llr(beta + index_1 + 1)) * min(abs(llr(beta + 1)), abs(llr(beta + index_1 + 1)));
                end
                for i_layer = m - 2 : -1 : 0
                    index_1 = lambda_offset(i_layer + 1);
                    index_2 = lambda_offset(i_layer + 2);
                    for beta = 0 : index_1 - 1
                        P(beta + index_1, l_index) = sign(P(beta + index_2, l_index)) *...
                            sign(P(beta + index_1 + index_2, l_index)) * min(abs(P(beta + index_2, l_index)), abs(P(beta + index_1 + index_2, l_index)));
                    end
                end
            case N/2
                index_1 = lambda_offset(m);
                for beta = 0 : index_1 - 1
                    x_tmp = C(beta + index_1, 2 * l_index - 1);
                    P(beta + index_1, l_index) = (1 - 2 * x_tmp) * llr(beta + 1) + llr(beta + 1 + index_1);
                end
                for i_layer = m - 2 : -1 : 0
                    index_1 = lambda_offset(i_layer + 1);
                    index_2 = lambda_offset(i_layer + 2);
                    for beta = 0 : index_1 - 1
                        P(beta + index_1, l_index) = sign(P(beta + index_2, l_index)) *...
                            sign(P(beta + index_1 + index_2, l_index)) * min(abs(P(beta + index_2, l_index)), abs(P(beta + index_1 + index_2, l_index)));
                    end
                end
            otherwise
                index_1 = lambda_offset(layer + 1);
                index_2 = lambda_offset(layer + 2);
                for beta = 0 : index_1 - 1
                    P(beta + index_1, l_index) = (1 - 2 * C(beta + index_1, 2 * l_index - 1)) * P(beta + index_2, lazy_copy(layer + 2, l_index)) +...
                        P(beta + index_1 + index_2, lazy_copy(layer + 2, l_index));
                end
                for i_layer = layer - 1 : -1 : 0
                    index_1 = lambda_offset(i_layer + 1);
                    index_2 = lambda_offset(i_layer + 2);
                    for beta = 0 : index_1 - 1
                        P(beta + index_1, l_index) = sign(P(beta + index_2, l_index)) *...
                            sign(P(beta + index_1 + index_2, l_index)) * min(abs(P(beta + index_2, l_index)),...
                            abs(P(beta + index_1 + index_2, l_index)));
                    end
                end
        end
    end
    if frozen_bits(phi + 1) == 0  % unfrozen bit
        PM_pair = realmax * ones(2, L);
        for l_index = 1 : L
            if activepath(l_index) == 0
                continue;
            end
            % ===== 核心修改：加入先验 LLR =====
            L_eff = P(1, l_index) + prior_llr(phi + 1);
            if L_eff >= 0
                PM_pair(1, l_index) = PM(l_index);               % bit=0
                PM_pair(2, l_index) = PM(l_index) + L_eff;       % bit=1
            else
                PM_pair(1, l_index) = PM(l_index) - L_eff;       % bit=0
                PM_pair(2, l_index) = PM(l_index);               % bit=1
            end
        end
        middle = min(2 * sum(activepath), L);
        PM_sort = sort(PM_pair(:));
        PM_cv = PM_sort(middle);
        compare = PM_pair <= PM_cv;
        kill_index = zeros(L, 1);
        kill_cnt = 0;
        for i = 1 : L
            if (compare(1, i) == 0)&&(compare(2, i) == 0)
                activepath(i) = 0;
                kill_cnt = kill_cnt + 1;
                kill_index(kill_cnt) = i;
            end
        end
        for l_index = 1 : L
            if activepath(l_index) == 0
                continue;
            end
            path_state = compare(1, l_index) * 2 + compare(2, l_index);
            switch path_state
                case 1
                    u(cnt_u, l_index) = 1;
                    C(1, 2 * l_index - 1 + phi_mod_2) = 1;
                    PM(l_index) = PM_pair(2, l_index);
                case 2
                    u(cnt_u, l_index) = 0;
                    C(1, 2 * l_index - 1 + phi_mod_2) = 0;
                    PM(l_index) = PM_pair(1, l_index);
                case 3
                    index = kill_index(kill_cnt);
                    kill_cnt = kill_cnt - 1;
                    activepath(index) = 1;
                    lazy_copy(:, index) = lazy_copy(:, l_index);
                    u(:, index) = u(:, l_index);
                    u(cnt_u, l_index) = 0;
                    u(cnt_u, index) = 1;
                    C(1, 2 * l_index - 1 + phi_mod_2) = 0;
                    C(1, 2 * index - 1 + phi_mod_2) = 1;
                    PM(l_index) = PM_pair(1, l_index);
                    PM(index) = PM_pair(2, l_index);
            end
        end
        cnt_u = cnt_u + 1;
    else  % frozen bit
        for l_index = 1 : L
            if activepath(l_index) == 0
                continue;
            end
            if P(1, l_index) < 0
                PM(l_index) = PM(l_index) - P(1, l_index);
            end
            if phi_mod_2 == 0
                C(1, 2 * l_index - 1) = 0;
            else
                C(1, 2 * l_index) = 0;
            end
        end
    end

    for l_index = 1 : L  % partial-sum return
        if activepath(l_index) == 0
            continue
        end
        if (phi_mod_2  == 1) && (phi ~= N - 1)
            layer = bit_layer_vec(phi + 1);
            for i_layer = 0 : layer - 1
                index_1 = lambda_offset(i_layer + 1);
                index_2 = lambda_offset(i_layer + 2);
                for beta = index_1 : 2 * index_1 - 1
                    C(beta + index_1, 2 * l_index) = mod(C(beta, 2 *  lazy_copy(i_layer + 1, l_index) - 1) + C(beta, 2 * l_index), 2);
                    C(beta + index_2, 2 * l_index) = C(beta, 2 * l_index);
                end
            end
            index_1 = lambda_offset(layer + 1);
            index_2 = lambda_offset(layer + 2);
            for beta = index_1 : 2 * index_1 - 1
                C(beta + index_1, 2 * l_index - 1) = mod(C(beta, 2 * lazy_copy(layer + 1, l_index) - 1) + C(beta, 2 * l_index), 2);
                C(beta + index_2, 2 * l_index - 1) = C(beta, 2 * l_index);
            end
        end
    end
    % lazy copy
    if phi < N - 1
        for i_layer = 1 : llr_layer_vec(phi + 2) + 1
            for l_index = 1 : L
                lazy_copy(i_layer, l_index) = l_index;
            end
        end
    end
end

% path selection
[~, min_index] = min(PM);
polar_info_esti = u(:, min_index);
end
