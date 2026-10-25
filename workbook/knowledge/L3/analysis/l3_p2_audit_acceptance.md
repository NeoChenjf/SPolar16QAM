

# L3 · p2_audit_acceptance

- **method_id**: l3_p2_audit_acceptance
- **file_path**: 16QAM_Polar/v2/analysis/p2_audit_acceptance.m
- **module**: analysis
- **health**: healthy

## Signature

`function gate_path = p2_audit_acceptance(power_dirs, pmf_dirs, power_file, model_file, out_dir)`

## Purpose / Math

真实原始表核验独立功率与必需PMF目标；3seed、每cell≥80码字、2000簇bootstrap。donor诊断模型单列。门禁绑定功率/模型哈希，文件存在不等于通过。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_p2_distribution_reference, l3_test_p2_mechanism

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_2ba73e3970f0_20261024; current_status=current; supersedes=[].
