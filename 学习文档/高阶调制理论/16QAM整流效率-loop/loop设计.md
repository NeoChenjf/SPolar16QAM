# Loop设计：16QAM联合能量强度实验与中期回填

> 状态：用户已审核确认；实现、smoke、正式运行及Unit 5审计已完成，待中期DOCX/PPT回填。接手先读[README](README.md)，再读本设计、[协调协议](协调协议.md)、[进度表](进度表.md)、[问题记录](问题记录.md)、[next_plan](next_plan.md)。

## 项目映射与核心思路

本仓库用CLAUDE.md与workbook作为项目真相源。loop-designer模板中的clarification映射到本目录需求澄清，project.toml/gates映射到现有配置、CLI包装和实验门禁，harness规则映射到workbook。stage.done留痕映射到高阶调制周报，不新建重复规则文件。用户禁止子agent，独立review步骤采用本上下文只读自审；此阶段不执行代码实现。

工作按统一实验点契约逐单元迭代：准备协议与统计模块，接入真实链路，smoke，正式扫参，图数审计，材料回填。每个单元完成后检查输入/输出/错误/边界，并同步协议、进度表、问题记录与周报。未完成单元可直接交接。

## 单元与目标文件

以下代码路径均已实现并验证。目录保留最初指定位置，英文文件名使用energy避免暗示整流计算。

| 单元 | 责任和目标 | 通过条件 |
| --- | --- | --- |
| Unit 0 | 术语、单位、功率、公平性和统计协议 | 用户审核整体设计，实施计划核验SNR/字段/旧基线 |
| Unit 1 | core下`compute_energy_tradeoff_stats.m`等纯统计函数；diagnostics/rectifier下断言测试 | 实际符号均方、配对归一化、CI、Pareto、并列/零跨度、非法输入均可验证 |
| Unit 2 | 为`core/sim_shaped_polar_16qam.m`增加可选逐帧统计和进度采集 | 同引擎同seed新旧BER/Goodput一致、RNG状态一致；保存计数可重建指标 |
| Unit 3 | `experiments/rectifier/run_16qam_energy_tradeoff.m`默认smoke；结果写出与断点检查 | 五p、SNR=[8,14,20]、seed=[42,43,44]、N=1024、每点2帧；完整文件/图/审计通过 |
| Unit 4 | 同入口显式formal模式；单独获运行授权 | 五p×13SNR×3seed×300帧完整联合数据；日志/checkpoint可追溯 |
| Unit 5 | `analysis/rebuild_16qam_energy_tradeoff_figures.m`及diagnostics/rectifier审计 | 四张图、全部工作点、CSV/MAT/图中数字一致，结论不过度 |
| Unit 6 | 本loop、中期进度表、阶段A、高阶调制周报、DOCX/PPTX | 新口径和正式证据回填、Word/PPT渲染QA、历史生成物按批准范围清理 |

smoke共90帧，仅验证工程链路。测试和计时可能增加少量诊断运行，任何预计长耗时执行仍先按项目规则取得授权。195个formal重复点共58,500帧；在smoke后分别估计构造、逐帧、存图时间，报告总时间范围和checkpoint方式。

## 实施约束

复用现有函数，config仅用cfg_local覆盖。采集开关默认关闭以保持旧调用行为；core保持平铺，diagnostics/experiments已由setup_paths递归加载。新脚本由自身mfilename定位v2根。

输出只写`v2/results/YYYYMMDD_HHMMSS_16qam_energy_tradeoff_smoke/`或`..._formal/`，目录已存在时拒绝覆写。正式批准前不运行formal。现有脏工作区修改属于用户，避免改动阶段B、根next_plan和其他无关文件。

Unit 2新增统计时同步对应L3，Unit 3新增入口同步L2，研究指标范围同步适用L1。不以v3替代v2整形链路，也不静默引入先验解调、消息条件化整形等行为变化。

## 验证及审查顺序

1. 方案审核后使用codex-plan-review，基于真实调用点审查统计接口、随机流、CI、SNR标签、恢复和Octave适配。
2. 实现Unit 1/2，使用test-quality-review和test-gap-to-test-plan：有效断言、负路径、极端数值、非支配点已知样例、零跨度和缺基线。以真实full-chain符号统计验证集成；人工数值样例仅用于纯算法单元测试。
3. 环境先执行现有`scripts/run_matlab.sh check_env`。环境文档记录的是旧Mac，当前Windows的bash/Octave可用性必须实查。本文未执行该命令，不保证环境已就绪。
4. 同引擎改前/改后同seed小样本回归；smoke复现、不同seed随机样本差异、写出失败、重复键和checkpoint恢复。不同seed的汇总值不必必然不同。
5. 全变更缺陷优先自审，修复后重验；simplify仅做保持行为改进。用户未授权子agent，不调用review编排器强行委派。
6. 单独授权formal后执行；完成数值审计与结果重绘。无收益和异常点如实记录；需要扩大网格/样本时另列建议，不自动改变冻结实验。

## 中期回填及结束

任务二按新代理口径重映射完成项：协议、实际符号统计、正式联合数据、四图/工作点、图数审计、材料QA。原T2模型项标为“口径调整后移出本阶段”，保留变化说明；不勾为“整流模型已完成”。任务三状态不因本任务改变。

Word使用docx及渲染流程检查表格边界；PPT使用pptx，至少完成生成→渲染→发现问题→修正（若需）→再渲染。替换前保留可恢复版本，验证后仅清理中期相关中确定被替代的生成物，先列绝对路径、mtime、内容比较和新版本QA证据；保留学校模板、附件原件、填写稿、操作说明、最新PPT和进度表。历史实验目录全部保留。

结束条件是六类新验收项都有可点击证据，文件可重建、材料已渲染复核、边界写入README/周报、rule reflection完成。当前只提交设计；用户确认后才能开始实现，这是最初任务和loop-designer明确要求的审核门禁。


## 2026-10-09 追加：整形构造对能量分析的影响范围

本轮修订改变的是 16QAM 极化源位的集合分工及消息条件化输出；它可能改变实际码字符号 PMF、接收 RF 均方、BER 和 Goodput，因此旧 v2 full-chain 能量/通信联合图只作为旧构造结果保留。解析星座几何和给定符号 PMF 下的能量关系不因集合构造变化而改变；真实整流器直流输出也仍未由 RF 代理量证明。新结果沿用原功率、噪声和资源口径以隔离构造变化，不能据此替代后续等功率比较。新图应在正式运行和审计完成后从新结果目录追加引用。当前状态见[重建清单](../../shaped_polar验证loop/理论更新与图重建/整形理论更新与仿真图重建清单.md)。


## 2026-10-24 等功率机制与P2状态追加

本文件旧能量图和工作点沿用原固定幅度/噪声协议；p变化同时改变发送功率，不能归为等功率增益。新构造单载波数据保留，当前多载波等功率主证据已由P1完成；本轮补随机辅助S/供体S机制对照及P2预测诊断，正式性能验收待预算确认。

本材料的职责是原实验协议与证据边界维护；本轮未新增整流器模型。若引用14 dB旧数值，BER .381→.315是下降，不是“升至”。该点不代表所有SNR的排序，也不代表等功率或DC收益。图片和后续替换范围见[当前结论](../../多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制与P2当前结论.md)。

Revision metadata: revision_id=p2_9ebc23c3eb2b_20261024; current_status=current; supersedes=[baseline_p2_9ebc23c3eb2b].


## 2026-10-25 学习文档归档路径补充

本段仅更新阅读位置，原研究结论和历史路径文字保留。当前文档位置：

- [等功率机制与P2当前结论.md](../../多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制与P2当前结论.md)
- [整形理论更新与仿真图重建清单.md](../../shaped_polar验证loop/理论更新与图重建/整形理论更新与仿真图重建清单.md)

Revision metadata: revision_id=learning_relocation_52bddf505c_20261025; current_status=current; supersedes=[p2_9ebc23c3eb2b_20261024].
