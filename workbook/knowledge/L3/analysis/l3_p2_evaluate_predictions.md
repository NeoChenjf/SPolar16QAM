

# L3 · p2_evaluate_predictions

- **method_id**: l3_p2_evaluate_predictions
- **file_path**: 16QAM_Polar/v2/analysis/p2_evaluate_predictions.m
- **module**: analysis
- **health**: healthy

## Signature

`function report = p2_evaluate_predictions(T)`

## Purpose / Math

分别评价test_seen/test_unseen；至少10个独立信道可评价。倍数误差中位数≤2、p90≤5，Goodput MAE≤.02，每帧归一在线速度≥10；不足标证据不足。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

无项目外部方法依赖；使用MATLAB内置功能。

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_af33d7ab1101_20261024; current_status=current; supersedes=[].
