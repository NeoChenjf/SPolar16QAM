# L2 实验流程层 Schema —— Experiment Flow

> L2 是「可执行实验流程」层。每个 L2 文件描述一条**端到端实验 pipeline**：从某个入口
> 脚本出发，经过编码→调制→信道→译码→指标的有序步骤，每一步引用一个 L3 方法契约。
> 对标 hic-spec 的「工作流编排」，但编排的是科研实验而非业务调用。
>
> 一句话类比：L2 就像一份「实验操作规程（SOP）」——按几步走、每步用哪个仪器（L3）、
> 跑完拿什么产物、怎么判定实验成功（验收标准）。

---

## 文件命名

`workbook/knowledge/L2/l2_{flow}.md`，例：`l2_run_single.md`（对应 `run_single.m`）

## 字段定义

| 字段 | 必填 | 说明 |
|------|------|------|
| `flow_id` | ✅ | `l2_*`，全局唯一 |
| `entry_script` | ✅ | 入口脚本相对路径，如 `16QAM_Polar/v2/run_single.m` |
| `runtime` | ✅ | `minutes`（冒烟级）/ `long`（长跑，须用户本地运行） |
| `needs_user_run` | ✅ | 布尔。`true` = 长跑/高算力，AI 不得擅自执行（遵守项目硬规则） |
| `purpose` | ✅ | 实验目的 + 回答哪个 L1 的哪条假设（`validates: l1_xxx#H1`） |
| `pipeline` | ✅ | 有序步骤，每步含 `step` + `l3_ref`（引用的方法契约）+ 说明 |
| `inputs` | ✅ | 关键参数，引用 `config.m` 字段（N、p_fixed、SNR_dB、num_frames、seed、decoder…） |
| `outputs` | ✅ | 产物：results/ 目录结构、图、表、MAT |
| `acceptance` | ✅ | 验收标准（可量化）；**应吸收对应 L1 的 pitfalls** |
| `weekly_report_link` | ⬜ | 关联的 `周报/*.md` 或 Stage 文档 |

## Markdown 骨架

```markdown
# L2 · {flow 名称}

- **flow_id**: l2_{flow}
- **entry_script**: 16QAM_Polar/v2/run_single.m
- **runtime**: minutes | long
- **needs_user_run**: true | false
- **validates**: l1_metrics_tradeoff#H1, l1_polar_coding#H2

## Purpose
（实验目的：回答什么、验证哪条假设）

## Pipeline
| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | 生成信息位 + 极化编码 | l3_polar_encoder | 4 路独立 |
| 2 | 串并转换 → Gray 16QAM 调制 | l3_parallel_to_serial_bits | qammod |
| 3 | AWGN 信道 | （内联，cfg.snr_mode） | fixed_esn0/fixed_n0 |
| 4 | 软解调 → LLR | l3_llr_16qam_gray_LSE | qamdemod OutputType=llr |
| 5 | SC/SCL 译码 | l3_SC_decoder / l3_SCL_decoder_prior | 按 cfg.decoder |
| 6 | 指标统计 BER/BLER/MI | l3_sim_shaped_polar_16qam | 加权 |

## Inputs（config.m）
- N=1024, M=16, p_fixed=[0.5,NaN,0.5,NaN]
- SNR_dB=-5:1:25, num_frames=1000, seed=42, decoder='SC'

## Outputs
- results/YYYYMMDD_HHMMSS_run_single/ : params、MAT、figures、README

## Acceptance
- 先定位 BER ∈ [1e-4, 1e-1] 的瀑布区，再判定结果（见 l1_metrics_tradeoff pitfalls）
- 判定吞吐前核对设计码率上界 R = ΣK/(4N)

## Weekly Report
- 周报/阶段X/xxx.md
```

## 提取约束

1. **pipeline 每步尽量挂 `l3_ref`**：纯内联的步骤（如 AWGN 加噪）可注明「内联」，
   但凡是调用了 `.m` 函数的步骤都必须引用对应 L3，否则 checker 报「断链」。
2. **needs_user_run 守规则**：`run_sweep` 这类长跑必须 `needs_user_run: true`，
   提醒 AI 不要擅自跑（对应 `AGENTS.md` Non-Negotiables）。
3. **acceptance 吸收护栏**：把对应 L1 的 pitfalls 落成本流程可检查的验收项。
