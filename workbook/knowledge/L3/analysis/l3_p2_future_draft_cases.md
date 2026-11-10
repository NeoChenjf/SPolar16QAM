# L3 · p2_future_draft_cases

- method_id: l3_p2_future_draft_cases
- file_path: 16QAM_Polar/v2/analysis/p2_future_draft_cases.m
- module: analysis
- health: draft_only

`cases=p2_future_draft_cases(strategy_p,strategy_names,controls)` 按三组p和控制类型展开拟议case，要求shaped位于首位；沿用当前原型对全p=.5只保留首项、差信道纯能量只保留shaped的规则。规则复用不等于证明各控制在p=.5完全等价，也不检查I/S/F或目标分布；正式协议需单独确认。纯算术构造，不运行仿真。

MATLAB验证A=6、B/C/D=3、E/F=28，全.5去重和无效顺序拒绝。case命名/排序仅草案，需与最终正式入口逐项比对。

## 2026-11-06 对既有策略资产的编号核对

使用已有训练批 `20261106_170217_p2_common_env_pilot_strategy_training_b657112d/cases.mat`，MATLAB逐项比较草案展开的27组+纯能量case，ID、p向量、kind均完全一致；这是对既有资产的映射验证，不是对尚未实现的正式入口验收。关键映射：`combo_06_shaped=[.5,.3,.1]`（好信道偏信息）、`combo_22_shaped=[.1,.3,.5]`（好信道偏能量）、`combo_27_shaped=[.5,.5,.5]`（均匀基线）；`bad_channel_energy_only_shaped=[.5,.3,.1]` 另通过实现将第3组消息置零并从信息统计中排除。实现按信道增益降序分组；不同方案K/资源分母必须单列。测试 `test_p2_future_draft_cases` 已加入全28项对照并通过。历史训练资产尚不能证明正式物理、策略表现或器件有效性。
