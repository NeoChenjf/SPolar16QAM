# L1 研究领域提取指南

## 来源
L1 是高维认知层，主要从**周报（`周报/`）+ 代码模块结构 + workbook 规则**归纳，不是逐行读代码。

## 扫描锚点

| 字段 | 来源 | 提取目标 |
|------|------|----------|
| domain_name / research_question | 周报阶段标题、模块职责 | 研究子领域 + 核心科学问题 |
| hypotheses | 周报里的"我们想验证…""预期…" | 可被 L2 验证的假设，标 `#Hn` |
| core_quantities | config.m 参数 + 代码核心物理量 | 符号/定义/单位/计算位置(指向 L3) |
| theoretical_boundaries | config.m 注释、周报理论推导 | 闭式公式、极限 |
| pitfalls | `workbook/mandatory-rules.md` / `CLAUDE.md` / `AGENTS.md` | ⚠️ 护栏，**必须回链规则文件** |
| collaborators | 模块间调用、数据流 | 与其它 L1 的耦合 + 传递量 |
| code_anchors | 该领域对应的 .m / L3 method_id | 锚点列表 |

## 本项目领域划分（参考）
1. `l1_probabilistic_shaping` — 概率成形（能量轴）
2. `l1_polar_coding` — 极化码（编码/译码/GA）
3. `l1_16qam_modulation_llr` — 调制与软解调 LLR
4. `l1_channel_snr` — 信道与 SNR 口径
5. `l1_metrics_tradeoff` — 指标与三维权衡（终端汇聚）
6. `l1_multicarrier_ofdm` — 多载波 OFDM（Stage B，部分占位）

## 护栏回链对照（必背）
- 码率上界优先 → `workbook/mandatory-rules.md` §7
- 瀑布区优先 / 高 SNR 全零非异常 / 同口径原则 → §8
- 长跑须用户运行 → §3
- Stage B 三基线对照 → `AGENTS.md` Non-Negotiables

## 约束
1. 每条 hypothesis 尽量关联一个 L2（否则 checker 标"无验证缺口"）。
2. pitfalls 不得凭空发明，必须能指到既有规则文件。
3. maturity 真实标注：在研 active / 已验证 explored / 计划 planned。
