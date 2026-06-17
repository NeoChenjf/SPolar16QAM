# 阶段 B：多载波系统构建

> 当前口径：从阶段 A 的单载波 SC 结论出发，进入多载波 OFDM 系统构建  
> 阶段边界：先建立可复现实验链路，再做子载波级自适应整形；不把 SCL、整流器硬件模型、USRP 上板作为阶段 B 起步阻塞项  
> 计划来源：`项目整体计划书.md` 中“阶段 B：多载波系统构建（2026.05 - 2026.09）”
> 文档结构：本文为阶段 B 总纲；B1/B2/B3 细化见 `周报/阶段B/` 下各阶段文档

阶段 B 的核心问题是：在多载波信道中，不同子载波具有不同可靠性，单一全局整形参数 `p` 可能不是最合适的选择。因此本阶段要把阶段 A 中已经建立的 `p -> BER / Goodput / Energy` 机制迁移到 OFDM 场景，进一步研究子载波级或子载波分组级的动态概率整形策略。

这里不能预设“好信道一定应该用更小的 `p`”。阶段 B 需要比较至少三类策略：好信道偏信息传输、好信道偏能量整形、以及传统的差子载波纯传能方案。哪个方案更好，应由 Goodput、收集能量、BER 约束和复杂度共同决定。

---

## 1. 阶段入口

阶段 A 已经给出单载波 SC 口径下的关键结论：

1. 强整形会带来几何/能量收益；
2. 强整形也会带来编码侧 BER 损失；
3. 强整形会降低 `R_total(p)`，从而降低 Goodput 上限；
4. 单载波 SC 下，`p=0.5` 在统一口径 final global curve 中仍是最高或最稳 Goodput 方案；
5. `p=0.1` 等强整形只在部分中低 SNR 区间表现出局部 tradeoff。

这些结论说明：阶段 B 不能直接假设“越强整形越优”，而应当根据子载波可靠性选择 `p_k` 或选择是否让该子载波承担信息传输。直观上存在两种相反但都合理的思路：

1. 好信道能承受更强整形，因此可在好信道上使用较小 `p` 来换取能量收益；
2. 好信道最适合承载信息，因此应让好信道使用接近 `0.5` 的 `p` 保持码率和 BER，差子载波则偏向能量传输。

阶段 B 的任务不是提前判断二者谁一定正确，而是把它们和传统纯传能方案放到同一指标体系下比较。

---

## 2. 阶段目标

阶段 B 面向多载波系统，目标分为五个子任务：

| 编号 | 任务 | 输出 |
| --- | --- | --- |
| B1 | OFDM AWGN baseline 与可视化诊断 | 统一 `p` 的 AWGN OFDM full-chain baseline、PSD/频域资源网格/星座图 |
| B2 | Rayleigh 子载波可靠性画像 | `|H_k|^2`、等效 `gamma_k`、MI proxy、high/mid/low 分组 |
| B3 | 统一 `p` baseline 与三类子载波策略对比 | 统一 `p`、好信道偏信息、好信道偏能量整形、差子载波纯传能 |
| B4 | 低复杂度优化算法 | 查表、贪心、分组优化或近似凸松弛 |
| B5 | 论文二材料整理与初稿 | 多载波概率整形极化码论文二素材 |

本阶段的最终目标不是只证明 OFDM 可运行，而是形成一个可以支撑论文二的问题链条：

```text
多载波频率选择性
-> 子载波可靠性不均匀
-> 统一 p 不是唯一选择
-> 好信道偏信息 / 好信道偏能量 / 差信道纯传能 三类策略对比
-> 在 BER、Goodput、Energy 之间形成新的 Pareto tradeoff
```

---

## 3. 第一轮任务：OFDM Baseline

第一轮只做最小可复现 OFDM baseline，不直接进入复杂优化。这样做的原因是：如果基础 OFDM 链路、CP、均衡、解调、极化码接口尚未稳定，过早引入 `p_k` 会让错误来源变得不可定位。

本轮阶段文档：

```text
周报/阶段B/B1：OFDM baseline阶段文档.md
```

建议第一版固定参数：

```matlab
p_list = [0.5, 0.3, 0.1];
snr_grid = [8, 12, 16, 20];
n_subcarriers = 64;
cp_ratio = 1/4;
channel_model = 'AWGN';
decoder = 'SC';
num_frames = 100;
seed = 42;
```

第一轮只比较统一 `p` 的 OFDM 表现，指标沿用阶段 A：

$$
G(p,\gamma)=R_{\mathrm{total}}(p)\left(1-\mathrm{BER}(p,\gamma)\right),
$$

$$
E(p)=18-16p.
$$

输出目录建议：

```text
16QAM_Polar/v2/results/YYYYMMDD_HHMMSS_ofdm_baseline/
```

必须输出：

```text
ofdm_baseline.csv
README.txt
figures/ofdm_ber_vs_snr.png/pdf/fig
figures/ofdm_goodput_vs_snr.png/pdf/fig
figures/ofdm_energy_goodput.png/pdf/fig
```

README 需要写明：

1. OFDM 子载波数；
2. CP 长度或比例；
3. 信道模型；
4. 是否使用统一 `p`；
5. 是否仍为 SC；
6. 与阶段 A 单载波结果的对比边界。

---

## 4. 第二轮任务：Rayleigh 与子载波可靠性

OFDM baseline 稳定后，进入 Rayleigh 多径信道：

```matlab
channel_model = 'Rayleigh';
channel_taps = 16;
perfect_CSI = true;
```

本轮重点不是立刻优化 `p_k`，而是先形成可靠性画像：

1. 记录每个子载波的频域增益 `|H_k|^2`；
2. 计算每个子载波的等效 SNR：

$$
\gamma_k = \gamma_{\mathrm{avg}} |H_k|^2.
$$

3. 估计或统计每个子载波的 MI / BER proxy；
4. 判断子载波是否可以按可靠性分组。

建议输出：

```text
subcarrier_reliability.csv
figures/subcarrier_snr_profile.png/pdf/fig
figures/subcarrier_mi_profile.png/pdf/fig
```

---

## 5. 第三轮任务：三类子载波策略对比

当子载波可靠性可观测后，再引入策略对比。当前至少保留三类方案：

### 5.1 方案一：好信道偏信息

这类方案把高可靠子载波优先用于信息传输，因此让高可靠子载波使用接近 `0.5` 的 `p`，以维持较高 `R_total` 和较低编码侧损失；低可靠子载波本来难以稳定传信息，因此使用更小 `p` 或降低信息承载比例，偏向能量收益。

| 子载波组 | 可靠性 | 候选 p |
| --- | --- | --- |
| 高可靠组 | `gamma_k` 高 | `p=0.5` 或 `0.4` |
| 中可靠组 | `gamma_k` 中 | `p=0.3` |
| 低可靠组 | `gamma_k` 低 | `p=0.2` 或 `0.1` |

该方案的直觉是“把能可靠传信息的资源留给信息，把不适合传信息的资源转向能量”。它可能更适合以 Goodput 为主、能量为辅的目标。

### 5.2 方案二：好信道偏能量整形

这类方案认为高可靠子载波有更强误码容忍度，可以承受小 `p` 带来的编码侧损失，因此在好信道上使用更强整形以换取能量收益；低可靠子载波则使用接近 `0.5` 的 `p`，避免信道差和编码损失叠加。

| 子载波组 | 可靠性 | 候选 p |
| --- | --- | --- |
| 高可靠组 | `gamma_k` 高 | `p=0.1` 或 `0.2` |
| 中可靠组 | `gamma_k` 中 | `p=0.3` |
| 低可靠组 | `gamma_k` 低 | `p=0.5` 或 `0.4` |

该方案的直觉是“好信道可以承担更多整形代价”。它可能更适合能量收益权重较高、同时仍要求一定 BER 的目标。

### 5.3 方案三：差子载波纯传能

这是传统对照方案：把信道条件差、信息传输效率低的子载波直接改为纯传能信号，不再承载信息；其余较好子载波承载常规或轻度整形的信息。

| 子载波组 | 可靠性 | 角色 |
| --- | --- | --- |
| 高可靠组 | `gamma_k` 高 | 信息传输，`p=0.5` 或轻度整形 |
| 中可靠组 | `gamma_k` 中 | 信息/能量折中 |
| 低可靠组 | `gamma_k` 低 | 纯传能，不计入信息 BER |

该方案的优点是逻辑清楚、通信可靠性容易保证；缺点是低可靠子载波完全放弃信息，Goodput 上限会下降。它应作为阶段 B 的传统 baseline。

### 5.4 比较指标

三类策略必须在同一口径下比较：

$$
G=\frac{\text{成功解码信息位数}}{\text{总时频资源}},
$$

$$
E_{\mathrm{rx}}=\sum_k |H_k|^2 E(p_k),
$$

并记录：

1. overall BER；
2. Goodput；
3. 接收侧能量 proxy；
4. 信息子载波占比；
5. 子载波分组阈值；
6. 复杂度和信令开销。

最终结论应写成条件性判断：当目标更偏 Goodput 时，方案一可能占优；当目标更偏能量且 BER 约束可满足时，方案二可能占优；当差子载波的通信收益很低时，方案三可能成为稳健对照。

---

## 6. 验收标准

阶段 B 第一批验收不追求最终最优，而追求链路可靠、口径清晰、结果可复现。

OFDM baseline 验收：

1. 结果目录符合 `results/YYYYMMDD_HHMMSS_*`；
2. CSV 包含 `p、SNR、BER、Goodput、R_total、E_theory、E_norm`；
3. 图包含 BER、Goodput、Energy-Goodput；
4. README 写清实验参数与运行命令；
5. 文档明确说明与阶段 A 单载波结果不能直接等同。

Rayleigh 可靠性验收：

1. 能输出每个子载波的 `|H_k|^2` 或等效 SNR；
2. 能展示子载波可靠性差异；
3. 能给出 `gamma_k -> p_k` 的初步映射依据；
4. 不把单次随机信道的结果写成全局结论。

自适应整形与纯传能对比验收：

1. 至少包含统一 `p` baseline；
2. 至少包含“好信道偏信息”和“好信道偏能量整形”两种 `p_k` 策略；
3. 至少包含“差子载波纯传能”传统对照；
4. 比较 BER、Goodput、Energy、信息子载波占比；
5. 如果收益只在部分 SNR 或部分信道实现，结论写成条件性 tradeoff。

---

## 7. 当前不做

1. 不把 SCL 先验适配作为阶段 B 起步阻塞项；
2. 不立即引入整流器非线性模型；
3. 不做 USRP 或硬件接收机；
4. 不直接跑正式大网格；
5. 不把第一次 OFDM baseline 结果写成论文二最终结论；
6. 不把阶段 A 的单载波异常点继续作为阶段 B 阻塞项。

---

## 8. 下一步执行清单

B1 已完成 AWGN OFDM baseline 和可视化诊断。B2 已完成第一版 Rayleigh 子载波可靠性画像。B3 已完成第一版 proxy-level 子载波策略对比，后续应先讨论哪些策略值得进入 full-chain BER / Goodput 验证。

当前 B3 脚本路径：

```text
16QAM_Polar/v2/experiments/multicarrier/run_subcarrier_strategy_compare.m
```

当前 B3 阶段文档：

```text
周报/阶段B/B3：子载波策略对比.md
```

当前 B3 结果目录：

```text
16QAM_Polar/v2/results/20260614_212900_subcarrier_strategy_compare/
```

下一步建议：

1. 保留 `uniform_p05` 作为统一通信 baseline；
2. 保留 `good_channel_information` 和 `good_channel_energy_shaping` 作为两条相反假设；
3. 保留 `bad_channel_energy_only` 作为传统纯传能对照，但不再作为主图的第三条方向性策略标签；
4. 进入 full-chain 前，先定义子载波级 `p_k` 如何接入 polar bit-level 编码、16QAM LLR 和 Goodput 统计。

---

## 9. 变更记录

- **2026-06-17**：**运行环境打通，端到端仿真可跑**（接续当日早些时候的环境搭建）。Octave communications package 的 `qammod/qamdemod` 签名与 MATLAB 不兼容（不接受 `'gray'`/`'UnitAveragePower'`/`'OutputType','llr'` 等参数，直接报 "too many inputs"），`bitrevorder` 又属 signal package（需 control 编译）。**解决方案**：新增 `16QAM_Polar/v2/compat/octave/`（`qammod.m`/`qamdemod.m`/`bitrevorder.m`/`sgtitle.m`），复刻 MATLAB 口径；`qamdemod` 的 LLR 复用项目纯数学 `llr_16qam_gray_LSE`，与 qammod 共用同一星座。`setup_paths.m` **仅 Octave 下** `addpath(...,'-begin')` 把 compat 放最前以遮蔽 package 同名函数，**MATLAB 下不生效、用原生**，算法代码零改动。**验证**：(1) compat 自洽闭环——16 星座点 qammod→qamdemod(llr)→硬判决 0 失配、bitrevorder/bit 往返一致、平均功率归一化=1；(2) `check_env` 全绿；(3) `run_single` 端到端 exit 0、无 error、BER 随 SNR 单调下降（4.94e-01@0dB → 3.08e-02@20dB，p=0.3/100帧/SC，耗时约 250s）。communications package 仅用 `-nodeps` 装上以提供 `de2bi/bi2de`；signal/control **不需要**。详见 `workbook/environment-setup.md`。**影响范围**：新增 compat 层 + `setup_paths.m` 仅加一段 Octave 分支路径，未改任何算法逻辑或 `config.m`。Rule reflection: no new durable rule（compat 方案与验证法已沉淀于 `environment-setup.md`）。
- **2026-06-17**：搭建本机运行环境（GNU Octave 路线，agent 可驱动 CLI）。本机（Apple M3 Pro/arm64，无 MATLAB License）`brew install octave` 装好 **Octave 11.3.0**（arm64 原生）；新增 agent 一键调用包装 `scripts/run_matlab.sh`（自动 cd v2 + pkg load + setup_paths + 退出码透传）、环境自检脚本 `16QAM_Polar/v2/diagnostics/check_env.m`、`workbook/environment-setup.md`（安装/CLI/已知 Octave↔MATLAB 差异清单），并在 `workbook/README.md`、`CLAUDE.md` 增加环境入口。`.gitignore` 由 `.claude/` 调整为 `.claude/*` + `!.claude/skills/`，使本会话所建科研 skill 可入库，`settings.local.json` 仍忽略。**影响范围**：仅新增环境脚手架/文档与 .gitignore 规则，未改动任何 `.m` 算法代码或 `config.m`。Rule reflection: no new durable rule。
- **2026-06-17**：统一 agent 指引为单一真相源。`CLAUDE.md` 改写为中文并作为唯一真相源（合并了原 `AGENTS.md` 独有的当前阶段入口、`cfg_local` 覆盖、results 时间戳目录、阶段 B 三基线对照等条款）；`AGENTS.md` 退化为仅引用 `CLAUDE.md` 的极简文件。**目的**：消除两份指引各自维护、反复同步备份的负担。**影响范围**：仅 agent 指引文档，未改动任何 `.m` 代码、`config.m` 或知识库内容。Rule reflection: no new durable rule。
- **2026-06-17**：接入科研 spec-harness（对标 hic-spec 的 L1/L2/L3 知识库 + skill + 完备度评分）。新增 `workbook/knowledge/`（schema×3、L1×6、L2×6、L3×26、`meta/`、`reports/`），`.claude/skills/` 三个科研专用 skill（`research-meta-extractor` 提取 / `research-spec-checker` 校验 / `research-scan-orchestrator` 编排）与纯标准库评分脚本 `rks_evaluate.py`；并在新建的 `README.md` 及 `CLAUDE.md` / `AGENTS.md` / `workbook/README.md` 增加知识库入口。**影响范围**：仅新增文档/元数据与 AI harness，未改动任何 `.m` 仿真代码或 `config.m`。**验证方法**：`rks_evaluate.py` 自检 RKS=96.0（阈值 75，PASS）——方法覆盖 26/26、流程覆盖 6/6、跨层完整 41/41、护栏留痕 6/6、假设覆盖 8/10（`l1_16qam_modulation_llr#H1`、`l1_multicarrier_ofdm#H2` 待补 L2 验证，属如实记录的覆盖缺口）；结构核对 `.m` 函数数 = L3 契约数 = 26。**产物**：`workbook/knowledge/reports/rks-20260617_113301.md`、账本 `workbook/knowledge/meta/scan-ledger.tsv`。L1 护栏全部回链既有规则（mandatory-rules §7/§8/§3、AGENTS 三基线），不另立规则。Rule reflection: no new durable rule（spec-harness 维护约定已写入 `workbook/knowledge/README.md` 与各 skill 内，无需新增 workbook 硬规则）。

- **2026-06-14**：收束 B3 主图叙事。最新 B3 结果目录为 `16QAM_Polar/v2/results/20260614_212900_subcarrier_strategy_compare/`；数据层仍保留 `bad_channel_energy_only` 作为传统对照，但主图只突出 `good_channel_information` 与 `good_channel_energy_shaping` 两条方向性策略，避免“好信道偏信息”和“差子载波纯传能”在叙事上重复。Rule reflection: no new durable rule
- **2026-06-03**：B3 补充能量性能与信息性能对比表。`run_subcarrier_strategy_compare.m` 新增接收侧能量 RMS proxy `rx_energy_proxy_rms` 和多载波 Goodput 上限 proxy `multicarrier_goodput_proxy_sum`；重新运行输出 `16QAM_Polar/v2/results/20260603_000515_subcarrier_strategy_compare/`。该表仍为 proxy/upper-bound 口径，不替代 full-chain BER/Goodput Monte Carlo。Rule reflection: no new durable rule
- **2026-06-02**：修正 B3 策略对比图标签显示问题。`run_subcarrier_strategy_compare.m` 绘图时将内部策略 ID 转换为显示标签，例如 `good_channel_information` 显示为 `good channel information`，并设置文本解释器避免 MATLAB 将 `_` 渲染为下标；重新运行输出 `16QAM_Polar/v2/results/20260602_235630_subcarrier_strategy_compare/`。B3 文档已补充当前关键结论。Rule reflection: added/updated `workbook/code-experiment-standards.md` because MATLAB figure labels with underscores can recur across experiments
- **2026-05-26**：B3 子载波策略对比首轮完成。新增脚本 `16QAM_Polar/v2/experiments/multicarrier/run_subcarrier_strategy_compare.m` 与文档 `周报/阶段B/B3：子载波策略对比.md`；轻量运行输出 `16QAM_Polar/v2/results/20260526_182757_subcarrier_strategy_compare/`，包含 assignment/summary CSV、MAT、README、run_log 和两张 proxy 图。该结果只比较接收侧能量 proxy、信息子载波 MI proxy、信息子载波占比和码率权重 proxy，不运行 polar BER/Goodput Monte Carlo，也不写最终策略最优结论。Rule reflection: no new durable rule
- **2026-05-24**：对齐 `项目整体计划书.md` 中阶段 B 小阶段描述。将原先 B1“OFDM 基础链路与瑞利信道建模”、B2“子载波级可靠性估计与 `gamma_k -> p_k` 映射”的粗粒度描述，更新为当前执行口径：B1=OFDM AWGN baseline 与可视化诊断，B2=Rayleigh 子载波可靠性画像，B3=统一 `p` baseline 与三类子载波策略对比，B4=低复杂度优化，B5=论文二材料整理。Rule reflection: no new durable rule
- **2026-05-24**：B2 Rayleigh 子载波可靠性画像首轮完成。新增脚本 `16QAM_Polar/v2/experiments/multicarrier/run_rayleigh_subcarrier_profile.m` 与文档 `周报/阶段B/B2：Rayleigh子载波可靠性画像.md`；轻量运行输出 `16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/`，包含 `|H_k|^2`、等效 `gamma_k`、MI proxy 和 high/mid/low 分组画像。该结果只作为 B3 分组依据，不作为最终策略结论。
- **2026-05-22**：B1 OFDM baseline 轻量运行完成。结果目录 `16QAM_Polar/v2/results/20260522_174039_ofdm_baseline/`；输出 CSV/MAT/README/run_log 和三张图均齐全；最高 CP 修正 Goodput 为 `p=0.5, 20 dB` 的 `0.393934`，`p=0.1` 在低中 SNR 有局部 BER / Goodput 优势。该结果只作为 B1 baseline，不作为最终多载波策略结论。
- **2026-05-22**：B1 OFDM baseline 脚本已实现。新增 `16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m`，覆盖统一 `p`、AWGN OFDM、SC decoder、CP 修正 Goodput、CSV/MAT/README/图输出；静态 `checkcode` 通过，正式 Monte Carlo 待本地运行。
- **2026-05-22**：更新 `AGENTS.md` harness 入口。新增当前阶段入口、阶段 B 文档组、B1 当前任务文档、`experiments/multicarrier/` 约定和三类策略对比边界。
- **2026-05-22**：阶段 B 文档文件夹化。阶段 B 总纲统一放在 `周报/阶段B/阶段B：多载波系统构建.md`；新增 `周报/阶段B/B1：OFDM baseline阶段文档.md` 作为第一轮任务阶段文档。
- **2026-05-22**：补充阶段 B 三类策略对比框架：好信道偏信息、好信道偏能量整形、差子载波纯传能；将原先单一“好信道用小 `p`”假设改为待比较的研究问题。
- **2026-05-22**：新建阶段 B 主文档。根据 `项目整体计划书.md` 将阶段 B 拆分为 OFDM baseline、Rayleigh 子载波可靠性、自适应整形、低复杂度优化和论文二材料整理；当前第一任务确定为最小 OFDM baseline。
- **Rule reflection**：no new durable rule。
