# L3 · p2_evaluate_strategy_asset

- **method_id**: l3_p2_evaluate_strategy_asset
- **file_path**: 16QAM_Polar/v2/analysis/p2_evaluate_strategy_asset.m
- **module**: analysis
- **health**: degraded（探索原型，非正式资产与统计验收）

## Signature

`summary=p2_evaluate_strategy_asset(asset_file,test_dir,baseline_ids)`

## Purpose / Math

校验冻结训练参数、表、cases、源码指纹清单及全部raw哈希，再调用独立test策略评价。

## Numerical Notes

模型能量仍是未标定矩代理；仅校验源码哈希清单文件自身，并未重新逐份核验清单所列源码副本。噪声哈希基于运行时记录，未存原数组。训练/测试各2信道每候选1帧，不能证明收益或误差。正式模式不可用。

## Dependencies

l3_p2_evaluate_frozen_run。

## Verification status

MATLAB对真实N1024 27组合训练和独立短测试构建资产并评价通过；改写资产内训练表哈希、以测试集冒充训练分别被拒绝。未完成独立多信道置信区间/模型/硬件验收。


## 2026-11-06 快照逐文件核验补充

此前“仅核验清单本身”的限制已针对当前实现修正：冻结及测试前调用l3_p2_verify_common_snapshot逐份检查源码副本与外部资产；清单真实性仍依赖冻结资产绑定，且外部路径迁移未处理。
