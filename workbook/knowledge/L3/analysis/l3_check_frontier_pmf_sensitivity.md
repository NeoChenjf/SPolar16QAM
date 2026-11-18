# L3 · 训练分布灵敏度

- method_id为l3_check_frontier_pmf_sensitivity。
- file_path为16QAM_Polar/v2/analysis/check_frontier_pmf_sensitivity.m。
- module为analysis，health为degraded，探索性固定子集而非独立验证。

## Signature

check_frontier_pmf_sensitivity(out)从历史训练40帧的16点计数按帧重抽，固定H1/H8×标签16/28×弱组×p=.1/.5，各10次，调用l3_p1_predict_minsum并输出PMF及80条预测，不产生通信帧。

## Math / Algorithm

每档独立帧bootstrap得到PMF，原seed/B/order不变；计算组BER与原值差、PMF总变差。

## Numerical Notes

固定随机数经离散CDF映射产生的粒子扰动与PMF扰动混合；10次不构成置信区间，不替换原始预测。

## Dependencies

l3_p1_predict_minsum、冻结协议与历史训练计数。
