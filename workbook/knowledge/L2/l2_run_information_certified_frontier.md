# L2 · run_information_certified_frontier

- **flow_id**: l2_run_information_certified_frontier
- **entry_script**: 16QAM_Polar/v2/diagnostics/run_information_certified_frontier.m
- **runtime**: long
- **needs_user_run**: true
- **validates**: 本轮独立问题登记见学习文档loop/信息预测收敛与5%约束回退实验-2026-11-18.md；不新增或宣称既有L1假设通过。

## Purpose
比较简单指标引导、显式SC数值引导、直接完整SC在同预算下，守住相对全p=.5损失5%的能量收益及认证覆盖。

## Pipeline
|#|step|l3_ref|说明|
|---|---|---|---|
|1|冻结输入|内联prepare|历史训练PMF/I/S/F，125候选，新H与种子|
|2|编码与物理接收|l3_p2_transmit_block、l3_ofdm_common_noise_roundtrip、l3_p2_decode_block|生产min-sum SC；配对候选/基线|
|3|预测调度|l3_information_score_quadrature、l3_p1_predict_minsum|有限数值细化；非认证输入|
|4|统一证书|l3_goodput_betting_certificate|每H全候选全时保护；不确定则回退|
|5|独立评价|l3_analyze_information_certified_frontier|三方法全部停止后100帧评价，不反馈选择|

## Inputs
cfg_local式冻结参数：N1024，三组p各.1/.2/.3/.4/.5；4随机H标签16/24加既定深衰落诊断20；预算60/180/600秒；look5/20/80/320/1280；8帧能量catalog；100帧独立评价。公共幅度、映射、构造不改；I/S自由，F已知，只统计I。沿用旧40帧PMF，不用测试更新。

## Outputs
results/20261117_234819_certified_frontier/：protocol.json、frozen.mat、catalog、method、condition、ledger、CSV/MAT及图。历史数据不覆盖。

## Acceptance
12小时授权仅适用2026-11-17本批；非永久撤销needs_user_run。准备2小时，08:48:19停止新增通信，11:48:19最终截止；case上限650000、4GiB、0独立无编码符号。方法预算计入catalog共同计价、预测与认证；评价成本另报。认证集合95%保护不指跨H、真实Pareto或硬件DC。新H/seed不因结果替换，不因证据不足自动扩样或降低标准；零错误保留分母；核对K和资源上界。描述性无收益/认证不足亦为有效研究交付。

## Weekly Report
周报/阶段B/B4：full-chain策略验证.md（由主任务集中追加）；最新结论认loop主报告末尾。


## 2026-11-18 未完成运行

9条件仅C1完整、C2partial。禁止直接run重生成；无完整无重复恢复能力。保存通信下界36423、上界37422。全批独立验证未完成，保持degraded。
