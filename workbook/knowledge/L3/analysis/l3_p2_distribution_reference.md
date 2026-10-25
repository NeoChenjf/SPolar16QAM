

# L3 · p2_distribution_reference

- **method_id**: l3_p2_distribution_reference
- **file_path**: 16QAM_Polar/v2/analysis/p2_distribution_reference.m
- **module**: analysis
- **health**: healthy

## Signature

`function [pmf, role, required] = p2_distribution_reference(state, independent_model)`

## Purpose / Math

shaped对应目标PMF；random_s/native对应均匀目标并检查覆盖；same_k_i对应精确冻结集合模型；donor_s仅对应独立样本的诊断模型，不谎称均匀或原p目标。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_p2_uniformity_contract

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_81264488457a_20261024; current_status=current; supersedes=[].
