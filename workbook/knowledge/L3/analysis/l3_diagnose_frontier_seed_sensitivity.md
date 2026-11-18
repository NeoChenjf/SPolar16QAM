# L3 · 固定失败案例粒子种子诊断

- method_id为l3_diagnose_frontier_seed_sensitivity。
- file_path为16QAM_Polar/v2/analysis/diagnose_frontier_seed_sensitivity.m。
- module为analysis，health为degraded：针对已观察反例做事后解释，不是独立验证。

## Signature

diagnose_frontier_seed_sensitivity(out)对H5/标签20候选99与120计算五个额外粒子种子的显式SC预测，不生成通信帧，也不替换冻结结果。

## Math / Algorithm

对三个资源组、p=.4/.5按冻结分布和信道调用l3_p1_predict_minsum，以各组实际K合成为候选Goodput。列出各seed的99−120差及计算耗时。

## Numerical Notes

所选案例由测试结果触发，纯粹用于诊断数值不稳定；五个seed只量化一部分有限粒子波动，不覆盖训练分布或模型结构误差。

## Dependencies

l3_p1_predict_minsum、frozen.mat与原始预测。
