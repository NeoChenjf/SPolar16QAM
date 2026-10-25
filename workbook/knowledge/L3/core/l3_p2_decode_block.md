

# L3 · p2_decode_block

- **method_id**: l3_p2_decode_block
- **file_path**: 16QAM_Polar/v2/core/p2_decode_block.m
- **module**: core
- **health**: healthy

## Signature

`function result = p2_decode_block(y, sigma, scale, block, diagnose)`

## Purpose / Math

沿用当前LLR与min-sum SC，活动集I∪S，仅统计I。真实前序位诊断把全部历史决策强制为真实u，用决策前LLR观察局部错误；不是新接收机或严格界。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_SC_decoder, l3_get_bit_layer, l3_get_llr_layer, l3_llr_16qam_gray_LSE, l3_v3_sc_decode_forced_full

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_d461b5468860_20261024; current_status=current; supersedes=[].
