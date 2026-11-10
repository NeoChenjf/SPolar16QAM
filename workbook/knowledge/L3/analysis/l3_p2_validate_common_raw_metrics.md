# L3 · p2_validate_common_raw_metrics

- **method_id**: l3_p2_validate_common_raw_metrics
- **file_path**: 16QAM_Polar/v2/analysis/p2_validate_common_raw_metrics.m
- **module**: analysis
- **health**: degraded（探索原型，非正式资产与统计验收）

## Signature

`p2_validate_common_raw_metrics(run_dir,T)`

## Purpose / Math

核对训练或测试表角色/seed，并从各raw重算错误数、信息分母、码率、Goodput、L4矩和N0；不选择策略。

## Numerical Notes

模型能量仍是未标定矩代理；仅校验源码哈希清单文件自身，并未重新逐份核验清单所列源码副本。噪声哈希基于运行时记录，未存原数组。训练/测试各2信道每候选1帧，不能证明收益或误差。正式模式不可用。

## Dependencies

无其他项目方法依赖。

## Verification status

MATLAB对真实N1024 27组合训练和独立短测试构建资产并评价通过；改写资产内训练表哈希、以测试集冒充训练分别被拒绝。未完成独立多信道置信区间/模型/硬件验收。
