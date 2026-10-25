

# L3 · p2_uniformity_contract

- **method_id**: l3_p2_uniformity_contract
- **file_path**: 16QAM_Polar/v2/analysis/p2_uniformity_contract.m
- **module**: analysis
- **health**: healthy

## Signature

`function proof = p2_uniformity_contract(state, free_set)`

## Purpose / Math

在声明的公平自由输入集上，检查生成矩阵每列是否至少有一个非零系数；非零GF(2)线性函数公平，否则固定0。先得到每个位置四路独立联合PMF，再平均；不能乘平均边缘。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_get_GN

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_7d3da005829a_20261024; current_status=current; supersedes=[].
