# L3 · 全均匀信息基线对照

- method_id为l3_analyze_frontier_uniform_baseline。
- file_path为16QAM_Polar/v2/analysis/analyze_frontier_uniform_baseline.m。
- module为analysis，health为degraded：样本内选择使区间有选择偏差。

## Signature

analyze_frontier_uniform_baseline(out)读取逐帧通信结果，逐条件比较125候选的样本内最高Goodput和全p=.5候选，以2000次配对整帧bootstrap给固定候选差区间。

## Math / Algorithm

Goodput=(K−错误)/(4×49×80)。先取样本内点最优，再将该候选与均匀基线的每帧差重采样。

## Numerical Notes

区间未覆盖样本内挑选最优、多个条件同时比较或PMF模型误差；诊断信道单列。

## Dependencies

冻结协议、逐条件通信MAT，MATLAB prctile与rng。
