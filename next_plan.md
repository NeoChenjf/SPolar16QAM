# 下一步执行计划：阶段 B 收束到 B4/B5

> 更新时间：2026-06-14  
> 当前状态：B1/B2/B3 已完成并文档化；B4 脚本已初步新建但尚未验收  
> 下一位 Agent 的目标：先修正并验证 B4 full-chain 策略验证口径，再进入 B5 论文二初稿  

---

## 0. 继任者只看这一份的入口

工作目录：

```text
C:\Users\11956\Desktop\研究生毕设
```

必须遵守：

1. 长 MATLAB 仿真不要自动跑 full mode，除非用户明确授权；
2. 任何代码、脚本、文档修改后，都要更新相关 `周报/阶段B/*.md`；
3. B 阶段不能声称某个多载波策略最优，除非已经同口径比较：
   - `uniform_p05`
   - `good_channel_information`
   - `good_channel_energy_shaping`
   - `bad_channel_energy_only` 传统对照
4. MATLAB 图上可见文字不要直接显示带 `_` 的内部策略名，避免 TeX 下标问题；
5. 任务收尾前运行 `workbook/rule-reflection-hook.md` 的反思检查，并把结果写入阶段文档。

建议先读文件：

```text
AGENTS.md
workbook/README.md
workbook/mandatory-rules.md
workbook/code-experiment-standards.md
workbook/quality-assurance.md
周报/阶段B/阶段B：多载波系统构建.md
周报/阶段B/B1：OFDM baseline阶段文档.md
周报/阶段B/B2：Rayleigh子载波可靠性画像.md
周报/阶段B/B3：子载波策略对比.md
周报/阶段B/Rayleigh相关知识.md
```

---

## 1. 已完成状态

### B1：OFDM AWGN baseline

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_visual_check.m
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline_dense.m
```

主要结果：

```text
16QAM_Polar/v2/results/20260522_174039_ofdm_baseline/
16QAM_Polar/v2/results/20260524_163654_ofdm_visual_check/
```

关键结论：

1. B1 采用统一 `p`、64 子载波、CP=1/4、SC decoder；
2. AWGN OFDM baseline 中 `p=0.5, 20 dB` 的 CP 修正 Goodput 最高，为 `0.393934`；
3. `p=0.1` 在低中 SNR 有局部 BER/Goodput 现象，但 B1 只是轻量 baseline，不作为最终策略排序；
4. OFDM 频谱图规则已收束：PSD 横轴是频率，纵轴是功率谱密度；TX/RX 按同一 `p` 同列展示。

### B2：Rayleigh 子载波可靠性画像

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_rayleigh_subcarrier_profile.m
```

主要结果：

```text
16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/
```

关键结论：

1. B2 输出 `|H_k|^2`、等效 `gamma_k`、MI proxy 和 high/mid/low 分组；
2. Rayleigh 信道是随机生成的，但严谨性来自统计信道模型和多 realization 画像，不来自单条 realization；
3. 当前 `num_realizations=20` 只够做轻量画像和 B3 proxy 输入；
4. 论文级结论需要更多 realization / 多 seed / 分位区间或置信区间。

### B3：子载波策略 proxy 对比

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_subcarrier_strategy_compare.m
```

最新结果：

```text
16QAM_Polar/v2/results/20260614_212900_subcarrier_strategy_compare/
```

数据层已比较六类策略：

```text
uniform_p05
uniform_p03
uniform_p01
good_channel_information
good_channel_energy_shaping
bad_channel_energy_only
```

20 dB proxy 摘要：

| 策略 | 能量 RMS proxy | 多载波 Goodput 上限 proxy | 信息子载波占比 | 说明 |
| --- | ---: | ---: | ---: | --- |
| `uniform_p05` | 1.5724 | 32.0000 | 1.00000 | Goodput 上限最高，能量最低 |
| `uniform_p03` | 2.0756 | 30.0938 | 1.00000 | 中间折中 |
| `uniform_p01` | 2.5787 | 23.5000 | 1.00000 | 能量最高，但码率上限低，未计 BER 损失 |
| `good_channel_information` | 1.6480 | 28.4526 | 1.00000 | 好信道偏信息 |
| `good_channel_energy_shaping` | 2.5205 | 28.5854 | 1.00000 | 好信道偏能量，需 full-chain 验证 |
| `bad_channel_energy_only` | 1.6480 | 20.3745 | 0.65625 | low 组纯传能，信息子载波平均可靠性较高但资源少 |

B3 只能写成 proxy tradeoff，不能写最终 BER/Goodput 最优结论。
当前图表叙事已收束：主图只突出三个统一 `p` baseline 加两条方向性策略 `good_channel_information` / `good_channel_energy_shaping`；`bad_channel_energy_only` 保留在 CSV 和表格中作为传统对照，不再作为主图里的第三条策略标签。

---

## 2. 当前停止点

用户已经确认新的阶段 B 完成计划：

1. 阶段 B 以“数能折中”为主线收口到 B4+B5；
2. B4 做 full-chain 策略验证；
3. B5 写论文二初稿；
4. B4 采用“分组块编码”第一版口径：
   - high/mid/low 三组分别按对应 `p_k` 跑 full-chain；
   - 用组内/组间占比做加权汇总；
   - 不先做逐子载波 polar 编码；
   - 逐子载波编码写成后续扩展边界。

已有一个初稿脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_fullchain_strategy_validation.m
```

但它还没有完成验收，不要把它当作已完成 B4。

已知待核验风险：

1. 当前 B4 脚本调用 `sim_shaped_polar_16qam(p, snr_db, cfg_run)` 做 `p` block，可能更接近单载波/通用 full-chain proxy，而不是严格复用 B1 的 OFDM Rayleigh full-chain；
2. 自适应帧数循环里，同一个 `(p, snr, seed)` 的多个 batch 可能重复使用同一随机种子，导致批次不是独立 Monte Carlo；
3. 还没跑 `checkcode`；
4. 还没跑 smoke；
5. 还没新建 B4 文档；
6. 还没更新阶段 B 总纲和本文件之外的周报记录。

---

## 3. B4 目标口径

B4 不再扩展基础解释，直接做论文级验证口径的第一版实现。

固定参数：

```matlab
n_subcarriers = 64;
cp_ratio = 1/4;
decoder = 'SC';
channel_model = 'Rayleigh';
channel_taps = 16;
p_values = [0.5, 0.3, 0.1];
snr_grid = 8:2:20;
num_realizations = 50;
seed_list = 1:5;
min_frames = 100;
max_frames = 1000;
target_errors = 200;
```

数据层保留六类策略：

```text
uniform_p05
uniform_p03
uniform_p01
good_channel_information
good_channel_energy_shaping
bad_channel_energy_only
```

主指标：

1. BER；
2. CP 修正 Goodput；
3. 接收侧能量 proxy；
4. 信息子载波占比；
5. Pareto 前沿。

排序原则：

1. 不用单一加权分数硬排；
2. 优先画 Goodput-Energy Pareto；
3. 只写条件性结论，例如“在某些 SNR/BER 约束下形成折中优势”。

---

## 4. 下一步具体执行清单

### Step 1：先审查 B4 初稿脚本

重点看：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_fullchain_strategy_validation.m
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m
16QAM_Polar/v2/experiments/multicarrier/run_subcarrier_strategy_compare.m
```

检查点：

1. B4 是否应移植 B1 的 OFDM 本地仿真逻辑，而不是直接调用 `sim_shaped_polar_16qam`；
2. adaptive batch 是否每批使用不同 seed；
3. 是否所有输出都落到 timestamped `results/YYYYMMDD_HHMMSS_*`；
4. 图例、坐标、tick label 是否避免下划线显示；
5. 是否保存 CSV/MAT/README/run_log/figures。

### Step 2：修正 B4 脚本

推荐优先修：

1. 若继续使用 block-level proxy，必须在 README 和 B4 文档里明确“不是逐子载波 OFDM full-chain”；
2. 若要贴合用户确认的“保持 B1 OFDM 口径”，优先从 `run_ofdm_baseline.m` 移植或抽取 OFDM local simulation 逻辑；
3. 修复自适应帧数 seed 重复问题，例如按 `(p, snr, seed, batch)` 生成可复现但不同的 batch seed；
4. smoke mode 默认保留，full mode 只能由用户授权后运行。

### Step 3：静态检查

在 MATLAB 中执行：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
checkcode('experiments/multicarrier/run_b4_fullchain_strategy_validation.m','-id')
```

把结果写入 B4 文档。

### Step 4：只跑 smoke

在 MATLAB 中执行：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run('experiments/multicarrier/run_b4_fullchain_strategy_validation.m');
```

因为脚本默认 `run_mode='smoke'`，这一步只用于确认链路、输出和图表能生成。不要自动跑 full mode。

### Step 5：新建 B4 文档

新建：

```text
周报/阶段B/B4：full-chain策略验证.md
```

必须包含：

1. B4 目标；
2. 分组块编码口径；
3. 与逐子载波编码的区别；
4. 六类策略定义；
5. 参数表；
6. 输出文件；
7. smoke 结果目录；
8. 静态检查结果；
9. 当前可写结论和不可写结论；
10. full mode 本地运行命令；
11. Rule reflection 结果。

### Step 6：更新阶段 B 总纲

更新：

```text
周报/阶段B/阶段B：多载波系统构建.md
```

至少补充：

1. B4 已进入 full-chain 策略验证；
2. B4 与 B3 proxy 的关系；
3. full mode 是否已运行；
4. 若只完成 smoke，要明确不能写论文级最终策略结论。

### Step 7：更新 next_plan

B4 完成后，把本文件改成：

1. B4 当前结果目录；
2. B4 关键图和表；
3. B5 论文二初稿的直接写作入口；
4. 未完成的 full mode 或扩展边界。

---

## 5. B5 论文二初稿预期结构

B5 文档建议新建：

```text
周报/阶段B/B5：论文二初稿.md
```

初稿结构建议：

1. 研究动机：多载波 Rayleigh 信道下子载波可靠性不均匀；
2. 阶段 A 承接：单载波概率整形存在 BER/Goodput/Energy tradeoff；
3. B1：OFDM baseline；
4. B2：Rayleigh 子载波可靠性画像；
5. B3：六类策略 proxy 对比；
6. B4：full-chain BER/Goodput/Energy 验证；
7. Pareto 分析；
8. 机制解释；
9. 局限性：分组块编码不是逐子载波编码，未引入 SCL/整流器/硬件；
10. 下一步：逐子载波编码、SCL 先验适配、能量收集非线性模型。

---

## 6. 不要做的事

1. 不要回头继续纠缠阶段 A 单点异常；
2. 不要把 B3 proxy 当作最终策略结论；
3. 不要自动跑 B4 full mode；
4. 不要修改 `16QAM_Polar/v2/config.m` 来做实验专用参数；
5. 不要只比较 `uniform_p05` 和一个候选策略；数据层保留六类策略，但主图叙事只突出 `good_channel_information` 和 `good_channel_energy_shaping` 两条方向性策略，`bad_channel_energy_only` 是传统对照；
6. 不要在图里直接显示 `good_channel_information` 这种带下划线的内部 ID；
7. 不要声称随机生成一条 Rayleigh 信道就证明策略有效，必须写统计模型和多 realization 口径。

---

## 7. 当前文件变更记录

- **2026-06-14**：将 `next_plan.md` 重写为继任者交接版。明确 B1/B2/B3 已完成状态、B4 初稿脚本存在但未验收、B4 待修风险、下一步执行清单、B5 初稿结构和禁止事项。Rule reflection: no new durable rule
