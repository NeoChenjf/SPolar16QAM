# L3 · run_p1_reliability_batch
- **method_id**: l3_run_p1_reliability_batch
- **file_path**: 16QAM_Polar/v2/diagnostics/run_p1_reliability_batch.m
- **module**: analysis
- **health**: degraded — 研究开发证据，未独立验证
## Signature
`run_p1_reliability_batch()`；analyze入口接受results目录或`test`。
## Purpose / Math
复用3个H、2个噪声标签、2个p；各100帧新独立payload/noise；生产接收和真前序genie共享接收帧；保存逐位叶分布和错误。
## Numerical Notes
I/S自由译码，F已知，BER仅计I。固定幅度、实际集合和映射。GA使用m=2mu²/variance及0.5erfc(sqrt(m/4))；粒子f=sign(a)sign(b)min(abs(a),abs(b))，g=b+(1-2beta)a。独立边缘、符号对称和池化PMF均为近似，不等同成形全联合分布。无新无编码通信符号；数值积分节点不计通信样本。原GA与校准分开。
## Dependencies
l3_p2_predict_ga, l3_p2_llr_reference, l3_polar_encoder, l3_SC_decoder；批次另用p2_prepare_state/p2_transmit_block/ofdm_common_noise_roundtrip和v3 sc_decode_forced_full（复用已有方法）。
## Evidence
results/20261110_182159_p1_reliability；周报/阶段B/B4：full-chain策略验证.md最新记录。
