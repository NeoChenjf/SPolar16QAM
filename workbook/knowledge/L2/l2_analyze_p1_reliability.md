# L2 · analyze_p1_reliability
- **flow_id**: l2_analyze_p1_reliability
- **entry_script**: 16QAM_Polar/v2/diagnostics/analyze_p1_reliability.m
- **runtime**: minutes
- **needs_user_run**: false
- **validates**: 当前P1/P2/P3近似适用性；不升级既有L1科学结论
## Purpose
按H/标签/p/组/路聚合；实际位置sigma和A0联合PMF作Gauss-Hermite求积；原GA与唯一min-sum独立边缘粒子参照；递归SC保留部分和/判决反馈；帧级Hoeffding区间、逐位MAE/排序；test模式对N8/1024向量SC与生产SC差分。
## Pipeline
1. 读取冻结物理配置和保存数据（内联）。
2. 数值计算与计数：l3_analyze_p1_reliability。
3. 输出逐位、帧级分母、误差、耗时（内联）。
## Inputs
N1024，3诊断H，标签20/28，p=.5/.3；本轮用户新授权1200case帧/90分钟/500MiB。参数不用config覆盖。
## Outputs
时间戳results目录的MAT/CSV/PNG/PDF/源码/参数/报告。
## Acceptance
无自造科学成功线；非有限/生产参照不一致则停。零错误保留分母；固定H按帧评价，不外推跨H；开发结果不能作P4。运行仅本轮授权有效。
## Weekly Report
周报/阶段B/B4：full-chain策略验证.md


## 2026-11-10 最终数值分辨率与状态
最终候选order默认80、B默认8192、seed默认112100004；候选另接受可选order用于显式数值检查。原20阶/2048文本是开发版本。最新80阶全表证据见报告末尾，P4仍未独立验证/未压缩。PMF训练误差不包含在真实帧区间内。非零误差域代数对非均匀实际码字仍成立，独立边缘替代联合分布为近似，零平局限制保留。
