

# L3 · p2_prepare_state

- **method_id**: l3_p2_prepare_state
- **file_path**: 16QAM_Polar/v2/core/p2_prepare_state.m
- **module**: core
- **health**: healthy

## Signature

`function state = p2_prepare_state(template, snr_db, kind, reference)`

## Purpose / Math

固定源S，按当前SNR的GA在余位选择实际I；random_s/donor_s保持原S/I/F。same_k_i只作冻结集合诊断。记录源指纹、实际集合指纹和通信SNR。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_GA

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_78ec07aca9c2_20261024; current_status=current; supersedes=[].
