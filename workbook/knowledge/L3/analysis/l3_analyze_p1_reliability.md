# L3 · analyze_p1_reliability
- **method_id**: l3_analyze_p1_reliability
- **file_path**: 16QAM_Polar/v2/diagnostics/analyze_p1_reliability.m
- **module**: analysis
- **health**: degraded — 研究开发证据，未独立验证
## Signature
`analyze_p1_reliability()`；analyze入口接受results目录或`test`。
## Purpose / Math
按H/标签/p/组/路聚合；实际位置sigma和A0联合PMF作Gauss-Hermite求积；原GA与唯一min-sum独立边缘粒子参照；递归SC保留部分和/判决反馈；帧级Hoeffding区间、逐位MAE/排序；test模式对N8/1024向量SC与生产SC差分。
## Numerical Notes
I/S自由译码，F已知，BER仅计I。固定幅度、实际集合和映射。GA使用m=2mu²/variance及0.5erfc(sqrt(m/4))；粒子f=sign(a)sign(b)min(abs(a),abs(b))，g=b+(1-2beta)a。独立边缘、符号对称和池化PMF均为近似，不等同成形全联合分布。无新无编码通信符号；数值积分节点不计通信样本。原GA与校准分开。
## Dependencies
l3_p2_predict_ga, l3_p2_llr_reference, l3_polar_encoder, l3_SC_decoder；批次另用p2_prepare_state/p2_transmit_block/ofdm_common_noise_roundtrip和v3 sc_decode_forced_full（复用已有方法）。
## Evidence
results/20261110_182159_p1_reliability；周报/阶段B/B4：full-chain策略验证.md最新记录。


## 2026-11-10 最终数值分辨率与状态
最终候选order默认80、B默认8192、seed默认112100004；候选另接受可选order用于显式数值检查。原20阶/2048文本是开发版本。最新80阶全表证据见报告末尾，P4仍未独立验证/未压缩。PMF训练误差不包含在真实帧区间内。非零误差域代数对非均匀实际码字仍成立，独立边缘替代联合分布为近似，零平局限制保留。
