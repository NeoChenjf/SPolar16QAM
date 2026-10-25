

# L3 · p2_freeze_power

- **method_id**: l3_p2_freeze_power
- **file_path**: 16QAM_Polar/v2/analysis/p2_freeze_power.m
- **module**: analysis
- **health**: healthy

## Signature

`function artifact_path = p2_freeze_power(calibration_dirs, out_dir)`

## Purpose / Math

独立未缩放校准样本确定shaped全局系数；对照仅为机制匹配采用每组冻结系数，目标来自同策略shaped分量。保存实际PMF、种子与资源契约。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

无项目外部方法依赖；使用MATLAB内置功能。

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_976f15b92b1d_20261024; current_status=current; supersedes=[].
