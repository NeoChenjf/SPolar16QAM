

# L3 · p2_seed

- **method_id**: l3_p2_seed
- **file_path**: 16QAM_Polar/v2/core/p2_seed.m
- **module**: core
- **health**: healthy

## Signature

`function value = p2_seed(purpose, seed, realization, snr_index, frame, group)`

## Purpose / Math

将purpose、注册seed槽、信道、SNR序号、帧、组按互斥混合基数编码，配对策略共用key；独立辅助/供体使用组g+3，噪声使用组0。验证增样槽分配独立角色区间。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

无项目外部方法依赖；使用MATLAB内置功能。

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_421a0dd5587e_20261024; current_status=current; supersedes=[].
