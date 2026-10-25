

# L3 · analyze_p2_mechanism

- **method_id**: l3_analyze_p2_mechanism
- **file_path**: 16QAM_Polar/v2/analysis/analyze_p2_mechanism.m
- **module**: analysis
- **health**: healthy

## Signature

`function analysis_dir = analyze_p2_mechanism(run_dirs, out_dir, n_boot)`

## Purpose / Math

核验唯一键、保存功率/PMF/码率/逐路/S边缘表及图；零错误曲线用有限分母95%上界。RF参考残差单列，PDF回退记录。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_p2_distribution_reference, l3_p2_evaluate_predictions, l3_p2_paired_summary

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_98d4ecd098d1_20261024; current_status=current; supersedes=[].
