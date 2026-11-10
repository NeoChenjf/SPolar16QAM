# L3 · p2_evaluate_frozen_tradeoff

- **method_id**: l3_p2_evaluate_frozen_tradeoff
- **file_path**: 16QAM_Polar/v2/analysis/p2_evaluate_frozen_tradeoff.m
- **module**: analysis
- **health**: degraded（合成行为验证通过，未做正式独立信道验证）

## Signature

`summary = p2_evaluate_frozen_tradeoff(frozen,T,baseline_ids)`：接收已选训练结果、独立test_seen数据及基线ID；输出每个基线的配对信道数、BER/Goodput/代理差均值及选中策略满足门槛的经验信道数。

## Purpose / Math

按channel键对齐后取候选减基线的平均差；代理与训练使用相同beta2/beta4。函数只评价已选case，不在测试数据选策略。

## Numerical Notes

强制测试seed不同、SNR相同、同信道与帧数、N0一致；这些字段相同并不能证明实际h/n相同，必须从原始指纹/源码另行审计。未提供置信区间，不保证每次或任意信道达标；代理不等于DC。frozen需实际由训练生成、冻结并哈希，函数自身未验证文件来源。

## Dependencies

无项目方法调用；输入来自l3_p2_select_training_tradeoff。

## Verification status

MATLAB合成测试通过配对差、门槛计数、缺配对、同训练seed和N0冲突拒绝；无真实独立统计和三计划基线验收。


## 2026-11-06 独立策略角色

新增strategy_training/strategy_test角色支持；训练与测试独立seed及raw配对审计保持，模型calibration/test_seen旧入口兼容。N1024、27组合及纯能量基线的两信道单帧训练/测试仅完成探索通路，未验证统计收益或DC。
