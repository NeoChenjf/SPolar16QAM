function cost = compute_cost(G, E, G0, E0)
% COMPUTE_COST - 计算能量-信息代价函数
%
% 语法：cost = compute_cost(G, E, G0, E0)
%
% 输入参数：
%   G  - 当前 Goodput（标量或向量）
%   E  - 当前能量（标量或向量）
%   G0 - 基线 Goodput（p=0.5 时的值）
%   E0 - 基线能量（p=0.5 时的值）
%
% 输出参数：
%   cost - 代价值，仅在 E > E0 时有意义
%
% 公式：cost(p) = -(G(p) - G(p0)) / (E(p) - E(p0))
% 物理意义：单位能量增益带来的信息损失（越小越好）

    dE = E - E0;
    dG = G - G0;

    cost = nan(size(dE));
    valid = dE > 0;
    cost(valid) = -dG(valid) ./ dE(valid);
end
