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
| KCS 知识完备度评分 | RKS 科研完备度评分（五维） | `.claude/skills/.../rks_evaluate.py` |

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
  python3 .claude/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
    --project-root . --system-id spolar16qam --append-ledger --write-report
  ```

## 维护原则
- 改了 .m / run_* / 研究方向 → 同步更新对应 L3 / L2 / L1（并按硬规则更新周报）。
- L1 护栏只引用 `workbook/mandatory-rules.md` 等既有规则，不另立规则。
- 知识库只读代码，不触发 MATLAB 长跑仿真。
