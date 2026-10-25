

# L3 · p2_predict_ga

- **method_id**: l3_p2_predict_ga
- **file_path**: 16QAM_Polar/v2/analysis/p2_predict_ga.m
- **module**: analysis
- **health**: degraded

## Signature

`function prediction = p2_predict_ga(leaf_means, state, calibration)`

## Purpose / Math

逐位置非同分布高斯叶节点按SC的f/g配对传播，有限二分近似phi逆；按实际I和K加权Q项。数值下限1e-12单独标记，不代表真实BER。

## Numerical Notes

候选近似，尚未通过独立正式性能/速度门槛；不称为精确理论。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

无项目外部方法依赖；使用MATLAB内置功能。

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_d71818a686a2_20261024; current_status=current; supersedes=[].
