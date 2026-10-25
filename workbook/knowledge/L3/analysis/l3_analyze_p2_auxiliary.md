

# L3 · analyze_p2_auxiliary

- **method_id**: l3_analyze_p2_auxiliary
- **file_path**: 16QAM_Polar/v2/analysis/analyze_p2_auxiliary.m
- **module**: analysis
- **health**: healthy

## Signature

`function out = analyze_p2_auxiliary(preflight_dir, out)`

## Purpose / Math

只取第一可靠性组，池化3seed×8码字的独立计数；保存S边缘与32位置相关图。有限样本边缘熵不能替代源条件熵或联合独立性。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

无项目外部方法依赖；使用MATLAB内置功能。

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_60c0a9218cbf_20261024; current_status=current; supersedes=[].
