# SPolar16QAM

研究生课题：**自适应无线信息-能量协同传输编码**。当前在研实现是一个 MATLAB 仿真系统，
研究 **16QAM 概率成形 + 极化码（Polar）** 在 BER / Goodput / 收获能量三维权衡下，
面向无电池 6G IoT 场景的最优工作点。

活跃代码在 `16QAM_Polar/v2/`。

## 文档与规则入口

| 入口 | 作用 |
|------|------|
| `CLAUDE.md` / `AGENTS.md` | AI agent 工作入口与项目地图 |
| `workbook/` | 操作规则手册（`mandatory-rules.md` 为硬规则） |
| `周报/` | 阶段文档与周报（研究范围/验收/结果解释的真相源） |
| `next_plan.md` / `项目整体计划书.md` | 计划与总体规划 |

## 科研 Spec-Harness（L1 / L2 / L3 知识库）

本项目接入了一套对标 **hic-spec** 的科研知识治理体系，把课题结构化为三层、可被 AI
理解并量化完备度（RKS 评分）：

- **L1 研究领域** — 研究问题 / 假设 / 物理量 / 理论边界 / 护栏（`workbook/knowledge/L1/`）
- **L2 实验流程** — 每个 `run_*` 入口的端到端 pipeline / 参数 / 产物 / 验收（`workbook/knowledge/L2/`）
- **L3 方法契约** — 每个 `.m` 函数的签名 / 公式 / 数值坑 / 依赖 / 健康度（`workbook/knowledge/L3/`）

详见 `workbook/knowledge/README.md`。维护它的 skill 在 `.claude/skills/`：
`research-meta-extractor`（提取）、`research-spec-checker`（校验）、
`research-scan-orchestrator`（编排 + RKS 评分）。

```bash
# 快速看知识完备度评分（纯 Python 标准库，本地可跑）
python3 .claude/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
  --project-root . --system-id spolar16qam --append-ledger --write-report
```

## 常用 MATLAB 命令（在 `16QAM_Polar/v2/`）

```matlab
setup_paths; run_single;            % 快速冒烟测试（分钟级）
setup_paths; run_sweep;             % 全 p×SNR 扫参（长跑，先确认）
setup_paths; run_sc_theory_vs_sim;  % SC 理论 vs 仿真对照
```

> 长跑 / 高算力仿真须由用户本地运行（`workbook/mandatory-rules.md` §3）。
