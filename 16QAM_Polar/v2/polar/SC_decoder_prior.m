function polar_info_esti = SC_decoder_prior(llr, K, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec, prior_llr)
%SC_DECODER_PRIOR - SC decoder with non-uniform prior support.
%
% 与 SC_decoder 完全相同，唯一区别：
% 在非冻结位的硬判决中，使用 L_eff = L_channel + prior_llr(phi+1)
% 替代原始 L_channel，支持概率整形的非均匀先验。
%
% 输入：
%   prior_llr - 先验 LLR 向量 (N x 1), prior_llr(i) = ln(P(u_i=0)/P(u_i=1))
%               缺省或空则等价于标准 SC
%
N = length(llr);
n = log2(N);

if nargin < 7 || isempty(prior_llr)
    prior_llr = zeros(N, 1);
end

P = zeros(N - 1, 1);
C = zeros(N - 1, 2);
polar_info_esti = zeros(K, 1);
cnt_K = 1;
for phi = 0 : N - 1
    switch phi
        case 0
            index_1 = lambda_offset(n);
            for beta = 0 : index_1 - 1
                P(beta + index_1) = sign(llr(beta + 1)) * sign(llr(beta + 1 + index_1)) * min(abs(llr(beta + 1)), abs(llr(beta + 1 + index_1)));
            end
            for i_layer = n - 2 : -1 : 0
                index_1 = lambda_offset(i_layer + 1);
                index_2 = lambda_offset(i_layer + 2);
                for beta = index_1 : index_2 - 1
                    P(beta) = sign(P(beta + index_1)) * sign(P(beta + index_2)) * min(abs(P(beta + index_1)), abs(P(beta + index_2)));
                end
            end
        case N/2
            index_1 = lambda_offset(n);
            for beta = 0 : index_1 - 1
                P(beta + index_1) = (1 - 2 * C(beta + index_1, 1)) * llr(beta + 1) + llr(beta + 1 + index_1);
            end
            for i_layer = n - 2 : -1 : 0
                index_1 = lambda_offset(i_layer + 1);
                index_2 = lambda_offset(i_layer + 2);
                for beta = index_1 : index_2 - 1
                    P(beta) = sign(P(beta + index_1)) * sign(P(beta + index_2)) * min(abs(P(beta + index_1)), abs(P(beta + index_2)));
                end
            end
        otherwise
            llr_layer = llr_layer_vec(phi + 1);
            index_1 = lambda_offset(llr_layer + 1);
            index_2 = lambda_offset(llr_layer + 2);
            for beta = index_1 : index_2 - 1
                P(beta) = (1 - 2 * C(beta, 1)) * P(beta + index_1) + P(beta + index_2);
            end
            for i_layer = llr_layer - 1 : -1 : 0
                index_1 = lambda_offset(i_layer + 1);
                index_2 = lambda_offset(i_layer + 2);
                for beta = index_1 : index_2 - 1
                    P(beta) = sign(P(beta + index_1)) * sign(P(beta + index_2)) * min(abs(P(beta + index_1)), abs(P(beta + index_2)));
                end
            end
    end
    phi_mod_2 = mod(phi, 2);
    if frozen_bits(phi + 1) == 1  % frozen bit
        C(1, 1 + phi_mod_2) = 0;
    else  % unfrozen bit
        % ===== 核心修改：加入先验 LLR =====
        L_eff = P(1) + prior_llr(phi + 1);
        C(1, 1 + phi_mod_2) = L_eff < 0;
        polar_info_esti(cnt_K) = L_eff < 0;
        cnt_K = cnt_K + 1;
    end
    if phi_mod_2 == 1 && phi ~= N - 1
        bit_layer = bit_layer_vec(phi + 1);
        for i_layer = 0 : bit_layer - 1
            index_1 = lambda_offset(i_layer + 1);
            index_2 = lambda_offset(i_layer + 2);
            for beta = index_1 : index_2 - 1
                C(beta + index_1, 2) = mod(C(beta, 1) + C(beta, 2), 2);
                C(beta + index_2, 2) = C(beta, 2);
            end
        end
        index_1 = lambda_offset(bit_layer + 1);
        index_2 = lambda_offset(bit_layer + 2);
        for beta = index_1 : index_2 - 1
            C(beta + index_1, 1) = mod(C(beta, 1) + C(beta, 2), 2);
            C(beta + index_2, 1) = C(beta, 2);
        end
    end
end
end
