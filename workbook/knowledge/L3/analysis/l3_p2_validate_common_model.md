# L3 · p2_validate_common_model

- method_id: l3_p2_validate_common_model
- file_path: 16QAM_Polar/v2/analysis/p2_validate_common_model.m
- module: analysis
- health: exploratory

## Scope

`manifest=p2_validate_common_model(model_file)` 对探索模型检查训练配置、PMF原始计数一致性、当前训练清单、参考重算及从训练表重新拟合参数；只验证当前文件链一致性，不能追溯原始冻结时刻、证明独立性或模型精度。

## Verification

MATLAB对现有探索模型及27条训练raw通过，复制模型并改变校准参数被拒。依赖 l3_p2_validate_common_pmf、l3_p2_model_training_manifest、l3_p2_validate_common_references、l3_p2_calibrate_model。
