# P4 · run_p4_independent
- method_id: l3_run_p4_independent
- flow_id: l2_run_p4_independent
- file_path / entry_script: 16QAM_Polar/v2/diagnostics/run_p4_independent.m
- module: analysis
- runtime: minutes
- needs_user_run: false（仅本轮明确追加授权内）
- health: healthy（实现参照支持不等于模型科学验收）
## Signature / Inputs
run_p4_independent(out)，out是已保存params.json的时间戳结果目录。N1024、3既有H、标签20/28、p.5/.3；实际SIF/K、Gray16QAM、幅度1、min-sum。新seed113000000+H*10000+label*100+frame。
## Purpose / Pipeline / Math
run批次只生成12格各50新帧，总600；同接收帧供普通SC/轨迹/genie使用一次计数。run预测只读A0离线PMF/状态/H/N0/位置，调用冻结p1_predict_minsum（order80/B8192/seed112100004），不读测试数据。analyze提取7200帧路记录与分母，并重用保存LLR计时普通SC，重复计算不生成通信数据；核对原状态fingerprint和生产判决。BER仅计I，I/S自由、F0。
## Dependencies
l3_p1_predict_minsum、l3_p2_prepare_state、l3_p2_transmit_block、l3_llr_16qam_gray_LSE、l3_SC_decoder；ofdm_common_noise_roundtrip与v3 sc_decode_forced_full复用已有生产/参照。
## Outputs
results/20261110_191153_p4_independent：params/frozen源码、raw summaries、逐帧CSV、冻结预测、统计/成本/图/报告。
## Acceptance / Numerical Notes
600新增通信帧加此前1200，总上限1800；0新增无编码符号，墙钟19:48:10、通信19:23:10止、总500MiB。参数/seed冻结后不调参、不扩样。固定H内按帧区间，不声明跨H泛化；零错误保留分母。无自造通过线。P4模型适用性以独立报告为准。
## Weekly Report
周报/阶段B/B4：full-chain策略验证.md最新追加。
