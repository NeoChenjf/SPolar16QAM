# Knowledge Base — 科研三层知识库（L1 / L2 / L3）

> 本目录是 SPolar16QAM 的「科研 spec-harness 知识层」，对标 hic-spec 的 L1/L2/L3 元数据体系，
> 但把每一层的语义从「业务代码」换成「科研项目」。它让 AI 能像领域专家一样理解本课题，
> 并能用 RKS 评分量化知识完备度。

## 一句话类比
- **L3 方法契约** = 实验室每台仪器的「铭牌 + 说明书」（输入输出、原理公式、使用注意）。
- **L2 实验流程** = 一份「实验操作规程 SOP」（按几步走、每步用哪台仪器、怎么判定成功）。
- **L1 研究领域** = 一位「资深审稿人」用一页纸讲清这个子领域在研究什么、有哪些坑。

## hic-spec → 科研映射

| hic-spec（业务代码） | 本项目（科研仿真） | 目录 |
|---|---|---|
| L1 领域专家认知（边界/状态机/护栏） | L1 研究领域（问题/假设/物理量/理论边界/护栏） | `L1/` |
| L2 工作流编排 | L2 实验流程（pipeline/参数/产物/验收） | `L2/` |
| L3 原子工具契约 | L3 方法契约（.m 函数签名/公式/数值坑/依赖） | `L3/` |
| KCS 知识完备度评分 | RKS 科研完备度评分（五维） | `.agents/skills/.../rks_evaluate.py` |

## 目录结构
```
workbook/knowledge/
├── README.md            ← 本文件
├── schema/              ← 三层提取规范（字段定义 + 骨架 + 约束）
│   ├── L1-research-domain.md
│   ├── L2-experiment-flow.md
│   └── L3-method-contract.md
├── L1/                  ← 研究领域层（6）
├── L2/                  ← 实验流程层（6）
├── L3/{core,polar,modulation,analysis}/  ← 方法契约层（26）
├── reports/             ← 扫描 / RKS 报告输出
└── meta/
    ├── system-registry.yaml   ← 系统登记
    └── scan-ledger.tsv        ← RKS 评分账本
```

## L1 索引（研究领域）
| domain_id | 领域 | maturity |
|-----------|------|----------|
| l1_probabilistic_shaping | 概率成形（能量轴） | active |
| l1_polar_coding | 极化码（编码/译码/GA） | active |
| l1_16qam_modulation_llr | 16QAM 调制与软解调 | active |
| l1_channel_snr | 信道与 SNR 口径 | active |
| l1_metrics_tradeoff | 指标与三维权衡（终端） | active |
| l1_multicarrier_ofdm | 多载波 OFDM（Stage B） | active（部分占位） |

## L2 索引（实验流程）
| flow_id | 入口 | 长跑 |
|---------|------|------|
| l2_run_single | run_single.m | 否 |
| l2_run_sweep | run_sweep.m | 是（须用户跑） |
| l2_sc_theory_vs_sim | run_sc_theory_vs_sim.m | 视范围 |
| l2_sc_ga_only_curve | run_sc_ga_only_curve.m | 否 |
| l2_find_waterfall_and_refine | experiments/sc_checks/run_find_waterfall_and_refine.m | 视范围 |
| l2_ofdm_baseline | experiments/multicarrier/run_ofdm_baseline.m | 否（基线） |

## L3 索引（方法契约，26）
- core(5)：sim_shaped_polar_16qam / compute_energy / compute_goodput / compute_cost / estimate_ber_hat_sc_dual
- polar(12)：GA / phi / phi_inverse / derivative_phi / get_GN / polar_encoder / get_llr_layer / get_bit_layer / SC_decoder / SC_decoder_prior / SCL_decoder / SCL_decoder_prior
- modulation(3)：llr_16qam_gray_LSE / llr_16qam_gray_LSE_prior / parallel_to_serial_bits
- analysis(6)：plot_ber_vs_snr / plot_goodput_vs_snr / plot_mi_vs_snr / plot_pareto / plot_cost_curves / extract_weekly_report_from_sweep

## 怎么用
- 提取/补全 → skill `research-meta-extractor`
- 校验一致性 → skill `research-spec-checker`
- 全流程 + 评分 → skill `research-scan-orchestrator`
- 快速打分：
  ```bash
  python .agents/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
    --project-root . --system-id spolar16qam --append-ledger --write-report
  ```

## 维护原则
- 改了 .m / run_* / 研究方向 → 同步更新对应 L3 / L2 / L1（并按硬规则更新周报）。
- L1 护栏只引用 `workbook/mandatory-rules.md` 等既有规则，不另立规则。
- 知识库只读代码，不触发 MATLAB 长跑仿真。


## 2026-10-10 当前研究范围与机器索引

主线/支撑边界见`meta/research-scope.json`；修订解析入口为`meta/current-revisions.json`；假设与证据状态登记见`meta/research-claims.json`。当前RKS扫描仅度量结构覆盖和引用完整性，报告须列实际纳入范围，不能把100%解释为科学验证。B4等功率P1流程见`L2/l2_b4_equal_power_p1.md`。

Revision metadata: revision_id=knowledge_scope_index_20261010; current_status=current; supersedes=[baseline].


## 2026-10-11 当前证据入口与扫描结果

当前多载波结论以`workbook/knowledge/L1/l1_multicarrier_ofdm.md`最后追加的P1说明为准；运行契约、实际参数和验收记录见`workbook/knowledge/L2/l2_b4_equal_power_p1.md`；runner和分析器契约见对应L3末尾。机器索引为`meta/current-revisions.json`，假设证据状态为`meta/research-claims.json`。读取器只将索引中唯一`current`修订视为有效，历史段落留作追溯。

RKS报告`reports/rks-20261011_000500.md`得分70.5/100，明确仅为结构完整度，不是研究通过率：当前范围35/35方法契约、6/31入口流程、12/18假设引用、88/88引用完整性、10/18逐假设护栏；18项主张中1项有本轮P1证据但整体仍为inconclusive，其他17项not_assessed。仍有入口契约和假设/护栏关联缺口，需在后续治理中分批补齐。

Revision metadata: revision_id=knowledge_reading_entry_p1_20261011; current_status=current; supersedes=[prior_reading_entry].

## 2026-10-11 最终当前阅读快照

本轮最终扫描报告为`workbook/knowledge/reports/rks-20261011_002100.md`：35/35方法契约、6/31当前入口流程、12/18有效假设引用、88/88跨层完整性、9/17适用护栏，结构分70.1/100。当前L1/L2/L3文件均登记在`meta/current-revisions.json`；对带修订链的L2/L3，扫描器按索引ID只读取最新有效追加段，初始未修订文档以baseline current登记。1条P1假设证据为inconclusive，17条仍not_assessed。流程与假设关联覆盖不完整是后续治理任务；结构分不代表理论或实验结论通过。

Revision metadata: revision_id=knowledge_reading_entry_p1_final_20261011; current_status=current; supersedes=[knowledge_scope_index_20261010].

## 2026-10-11 最终报告编号校正

最终可复现扫描报告为`workbook/knowledge/reports/rks-20261011_002500.md`，结果70.1/100；它按current revision slices重新计算了coverage，替代本文件前一段引用的较早报告。报告范围和结构分项为方法35/35、流程6/31、假设引用12/18、完整性88/88、适用护栏9/17。科研证据状态仍为1条inconclusive、17条not_assessed。

Revision metadata: revision_id=knowledge_reading_entry_p1_report_final_20261011; current_status=current; supersedes=[knowledge_reading_entry_p1_final_20261011].

## 2026-10-11 最终报告动态入口

最终扫描报告路径由`workbook/knowledge/reports/LATEST_RKS_REPORT.txt`指向。当前范围、当前修订切片和分项结果以该指针所指报告为准；历史RKS报告保留用于审计，不覆盖。

Revision metadata: revision_id=knowledge_rks_dynamic_pointer_20261011; current_status=current; supersedes=[knowledge_reading_entry_p1_report_final_20261011].
