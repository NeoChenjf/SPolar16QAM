# L1 · 通用 Cartesian Gray QAM shaped polar

- **domain_id**: l1_general_gray_qam_shaping
- **maturity**: planned
- **rks_score**: 45

## Research Question

能否把 v2 固定 Gray 16QAM 的四路二元成形，推广为调制阶数 `M` 驱动的 Cartesian Gray QAM multi-stream shaped-polar系统，使8/16/32/64QAM在同一接口下实现可验证的PMF、SC编解码、BER/Goodput与平均发射RF能量代理量权衡？

## Hypotheses

- H1: 从 `M` 自动构造 I/Q Gray-PAM 轴、标签和固定均匀能量缩放，可让 8/16/32/64QAM通过同一星座/标签协议。
- H2: 每轴 latent `p_i` 与可逆 GF(2) relation 能表达一族相关 Gray 标签 PMF，并以 KL最小化逼近能量倾斜目标。
- H3: 在固定缩放与 `fixed_n0` 下，正能量倾斜参数增大可使实际平均符号能量单调不减；BER/Goodput变化必须结合码率上界解释。
- H4: 按 `z=T^-1b` latent labels直接计算的symbol-prior MAP/LSE LLR能完成SC-only无噪声环回和AWGN瀑布验证。

## Core Quantities

| 符号 | 定义 | 单位 | 计划计算位置 |
| --- | --- | --- | --- |
| `M` | Cartesian QAM 点数，首版 8/16/32/64 | — | v3 top-level API |
| `M_I,M_Q` | I/Q PAM 阶数 | — | constellation builder |
| `p_I,p_Q` | 每轴 latent bit 的 `P(z=1)` | — | shaping solver |
| `T_I,T_Q` | 每轴 GF(2) 可逆关系 | — | axis relation module |
| `P_target,P_model,P_emp` | 目标/可实现/经验符号 PMF | — | PMF analysis |
| `D_KL` | `D_KL(P_target||P_model)` | nat或bit，结果须标注 | shaping solver |
| `E` | 固定均匀缩放下 `ΣP_model|x|²` | 能量 | generic metrics |
| `R_code` | `sum(K_b)/(log2(M)N)` | bit/coded bit | generic core |
| `R_bpcu` | `sum(K_b)/N` | bit/channel use | generic core |

## Theoretical Boundaries

- 首版只处理可分解为两个 `2^k`-PAM 轴的 Cartesian Gray QAM，不覆盖 cross-QAM/APSK。
- 固定 relation 与有限 `p_i` 不保证精确表达任意 PMF；必须报告 KL/TV。
- QAM 模型 PMF首版采用 `P_X=P_I P_Q`；轴内 label bits 可相关，I/Q 轴之间不建模相关性。
- 同一个 `M` 的星座缩放固定为均匀 PMF基准，不随 shaped PMF变化。
- v3是每个latent bit-level一条长度N polar stream的BICM扩展，不声称与论文单整体polar graph有限长等价。
- relation发送变换后，接收端必须按 `z=T^-1b` 直接枚举latent bit metric；不能把label LLR当latent LLR。
- shaped-polar precoder必须先约束本帧payload `I` 与冻结位 `F`，再求 `S`；通信SC只冻结 `F`，联合解码 `I∪S`，仅 `I` 计入payload。

## Pitfalls（护栏）

- ⚠️ 不得硬编码 16QAM 的第 2/4 bit 为幅度位；角色由 Gray-PAM 几何推导。
- ⚠️ 不得将 Cartesian 8/32QAM 结论扩写为任意 8/32QAM 星座。
- ⚠️ `fixed_n0` 与 `fixed_esn0` 必须分开报告；能量增益结论使用固定scale与固定噪声参考，并称平均发射RF能量代理量，不称整流收获能量。
- ⚠️ 先核对 `R_code/R_bpcu` 上界，再解释 Goodput；BER结论先定位瀑布区。
- ⚠️ v2 只作限定回归，不是 v3 multi-stream relation shaped-polar 的目标实现。

## Collaborators

- → `l1_polar_coding`：SC precoder/decoder、S/I/F构造与码率。
- → `l1_probabilistic_shaping`：从独立单 p 扩展到 axis latent p + relation。
- → `l1_16qam_modulation_llr`：16QAM特例与 LSE LLR经验被泛化。
- → `l1_channel_snr`、`l1_metrics_tradeoff`：SNR/能量/Goodput口径。

## Planned Evidence

- `学习文档/高阶调制理论/通用GrayQAM-loop/`
- 后续 v3 的 L2 统一入口与各 `.m` 的 L3 契约。
