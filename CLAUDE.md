# CLAUDE.md

本文件为在本仓库工作的 AI agent（Claude Code、Codex 等）提供统一指引，是本项目
agent 指引的**唯一真相源**。`AGENTS.md` 只引用本文件，不重复内容。

## 项目背景

这是一个研究生学位课题：**自适应无线信息-能量协同传输编码**。当前在研实现是一个 MATLAB
仿真系统，研究 **16QAM 概率成形 + 极化码（Polar）** 在 BER / Goodput / 收获能量三维权衡下，
面向无电池 6G IoT 场景的最优工作点。

活跃代码在 `16QAM_Polar/v2/`。`16QAM_Polar/` 下的旧脚本视为历史参考，除非用户明确要求修改，
否则不要改动。

## 当前阶段入口

- 当前阶段：**阶段 B，多载波 OFDM 系统构建**。
- 阶段 B 总纲：`周报/阶段B/阶段B：多载波系统构建.md`
- 当前任务文档：`周报/阶段B/B1：OFDM baseline阶段文档.md`
- 下一代码目标：`16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m`

阶段文档是研究范围、验收标准、结果解释的工作真相源。保持简洁，并在关闭任务前更新相关阶段文档。

## 启动规则

做非平凡工作前，先读：

1. `workbook/README.md`
2. `workbook/mandatory-rules.md`
3. `workbook/README.md` 中列出的任务相关 workbook 文件
4. `next_plan.md`
5. `周报/` 下相关的阶段文档

规则冲突时，以 `workbook/mandatory-rules.md` 为准。

## 不可妥协规则（Non-Negotiables）

- 任何代码、脚本、文档改动，关闭前必须更新相关 `周报/*.md` 或 `周报/阶段B/` 下的阶段文档。
- 任何 bug 修复还必须更新 `workbook/troubleshooting-history.md`。
- 长时间 / 高算力 MATLAB 仿真必须由用户本地运行，除非明确授权。
- 产出结果的脚本必须把 参数/数据/图/README 存到带时间戳的 `results/` 目录下。
- 不要为单次实验覆盖去改 `config.m`；用 `cfg_local`。
- 做 BER 理论 vs 仿真分析时，先定位 BER 约为 `1e-4 ~ 1e-1` 的信息瀑布区；高 SNR 全零错误不是 BER 异常的证据。
- 判定极化码吞吐 / Goodput 优劣前，先核对由 `N`、`K`、成形位、冻结位确定的设计码率上界，不要把设计码率限制当成算法失败。
- 阶段 B 中，在与三个计划基线对照之前，不得宣称某多载波策略"最优"：好信道偏信息、好信道偏能量成形、坏信道纯能量传输。
- 关闭任何非平凡任务前，运行 `workbook/rule-reflection-hook.md` 的规则反思检查，并把结果记入周报。
- 解释理论、代码、公式或结果时，先用通俗直觉（必要时配生活比喻）建立理解，再给技术细节。

## 常用 MATLAB 命令

> **本机无 MATLAB License，用 GNU Octave 运行。** agent 一律通过 CLI 包装调用，
> 它自动 `cd v2` + `pkg load` + `setup_paths`：
>
> ```bash
> scripts/run_matlab.sh check_env     # 环境自检（跑仿真前先跑这个）
> scripts/run_matlab.sh run_single    # 端到端冒烟
> scripts/run_matlab.sh run_sweep     # 长跑，须用户授权
> ```
>
> 安装、CLI 用法、以及 Octave↔MATLAB 已知差异（qammod/qamdemod 口径、随机数发生器）
> 见 `workbook/environment-setup.md`。口径以 `check_env` 实测为准。

下列命令在 MATLAB 中从 `16QAM_Polar/v2/` 运行；在本机改用上面的 `scripts/run_matlab.sh <脚本名>`。

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run_single;                       % 快速冒烟测试，分钟级
```

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run_sweep;                        % 完整 p × SNR 扫参，长跑；先确认
```

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run_sc_theory_vs_sim;             % SC 理论 vs 仿真对照
run_sc_ga_only_curve;             % 仅 GA 理论曲线
run_find_waterfall_and_refine;    % 粗扫 BER 瀑布区，再可选局部加密
run('experiments/multicarrier/run_ofdm_baseline.m'); % 阶段 B/B1 计划入口
```

`setup_paths` 后，diagnostics 与 experiments 都已在 MATLAB 路径上，可从 `v2` 根直接调用：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
diagnose_mc_simulation;
run_local_12db_check;
run_single_scl;
run_sweep_scl;
```

本仓库没有单独的构建系统或 lint 命令；验证靠 MATLAB 冒烟测试、诊断脚本和实验产物。

## 架构概览

`16QAM_Polar/v2/` 围绕少量顶层入口脚本 + 模块化仿真组件组织：

- `config.m` 是主流程的共享参数入口（`N`、成形概率、SNR 网格、帧数、随机种子、输出路径）。
- `setup_paths.m` 初始化 `core/`、`polar/`、`modulation/`、`analysis/`、`diagnostics/`、`experiments/` 的路径。
- `run_single.m` 是快速验证路径。
- `run_sweep.m` 是完整 BER / Goodput / 能量扫参。
- `run_sc_theory_vs_sim.m`、`run_sc_ga_only_curve.m`、`run_find_waterfall_and_refine.m` 支持 SC 理论检查与瀑布区窗口选择。

核心数据流：

1. 四路并行极化码比特流编码。
2. 比特串行化为 Gray 映射的 16QAM 符号。
3. 在成形参数 `p` 下仿真 AWGN 信道。
4. 用均匀或非均匀先验计算 LLR。
5. SC/SCL 译码器恢复每路比特流。
6. 分析函数计算 BER、Goodput、能量、互信息、代价和 Pareto 曲线。

主要模块：

- `core/sim_shaped_polar_16qam.m`：端到端成形极化码 16QAM 仿真。
- `core/compute_energy.m`、`compute_goodput.m`、`compute_cost.m`：派生指标定义。
- `polar/`：GA 可靠性估计 + 极化编码器 + SC/SCL 译码器（含先验感知变体）。
- `modulation/`：比特串行化 + 均匀/成形先验下的 16QAM LLR 函数。
- `analysis/`：绘图与扫参报告提取工具。
- `diagnostics/`：快速基线、环回、LLR、蒙特卡洛调试脚本。
- `experiments/`：分阶段脚本，含 layer1/layer2 对齐、SC/SCL 检查、单载波收束实验、`multicarrier/`（阶段 B）。

## 实验与产物约定

- 优先在 `16QAM_Polar/v2/config.m` 改共享实验参数；单次实验覆盖可留在对应实验脚本，但必须记入结果 README 与周报（即用 `cfg_local`，不改 `config.m`）。
- 产出结果的脚本应写到 `16QAM_Polar/v2/results/YYYYMMDD_HHMMSS_实验名/`。
- 结果目录应含参数/种子、数据表或 MAT 文件、（如有）图、以及 README 或元数据文件。
- 长时间或易崩的实验应写日志、进度标记和部分检查点。
- BER 理论 vs 仿真分析：先定位 BER 约 `1e-4 ~ 1e-1` 的信息瀑布区；高 SNR 全零错误不是异常证据。
- 判定极化码吞吐或 Goodput 时，先核对由 `N`、`K`、成形位、冻结位确定的设计码率上界，再下"差"的结论。

## MATLAB 约定

- MATLAB 文件名须匹配 `[A-Za-z][A-Za-z0-9_]*.m`。
- 需要项目函数的活跃脚本应调用 `setup_paths`。
- `diagnostics/` 或 `experiments/` 下的可运行脚本，应先从 `mfilename('fullpath')` 自举出项目根再调 `setup_paths`，确保 MATLAB 当前目录在别处时也能跑。
- 使用相对路径和 `fullfile()`；不要在可复用脚本里硬编码绝对用户路径。
- 论文用图存 PDF，复核用图存 PNG；需要复用 MATLAB 图窗时存 `.fig`。

## 知识库（L1 / L2 / L3）

`workbook/knowledge/` 是一套三层科研 spec-harness（对标 hic-spec），把本项目结构化以便 AI 推理：

- **L1 研究领域** —— 研究问题、假设、核心物理量、理论边界、护栏（`workbook/knowledge/L1/`）。
- **L2 实验流程** —— 每个 `run_*` 入口的端到端 pipeline，含输入、产物、验收标准（`workbook/knowledge/L2/`）。
- **L3 方法契约** —— 每个 `.m` 函数一份契约：签名、数学定义、数值注意点、依赖、健康度（`workbook/knowledge/L3/`）。

当你改动一个 `.m` 函数、一个 `run_*` 入口或研究方向时，更新对应的 L3 / L2 / L1 文件（并更新周报）。
L1 护栏只引用 `workbook/mandatory-rules.md` 等既有规则，所以知识库是这些规则的结构化索引，不是第二套规则手册。

`.claude/skills/` 下的 skill 维护它：`research-meta-extractor`（提取）、`research-spec-checker`（一致性校验）、
`research-scan-orchestrator`（编排 + RKS 完备度评分）。这些 skill 只读代码、只写元数据，不触发 MATLAB 长跑仿真。

快速看 RKS 评分：

```bash
python3 .claude/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
  --project-root . --system-id spolar16qam --append-ledger --write-report
```
