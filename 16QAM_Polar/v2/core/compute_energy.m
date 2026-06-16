function E = compute_energy(p, cfg)
% COMPUTE_ENERGY - 计算给定整形参数 p 下的 16QAM 理论符号能量
%
% 语法：E = compute_energy(p, cfg)
%
% 输入参数：
%   p   - 整形参数（标量或向量）
%   cfg - config() 返回的参数结构体
%
% 输出参数：
%   E   - 符号能量（与 p 同维度）
%
% 推导（见周报 1.28）：
%   对 16QAM (r1=1, r2=3) Gray 映射，bit2/bit4 整形参数为 p，
%   内圈概率 p1 = p^2, 中圈 p2 = 2p(1-p), 外圈 p3 = (1-p)^2
%   E(p) = 2*p1 + 10*p2 + 18*p3 = 18 - 16*p
%
% 归一化：E_norm = E(p) / E(0.5) = (18 - 16*p) / 10

    E = 18 - 16 * p;
end
