# 下一步执行计划：阶段 B 从正式统计进入独立验证与论文收束

> 更新时间：2026-09-17
> 当前状态：24 dB边界失败已转化为28 dB保护带；第三批全新样本验证PASS；B5初稿已更新
> 下一位 Agent / 用户的目标：补充复杂度运行时间实测、论文最终排版与中期PPT实际制作

---

## 0. 继任者入口

工作目录：

```text
C:\Users\11956\Desktop\研究生毕设
```

必读：

```text
CLAUDE.md
workbook/README.md
workbook/mandatory-rules.md
workbook/code-experiment-standards.md
workbook/quality-assurance.md
workbook/environment-setup.md
周报/阶段B/阶段B：多载波系统构建.md
周报/阶段B/B1：OFDM baseline阶段文档.md
周报/阶段B/B2：Rayleigh子载波可靠性画像.md
周报/阶段B/B3：子载波策略对比.md
周报/阶段B/B4：full-chain策略验证.md
```

必须遵守：

1. 不自动跑 full mode 或长 MATLAB 仿真；
2. 任何代码、脚本、文档改动后更新相关 `周报/阶段B/*.md`；
3. 阶段 B 不能声称策略最优，除非同口径比较 `uniform_p05`、`good_channel_information`、`good_channel_energy_shaping`、`bad_channel_energy_only`；
4. MATLAB 图上不要直接显示带 `_` 的内部策略名；
5. 测试、smoke、验证或实验结果写入阶段文档时，尽量附关键图片和图片分析；
6. 关闭非平凡任务前运行 rule reflection，并写入阶段文档。

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

关键结论：AWGN OFDM baseline 已跑通；`p=0.5, 20 dB` 的 CP 修正 Goodput 最高，为 `0.393934`。B1 只是轻量 baseline，不用于最终策略排序。

### B2：Rayleigh 子载波可靠性画像

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_rayleigh_subcarrier_profile.m
```

主要结果：

```text
16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/
```

关键结论：已输出 `|H_k|^2`、等效 `gamma_k`、MI proxy 和 high/mid/low 分组。当前 realization 数只够支撑画像和 B3 proxy，不够论文级统计结论。

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

B3 只能写成 proxy tradeoff，不能写最终 BER/Goodput 最优结论。

### B4a：分组块 full-chain 策略验证

脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_fullchain_strategy_validation.m
```

阶段文档：

```text
周报/阶段B/B4：full-chain策略验证.md
```

smoke 结果：

```text
16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/
```

已完成：

1. 修复 adaptive batch 重复 seed 风险；
2. MATLAB `check_env` 通过；
3. 默认 smoke 运行成功；
4. 输出 block/realization/summary CSV、MAT、README、run_log 和三张图；
5. README 和 B4 文档明确 B4a 不是严格逐子载波 OFDM polar 编码。

B4a 只能作为分组块近似验证。不能写最终策略排序，不能写成严格 Rayleigh OFDM full-chain。

---

## 2. 已完成：正式统计、配对分析与低复杂度码本

B4b入口已经实现：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
```

正式结果：

```text
16QAM_Polar/v2/results/20260917_210504_b4_strict_ofdm_rayleigh_formal/
16QAM_Polar/v2/results/20260917_215938_b4b_paired_policy_analysis/
```

正式仿真采用以下预登记参数，并在用户授权后完成：

```matlab
snr_grid = [20 24 28 32 36 40];
num_realizations = 30;
min_frames = 5;
target_errors = 200;
max_frames = 50;
run_mode = 'formal';
```

正式仿真形成1080条重复记录、36条汇总与1920条信道记录，独立审计PASS。随后按同一SNR/realization完成90条配对差值，并形成六项低复杂度约束码本：BER上区间不超过0.1且Goodput下区间不低于0.25时最大化接收能量，否则回退最大Goodput。默认结果为20 dB选择`uniform_p05`，24—40 dB选择`uniform_p01`。

当前验收：

1. 正式重复以Rayleigh realization为统计单元，公共信道/噪声用于配对比较；
2. 全零错误点已写入上界，不作为理论BER=0；
3. 配对键、区间、方向检验、可行性筛选和码本选择规则均通过独立审计；
4. 已新增`学习文档/多载波OFDM瑞利信道-loop/中期PPT材料.md`逐图解释结果；
5. 下一步不是重复正式长跑，而是用独立信道样本验证固定码本，并进入B5论文收束。

---

## 3. 下一步首选：独立样本验证与B5论文初稿

建议新建：

```text
周报/阶段B/B5：论文二初稿.md
```

初稿结构：

1. 研究动机：Rayleigh OFDM 子载波可靠性不均匀；
2. 阶段 A 承接：单载波概率整形存在 BER / Goodput / Energy tradeoff；
3. B1：AWGN OFDM baseline；
4. B2：Rayleigh 子载波画像；
5. B3：六类策略 proxy 对比；
6. B4a：分组块 full-chain 验证；
7. B4b：严格 OFDM Rayleigh full-chain，作为增强验证或待完成边界；
8. Pareto 分析；
9. 局限性：B4a 不是逐子载波编码，未引入 SCL / 整流器 / 硬件；
10. 下一步：逐子载波编码、SCL 先验适配、能量收集非线性模型。

---

## 4. 不要做的事

1. 不要回头纠缠阶段 A 单点异常；
2. 不要把 B3 proxy 当作最终策略结论；
3. 不要把 B4a smoke 当作论文级统计结果；
4. 不要自动跑 B4a/B4b full mode；
5. 不要修改 `16QAM_Polar/v2/config.m` 做实验专用覆盖；
6. 不要只比较 `uniform_p05` 和单一候选策略；
7. 不要声称单次或少量 Rayleigh realization 证明策略有效。

---

## 5. 当前文件变更记录

- **2026-09-17**：两轮B4b受限pilot完成且通过审计：`20260917_194823_b4_strict_ofdm_rayleigh_pilot`覆盖20—32 dB，`20260917_194950_b4_strict_ofdm_rayleigh_pilot_high_snr`覆盖32—40 dB。正式网格预登记为20—40 dB六点、30 realization、5—50帧、目标200错误；实际长跑仍待实现checkpoint/resume与用户授权。Rule reflection: no new durable rule
- **2026-09-17**：正式统计入口现已支持checkpoint/resume、partial CSV和零错95%上界，并拒绝没有`formal_authorized=true`的实际启动。重构后的高SNR pilot`20260917_205527_b4_strict_ofdm_rayleigh_pilot_high_snr_formal_ready`审计通过；正式长跑仍等待用户授权。Rule reflection: no new durable rule
- **2026-09-17**：B4b严格OFDM-Rayleigh六策略smoke完成并通过审计，权威目录为`16QAM_Polar/v2/results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/`。8—20 dB主要仍在高误码区，下一步改为20—32 dB短pilot定位瀑布区；正式长仿真需在pilot后预登记预算并取得用户授权。Rule reflection: no new durable rule
- **2026-06-28**：按用户反馈加宽 B4a SNR 范围。脚本 full 默认 SNR 改为 `0:2:20`，默认 smoke 改为 `0:5:20`；重新运行 smoke 输出 `16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/`，B4 文档图片和分析已切换到新结果。Rule reflection: no new durable rule
- **2026-06-28**：补充 B4a smoke 图和图片分析；`CLAUDE.md` 新增测试/验证结果写入阶段文档时应尽量附关键图片和图片分析的规则。Rule reflection: added/updated `CLAUDE.md` because result documentation should include figures and figure analysis for readability.
- **2026-06-28**：B4a 分组块 full-chain 策略验证完成 smoke。结果目录 `16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/`；脚本修复 adaptive batch 重复 seed 风险；新增 `周报/阶段B/B4：full-chain策略验证.md`；阶段总纲已更新。下一步进入 B4b 严格 OFDM Rayleigh smoke 或 B5 论文二初稿。Rule reflection: no new durable rule
