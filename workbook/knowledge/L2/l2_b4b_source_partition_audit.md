# L2 · B4源集合条件熵审计

- **flow_id**: l2_b4b_source_partition_audit
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_b4b_source_partition_audit.m
- **runtime**: seconds（本轮4.01秒）
- **needs_user_run**: false（固定短预算；扩大预算按长跑规则）
- **validates**: l1_multicarrier_ofdm#H2

## Purpose
检查B4 GA集合是否具有源整形所需的低熵S、高熵I结构。

## Pipeline
| step | l3_ref | 说明 |
|---|---|---|
| iid源样本与精确源熵 | l3_v3_build_stream_partition_source_mc_ga | p=0.3/0.1，各seed80个码字 |
| 保留B4码率重建集合 | l3_GA | 源熵选S，剩余位置GA选I；K保留ceil |
| 条件熵分组统计及保存 | 内联 | 两种集合的S/I/F均值，保存完整逐位置熵 |

## Inputs
cfg_local：N=1024，seeds=[1701,2903,4127]，source_samples=80，sigma_design=10^(-20/20)。

## Outputs
时间戳results目录：CSV/MAT/README/log/source_entropy.png及pdf。

## Acceptance
条件熵按精确源条件概率计算；全位置均值应接近H2(p)，只作数值自检。
同一估计选集合和评价集合，只能作描述性诊断。因果改善需独立构造样本及PMF验证。
不包含BER、Goodput、RF能量排序，不替代正式PMF门禁。

## Weekly Report
周报/阶段B/B4：full-chain策略验证.md

## 2026-10-09 构造契约追加

新版本为`source_entropy_S_GA_IF`：每一路保持原K和S数量；固定源熵估计选择S；每个通信SNR在剩余位置重新GA排序选I/F；逐帧按payload和F=0调用v3精确源SC强制构造。源熵估计seed与评价seed必须分离。接收端仍是现有SC/LLR契约，不能将source precoder准确性等同于接收度量匹配。正式PMF门禁和码长对照见本轮时间戳结果；本次不更新最优性能结论。
