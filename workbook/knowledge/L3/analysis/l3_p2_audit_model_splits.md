# L3 · p2_audit_model_splits

- method_id: l3_p2_audit_model_splits
- file_path: 16QAM_Polar/v2/analysis/p2_audit_model_splits.m
- module: analysis
- health: exploratory

## Scope

`result=p2_audit_model_splits(model_file,test_dir)` 核对探索模型及PMF引用、测试角色/seed、关键配置及seen/unseen配置关系；调用当前模型、测试raw与参考一致性检查，重现信道seed/taps并检查训练/测试信道指纹和key不重叠，恢复调用者RNG。

## Limits / verification

不同key和实现不证明随机流数学独立；未逐项跨split核对所有噪声、payload及辅助位key，也无法证明数据未被提前观察。当前seen键曾用于pilot，非盲测。MATLAB用现有训练/seen各3信道通过，校准目录冒充测试被拒，RNG恢复通过。正式冻结、样本和精度速度验收未完成。依赖 l3_p2_validate_common_model、l3_p2_verify_common_snapshot、l3_p2_audit_common_pairing、l3_p2_validate_common_raw_metrics、l3_p2_validate_common_references、l3_p2_validate_common_predictions、l3_p2_paired_seed。
