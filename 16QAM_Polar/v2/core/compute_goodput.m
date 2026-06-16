function G = compute_goodput(result)
% COMPUTE_GOODPUT - 从仿真结果计算 Goodput（有效信息传递效率）
%
% 语法：G = compute_goodput(result)
%
% 输入参数：
%   result - sim_shaped_polar_16qam 返回的结构体
%
% 输出参数：
%   G - Goodput 向量 (1 x nSNR)
%
% 公式：G(p, SNR) = R_total(p) * (1 - BER(p, SNR))
%   其中 R_total = sum(K) / (4*N)

    G = result.R_total * (1 - result.BER);
end
