

# L2 · 已批准P2顺序批次

- **flow_id**: l2_p2_approved_batch
- **entry_script**: scripts/run_p2_approved_batch.py
- **runtime**: long
- **needs_user_run**: true（本轮已取得明确批准）
- **validates**: l1_multicarrier_ofdm#H2, l1_probabilistic_shaping#H4（仅编排对应流程，不代表假设通过）

## Pipeline

| step | l3_ref | 行为 |
|---|---|---|
| 注册job与恢复 | l3_p2_execute_batch_job, l3_run_p2_registered_job | 协议/批准/源码绑定；唯一恢复目标 |
| 功率阶段 | l3_p2_freeze_power, l3_p2_batch_power_check | 冻结系数并提前阻断失败门禁 |
| PMF/合同验收 | l3_p2_audit_acceptance | 真实数据、目标/诊断模型分开 |
| 冻结模型 | l3_p2_freeze_model | 仅校准集、记录训练功率哈希 |
| 独立验证/分析 | l3_run_p2_mechanism, l3_analyze_p2_mechanism | 不使用测试调参，配对信道簇区间 |

## Inputs / Outputs

冻结协议与真实批准记录；23job及414366帧。输出16QAM_Polar/v2/results/20261025_011808_p2_approved_batch中的status.json、events.log、源码快照/哈希、各job日志与目录标记。每个job自身保留原始计数、MAT/CSV、checkpoint、参数、图与README。调度器使用操作系统锁和原子状态写入。

## Acceptance

先已批准功率/PMF基础门禁，失败停止依赖任务而不增加预算。BER瀑布区与实际码率上界、CP/padding及固定复噪声口径继承原流程；辅助位不计K，RF非DC、BLER非CRC。只有具体数据验收后更新科研完成项。needs_user_run授权来自用户当前指令，不能外推至新协议或新增预算。

## Weekly Report

周报/阶段B/B4：full-chain策略验证.md；学习文档/等功率机制对照与P2执行清单.md。

Revision metadata: revision_id=l2_p2_approved_batch_v1_20261025; current_status=current; supersedes=[].


## 2026-10-25 当前状态更正：功率门禁失败，正式批次已停止

本段取代此前“正式运行中”的即时状态。注册批次01:18:21启动、03:39:41停止（Asia/Shanghai）；23job完成6个，83,520帧。三组校准和三组独立功率验证完成，但522个验证单元有206个至少一组功率偏差超过1%；总功率3单元超限，最大总偏差1.12635%、最大组偏差1.80612%。因此F02未通过，正式PMF/通信/模型测试未启动，不得把NaN通信指标当零错误。现有P1结果不因本次控制匹配失败而自动失效。

证据：`16QAM_Polar/v2/results/20261025_011808_p2_approved_batch/status.json`、`events.log`、`ofdm_power_check/power_gate.csv`。完整解释、图与产物目录见[阶段汇报](../../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2阶段进度与写作交接-2026-10-25.md)。仅整理和追加文档，不修改实验源码、不启动补跑。先以已有raw数据诊断有限样本、SNR集合变化和功率口径，再提交具体追加预算；原授权不覆盖自动扩大预算。不放宽1%或改聚合方式追认通过。

Rule reflection: no new durable rule。沿用预登记门禁、原始证据及追加修订规则；本轮只读核查与文档交接，不把推测记为已确认缺陷。

Revision metadata: revision_id=p2_batch_gate_failed_20261025; current_status=current; supersedes=[l2_p2_approved_batch_v1_20261025].


## 2026-10-25 学习文档归档路径补充

本段仅更新阅读位置，原研究结论和历史路径文字保留。当前文档位置：

- [等功率机制对照与P2执行清单.md](../../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制对照与P2执行清单.md)
- [P2阶段进度与写作交接-2026-10-25.md](../../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2阶段进度与写作交接-2026-10-25.md)

Revision metadata: revision_id=learning_relocation_e29b66eb63_20261025; current_status=current; supersedes=[p2_batch_gate_failed_20261025].
