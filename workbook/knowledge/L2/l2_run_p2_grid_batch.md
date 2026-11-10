# L2 · run_p2_grid_batch

- **flow_id**: l2_run_p2_grid_batch
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_grid_batch.m
- **runtime**: long
- **needs_user_run**: true（2026-11-09用户明确授权本轮8小时/10GiB/178800case-帧）
- **validates**: E2三档相对五档有限网格的需求覆盖；不新增物理假设

## Purpose
保持固定幅度与好中差动态分组，比较三档和五档的平均Goodput—假设代理折中，5%实际收益容差。

## Pipeline
| step | l3_ref | 说明 |
|---|---|---|
| 源模板与分区 | l3_build_source_entropy_partition / l3_p2_prepare_state | 0.2/0.4新增模板，原档模板复用，保留实际I/S/F/K |
| 实际发送与译码 | l3_p2_transmit_block / l3_p2_decode_block | 真实共同h/n计算，非E1预测 |
| OFDM与矩 | l3_ofdm_common_noise_roundtrip / l3_ofdm_oversampled_channel / l3_rf_envelope_moments | L1/4/8/16原计算链 |
| 训练选择 | l3_p2_select_training_tradeoff | 19个平均Goodput需求，测试前冻结 |
| 确认性分析 | scripts/analyze_p2_grid_study.py | 新20信道；整体配对、同时区间；不再选策略 |

## Inputs
N1024、64子载波、CP16、16tap、24dB参考噪声；125组合；训练仅新增98组合×20×40，旧27训练复用；确认125×20×40；smoke125帧。

## Outputs
results/20261109_115203_p2_grid_study/：参数、源码快照、raw、CSV、冻结选择、JSON判据、图与报告。

## Acceptance
5%代理收益容差；平均通信需求须一并核对；20个信道不支持逐信道保证；区间未排除有意义收益不能判三档足够。不证明连续p最优、实际DC或等功率机制收益。

## Weekly Report
周报/阶段B/B4：full-chain策略验证.md，2026-11-09追加段。


## 2026-11-10 执行证据与结论边界

本轮数据与分析已交付：`results/20261109_115203_p2_grid_study/`。完整开发2500行、确认2500行；新增178525帧，复用21600帧。主结论为分需求成立/联合验收证据不足；不能据此认定三档全域充分、连续p最优或真实DC收益。最终证据见学习文档loop的`E2三档与五档独立验证结果-2026-11-10.md`和B4阶段文档末尾。旧初次入口保持原截止退出状态，后由明确授权的分段接续完成，勿直接重跑旧入口。
