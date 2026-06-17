# L3 · compute_energy

- **method_id**: l3_compute_energy
- **file_path**: 16QAM_Polar/v2/core/compute_energy.m
- **module**: core
- **health**: healthy

## Signature
**输入**：`p`（标量或向量，整形参数）、`cfg`（参数结构体）
**输出**：`E`（符号能量，与 p 同维度）

## Purpose
计算给定整形参数 p 下的 16QAM 理论平均符号能量（归一化前）。

## Math / Algorithm
对 Gray 16QAM（轴值 ±1, ±3），bit2/bit4 整形参数为 p：
- 内圈概率 `p1 = p^2`，中圈 `p2 = 2p(1-p)`，外圈 `p3 = (1-p)^2`
- `E(p) = 2·p1 + 10·p2 + 18·p3 = 18 - 16p`
- 归一化：`E_norm = E(p)/E(0.5) = (18-16p)/10`（基线 E(0.5)=10）

推导见周报 1.28。

## Numerical Notes
无；纯解析闭式。

## Dependencies
无（仅用 cfg 常量；实际实现直接返回 `18-16p`）。

## Health
healthy
