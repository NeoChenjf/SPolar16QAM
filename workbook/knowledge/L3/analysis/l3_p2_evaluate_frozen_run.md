# L3 · p2_evaluate_frozen_run

- **method_id**: l3_p2_evaluate_frozen_run
- **file_path**: 16QAM_Polar/v2/analysis/p2_evaluate_frozen_run.m
- **module**: analysis
- **health**: degraded（单case短实链路测试通过；非正式统计）

## Signature

`summary=p2_evaluate_frozen_run(frozen,run_dir,baseline_ids)`：读取独立test_seen目录，先审计原始配对，再核验选中case和基线的指标，最终按信道配对求差。

## Purpose / Math

从raw重算错误数、信息位数、设计码率、BER、Goodput恒等式、归一包络矩和N0，与CSV核对；通过后交给策略评价器。N0以相对1e-12容差容许CSV十进制往返，其余浮点比较为1e-12绝对容差。

## Numerical Notes

噪声/payload只验证记录的哈希无法重新计算；frozen资产来源/哈希由上游冻结过程保证，本方法未实施冻结；未计算bootstrap。数据不足不能声称基线胜出。

## Dependencies

- l3_ref: l3_p2_audit_common_pairing
- l3_ref: l3_p2_evaluate_frozen_tradeoff

## Verification status

先以pilot角色验证拒绝；一次真实test_seen单帧自对照链通过（差0），发现并修复CSV N0浮点往返的错误拒绝。未执行多策略独立信道/置信区间验收。


## 2026-11-06 信息分母修订

码率从raw的每帧info_counts重建，支持纯能量组K不计有效载荷；配合raw/哈希审计进行独立短接口比较。纯能量组不计BER与信息块BLER。无正式科学验收。


## 2026-11-06 独立策略角色

新增strategy_training/strategy_test角色支持；训练与测试独立seed及raw配对审计保持，模型calibration/test_seen旧入口兼容。N1024、27组合及纯能量基线的两信道单帧训练/测试仅完成探索通路，未验证统计收益或DC。
