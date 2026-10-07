# AGENTS.md

本文件为在本仓库工作的 AI agent（Codex、Claude Code 等）提供统一指引，是本项目
agent 指引的**唯一真相源**。不要另建或维护 `CLAUDE.md` 作为平行规则文件。

## 项目背景

这是一个研究生学位课题：**自适应无线信息-能量协同传输编码**。当前在研实现是一个 MATLAB
仿真系统，研究 **16QAM 概率成形 + 极化码（Polar）** 在 BER / Goodput / 收获能量三维权衡下，
面向无电池 6G IoT 场景的最优工作点。

活跃代码在 `16QAM_Polar/v2/`。`16QAM_Polar/` 下的旧脚本视为历史参考，除非用户明确要求修改，
否则不要改动。

## 当前阶段入口

- 当前阶段：**阶段 B，多载波 OFDM 正式统计后的独立验证与论文收束**。
- 阶段 B 总纲：`周报/阶段B/阶段B：多载波系统构建.md`
- 当前任务文档：`周报/阶段B/B4：full-chain策略验证.md`、`周报/阶段B/B5：论文二初稿.md`
- 下一目标：补充复杂度运行时间实测、论文最终排版与中期 PPT 实际制作；不得重复启动正式长跑。

阶段文档是研究范围、验收标准、结果解释的工作真相源。保持简洁，并在关闭任务前更新相关阶段文档。

## 启动规则

做非平凡工作前，先读：

1. `workbook/README.md`
2. `workbook/mandatory-rules.md`
3. `workbook/README.md` 中列出的任务相关 workbook 文件
4. `next_plan.md`
5. `周报/` 下相关的阶段文档

规则冲突时，以 `workbook/mandatory-rules.md` 为准。

## Skill 自动路由

项目级 Skills 的 Codex 发现目录是 `.agents/skills/`。Agent 先用每个 `SKILL.md` 的
`name` 与 `description` 判断是否匹配；命中后必须完整读取对应 `SKILL.md`，再按其中路由只加载
当前任务需要的 references、scripts 或子工作流。用户无需记住 Skill 名称，自然语言描述任务即可。

### 路由原则：主任务 Skill + 必要的伴随 Skill

1. **先看最终产物或主要判断**，选择一个主 Skill。例如科研汇报选 `research-presentation`，论文修订选
   `academic-research-suite`，知识库扫描选 `research-scan-orchestrator`。
2. **再看是否实际读写特定文件格式**。只有需要打开、创建或修改对应文件时，才叠加 `pptx/presentations`、
   `documents/docx`、`pdf` 或 `spreadsheets/xlsx` 等格式 Skill。
3. **只在任务确实需要新增领域判断时叠加领域 Skill**。例如已有结论的PPT排版不必调用
   `academic-research-suite`；需要重新解释统计结果、核验引用或形成新研究结论时才调用。
4. **选择能完整覆盖任务的最小集合**。同类格式 Skill 选择当前环境中功能最完整的一份，不为保险重复加载；
   一个 Skill 已包含的工作不再通过另一个宽泛 Skill 重做。
5. **关键词不是唯一依据**。“PPT”可能只是提取文字，“论文”也可能只是把既有结论放进幻灯片；应根据用户要求的
   实际动作和交付物判断，而不是看到名词就触发所有相关 Skill。

### 常用场景路由表

| 用户场景或任务信号 | 主 Skill | 必要时组合 | 不应误触发的边界 |
| --- | --- | --- | --- |
| 创建、重构或审查开题/中期/答辩/实验汇报；修改一页科研图表逻辑；生成逐页讲稿或 Speaker Notes | `research-presentation` | 实际读写`.pptx`时加`pptx`或`presentations`；需要新文献、引用核验或新统计解释时再加`academic-research-suite` | 不能只调用通用PPT Skill；已有研究口径的版式调整不自动触发学术深度调研 |
| 仅打开PPT、提取文字、合并/拆分幻灯片、修改普通商务/教学PPT或处理母版/备注 | `pptx`或`presentations` | 内容本身属于科研论证时才加`research-presentation` | “文件是PPTX”不等于“科研汇报” |
| 根据现有科研PPT制作限时讲稿，或要求PPT、讲稿、切页提示和Speaker Notes逐页一致 | `research-presentation` | 加`pptx`或`presentations`读取页面及备注 | 不能只用普通写作 Skill，因为需要跨文件、页码和时间同步 |
| 将参考PPT抽象成以后反复使用的可复用模板 Skill | `template-creator` | 加`pptx`或`presentations`检查模板；若模板包含科研叙事规范，再加`research-presentation` | 一次性“参考这个模板做一份PPT”不触发`template-creator` |
| 写论文、改论文、做文献综述、核验引用、设计实验或重新解释统计结果 | `academic-research-suite` | 若输出同时是科研PPT，再加`research-presentation`与格式 Skill | 只做PPT版式、讲稿同步或已有结论搬运时不必调用 |
| 生成或修改MATLAB方法、函数、`run_*`实验入口，或改变研究领域 | 正常开发流程 + `research-meta-extractor` | 完成后按改动更新L3/L2/L1；若还要检查断链，再加`research-spec-checker` | 只读解释代码、不改方法和契约时不自动写知识库 |
| 检查L1/L2/L3断链、假设覆盖或理论护栏 | `research-spec-checker` | 发现缺失元数据且用户要求补建时再加`research-meta-extractor` | 不等同于全量扫描或RKS评分 |
| 全量/增量扫描科研知识库、端到端提取→校验→RKS评分 | `research-scan-orchestrator` | 由该Skill按需编排`research-meta-extractor`和`research-spec-checker` | 不要再手工重复启动同一流水线中的子Skill |
| 只生成科研示意图、位图素材或编辑图片 | `imagegen`；低清修复用`image-enhance` | 图片将进入科研PPT时由`research-presentation`定义信息目的和版面角色 | 不用图片 Skill 代替科学数据图的计算与统计核验 |
| 创建或更新Skill、优化触发描述或调用规则 | `skill-creator` | 涉及科研PPT Skill时结合真实汇报反馈与回归样例 | 不把单次页码、一次性数值或个人临时偏好写成通用规则 |

### Presentation 快速判定

- “做/改科研PPT、答辩逻辑、结果页、结论页、逐页讲稿” → `research-presentation`。
- 上述任务实际触碰`.pptx` → 再加 `pptx` 或 `presentations`。
- 只是提取PPT内容、改普通PPT格式、合并拆分页 → 只用 `pptx` 或 `presentations`。
- 需要从原始结果重新得出结论、核验引用或设计新实验 → 再加 `academic-research-suite`。
- 要把参考PPT做成“以后可重复调用的模板Skill” → `template-creator`；只参考一次不调用。

示例：

- “优化中期PPT第7页左右图的关系并同步讲稿” → `research-presentation + presentations`。
- “从这个PPTX提取全部文字做摘要” → `pptx`。
- “根据三份结果材料重新判断结论，再制作答辩PPT” → `academic-research-suite + research-presentation + presentations`。
- “沿用开题PPT样式制作本次中期汇报” → `research-presentation + presentations`，不是`template-creator`。
- “把这套开题PPT沉淀为以后能复用的模板Skill” → `template-creator + presentations`，必要时再加`research-presentation`。

默认保持人在环：不得因通用科研 Skill 而自动启动长时间 MATLAB 仿真、跨模型上传未公开材料、
安装 hook、提交论文或替用户作出研究结论。相关动作仍须遵守本文件的权限和验证规则。

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
- 面向 Typora 的 Markdown 文档，行内公式统一写为 `$...$`，独立公式统一写为独占行的 `$$...$$`；不得使用 `\\(...\\)` 或 `\\[...\\]` 作为数学分隔符。修改含公式的文档后，检查公式分隔符成对、无遗留旧分隔符及无不可见控制字符。

## 常用 MATLAB 命令

2026-09-12 Windows 环境复核：本机 MATLAB R2020b 与通信工具箱许可可用，`check_env` 已通过。
此 Windows 工作区使用 `scripts/run_matlab_local.ps1 "check_env"`（同样自动进入 v2 并运行
`setup_paths`）。下方 Octave 包装仅保留给旧 Mac/Octave 环境；以当前环境实测为准，长实验仍须单独授权。

> **旧 Mac/Octave 环境：** 无 MATLAB License 时，agent 通过 CLI 包装调用，
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
- 测试、smoke、验证或实验结果写入阶段文档时，应尽量附上关键图片并写简短图片分析，说明图中能支持什么、不能支持什么，便于后续阅读和论文材料整理。
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

`.agents/skills/` 下的项目级 Skill 维护它：`research-meta-extractor`（提取）、
`research-spec-checker`（一致性校验）、`research-scan-orchestrator`（编排 + RKS 完备度评分）。
这些 Skill 只读代码、只写元数据，不触发 MATLAB 长跑仿真。

快速看 RKS 评分：

```bash
python .agents/skills/research-scan-orchestrator/scripts/rks_evaluate.py \
  --project-root . --system-id spolar16qam --append-ledger --write-report
```
