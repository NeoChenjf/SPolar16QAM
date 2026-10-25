

# L3 · p2_freeze_model

- **method_id**: l3_p2_freeze_model
- **file_path**: 16QAM_Polar/v2/analysis/p2_freeze_model.m
- **module**: analysis
- **health**: healthy

## Signature

`function model_path = p2_freeze_model(calibration_dirs, out_dir)`

## Purpose / Math

合并指定训练目录，保留训练模式和功率哈希；冻结两参数，拒绝同一seed重复录入及未见组合进入拟合。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_p2_calibrate_model

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_fda2166d4d30_20261024; current_status=current; supersedes=[].
