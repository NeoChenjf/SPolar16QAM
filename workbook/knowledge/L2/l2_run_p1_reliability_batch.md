# L2 · run_p1_reliability_batch
- **flow_id**: l2_run_p1_reliability_batch
- **entry_script**: 16QAM_Polar/v2/diagnostics/run_p1_reliability_batch.m
- **runtime**: minutes
- **needs_user_run**: false
- **validates**: 当前P1/P2/P3近似适用性；不升级既有L1科学结论
## Purpose
复用3个H、2个噪声标签、2个p；各100帧新独立payload/noise；生产接收和真前序genie共享接收帧；保存逐位叶分布和错误。
## Pipeline
1. 读取冻结物理配置和保存数据（内联）。
2. 数值计算与计数：l3_run_p1_reliability_batch。
3. 输出逐位、帧级分母、误差、耗时（内联）。
## Inputs
N1024，3诊断H，标签20/28，p=.5/.3；本轮用户新授权1200case帧/90分钟/500MiB。参数不用config覆盖。
## Outputs
时间戳results目录的MAT/CSV/PNG/PDF/源码/参数/报告。
## Acceptance
无自造科学成功线；非有限/生产参照不一致则停。零错误保留分母；固定H按帧评价，不外推跨H；开发结果不能作P4。运行仅本轮授权有效。
## Weekly Report
周报/阶段B/B4：full-chain策略验证.md
