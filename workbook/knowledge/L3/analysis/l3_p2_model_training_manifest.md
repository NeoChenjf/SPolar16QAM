# L3 · p2_model_training_manifest

- method_id: l3_p2_model_training_manifest
- file_path: 16QAM_Polar/v2/analysis/p2_model_training_manifest.m
- module: analysis
- health: exploratory

## Signature / purpose

`manifest=p2_model_training_manifest(run_dir,expected)` 在探索模型校准目录核验源码副本、共同环境配对、表与raw指标及行集合，计算参数、表、cases、源码清单、PMF文件及全部raw的SHA-256。可选 `expected` 逐项比较此前生成并可信保存的清单，变化则拒绝。清单创建时间就是调用时间，不能追溯证明更早的模型冻结时点。

## Limits and verification

清单自身必须由独立可信渠道冻结；对其一并篡改无法检出。PMF资产来源、训练预测值、计时、模型参数是否由表重算以及跨split真实独立性均未由此保证；不能用于正式门禁。MATLAB对现有探索校准批27 raw两次计算一致，合成修改清单行哈希被拒绝；没有修改既有数据。依赖 l3_p2_verify_common_snapshot、l3_p2_audit_common_pairing、l3_p2_validate_common_raw_metrics。

## 2026-11-06 预测数值内部复算补充

训练清单调用 `p2_validate_common_predictions`，该函数根据raw中保存的refs/states重算GA与校准值。校准和seen探索各27行通过；并未重算refs、证明PMF来源或计时，仍非正式可信冻结。
