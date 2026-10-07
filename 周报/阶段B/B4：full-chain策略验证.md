# B4：full-chain 策略验证

> 所属阶段：阶段 B 多载波系统构建  
> 当前任务：以B4a分组块近似为前置，完成B4b严格OFDM-Rayleigh full-chain及正式统计  
> 当前状态：B4a与B4b smoke均已完成；B4b正式长仿真尚未运行  
> 阶段边界：B4b首版为high/mid/low三组独立polar块映射到真实子载波，不是64套逐子载波独立polar码

B4 的作用是把 B3 的 proxy 策略比较推进到包含 BER / Goodput / Energy 的 full-chain 验证口径。为避免一次性实现过重，本阶段拆成两步：

1. B4a：分组块 full-chain 验证。high/mid/low 三组分别用对应 `p` 的 full-chain block 结果加权汇总。
2. B4b：严格 OFDM Rayleigh full-chain。现已复用共享B1物理核心，在Rayleigh多径、CP、频域均衡和子载波策略下完成smoke，正式统计待执行。

---

## 1. B4a 目标

B4a 的目标不是证明逐子载波编码最优，而是先回答：

1. B3 的六类策略能否接入一个包含 BER / Goodput / Energy 的统一验证脚本；
2. 分组块口径下，策略间是否形成可观察的 Goodput-Energy tradeoff；
3. 结果目录、图表和 README 是否足够支撑 B5 论文二初稿的第一版材料。

当前脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_fullchain_strategy_validation.m
```

---

## 2. 分组块编码口径

B4a 的核心口径是：

```text
先对 p=0.5 / 0.3 / 0.1 分别跑 shaped polar 16QAM full-chain block
-> 生成每个 p 和 SNR 下的 BER / Goodput / rate
-> 生成 Rayleigh 多径 realization，并按 |H_k|^2 把 64 个子载波分成 high/mid/low
-> 按策略给 high/mid/low 分配 p 和是否承载信息
-> 按子载波数量、码率和能量 proxy 加权汇总
```

因此 B4a 仍是分组级近似验证。它不做：

1. 每个子载波独立 polar 编码；
2. 每个子载波独立 LLR / decoder 链路；
3. 严格 Rayleigh OFDM 时域多径卷积 + CP + 频域均衡下的逐子载波策略验证。

这些内容留给 B4b。

---

## 3. 策略定义

数据层保留六类策略：

| 策略 ID | high | mid | low | 信息子载波 |
| --- | --- | --- | --- | --- |
| `uniform_p05` | `p=0.5` | `p=0.5` | `p=0.5` | 全部 |
| `uniform_p03` | `p=0.3` | `p=0.3` | `p=0.3` | 全部 |
| `uniform_p01` | `p=0.1` | `p=0.1` | `p=0.1` | 全部 |
| `good_channel_information` | `p=0.5` | `p=0.3` | `p=0.1` | 全部 |
| `good_channel_energy_shaping` | `p=0.1` | `p=0.3` | `p=0.5` | 全部 |
| `bad_channel_energy_only` | `p=0.5` | `p=0.3` | `p=0.1` | low 组不承载信息 |

图例中显示为普通文本，例如 `good channel information`，避免 MATLAB 把下划线渲染成下标。

---

## 4. 参数与输出

full-paper 默认参数保留在脚本内，但默认运行模式为 `smoke`。

| 参数 | full 默认 | smoke 本次值 |
| --- | ---: | ---: |
| `n_subcarriers` | 64 | 64 |
| `cp_ratio` | 1/4 | 1/4 |
| `channel_taps` | 16 | 16 |
| `snr_grid` | `0:2:20` | `[0 5 10 15 20]` |
| `num_realizations` | 50 | 2 |
| `seed_list` | `1:5` | `1` |
| `min_frames` | 100 | 5 |
| `max_frames` | 1000 | 10 |
| `target_errors` | 200 | 5 |

本次 smoke 结果目录：

```text
16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/
```

输出文件：

```text
b4_p_block_results.csv
b4_strategy_realization_results.csv
b4_strategy_summary.csv
b4_fullchain_strategy_validation.mat
README.txt
run_log.txt
figures/b4_ber_vs_snr.png/pdf/fig
figures/b4_goodput_vs_snr.png/pdf/fig
figures/b4_goodput_energy_pareto.png/pdf/fig
```

---

## 5. 本次修正与验证

### 5.1 重复 seed 风险修正

原脚本在 adaptive batch 循环中，同一个 `(p, snr, seed)` 的多个 batch 复用同一个 `cfg_run.seed`，存在重复随机流风险。

已修正为每个 batch 使用可复现的派生 seed：

```text
batch_seed = base_seed + 10000*p_index + 100*snr_index + batch_index
```

影响范围：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_fullchain_strategy_validation.m
```

### 5.2 环境检查

执行命令：

```text
matlab -batch "cd('16QAM_Polar/v2'); setup_paths; check_env"
```

结果：MATLAB 9.9 环境自检通过，`qammod/qamdemod/de2bi/bi2de/bitrevorder` 均 PASS。

### 5.3 B4a smoke

执行命令：

```text
matlab -batch "cd('16QAM_Polar/v2'); setup_paths; run('experiments/multicarrier/run_b4_fullchain_strategy_validation.m');"
```

结果：exit 0，结果目录为：

```text
16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/
```

smoke 摘要表包含六类策略和五个 SNR 点。由于 smoke 仅 `num_realizations=2`、`seed_list=1`、每个 p/SNR 只用 5 帧，CI 和排序不具备统计解释力。

### 5.4 B4a smoke 图与图片分析

BER 曲线：

![B4 grouped full-chain BER](../../16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/figures/b4_ber_vs_snr.png)

图片分析：该图显示六类策略在 smoke 的 `0/5/10/15/20 dB` 五个点上均成功生成 BER 输出，说明 B4a 的策略聚合、summary 表和绘图链路已经闭环。低 SNR 附近 BER 接近随机判决，高 SNR 端明显下降，宽 SNR 视野比原先 `8/10 dB` 两点更适合检查趋势形态。但由于每个 p/SNR 只有 5 帧、Rayleigh realization 只有 2 次，曲线仍只能用于检查量级和输出形态，不能据此判断稳定排序或曲线交叉。

CP 修正 Goodput 曲线：

![B4 grouped full-chain Goodput](../../16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/figures/b4_goodput_vs_snr.png)

图片分析：该图验证了每类策略都能输出 CP 修正 Goodput per resource，且五个 SNR 点的 Goodput 可随 BER 变化联动。当前 smoke 中，高 SNR 端 `uniform p=0.5` 的 Goodput 抬升更明显，符合阶段 A/B1 中“高 SNR 下码率上限更重要”的直觉；中低 SNR 下不同整形策略仍有交错。由于统计量很轻，这些现象只能作为后续 full mode 或 B4b 的检查线索，不能写成论文级结论。

Goodput-Energy Pareto smoke 图：

![B4 grouped full-chain Goodput-Energy Pareto](../../16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/figures/b4_goodput_energy_pareto.png)

图片分析：该图把 `20 dB` smoke 点的 CP 修正 Goodput 与接收侧能量 RMS proxy 放在同一坐标中，便于观察策略间的数能折中形态。当前图中可以看到高 Goodput、低能量和高能量策略之间的分离，但由于统计量极轻，当前只能作为图表模板和链路验收图，不作为最终 Pareto 前沿。

---

## 6. 当前可写结论与不可写结论

当前可以写：

1. B4a 分组块 full-chain 验证脚本已经跑通；
2. 六类 B3 策略已接入统一 BER / CP 修正 Goodput / 接收侧能量 proxy / 信息子载波占比输出；
3. smoke 结果证明输出链路、图表和 README 结构可用；
4. B4a 的结果只能作为分组近似验证，不替代严格逐子载波 OFDM Rayleigh full-chain。

当前不能写：

1. 不能声称任何策略是阶段 B 最优；
2. 不能从本次 smoke 的五点 smoke 结果推断稳定曲线交叉或 Pareto 前沿；
3. 不能把 B4a 结果表述为逐子载波 polar 编码结果；
4. 不能把 B4a 结果表述为严格 Rayleigh OFDM 时域链路验证。

---

## 7. B4b严格OFDM-Rayleigh smoke

B4b入口：

```text
16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
```

已实现：

1. 抽取`ofdm_channel_roundtrip.m`，B1与B4b共用IFFT/CP/信道/AWGN/FFT/ZF物理核心；
2. high/mid/low各使用独立`N=1024` polar块，映射到共同64子载波、49个OFDM符号的帧；
3. 16-tap Rayleigh、CP=16、逐子载波均衡后噪声方差LLR与SC译码闭环；
4. 六策略使用公共信道与噪声；纯能量low组发送真实`p=0.1`波形且payload为0；
5. Goodput计入完整资源网格、2.0408% padding及CP；主能量指标为加噪前接收时域均方。

权威结果：

```text
16QAM_Polar/v2/results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/
```

参数为`SNR=[8,14,20] dB`、2个Rayleigh realization、每点1帧、六策略；计算4.42秒。审计覆盖36条重复记录、18条汇总记录、128条信道记录、36对START/DONE以及四图三格式，全部PASS。两次默认smoke的repetition与summary CSV SHA256一致，说明固定seed下可复现。

### 7.1 BER

![B4b strict OFDM-Rayleigh BER](../../16QAM_Polar/v2/results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/figures/b4b_ber_vs_snr.png)

图片分析：六策略均经过真实OFDM-Rayleigh/polar链路并产出有限BER，证明维度、均衡方差LLR和译码接口闭环。但8—20 dB处BER多数仍在0.14—0.49，主要属于高误码区；曲线仅适合发现异常和定位下一轮SNR，不支持排序。

### 7.2 CP/padding修正Goodput

![B4b strict OFDM-Rayleigh Goodput](../../16QAM_Polar/v2/results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/figures/b4b_goodput_vs_snr.png)

图片分析：Goodput随实际信息位数和BER联动，分母包括49×64个资源元素、padding和CP。图能验证纯能量组零payload与资源占用的统计口径，不能用2个realization判断策略优劣。

### 7.3 接收侧主能量代理

![B4b strict OFDM-Rayleigh receive energy](../../16QAM_Polar/v2/results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/figures/b4b_rx_energy_vs_snr.png)

图片分析：该图展示Rayleigh卷积后、加AWGN前的接收时域均方，能排除噪声项对主能量比较的污染；含噪接收功率与发送端QAM/OFDM功率另存作诊断。它仍是能量代理量，不是RF—DC整流效率。

### 7.4 20 dB tradeoff模板

![B4b strict OFDM-Rayleigh smoke tradeoff](../../16QAM_Polar/v2/results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/figures/b4b_goodput_energy_smoke.png)

图片分析：20 dB处已形成Goodput—接收能量散点模板，但样本量过小、误码率仍偏高，不能称Pareto前沿。下一步应先在20—32 dB做短pilot定位有效瀑布区。

---

## 8. 下一步边界

两轮受限pilot已经完成：`[20,24,28,32] dB`（20.4秒）与`[32,36,40] dB`（15.3秒），各为5个realization、每点2帧。普通策略在24—40 dB覆盖约`10^-1—10^-3/10^-4`；纯能量策略在20—24 dB处于有效区，28 dB以上出现聚合零错。零错值保留在CSV，但不进入对数图；正式统计必须报告上界。

![B4b high-SNR pilot BER](../../16QAM_Polar/v2/results/20260917_194950_b4_strict_ofdm_rayleigh_pilot_high_snr/figures/b4b_ber_vs_snr.png)

图片分析：该图已用对数轴展示高SNR pilot；普通策略由32 dB的约`10^-2`继续下降到40 dB的约`10^-3`量级，说明40 dB足以覆盖正式曲线的低BER端。纯能量策略的零错点被刻意不画入对数曲线，避免把有限样本零错误解为理论零BER。此图仅用于网格选择，不用于策略最优性判断。

因此正式预登记为`[20,24,28,32,36,40] dB × 30 realizations`，每点最少5帧、目标200错误、最多50帧，并以公共信道/噪声进行配对比较。入口现已加入checkpoint/resume、partial CSV和零错上界；长跑约8—110分钟，仍需另行授权。

---

## 9. 变更记录

- **2026-09-17**：完成28 dB保护带第三批独立测试。新规则预登记为20/24 dB使用`uniform_p05`、28—40 dB使用`uniform_p01`；`seed=2042`的30个全新Rayleigh实现正式目录`20260917_223848_b4b_guardband_policy_test`含360条重复记录，耗时503.3秒并审计PASS。分析目录`20260917_225122_b4b_guardband_policy_test_analysis`审计与研究结论均PASS；28 dB最弱点BER上95%=0.0760、Goodput下95%=0.2659，28—40 dB能量增量约0.0066。第一批24 dB失败仍保留为保护带设计依据。Rule reflection: no new durable rule
- **2026-09-17**：完成冻结码本独立验证。为正式入口增加受白名单与去重校验的`strategy_names`子集覆盖，默认六策略不变；控制路径`20260917_220955_b4b_fixed_policy_control`审计PASS。按用户授权以`seed=1042`运行30个全新Rayleigh实现、六个SNR、两策略、5—50帧/200错误，结果`20260917_221105_b4b_fixed_policy_holdout`共360条重复记录，耗时661.7秒并通过正式审计。冻结策略分析`20260917_222439_b4b_fixed_policy_holdout_analysis`审计PASS但研究状态PARTIAL：20 dB回退正确，28—40 dB通过，24 dB的BER上95%=0.1060超过0.1门限；未使用验证集重新调参。新增`周报/阶段B/B5：论文二初稿.md`。Rule reflection: no new durable rule
- **2026-09-17**：完成正式结果配对统计与低复杂度约束码本，结果目录`20260917_215938_b4b_paired_policy_analysis`。以同一SNR/realization的`uniform_p05`为参考生成90条BER/Goodput/接收能量配对差值及方向检验；生成36条带区间汇总、逐SNR三目标非支配点和6条策略选择。默认门限为BER上区间`<=0.1`、Goodput下区间`>=0.25`，可行后最大化接收能量，无可行项回退最大Goodput；结果为20 dB选`uniform_p05`，24—40 dB选`uniform_p01`。在线复杂度为`O(Nsc log Nsc)+O(6)`，码本信令3 bit。`checkcode`、共享OFDM核心测试、正式结果审计、配对码本审计、Markdown公式检查和图像复核全部通过；RKS=92.5 PASS。新增`学习文档/多载波OFDM瑞利信道-loop/中期PPT材料.md`逐图解释正式结果。该码本由同一正式数据设计并回看，不写成独立泛化证明。测试质量复核确认审计器会验证配对键、差值恒等式和选择规则；简化复核未发现值得冒险的行为保持修改。Rule reflection: no new durable rule
- **2026-09-17**：在用户正式授权后完成B4b严格OFDM-Rayleigh正式统计，目录为`16QAM_Polar/v2/results/20260917_210504_b4_strict_ofdm_rayleigh_formal/`，总耗时1850.2秒。预登记网格为`[20,24,28,32,36,40] dB × 30`个公共Rayleigh实现 × 6策略；每重复最少5帧、目标200错误、最多50帧，形成1080条重复记录、36条汇总、通道账本与四类PNG/PDF/FIG。独立审计PASS。纯能量策略在28 dB以上出现累计零错，但CSV记录95%上界`5.0256e-7`，不将其写为理论零BER；普通策略的最终排序仍待基于原始配对重复表计算差值区间。Rule reflection: no new durable rule
- **2026-09-17**：完成B4b正式统计入口的受限实现与回归。`formal`必须显式传入`formal_authorized=true`，否则拒绝；已支持每完成一个重复就写`b4b_repetition_partial.csv`、通过`resume_dir`跳过已完成键、每重复5—50帧且目标200错误的自适应停止。新高SNR pilot目录`20260917_205527_b4_strict_ofdm_rayleigh_pilot_high_snr_formal_ready`验证了重构后的循环、审计和零错95%上界：纯能量策略32/36/40 dB的累计零错上界均为`7.5383e-5`，不写成BER=0。实际formal尚未运行。Rule reflection: no new durable rule
- **2026-09-17**：完成formal控制路径验证（非正式统计）：`1 SNR × 1 realization × 1帧 × 6策略`在`20260917_205835_b4_strict_ofdm_rayleigh_formal_controlpath_test`写入6条partial记录；以同一`resume_dir`重启后六个键全部SKIP，审计PASS。它只验证授权开关、checkpoint/resume与产物结构，不是30 realization正式数据。Rule reflection: no new durable rule
- **2026-09-17**：完成两轮B4b瀑布区pilot，并修复BER图对数轴。为防止误启动长跑，`run_b4_strict_ofdm_rayleigh_validation.m`只允许有上限的`smoke`/`pilot`模式，拒绝`formal`；两轮目录为`20260917_194823_b4_strict_ofdm_rayleigh_pilot`与`20260917_194950_b4_strict_ofdm_rayleigh_pilot_high_snr`，均通过独立审计。图形复核发现MATLAB在先`hold on`后`semilogy`时保留线性轴，且零错点不能用于对数图；已改为零值`NaN`掩码和显式对数轴，复跑检查通过。pilot只用于选网格，不做策略排序。Rule reflection: no new durable rule
- **2026-09-17**：完成B4b严格OFDM-Rayleigh六策略smoke。新增共享物理核心、B4b入口、聚焦诊断和独立审计；B1回归复用共享核心。权威结果`20260917_112216_b4_strict_ofdm_rayleigh_smoke`包含CSV/MAT/README/run/progress日志和四类PNG/PDF/FIG，结构、恒等式、有限性、进度与信道分组审计全部PASS。smoke只关闭实现与轻量验证门禁，不支持策略排序；下一步先做高SNR短pilot。Rule reflection: no new durable rule
- **2026-06-28**：补充 B4a smoke 图与图片分析。本文档加入 BER、CP 修正 Goodput、Goodput-Energy Pareto 三张结果图，并在每张图下说明该图能支持链路验收和图表模板检查，但不能支持最终策略排序。同步在 `CLAUDE.md` 增加规则：测试、smoke、验证或实验结果写入阶段文档时，应尽量附关键图片和图片分析，说明图中能支持什么、不能支持什么。Rule reflection: added/updated `CLAUDE.md` because result documentation should include figures and figure analysis for readability.
- **2026-06-28**：按用户要求加宽 B4a smoke SNR 视野。`run_b4_fullchain_strategy_validation.m` 的 full 默认 SNR 从 `8:2:20` 改为 `0:2:20`，smoke 从前两个点改为 `0:5:20`；重新运行默认 smoke，结果目录为 `16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/`。图文分析已更新为五个 SNR 点，说明低 SNR 随机判决区、高 SNR Goodput 抬升和 Pareto 模板，但仍不做最终排序。Rule reflection: no new durable rule
- **2026-06-28**：完成 B4a 分组块 full-chain 验证脚本修正与 smoke。`run_b4_fullchain_strategy_validation.m` 修复 adaptive batch 重复 seed 风险，并在 README 明确 B4a 不是严格逐子载波 OFDM polar 编码；MATLAB `check_env` 通过，默认 smoke 运行成功，结果目录为 `16QAM_Polar/v2/results/20260628_143653_b4_fullchain_strategy_validation_smoke/`。本次仅验证链路和输出，不写最终策略排序；B4b 严格 OFDM Rayleigh full-chain 留作下一步增强。Rule reflection: no new durable rule
