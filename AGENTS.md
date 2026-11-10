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


## Append-only文档维护规则（2026-10-09）

- `学习文档/` 下已有Markdown一律只在文件末尾追加；禁止删除、替换、重排已有文字或原位勾选。修正采用有日期的补充章节，指出被更新的旧结论及新证据。
- 新建Markdown作为首版写入；其后也只追加。
- 每轮任务状态以文件末尾最新的完整清单快照为准，快照保留固定编号、未完成项和证据链接；旧快照不可改写。
- 历史数据和图片不覆盖。新版本另存时间戳目录，再追加索引。
- 源码不受此规则限制；代码修改仍须保留历史结果的可复现性。

## Append-only scope clarification (2026-10-09)

This clause supersedes the narrower `学习文档/` scope above: append-only applies to every repository Markdown document, including `AGENTS.md`, learning documents, weekly reports, stage documents, project plans, workbook rules, and L1/L2/L3 contracts. Existing text is not edited in place. Corrections and status changes are dated appendices; checklists use new complete snapshots. Code and generated non-Markdown data remain governed by their own reproducibility rules.


## 2026-10-10 当前研究主线边界

固定16QAM为主研究线，承担多载波、BER/BLER/Goodput、策略优化和USRP验证；多QAM仅用于验证整形方法可外推，复用已有证据，不扩展为多载波或Goodput主线。当前下一阶段为知识库与Harness治理及B4等功率P1。

Revision metadata: revision_id=study_scope_16qam_mainline_20261010; current_status=current; supersedes=[baseline].


## 2026-11-06 科研执行防空转规则（实验与证据优先）

### 本次失效模式

长时间自主执行曾把总体科研目标拆成大量helper、哈希、随机键、恢复和文档检查；每项局部测试成功都被记作进展，但没有关闭模型或策略的核心研究问题。准备中发现新问题便继续扩充准备，形成检查→新工具→新检查的自我循环；已知道正式入口/授权未闭合，却没有及时收敛成可运行方案或请求必要决定。重复smoke和完整快照又放大了“持续在工作”的表象。硬件未知等非当前MATLAB目标的条件也被前置。根因是缺少面向科研交付的优先级、准备终止条件和范围控制，不是课题必然需要如此多工程准备。

### 强制执行规则

1. **先定义本轮可回答的研究问题和交付。** 明确实际数据批、关键图/表、判断标准和预算；代码可运行、测试通过、文档/快照增加只能列为准备进度，不能代替科研进展或宣称Goal接近完成。准备任务的Goal也只能按其明确目标验收，不得冒充研究验收。
2. **准备必须有终点。** 实验任务开始时给出准备时间盒，默认30分钟，并复用已有环境、代码、计时及验证。最小必要检查和一次smoke后进入可分析的数据批；超过时间盒仍不能启动时，必须说明具体阻塞、已有证据、最小修复及是否需要用户决定。时间盒不是强制运行错误代码的理由，也不得靠重命名任务重新计时。
3. **每个新增检查/工具必须有直接必要性。** 只有证据表明问题会影响当前实验的正确性、基本复现、运行可行性或用户明确要求的条件，才允许作为前置工作。可逆的小风险不自动升级为通用框架、完整资产信任链、全项目随机键审计或完美恢复要求。真正发现的错误应修复并记录，修复后只重跑受影响检查。
4. **禁止把局部活动当作目标推进。** 每个工作段结束时说明“本轮哪个研究问题因新证据而更接近回答”。若连续两个工作段仅增加helper、重复smoke或改状态文档，尚无新可分析数据或改变实验决策的证据，必须执行一次收敛：停止扩大准备范围，选择最小有价值实验；若实验确实不可运行，明确升级阻塞。收敛不能用新增审计任务替代。
5. **权限边界要及时处理。** 不得擅自越过正式实验、资源或范围授权，也不得把未获批准当作无限准备的理由。发现下一关键步骤需要授权时，先完成必要的具体方案、现有计时依据、样本与资源上限、停止条件，再一次性请求所需决定；在等待时只做不依赖批准且直接有价值的工作。已有明确授权不反复确认。自己生成的approved字段不等于用户批准。
6. **只前置当前问题需要的条件。** 纯MATLAB实验不以USRP、真实整流器或实验室资料齐备为开跑条件；需要未知物理参数时，可在研究范围允许的情况下使用明确登记的模型假设并限定结论。只有该未知条件确实决定本轮问题能否被回答时才升级用户决定，不能用假设冒充硬件验证。
7. **按研究批次交付。** 每个可分析批次完成后及时给图、分母、结果及限制，再决定下一批；模型失败、数据不足、策略无收益也应形成诚实结论。不能因结果不理想无限扩样、改门槛或延后报告。样本不足不得判通过或理论失败，追加实验仍服从具体预算。
8. **文档集中更新，避免记录循环。** 以一次有意义的实验/分析/方案变更为单位，集中追加阶段记录、必要契约和完整状态快照；不为每个helper或同类小检查复制整张进度表。记录准备与科研验收两种状态，不用文件数量或结构评分代替研究完成度。
9. **自主循环必须有停机路径。** 已获授权且能产生有效证据时持续执行；无可行下一步且需要用户或外部条件时明确交接。使用Goal时遵循其真实blocked阈值：同一阻塞重复至少三轮且已无有意义独立工作则标blocked，不能通过制造外围任务维持active；用户暂停立即停止研究工作。

本节约束执行顺序和进度判据，不撤销科学正确性、训练测试隔离、数据保存、append-only和实验授权规则。用户当前明确范围与具体实验计划优先；纯设计/只读讨论任务不因此自动启动实验。


## 2026-11-07 防空转复盘补充：阻塞收敛与实际执行

本节补充上一节九条规则，不重复建立另一套流程。本次并非没有运行任何MATLAB：已有smoke和计时，但主要研究问题仍未得到足量独立实验回答。关键偏差是把“完成一个能通过的局部检查”当成下一步选择标准，持续优化工程完整性，却没有优先消除阻止核心实验启动的那个阻塞。每次发现外围限制便增加新依赖，造成准备范围递归膨胀；频繁快照和自动Goal续轮掩盖了实际研究交付长期没有变化。

### 执行时必须落实的补充约束

1. **固定核心阻塞，不递归扩展前置队列。** 准备开始即列出当前最小实验、直接阻塞它的问题及必要修复。新发现项只有明确影响该实验的科学正确性、基本复现或实际运行才进入前置队列；其余记为后续，不得不断把“完整框架”加进关键路径。以能回答研究问题的最小充分实验为目标，不能偷偷缩成更容易通过的smoke。
2. **区分用户授权限制与软件自设限制。** 用户未授权须及时给具体预算并请求决定；已有授权范围内的入口缺失、旧门禁耦合或原型样本上限属于需要实现/修复的软件工作。不能自设一个始终不可达的formal入口，然后持续以该入口不可用解释无法实验；也不得简单删除保护、改标签或伪造approved记录来绕过真实授权与科学条件。
3. **准备时间和无实质进展跨轮累计。** 默认30分钟准备盒和连续两个工作段收敛规则，跨工具调用、自动Goal续轮、换子任务及上下文压缩累计，不因一次小测试通过或增加文档而重置。继续前应回答：核心批次是否已启动、是否已有可分析数据、哪个关键实验决定因证据改变。若均无，必须收敛或说明真实阻塞，不能以新helper延续循环。
4. **为结果分析保留预算。** 本轮预算必须覆盖数据运行、关键图表和结论分析；不能把全部资源消耗在准备或数据生成上。每批完成后先报告实际样本、分母、图和可支持的结论，再决定下一批。未完成正式验收时明确写出，不以频繁“Goal仍active”或工程检查清单替代结果。

这些约束同样适用于执行agent及其子agent；独立审查应优先检查实验是否能够在已授权条件下产生有效证据，而不是无证据增加通用工程要求。用户暂停立即停止研究，纯规则修订不会自动恢复Goal或启动实验。


## 2026-11-10 交接提示词默认连续自主执行
为下一个agent编写交接提示词时，默认以其能够连续、长时间自主完成约定阶段为目标，而非只读文件、给计划后等待用户。必须交代全局位置、明确阶段交付/验收及失败出口、阅读入口、可自主决策范围、当前有效授权与资源边界、恢复/交接状态和硬性停机条件。授权内常规实现、局部修复、验证、分析和集中更新连续推进，不逐步要求用户确认。仅在真实权限/预算/外部条件或会改变研究含义的重大决定无法自行消除时请求介入。
连续自主执行不等于无限预算或保证研究成功；不得继承已结束预算、伪造授权/通过门槛、绕过限制或用外围任务维持Goal。用户仅要求讨论或文档时仍遵守该范围。提示词有候选新预算须明确用户发送/批准后才生效；没有预算时先完成直接有价值的准备并一次性提出具体资源决定。
