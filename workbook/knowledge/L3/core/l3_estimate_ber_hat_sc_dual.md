# L3 · estimate_ber_hat_sc_dual

- **method_id**: l3_estimate_ber_hat_sc_dual
- **file_path**: 16QAM_Polar/v2/core/estimate_ber_hat_sc_dual.m
- **module**: core
- **health**: degraded — 近似模型，**不替代蒙特卡洛仿真**；含多个可调经验参数，仅用于趋势判别/快速优化

## Signature
**输入**
| 参数 | 类型 | 含义 |
|------|------|------|
| p | 标量 | 整形参数 |
| snr_dB | 1×nSNR | SNR 向量 |
| cfg | struct | 参数结构体 |
| opts | struct（可选） | 模型超参（alpha_rel, geom_model, beta_geom, pe_floor, geom_apply_mode, geom_combine_mode 等） |

**输出**：`model` 结构体，含 `.BER_hat .BER_hat_per_bit .A_rel_loss .B_geom_ratio .B_geom_q_gamma .K .S_size .R_total .radius_prob` 等。

## Purpose
用**双机制竞争解析模型**快速估计 BER_hat(p, SNR)，刻画整形 p 的净影响趋势，避免每次都跑长仿真。

## Math / Algorithm
- **机制 A（编码侧）**：p 改变 S/I/F 集合后信息位平均 GA 可靠性相对基线(p=0.5)的比值 `rel_ratio`，
  `A_loss = rel_ratio^(alpha_rel·code_high_weight)`；高 SNR 用 sigmoid 加权 `code_high_weight` 增强惩罚。
- **机制 B（调制侧）**：16QAM 半径类别概率 `内 p^2 / 中 2p(1-p) / 外 (1-p)^2`。
  - `strict_q`（主模型）：`P_e,geo = (2P_out+3P_mid+4P_in)·Q(√(2·dmin²/N0))`，`N0=Es/SNR_lin`，几何比值 = `P_e,geo(p)/P_e,geo(0.5)`。
  - `heuristic`（对照）：高斯窗加权的经验增益。
- **位级基础**：`pe_phi = 0.5·phi(channel_reliability)`（极化码位级误码近似）。
- **合成**：`ratio_scale`：`pe = pe_phi·A_loss·geom_ratio`；`independent_union`：`pe = 1-(1-pe_code)(1-pe_geo)`。
- 钳位 `pe ∈ [pe_floor, 0.5]`，加权 `BER_hat = Σ K_b·pe_b / ΣK_b`。

## Numerical Notes
- ⚠️ 经验模型，定量结论必须以 Monte Carlo（l3_sim_shaped_polar_16qam）为准。
- `Q(x) = 0.5·erfc(x/√2)`；多处 `max(·, eps)` 防除零。

## Dependencies
- l3_GA, l3_phi（`arrayfun(@phi, ·)`）。内部子函数：local_get_SK / local_radius_probabilities / local_geom_pe_strict_q。

## Health
degraded — 近似/经验模型，作趋势工具用，不作最终定量依据。
