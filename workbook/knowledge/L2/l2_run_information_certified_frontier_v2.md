# L2 · run_information_certified_frontier_v2

- **flow_id**: l2_run_information_certified_frontier_v2
- **entry_script**: 16QAM_Polar/v2/diagnostics/run_information_certified_frontier_v2.m
- **runtime**: long
- **needs_user_run**: true
- **validates**: 本轮逐信道5%约束与成本收益问题；科研验收待完整结果，不宣称既有L1假设通过。

## Purpose
在未观察随机信道条件下比较简单指标引导、显式SC数值引导和直接SC，以逐帧全时证书发布与共同保底避免固定查看档位漏发布。原入口与原失败证据保持不变，本入口为独立新轮。

## Pipeline
|#|step|l3_ref|说明|
|---|---|---|---|
|1|冻结|内联prepare|沿用训练PMF/构造、未观察H2至H4；新seed域|
|2|共同能量catalog|l3_p2_transmit_block、l3_ofdm_oversampled_channel、l3_rf_envelope_moments|8编码帧×125候选；实际一次、各流程同成本计价|
|3|预测与有限敏感性|l3_information_score_quadrature、l3_p1_predict_minsum|包括原始预测成本；总预测/catalog耗时120秒前才可能细化|
|4|生产完整SC|l3_ofdm_common_noise_roundtrip、l3_p2_decode_block|先全p=.4候选94；各方法独立配对seed流|
|5|逐帧财富与发布|l3_goodput_betting_certificate|mu0_step内联增量；越界才完整反演；发布前保存已过预算快照|
|6|独立评价|l3_analyze_information_certified_frontier|本条件三路停止后100帧×125，不参与认证或重选|

## Inputs
- 新授权起点2026-11-18 14:22:58；新增通信停止19:22:58；最终截止21:22:58。7小时总墙钟，最后2小时分析交付。
- case帧上限300000，磁盘1GiB，独立无编码符号0；smoke和能量编码帧均计入。needs_user_run长期规则仍true，本批有用户特别授权，不继承为未来实验权限。
- 固定16QAM、公共幅度、原映射与I/S/F；I/S自由译码，F已知，只统计I。N1024，三组p各.1/.2/.3/.4/.5共125候选，不修改config.m。
- 原冻结随机H2/H3/H4各标签16/24共6未观察条件；已知深衰落H5标签20单列诊断。H1仅用于smoke，不列独立证据。
- frame_seed_base2911180000；model_seed2611181423。catalog、方法认证及evaluation不同seed域；候选与基线按整帧配对。
- 每流程预算60/180/600秒含catalog计价、预测、可能的细化、编码与认证；预测器并非免费。look5/20/80/320/1280仅调度，不延迟逐帧证书发布。

## Outputs
带时间戳results目录：frozen.mat、protocol.json、冻结源码、catalog、method、condition、ledger、partial_method及分析CSV/MAT/PNG/PDF。每32帧或越界/阶段末checkpoint；禁止隐式重新生成已观察帧。保留原入口与第一轮证据。

## Acceptance
- 每候选流令 $Z=G_c-0.95G_{0.5}$；固定四下注比例与每尾 $0.05/(124\times3\times2)$，真实iid整帧均值处由非负鞅和Ville联合界保护每固定H全候选全时。下界非负才发布可用；不确定或超时则使用已认证者，否则全p=.5。
- first94共同保底在三方法内分别采样，无独立第四流。直接法pilot所有124非基线，预测法10候选加固定锚点，差异属于整策略，不能全归因于是否显式运行SC。未采样不等于不合格。
- 120秒是总预测与catalog限额，若原始预测已超限，160阶敏感性可为空，不宣称已执行或已收敛。
- 每帧更新mu0财富；反演前后先截取已过预算快照，防止截止后证书回流。整体条件三方法完成后才生成独立evaluation。
- 95%仅本轮每H可行候选保护，非跨H联合、真实Pareto前沿或器件DC准确度。不合并旧轮认证挑优而继续声称同错误率。
- 核对设计K、Goodput资源分母15680、位/帧分母和零错误；独立100帧点损失越5%不直接判证书失效。跨H统计仅3随机H，诊断另列。
- 功能测试不等于科研验收；最终证据支持、反例或不足均如实交付，不因结果改seed/扩样。

## Weekly Report
周报/阶段B/B4：full-chain策略验证.md，由主任务集中追加。实验状态以loop主报告末尾为准。

## 2026-11-18 独立源码审查边界
本审查上下文发现并报告局部函数作用域阻塞；主任务已修正并报告selftest及3帧smoke通过。修复后对seed域、逐帧发布和预算快照逻辑的只读核查未发现新增阻塞。该结论是有限范围独立源码审查，不是整模型或完整统计流程独立验证。
## 实际执行补记
7/7条件完成，63预算快照和126选择记录均经核查。C5恢复时换通信种子，预算计数包含999保守预留。详见安全前沿独立验证v2报告。
