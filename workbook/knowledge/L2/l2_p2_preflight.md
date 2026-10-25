

# L2 · run_p2_preflight

- **flow_id**: l2_p2_preflight
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_preflight.m
- **runtime**: minutes
- **needs_user_run**: false
- **validates**: l1_multicarrier_ofdm#H2, l1_probabilistic_shaping#H3

## Purpose

历史冻结S对照短诊断，显式保留旧controls；不代表当前均匀对照设计。 这是验证流程引用，不代表上述假设已被本轮支持。

## Pipeline

| step | l3_ref | 行为 |
|---|---|---|
| 配置与构造 | l3_p2_default_config, l3_p2_prepare_state | 复用200源码字seed9001模板，实际S/I/F |
| 输入与发送 | l3_p2_transmit_block, l3_p2_seed | 独立随机/供体S，配对消息和噪声 |
| 信道与接收 | l3_ofdm_channel_roundtrip, l3_p2_decode_block | 固定物理N0，缩放匹配当前LLR |
| 模型/门禁 | l3_p2_predict_ga, l3_p2_llr_reference, l3_p2_audit_acceptance | 区分目标、诊断模型及科研验收 |
| 统计与输出 | l3_analyze_p2_mechanism, l3_p2_paired_summary, l3_run_p2_preflight | 计数/哈希/检查点/图 |

## Inputs

cfg_local：N1024，16QAM，64子载波/CP16/16 taps，原五个全信息策略；random_s/donor_s/shaped/native。诊断不扩展多QAM或27组合。

## Outputs

时间戳results目录：参数/种子/实际集合与源模板、原始计数MAT与CSV、源码快照及哈希、日志、checkpoint、PNG/PDF/FIG和README。未测量通信为NaN。

## Acceptance

先smoke与瀑布区pilot再正式；确认码率上界K与CP/padding口径。功率含CP/padding，独立总/分组偏差≤1%，固定复噪声；随机S按均匀目标、shaped按整形目标TV单侧95%≤.05，供体模型另列。冻结模型后独立信道测试，BER约1e-4—1e-1且计数足够；零错误列上界。继承原P1三类基线边界，纯能量不加入本轮统一归因，不宣称策略最优。needs_user_run长跑必须先获得本轮具体预算确认；短模式不能冒充正式结果。RF均方非DC，BLER非CRC，Goodput非净吞吐。近似模型失败也如实收束，不推荐给P3。

## Weekly Report

周报/阶段B/B4：full-chain策略验证.md；学习文档/等功率机制对照与P2执行清单.md

Revision metadata: revision_id=p2_db82504e9e0f_20261024; current_status=current; supersedes=[].


# L2 · p2_preflight 当前真实调用流程

- **flow_id**: l2_p2_preflight
- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_preflight.m
- **runtime**: minutes
- **needs_user_run**: false
- **validates**: none（操作/历史诊断入口，本身不审定科研假设）

## Purpose

以源文件实际调用为准；验证流程存在不等于假设验收。原H3属于此前构造/有限长PMF证据，本轮新增辅助S问题用H4单独登记，避免借不相关引用提升coverage。

## Pipeline

| step | l3_ref | 行为 |
|---|---|---|
| 历史冻结集合探针 | l3_run_p2_preflight | 显式shaped/same_k_i/native，不当作均匀对照 |
| 短链路与冻结尺度 | l3_run_p2_mechanism, l3_p2_freeze_power | 两小校准seed和短pilot |
| 单载波与绘图 | l3_analyze_p2_mechanism | 仅smoke/计时，非正式统计 |

## Inputs

cfg_local、实际S/I/F、source_seed9001/200样本、策略与辅助位模式；长入口默认短模式，正式需当前预算批准及源码/产物哈希。

## Outputs

时间戳results目录；参数、原始计数、集合/源与源码哈希、CSV/MAT、日志/检查点、README与PNG/PDF/FIG。均匀证明脚本不输出通信性能。

## Acceptance

先smoke与BER约1e-4—1e-1瀑布区，再核对有效K码率上界及CP/padding口径。固定时域目标功率1与复N0，独立验证≤1%；shaped/random_s/native目标PMF门槛TV单侧95%≤.05，donor诊断模型单列。3×8不代替3×80正式门禁。原P1三类计划基线保留边界，不宣称最优；RF非DC、BLER非CRC、Goodput非净吞吐。近似模型须冻结后独立测试，精度或速度不足不进入P3。needs_user_run长跑等待本轮具体预算确认。

## Weekly Report

周报/阶段B/B4：full-chain策略验证.md；学习文档/等功率机制对照与P2执行清单.md。

Revision metadata: revision_id=p2_p2_preflight_actual_pipeline_20261025; current_status=current; supersedes=[p2_db82504e9e0f_20261024].


## 2026-10-25 学习文档归档路径补充

本段仅更新阅读位置，原研究结论和历史路径文字保留。当前文档位置：

- [等功率机制对照与P2执行清单.md](../../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制对照与P2执行清单.md)

Revision metadata: revision_id=learning_relocation_06e5f8f642_20261025; current_status=current; supersedes=[p2_p2_preflight_actual_pipeline_20261025].
