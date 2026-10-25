

# L3 · run_p2_uniformity_audit

- **method_id**: l3_run_p2_uniformity_audit
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_uniformity_audit.m
- **module**: experiments
- **health**: healthy

## Signature

`function out = run_p2_uniformity_audit()`

## Purpose / Math

N1024、3p×7SNR的确定性生成矩阵审计；同时记录原S冻结0与独立公平I∪S的精确PMF。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_p2_prepare_state, l3_p2_uniformity_contract

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_9bf221165210_20261024; current_status=current; supersedes=[].
