# L3 · A0诊断方法
- **method_id**: l3_run_a0_diagnostics
- **file_path**: 16QAM_Polar/v2/diagnostics/run_a0_diagnostics.m; run_a0_statistics.m; run_a0_production.m
- **module**: analysis
- **signature**: 三个无参诊断入口，输出时间戳结果目录；无返回值。
- **purpose**: 有限用例独立正确性和统计核验，不用于拟合或策略优化。
- **math_definition**: 递归min-sum f=sign(a)sign(b)min(abs(a),abs(b))，g=(1-2beta)a+b；无编码BER按独立符号内错误比例估方差，四项Bonferroni总alpha=.01；普通与全强制共享接收LLR。
- **dependencies**: l3_polar_encoder, l3_SC_decoder, l3_llr_16qam_gray_LSE；生产入口另调用p2_prepare_state、p2_transmit_block、ofdm_common_noise_roundtrip及v3 sc_decode_forced_full。
- **numerical_notes**: 零LLR判0；T5正态近似区间；catch保存失败后不抛错，退出码0不能证明通过。模板必须按p_vec匹配，不能假定位置。
- **health**: degraded — 初次生产诊断模板误取p=.1/.2；匹配修复未通信复验，指定T6未完成。禁止在本轮预算内重跑。

## 2026-11-10 修复批当前状态
正确p=.5/.3在用户额外120帧授权后运行完成；N1024恢复、独立频域差异阈值、全强制与自由位一致性断言通过；verify_a0_saved重算360组计数首错通过。health更新为healthy（有限用例），历史degraded记录保留。T3极端量级及所有当前位翻转未穷尽；不扩大科学结论。新增verify_a0_saved为无新增通信样本复核入口，输出audited_goodput.csv、diagnostic.png。
