

# L3 · p2_transmit_block

- **method_id**: l3_p2_transmit_block
- **file_path**: 16QAM_Polar/v2/core/p2_transmit_block.m
- **module**: core
- **health**: healthy

## Signature

`function block = p2_transmit_block(state, base_payload, auxiliary_bits, donor_payload)`

## Purpose / Math

shaped调用消息条件化整形；random_s令u(S)为独立公平辅助位；donor_s令u(S)来自独立消息的原整形向量；始终u(I)=当前消息，u(F)=0，x=uG。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_parallel_to_serial_bits, l3_polar_encoder, l3_v3_shape_stream_sc

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_4bd96d8621f6_20261024; current_status=current; supersedes=[].
