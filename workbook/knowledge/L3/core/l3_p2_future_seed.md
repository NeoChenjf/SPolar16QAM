# L3 · p2_future_seed

- method_id: l3_p2_future_seed
- file_path: 16QAM_Polar/v2/core/p2_future_seed.m
- module: core
- health: proposed_not_registered

`value=p2_future_seed(split,realization,snr_index,frame,group,role)` 为未来PMF、模型训练、首次seen/unseen、复验seen/unseen及策略训练/测试提供8个相互分离的候选key域；同一对照候选不编码case身份，共用相同物理输入。不是已冻结正式协议，不生成数据。

## Key space

在当前实现允许的 `p2_seed` 混合基数中，role_index最大10、slot最大3，结果上界为 $11\cdot2^{27}-1$；现有 `p2_paired_seed` 再乘2并加最多1，数值上界为2952790015。本函数候选域从3221225472开始，每split 2²⁶个键；信道、噪声、各组消息/辅助/供体使用互斥slot，按信道、SNR、帧逐层混合基数编码。8个候选split均落在uint32范围。

该界只针对当前项目 `p2_paired_seed` 实现及其依赖的p2_seed域；未证明工作区其他随机数实现都不使用该值。不同seed不构成PRNG统计独立的数学证明。正式使用前需完整注册、检查实验历史/其他随机流、冻结配置并验证；未来一次复验之外的预算不得擅自追加。

## Verification

MATLAB `test_p2_future_seed` 检查656个边界键互异、高于上述旧上界、uint32范围及非法输入拒绝；混合基数无碰撞由字段宽度和互斥slot结构推导，不以656点测试替代全域穷举。旧seed实现未修改。

## 2026-11-06 MATLAB高位seed兼容性补充

在 R2020b 以候选空间上边界附近的 `strategy_test` 高位seed实际调用 `rng(...,'twister')`，重复生成16个高斯数一致，换payload角色键后不同；测试恢复原RNG状态。仅是接口/可复现smoke，不证明随机序列独立或未与其他实验撞键。源码检索发现旧项目还包含配置驱动rng以及 `base + 1000000*realization + ...` 类动态seed，不能仅凭静态数字检索排除全项目冲突；正式注册需按具体冻结配置和实际历史记录核对。

## 2026-11-06 诊断键及测试键使用修订

候选split扩展到12个：在原8个之后追加 `diagnostic_a`、`diagnostic_b` 和 `seen_first_v2`、`unseen_first_v2`；旧8个slot的数值不变。984个边界键互异、落在uint32范围通过。当前混合基数可容纳16个slot，余量仅4；新键仍为候选、未正式注册。

**历史使用警告**：首次运行 `test_p2_future_seed_common_environment` 时误使用 `seen_first` 的信道1信道键、信道1参考点1帧1的noise和group1 payload键，以及 `unseen_first` 的信道1信道键生成了短smoke样本；没有运行通信性能实验，但这些键不能再称未触及。随后测试已改用专门诊断split。新增 `seen_first_v2`、`unseen_first_v2` 键只参与数值边界计算，尚未用作RNG生成测试样本；仍须按全项目历史和具体配置复核后才能作为候选。历史记录不得抹去。

MATLAB通过未来键与共同h/n、候选波形变更、按键重现及诊断split不同信道的短集成检查。不同seed不证明数学独立；本测试不是正式实验或验收。

同日补充：高位seed兼容测试也曾将 `strategy_test` 的信道31、参考点15、帧8191、组3的donor和payload键用于生成16个高斯数；未运行链路。策略测试split因此也不能声称全部键从未用于RNG，正式键分配须排除这些具体键或重新分配独立split。

## 2026-11-06 策略测试v2候选及保护

追加 `strategy_test_v2` 槽，不改变之前12槽映射。当前13槽的1066边界键互异。候选验证入口 l3_p2_candidate_validation_seed 保守拒绝已触及的原始seen/unseen/策略测试全域和diagnostic域；并不代表已完成全历史冲突审计或正式注册。
