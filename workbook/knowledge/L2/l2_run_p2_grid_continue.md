# L2 · run_p2_grid_continue

- **flow_id**: l2_run_p2_grid_continue
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_grid_continue.m
- **runtime**: long
- **needs_user_run**: true（2026-11-09用户已明确批准新增6小时）
- **validates**: E2三档相对五档的有限网格充分性

## Purpose
复用953个已提交训练单元，仅补第10信道剩27组合与信道11—20各98组合，然后冻结完整20训练信道的19组需求选择，在新20信道确认。

## Pipeline
| step | l3_ref | 说明 |
|---|---|---|
| 接续与拼接 | 内联；复用l2_run_p2_grid_batch | 保存原批，offset9/10映射物理信道10/11—20，汇总时恢复全局channel编号 |
| 选择冻结 | l3_p2_select_training_tradeoff | 完整20信道；平均Goodput要求0.26:0.005:0.35，示例BER≤0.2 |
| 独立测试 | l2_run_p2_grid_batch | 原先登记但尚未执行的新测试域，不用开发数据调测试 |
| 统计与图 | scripts/analyze_p2_grid_study.py | 冻结5%代理容差、配对整信道同时区间；通信可行性另核对 |

## Inputs
固定16QAM幅度、原五档模板、原protocol.mat、953行旧训练；新增40280训练帧和100000测试帧。新墙钟6小时，最后至少1小时分析；原总10GiB/178800帧上限不变。

## Outputs
原study目录下新分段raw/CSV/source_snapshot、training_segments.mat、完整development_candidates.csv、frozen_choices.csv与frozen_policy.mat、data_complete.mat及分析图表。旧raw/checkpoint/params不覆盖。

## Acceptance
训练汇总2500唯一channel-case行、每信道125组合；选择在测试前冻结。原实际I/S/F/K、共同h/n和指标分母不变。不得将训练内增益判为确认收益；不能宣称连续p最优、等功率额外收益、真实DC或逐信道保障。证据不足允许交付，但不偷换成三档足够。

## Weekly Report
周报/阶段B/B4：full-chain策略验证.md的2026-11-09接续段。


## 2026-11-10 执行证据与结论边界

本轮数据与分析已交付：`results/20261109_115203_p2_grid_study/`。完整开发2500行、确认2500行；新增178525帧，复用21600帧。主结论为分需求成立/联合验收证据不足；不能据此认定三档全域充分、连续p最优或真实DC收益。最终证据见学习文档loop的`E2三档与五档独立验证结果-2026-11-10.md`和B4阶段文档末尾。旧初次入口保持原截止退出状态，后由明确授权的分段接续完成，勿直接重跑旧入口。
