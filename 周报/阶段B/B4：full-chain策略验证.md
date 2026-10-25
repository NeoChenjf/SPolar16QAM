# B4：full-chain 策略验证

> 所属阶段：阶段 B 多载波系统构建  
> 当前任务：B4a/B4b full-chain策略验证已完成；当前补做整形机制审计与等功率比较前置
> 当前状态：B4a/B4b正式统计和独立验证已完成；2026-10新增整形机制审计，P0 smoke回环通过，PMF与等功率扩展尚未进入正式统计
> 阶段边界：B4b首版为high/mid/low三组独立polar块映射到真实子载波，不是64套逐子载波独立polar码

B4 的作用是把 B3 的 proxy 策略比较推进到包含 BER / Goodput / Energy 的 full-chain 验证口径。该正式统计与独立验证已完成；当前追加的工作用于核实整形机制和等功率比较的前置条件：

1. B4a：分组块 full-chain 验证。high/mid/low 三组分别用对应 `p` 的 full-chain block 结果加权汇总。
2. B4b：严格 OFDM Rayleigh full-chain。已复用共享B1物理核心，并完成正式统计、配对分析和固定策略独立验证；本轮不重复长跑。

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

## P0整形机制审计（2026-10-08）

新增入口[run_b4b_shaping_audit.m](../../16QAM_Polar/v2/experiments/multicarrier/run_b4b_shaping_audit.m)，保留原B4b入口与历史正式数据。static覆盖全零、全一和随机payload（2个seed）；smoke对$p=0.5/0.3/0.1$的旧固定整形位与payload条件化版本各运行8帧×2 seed，并记录S/I/F、无噪声信息位回环、逐帧星座原始计数、四bit边缘率和联合PMF。

权威smoke目录：`16QAM_Polar/v2/results/20261008_213557_b4b_shaping_audit_smoke/`，耗时4.16秒。96个码字信息位无噪声错误均为0；两版本payload指纹配对断言通过；分区表12行，CSV/MAT/README/run log及PNG/PDF图齐全。PMF区间仅是smoke诊断，不是正式门禁。

smoke显示独立bit边缘概率乘积模型与经验联合PMF存在明显差异：$p=0.3$时TV约0.115（旧版）/0.138（条件化）；$p=0.1$时约0.188（两版相同）。实际bit2/bit4边缘率分别约0.399/0.401及0.249/0.255，与请求$p$不符。payload极值探针中$p=0.3$的S位汉明距离为121，$p=0.1$为0。以上只能定位为“目标模型/有限长构造待查”，不能仅凭smoke断言B4b编码错误；P1等功率策略性能统计暂缓。

图示：![B4b整形审计smoke PMF](../../16QAM_Polar/v2/results/20261008_213557_b4b_shaping_audit_smoke/figures/pmf_by_variant.png)

下一步先核验Gray标签映射与bit边缘目标定义，再对照B4b GA分区和v3 source-MC+GA分区，解释PMF偏差后决定是否运行`pmf`规模。该默认规模为每$p$/版本3 seed×80帧、2000次簇bootstrap；其长跑尚未启动。P1约定已记录为含CP/padding的平均发射时域功率、每策略单一冻结缩放和固定物理噪声，但尚无策略等功率结果。

验证包括MATLAB `checkcode`（仅剩代码分析器旧消息）、static与smoke实际运行、结果表复核。简化复核删除未使用参数，审查确认随机数按seed重置且旧版/条件化版配对。故障记录同步见`workbook/troubleshooting-history.md`。Rule reflection: no new durable rule

## N=256/1024有限码长对照（2026-10-08）

用户提出有限码长可能解释请求$p$与经验分布的差距。为直接检验B4实现，扩展原审计入口的`blocklength`模式，保持B4的GA分区、ceil码率、固定/消息条件化编码、Gray映射和PMF统计不变，仅比较`N=256/1024`。每个码长对每个$p$/版本使用3个seed×20帧，按完整码字簇bootstrap 2000次；每个结果的无噪声信息位错误均为0。命令分别为：

```powershell
.\scripts\run_matlab_local.ps1 "b4b_audit_overrides=struct('mode','blocklength','N',256,'frames_per_seed',20,'seed_values',[1701,2903,4127]); run('experiments/multicarrier/run_b4b_shaping_audit.m')"
.\scripts\run_matlab_local.ps1 "b4b_audit_overrides=struct('mode','blocklength','N',1024,'frames_per_seed',20,'seed_values',[1701,2903,4127]); run('experiments/multicarrier/run_b4b_shaping_audit.m')"
```

结果目录分别为`20261008_215852_b4b_shaping_audit_blocklength_N256`和`20261008_215552_b4b_shaping_audit_blocklength_N1024`。每个p/版本每个N均有60个整码字簇，TV上界来自2000次cluster bootstrap：

| N | p | 版本 | TV点估计 | TV单侧95%上界 | bit2=1 | bit4=1 |
|---:|---:|---|---:|---:|---:|---:|
| 256 | 0.3 | 固定整形位 | 0.10655 | 0.11499 | 0.4010 | 0.3887 |
| 256 | 0.3 | 消息条件化 | 0.12249 | 0.13173 | 0.3979 | 0.3993 |
| 256 | 0.1 | 两版本相同 | 0.18500 | 0.19027 | 0.2501 | 0.2510 |
| 1024 | 0.3 | 固定整形位 | 0.11207 | 0.11542 | 0.3971 | 0.4012 |
| 1024 | 0.3 | 消息条件化 | 0.13985 | 0.14739 | 0.4052 | 0.4139 |
| 1024 | 0.1 | 两版本相同 | 0.18498 | 0.18778 | 0.2485 | 0.2505 |

p=0.3时经验bit2/bit4在两个码长都明显高于请求边缘率0.3；p=0.1时也都明显高于0.1。TV跨码长没有稳定下降，相应95% bootstrap上界均远高于0.05。

因此，有限码长可能造成误差，但当前B4构造下N从256增至1024并未显示主要边缘偏差随码长缩小，不能把当前差距主要归因于有限码长。该有限区间对照也不能证明N趋于无穷时不收敛。既有v3能量λ码长比较采用source-MC+GA及不同目标分布，可作为另一套构造的有限长证据，不能替代本B4同构造对照。下一步先检查B4 GA分区与source-MC+GA分区、请求p的映射定义，再决定正式PMF门禁预算。

码长对照中发现逐帧bit边缘率分母原写死为1024，已改用实际N；N=256数据已在修复后重跑，星座计数推导的TV不受此字段问题影响。故障记录见`workbook/troubleshooting-history.md`。Rule reflection: no new durable rule

## 冻结位取值敏感性（2026-10-08）

用户指出理论PMF可能按随机化非信息位（含F）推导，而工程实现通常把F固定为0。这个差异在理论上成立：参考MLHY/Honda–Yamamoto表述中，非消息位按前序位条件分布随机生成，随机性需发送接收双方共享；同一研究的短码实用版本则允许将高条件熵位确定为0、将低条件熵整形位按MAP规则决定。因此“理论随机化集合平均”与“F恒为零的确定性短码实现”要分开讨论。[参考文献](https://arxiv.org/pdf/2202.04010)

在原审计入口增加`frozen_compare`，用同一N=1024、B4 GA分区、消息条件化SC整形位、payload和映射，只比较F全0与F逐位iid Bernoulli(0.5)。随机F在发送端用于重新计算S，接收端假设已知同一F；旁信息开销未计，因此这只是分布敏感性诊断，不是可部署策略。每个p/版本3 seed×20码字，配对payload指纹断言通过，全部无噪声信息位错误为0。结果目录：`16QAM_Polar/v2/results/20261008_230215_b4b_shaping_audit_frozen_compare_N1024/`。

| p | F全0：TV点值（上95%） | F随机：TV点值（上95%） | 经验bit2/bit4：F全0 → F随机 |
|---:|---:|---:|---:|
| 0.5 | 0.00791（0.01494） | 0.00513（0.01073） | 0.502/0.499 → 0.503/0.498 |
| 0.3 | 0.13985（0.14739） | 0.19190（0.19596） | 0.405/0.414 → 0.455/0.455 |
| 0.1 | 0.18498（0.18778） | 0.18396（0.18606） | 0.249/0.251 → 0.249/0.250 |

单独把F改成均匀随机会显著改变p=0.3下的分布，方向是更偏离当前目标；p=0.1几乎没有变化。因此冻结值因素确实影响分布，但不足以单独解释差距。更重要的是，这个对照仍保留确定性MAP整形位，并用iid均匀近似F；理论参考通常是**所有非信息位按前序的源条件概率抽样**，而且B4 GA排序也未必把F选成源意义上的高熵位。下一步应比较完整随机SC参考、确定性F=0短码方案以及source-MC+GA分区，之后再判断哪些PMF公式适用于当前实现。

本诊断没有通过正式PMF门禁，也没有运行等功率或Rayleigh策略比较。L2契约、loop协调协议、next_plan和B5材料已同步。Rule reflection: no new durable rule


## 2026-10-08：精确源概率与集合定位

阅读入口：[整形分布偏差定位结论](../../学习文档/多载波OFDM瑞利信道-loop/整形分布偏差定位结论.md)。本轮核心判断：B4 GA集合缺少源低/高条件熵约束，是当前主要PMF偏差来源；不能将偏差全部归因于码长或F=0。

- 复用v3 forced-SC，增加可选精确f节点及显式uniforms条件抽样；默认min-sum硬判决保持不变。复用source-MC构造，增加可选SC概率口径；审计侧保留B4 ceil K。
- 新增`run_b4b_source_partition_audit.m`，N1024、p=0.3/0.1、3seed×80源码字，4.01秒。B4的I平均源条件熵约0.900/0.425，源熵集合约0.980/0.941。
- B4原集合source_compare：每p/配置3seed×20帧，540码字，28.80秒。精确MAP/F0 TV为0.1251/0.1850，精确条件随机非I位为0.1879/0.3174。
- 独立构造seed9001、200源码字后，同样payload和K，仅更换集合：保留原min-sum MAP/F0，p=0.3 TV由0.13985降为0.01149（上界0.01608）；p=0.1由0.18498降为0.02574（上界0.02733）。全部无噪声I恢复错误0。
- 运行目录：`20261008_233858_b4b_shaping_audit_source_compare`、`20261008_234728_b4b_source_partition_audit`、`20261008_235247_b4b_shaping_audit_source_compare_source_MC_GA`（均在v2/results）。运行入口是Windows `scripts/run_matlab_local.ps1`；source_compare覆写N1024、20frames、seeds[1701,2903,4127]，第二组另设partition=source_MC_GA。
- 精确源LLR通过N2/4所有前缀直接枚举似然断言（容差1e-10）；新旧默认配置B4基线数值吻合。测试质量检查为本上下文审查：独立枚举oracle可检测f/g和索引错误；PMF与熵估计不当作正确性证明。
- 三配置扩展暴露汇总/画图仍假定两个版本的问题，已改为动态版本数/三条样式；首个失败目录保留原始计数，第二个目录保存统计后补画图，未重复第三轮仿真。修复见故障历史#25。
- 审查与简化：本上下文缺陷审查；复用SC/源MC/既有PMF统计，未新建独立Polar算法。已知限制：精确模式契约为有限源LLR；源熵表为同估计描述性比较；随机F旁信息未计，不能直接部署。正式80帧/seed门禁未运行，未修改config.m及正式B4b入口。

![源熵集合](../../16QAM_Polar/v2/results/20261008_234728_b4b_source_partition_audit/source_entropy.png)

S低熵、I高熵的结构在源集合下明显改善；独立PMF对照进一步支持集合构造定位。

Rule reflection: no new durable rule

最终核对：跨分区540条payload四路指纹配对及无噪声错误为0通过；公式分隔符/控制字符检查通过；知识库跨层61/61可解析，RKS92.5。

## 2026-10-09 B4新构造状态修订

B4整形位集合不再取通信GA排序前缀。新版本固定码率和$|S|$，用源条件熵选择S，再按各信道/SNR的通信GA对剩余位置选择I/F；接收端当前仍沿用既有SC接收度量，本轮不把新增先验译码混入构造比较。

独立源条件熵holdout、N=256/1024的经验PMF/能量对照和N=1024 PMF正式门禁通过，图与原始结果见学习文档清单。OFDM正式性能网格pilot、六策略重建、低复杂度规则重训以及seed1042/2042独立验证尚未完成；此前保护带策略只作为旧版本记录。


## 2026-10-09 纯能量基线语义修正（待smoke验收）

代码审计发现，旧版bad_channel_energy_only虽然把low组排除在BER/Goodput分母外，却仍为该组随机生成信息位并发射，故旧图中的“纯能量”名称与载荷不一致。新版本仅对low组固定零payload，仍使用该组p=.1、原S/I/F构造和消息条件化整形；该组不计为信息子载波。加入零payload断言后再进行B4 pilot/正式运行。历史B4数据保留，但只代表旧定义，不能与修正版本直接合并或作同一baseline结论。


Rule reflection: added/updated [workbook/quality-assurance.md] to require checking strategy payload semantics separately from BER/Goodput metric masks; this prevents calling a randomly modulated group “pure energy-only.”

## 2026-10-09 20:35 Asia/Shanghai：B4新构造pilot网格冻结与正式训练启动

新构造pilot的独立验收通过，结果目录为16QAM_Polar/v2/results/20261009_202719_b4_source_entropy_strict_pilot，冻结记录及SHA-256位于该目录的PILOT_GRID_FREEZE.txt。pilot为seed42、5个Rayleigh realization、每策略/点2帧，SNR标签[20,28,36,40] dB；独立验证检查120条重复记录、行键、指标和START/DONE日志通过。正式训练网格冻结为[20,24,28,32,36,40] dB，保留24/32 dB解析瀑布过渡。正式训练启动参数为seed42、30个realization、6策略、每点最少5帧、目标200错误、最多50帧。pilot仅用于选网格，不参与阈值或策略选择。

本次低组纯能量策略的载荷语义已在smoke及pilot逐行核验：低组payload one计数均为0。pilot中低组在部分SNR观测到零错误只表示有限样本结果，不证明BER为零。新正式图与策略结论仍待完整训练、独立验证及统计/视觉审查。

## 2026-10-09 新构造B4正式统计与独立验证

正式训练：`16QAM_Polar/v2/results/20261009_203109_b4_source_entropy_formal/`，seed42、30个Rayleigh realization、SNR标签[20,24,28,32,36,40] dB、六策略、每重复至少5帧、达到200个错误则停、最多50帧。训练重复表1080行、汇总36行、信道表1920行；唯一键、START/DONE、rate/Goodput/padding恒等式、信息子载波比例、逐组payload计数与图审计通过，low组纯能量策略payload one总数为0。正式输出为F10–F15。

训练策略由训练集独立生成：一般最大能量码本在20/24 dB按预定规则回退到最大Goodput的uniform_p05，28–40 dB选uniform_p01。保护带候选在未查看验证集前冻结（训练BER上界≤.08、Goodput下界≥.27，优先最大接收能量；无可行项时最大Goodput回退）。

一般码本的独立验证seed1042目录为`results/20261009_211124_b4_source_entropy_holdout1042/`，分析`results/20261009_223148_b4b_fixed_policy_holdout_analysis/`：28/32/36/40 dB通过原BER上界≤.10和Goodput下界≥.25；20/24 dB是训练时已标注的最大Goodput回退，不算通信门槛通过。符合门槛点的接收能量代理相对uniform_p05为正，幅度约0.0096绝对功率单位（须注意该数据不是等功率实验）。

保护带候选seed2042独立验证目录为`results/20261009_223251_b4_source_entropy_guardband2042/`，分析`results/20261009_230741_b4b_guardband_policy_test_analysis/`：28–40 dB均通过原BER/Goodput门槛；低SNR的20/24仍按预注册规则回退最大Goodput，未声称通过约束。逐SNR策略为28 dB good_channel_information、32 dB good_channel_energy_shaping、36/40 dB uniform_p01；接收RF均方代理相对uniform_p05差值约0.00224/0.00833/0.01063/0.01063。seed2042未参与冻结，结果未用于调参。

边界：三批图均沿用原信道、功率、噪声、Goodput资源分母，用于隔离构造变化。接收能量是加噪前时域均方代理，不等于整流器直流输出；当前策略间发射符号功率不同，也不证明等功率收益。独立样本只支持这套信道/门槛/候选策略的有限验证，不代表任意单次CSI保证。保护带候选通过不意味着整个研究目标完成。

图索引：训练F10–F15位于`20261009_210714_b4b_source_entropy_training_policy_analysis/figures/`；一般码本F16/F17位于`20261009_223148_b4b_fixed_policy_holdout_analysis/figures/`；保护带F18位于`20261009_230741_b4b_guardband_policy_test_analysis/figures/`。各图有PNG/PDF/FIG，数值CSV与MAT同目录。

## 2026-10-09 新构造正式验证收束追加

本轮固定原K与S数量，源条件熵选S、剩余位置逐SNR按GA选I/F，并逐帧按当前payload与F=0进行消息条件化整形。完成30信道训练seed42，以及冻结规则后的独立seed1042和预先冻结保护带后的seed2042；三套结果均通过`verify_b4b_strict_smoke`严格数据审计，各1080重复、36汇总、1920信道记录，49个OFDM符号、padding 0.020408。主要图组F10–F18已重新分析并保存PNG/PDF/FIG。

训练策略在28–40 dB独立验证点通过登记的BER上界≤0.10、Goodput下界≥0.25门槛；20/24 dB为训练集max-Goodput回退，不计作通信门槛通过。seed2042保护带候选在28/32/36/40 dB通过相同门槛。接收能量是加噪前RF时域均方代理，且各策略发射功率仍有差别，因此本结果不证明等功率优势或直流收能增益。

源熵集合和新旧构造图、PMF门禁、码长对照、单载波正式图及F19模型偏差边界均汇总在`学习文档/整形理论更新与仿真图重建清单.md`末尾最终快照。RKS报告`workbook/knowledge/reports/rks-20261009_232031.md`为92.5 PASS；跨层完整性和理论护栏均100%，假设覆盖为62.5%（10/16），作为后续知识库补强项记录。Markdown基线前缀检查通过。

Rule reflection: added/updated `workbook/mandatory-rules.md` because the user requested repository-wide append-only documentation; the scope clarification prevents historical research claims and checklist states from being silently rewritten.

### 最终复核追加 — 2026-10-09

知识库重跑RKS结果为`workbook/knowledge/reports/rks-20261009_232420.md`，得分92.5 PASS；跨层引用82/82、理论护栏8/8。测试质量审查确认source partition合同测试断言针对可观察行为、随机种子固定且能在集合/无噪声恢复回归时失败；它不覆盖输入校验错误路径，此范围未被用作本轮验收主张。严格B4审计对三份正式数据均PASS。追加性检查、清单编号和所有PNG/PDF路径检查通过；`git diff --check`通过。简化复核未发现值得承担风险的行为保持型简化。


## 2026-10-10 追加：清单显示、读图边界与知识库治理复核

本轮未重跑正式仿真。新增阅读入口：学习文档/整形图重建当前验收状态.md、学习文档/新构造结果的边界与读图说明.md、学习文档/知识库与Harness治理缺口说明.md。原清单保留历史未勾选快照，追加真实任务列表的最新29项完成快照，避免表格中的[x]无法呈现复选框。交付完成不等于理论或硬件门禁全部通过。

复用独立验证原始数据补出F17逐信道图：results/20261010_201200_policy_channel_violation_audit/。一般码本seed1042在20/24/28/32/36/40 dB的联合满足数为0/3/21/28/29/30（每点30信道）；保护带seed2042为0/4/27/24/28/30。Wilson区间只描述有限帧经验阈值判定的比例，不能代替信道内误差区间；两seed不能当作配对比较。28—40 dB均值CI通过不构成逐信道保证，20/24 dB为不满足原通信门槛的回退。

纠正原知识库评分解释：35/35方法与6/6入口仅为当前扫描器有限枚举范围；理论护栏100%为关键词计分，不能声称全仓库护栏实际验证。六项未覆盖假设首先是证据关联缺口，不全部等同于六项新实验。扫描器未在本轮改动。

核验：补充图PNG/PDF存在；原始计数和信息位分母核对、每点30唯一信道、冻结策略复用；阅读文档路径与公式检查。未引入新的构造或策略调参。

Rule reflection: added/updated workbook/communication-documentation.md 与 workbook/quality-assurance.md：完整当前清单需使用真实任务列表；覆盖评分必须公开范围并区分文档引用、运行验证与科学证据。所有Markdown按末尾追加。


## 2026-10-11 等功率P1正式验证闭环

固定16QAM的B4等功率P1正式统计完成。正式输入目录：`16QAM_Polar/v2/results/20261010_220806_b4_equal_power_p1_formal/`；控制、校准和pilot目录：`16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/`；最终分析与图：该目录的`analysis_rerun_20261010_235754/`。首批错误噪声换算试跑已保留并标无效，不与新数据混算。

功率包括CP和padding；每策略仅一条冻结幅度系数。独立验证均值通过±1%门限，正式均值最大偏离目标约0.64%。seed3142共1260条唯一重复，30信道、七个SNR、每重复固定50帧。六策略共享配对信道、噪声和基础消息。SNR按目标时域发射功率/时域复噪声功率定义。

读图要点：BER、信息块BLER、Goodput和接收RF均方显示不同折中。24 dB好信道信息策略较uniform p=.5降低BER约0.02485，但Goodput降低约0.02984、接收RF均方降低约0.13337。32 dB好信道能量策略提升RF代理量约0.13474，同时BER上升约0.01038、Goodput下降约0.04524。95%配对区间见CSV和配对图；没有策略在三个维度全面支配均匀基线。结论限定于本候选集合、信道和协议。

零错误点显示有限样本Poisson单侧95%上界，不称作真实零BER/BLER。BLER为信息块错误率而非CRC包失败率；Goodput未扣CRC/协议开销；RF均方不等于DC输出。历史非等功率结果只作范围对照，不构成配对检验。30信道违反率和Wilson区间是描述性统计。

关键图：

![等功率校准与独立验证](../../16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261010_235754/figures/power_calibration_validation.png)
左侧为未缩放校准功率，右侧为冻结缩放后的独立验证，分开坐标轴避免把两者混为同一尺度。

![六策略BER-SNR](../../16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261010_235754/figures/ber.png)
纯能量策略高SNR零错误点绘为95%上界，不表示BER确定为零。

![六策略Goodput-SNR](../../16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261010_235754/figures/goodput.png)
均匀p=.5在中高SNR总体Goodput较高；信息与能量倾斜提供不同维度的折中。

![配对差值](../../16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261010_235754/figures/paired_differences.png)
正RF差代表更高接收RF代理量；正BER/负Goodput对应的利弊需结合轴标题理解。误差条按30信道簇bootstrap。

![候选Pareto点](../../16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261010_235754/figures/pareto_by_snr.png)
仅表示六策略候选内非支配点，不是全局最优。

![逐信道门槛比例](../../16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261010_235754/figures/channel_constraints.png)
BER≤0.1和Goodput≥0.25用于历史衔接，比例不是应用可靠性承诺。

Rule reflection (2026-10-11): 明确区分独立功率验证与正式测试集；报告拆分校准前原始功率与缩放后功率；限制RF均方、Goodput与BLER的解释边界。规则已写入P1契约和结果README。本轮无须新增全局规则。Markdown追加前缀检查和扫描器测试通过；知识库剩余覆盖差距记录于RKS报告。

## 2026-10-11 最终图表版式校正

最终结果图入口为`16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261011_002445/figures/`，由`LATEST_ANALYSIS_PATH.txt`指向。首版Pareto散点图中，跨SNR策略标签重叠；已按每个SNR拆分面板、隐藏逐点长标签，以黑色描边和尺寸标出六候选中的非支配点。更早版图保留为分析历史，不作为最终阅读入口。

![最终等功率候选Pareto图](../../16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261011_002445/figures/pareto_by_snr.png)
每个子图对应单独SNR；黑描边的大点是六策略候选中的非支配点。图只呈现候选集内关系。

## 2026-10-11 补充：验证功率逐seed门禁

从独立原始验证目录逐个重算每个seed×策略均值。seed7121、7122、7123的18个单元全部满足目标功率±1%，最大偏差0.62%；最终分析目录`analysis_rerun_20261011_002445/power_per_seed_audit.csv`保留校准原始均值、冻结尺度和独立验证观测。正式数据结果不变。


## 2026-10-24 P2实现中间状态：暂停新增对照，讨论冻结集合的分布

已执行：新增独立P2入口与局部配置，复用P1源熵模板；实现同K同I/原生基线、逐组功率、实际I驱动的近似预测、真实前序位诊断、两参数校准及测试隔离接口。`test_p2_mechanism`、`test_p2_resume_contract`、`test_b4_equal_power_scaling`已运行通过。正式预算未确认，未启动新正式长跑。

确定性发现：取消S并将其冻结为0时，原I不保证均匀输出。N=1024、16—40 dB七个构造点，源p=.3对应对照TV=0.10693359375，p=.1对应TV=0.43115234375；p=.5为0。证明采用生成矩阵在I上的列是否全零，N=4穷举与SC诊断已核对。此结论针对拟新增对照，不推翻原整形方案PMF证据。

证据：[生成矩阵审计](../../16QAM_Polar/v2/results/20261024_222326_p2_uniformity_exact/README.txt)、[精确分布图](../../16QAM_Polar/v2/results/20261024_222326_p2_uniformity_exact/uniformity_exact.png)、[短pilot](../../16QAM_Polar/v2/results/20261024_222219_p2_preflight/README.txt)。短pilot采用极小校准样本，功率门禁尚未通过，不能解释成正式策略收益或模型通过。当前候选模型在线速度亦尚未达到10倍使用门槛。

用户于本轮明确要求“先暂停新增对照，讨论这个理论问题”。因此不实现建议增加的同K/GA重选I对照，不推进正式实验。下一步先解释冻结位与线性码输出分布，再确定对照定义；之后补齐正式预算、完整文档台账与L1/L2/L3，不能把当前中间状态记为全计划完成。

PDF矢量输出因字体缓存写入限制失败，已提供图像PDF与原始FIG，记录在各分析目录pdf_export_notes.txt；PNG已检查。历史产物保留。原始校准表的零错误占位应按communication_measured=false排除，当前入口已修正为NaN，未以此作通信验收。

Rule reflection: no new durable rule。现有“实际PMF必须验证、文件存在不等于科研验收”规则已覆盖本次设计假设失效；未新增全局规则。当前为用户指定的研究讨论暂停点，完整元数据与交付审查仍待后续。


### 2026-10-24 理论讨论追加：随机辅助S的可行性

用户提出保留原S位置、令其承载不计入有效载荷的随机辅助位，并先观察整形时S的实际分布。只进行了生成矩阵只读核查，未实现或运行新的通信对照。N=1024、24 dB实际构造中，把I与S的并集作为独立公平随机输入、F仍为0，源p=.5/.3/.1三种集合的输出联合PMF理论TV均为0；四路各输出位置均不存在恒0位。此结论依赖四路输入独立且辅助位独立于当前消息，不能由S边缘概率单独推出。

当前SC接收端本来就把I与S都作为待判决位置、只对I计BER；因此随机辅助S候选可保持原S/I/F及接收掩码，不能沿用清空S的对照实现。有效载荷仍为K，但随机对照的实际输入自由度增加至K+|S|，报告必须说明它是机制对照而非同代码本大小的对照。

待讨论的另一候选为独立供体消息生成整形S向量，再与当前消息配对：保留S向量内部统计而打破其与当前消息的条件关系。尚未实现，不保证均匀PMF。每个S位置的边缘分布、S内部依赖、S与消息的耦合应分开描述；源条件低熵不意味着S每个位在跨消息统计中接近固定0。

Rule reflection: no new durable rule；延续暂停新增对照的用户要求。


## 2026-10-24 当前状态追加：辅助S方案恢复推进，正式预算待确认

用户已同意尝试独立随机S与独立供体S并继续原路径，取代前文“暂停新增对照”的中间状态。已完成独立P2实现、17配置短pilot、21组生成矩阵覆盖审计、3seed×8码字/S统计、原接收端回归与检查点/版本拒绝测试。源MC直接复用P1的200样本seed9001模板；未改共享config或旧正式结果。

随机S修复原S冻结0对照的非均匀问题：p=.3/.1实际24码字TV(均匀)=.00688/.00903，供体S为.04236/.31283。供体不是均匀目标。小校准尚未通过正式1%门禁；模型仅实现并完成合成/短训练smoke，未达独立精度或速度科研验收。冻结S旧对照只留诊断，不称GA错误或原整形PMF失败。

当前阅读入口：学习文档/等功率机制与P2当前结论.md；唯一任务入口：学习文档/等功率机制对照与P2执行清单.md；正式预算：学习文档/P2正式实验预算与执行顺序.md。首轮23job、414366帧，实测点估计18.8小时、建议预留23—30小时；具体批准前不启动。

本轮当前完成的是代码/理论诊断/材料准备。正式1%功率、3×80 PMF、单载波代表点、独立模型预测及正式图均未完成。P2之后才进入P3的27组合；P4非线性收能、CSI/削顶及P5 USRP、CRC/净吞吐/RF–DC标定仍开放。多QAM仅为外推支撑。

Rule reflection: added/updated workbook/quality-assurance.md，因为辅助S对照必须保留接收掩码、独立供体及有效载荷语义，并禁止把未测量通信记为零错误。所有Markdown采用追加；本上下文自审，不声称独立reviewer。源码自审/简化后最终检查另见清单最新快照。

Revision metadata: revision_id=p2_50c489765c24_20261024; current_status=current; supersedes=[baseline_p2_50c489765c24].


## 2026-10-25 P2准备阶段收尾

用户提出的随机辅助S与独立供体S已落实，原I/S/F和生产接收端保持。17项准备工作（含41文件台账、24方法/5流程契约、短pilot和源码/恢复测试）完成，8项正式/交接仍待本轮具体预算。最新清单与图片见学习文档/等功率机制对照与P2执行清单.md、等功率机制与P2当前结论.md。

正式提案为16QAM_Polar/v2/results/20261025_001500_p2_budget_proposal，23job/414366帧，实测点估计18.8小时，建议23—30小时；approved=false。当前源码已绑定最终协议，不启动正式长跑。随机S有21组覆盖证明和3×8诊断，供体不是均匀目标；两者均未获正式通信/RF收益结论。P2模型未获独立精度/速度验收，不能先给P3作可靠筛选。

最终验证：MATLAB机制/恢复/原缩放回归通过；RKS修订链解析21测试通过，当前源码与官方入口同哈希；Markdown原前缀、公式/图片路径及git diff检查通过。源码/测试审查及简化为本上下文自审。恢复路径采用临时checkpoint提交并重建CSV；其对应行为已实际测试。

Rule reflection: added/updated workbook/quality-assurance.md，原因是随机S辅助位、接收掩码及未测量通信必须有明确语义；补记RKS历史相同假设的严格修订链去重。模型、图像与文档交付不替代正式科研门禁。

Revision metadata: revision_id=p2_b4_preflight_closed_20261025; current_status=current; supersedes=[p2_50c489765c24_20261024].


## 2026-10-25 正式实验批准与启动

用户明确指令：“批准按该协议启动正式实验”。批准记录为16QAM_Polar/v2/results/20261025_011808_p2_approved_batch/approval.json，绑定协议SHA256 `3e030c9beb1557e62382d6a27165babdd40d6a88cdf4d4dc9508fe04a1f33962`；原提案及approved=false请求保留为历史，不作为当前批准状态。

本批于01:18（Asia/Shanghai）启动，当前执行ofdm_power_calibration_8101，已生成未缩放校准记录。按功率校准→独立功率验证→PMF门禁→单载波桥梁→模型校准→冻结模型→独立已见/未见测试→诊断与图表的依赖执行23个注册任务。若基础门禁失败即停止依赖阶段，未授权自动扩大80帧首轮预算。

新调度只安排已批准job，不改变协议中的方法、接收端或参数。调度源码另存orchestration_source并记录SHA256；正式方法仍由协议校验。实时状态16QAM_Polar/v2/results/20261025_011808_p2_approved_batch/status.json，事件日志events.log，每job独立日志和原始结果目录；中断可按同一批次恢复。尚未将任何功率/PMF/模型门禁标为通过。

相关入口：scripts/run_p2_approved_batch.py；p2_execute_batch_job.m；p2_batch_power_check.m。验证：Python语法通过，批准/协议/方法哈希一致，首job实际运行且产生数据。全部调度后续分支尚待实际执行，不宣称已通过。

Rule reflection: no new durable rule。沿用冻结预算、检查点、独立门禁及统计证据规则。本次仅确认启动，不表示正式研究完成。

Revision metadata: revision_id=p2_b4_approved_running_20261025; current_status=current; supersedes=[p2_b4_preflight_closed_20261025].


## 2026-10-25 当前状态更正：功率门禁失败，正式批次已停止

本段取代此前“正式运行中”的即时状态。注册批次01:18:21启动、03:39:41停止（Asia/Shanghai）；23job完成6个，83,520帧。三组校准和三组独立功率验证完成，但522个验证单元有206个至少一组功率偏差超过1%；总功率3单元超限，最大总偏差1.12635%、最大组偏差1.80612%。因此F02未通过，正式PMF/通信/模型测试未启动，不得把NaN通信指标当零错误。现有P1结果不因本次控制匹配失败而自动失效。

证据：`16QAM_Polar/v2/results/20261025_011808_p2_approved_batch/status.json`、`events.log`、`ofdm_power_check/power_gate.csv`。完整解释、图与产物目录见[阶段汇报](../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2阶段进度与写作交接-2026-10-25.md)。仅整理和追加文档，不修改实验源码、不启动补跑。先以已有raw数据诊断有限样本、SNR集合变化和功率口径，再提交具体追加预算；原授权不覆盖自动扩大预算。不放宽1%或改聚合方式追认通过。

Rule reflection: no new durable rule。沿用预登记门禁、原始证据及追加修订规则；本轮只读核查与文档交接，不把推测记为已确认缺陷。

Revision metadata: revision_id=p2_b4_gate_failed_20261025; current_status=current; supersedes=[p2_b4_approved_running_20261025].


## 2026-10-25 学习文档归档路径补充

本段仅更新阅读位置，原研究结论和历史路径文字保留。当前文档位置：

- [等功率机制对照与P2执行清单.md](../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制对照与P2执行清单.md)
- [等功率机制与P2当前结论.md](../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制与P2当前结论.md)
- [P2阶段进度与写作交接-2026-10-25.md](../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2阶段进度与写作交接-2026-10-25.md)
- [P2正式实验预算与执行顺序.md](../../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2正式实验预算与执行顺序.md)
- [新构造结果的边界与读图说明.md](../../学习文档/shaped_polar验证loop/理论更新与图重建/新构造结果的边界与读图说明.md)
- [整形理论更新与仿真图重建清单.md](../../学习文档/shaped_polar验证loop/理论更新与图重建/整形理论更新与仿真图重建清单.md)
- [整形图重建当前验收状态.md](../../学习文档/shaped_polar验证loop/理论更新与图重建/整形图重建当前验收状态.md)
- [知识库与Harness治理缺口说明.md](../../学习文档/知识库与Harness治理/知识库与Harness治理缺口说明.md)

本次迁移10份根目录文档、增加根导航与4份主题导航，机械修复链接/图片并同步修订索引；未改实验方法/结果。验证记录见 `16QAM_Polar/v2/results/20261025_231547_learning_documents_reorganization`。Rule reflection: no new durable rule。沿用目录迁移时的证据保留、链接核对与历史状态规则。

Revision metadata: revision_id=learning_relocation_ed9ccf9c6e_20261025; current_status=current; supersedes=[p2_b4_gate_failed_20261025].


## 2026-10-25 用户主导的研究回顾第一轮（R01a）

用户要求先核查和分批理解中期之后全部产物，明确确认后再进入第二阶段。本轮建立[产物台账与路线](../../学习文档/研究回顾与讨论/中期后产物台账与阅读路线-2026-10-25.md)及[追加式讨论记录](../../学习文档/研究回顾与讨论/追加式阅读与讨论记录.md)，导航末尾追加入口。只新增说明材料和目录元数据清单，不改源码、config、冻结数据或实验，不启动MATLAB。

验证：直接读取P2 status/events并重算522行门禁CSV，206失败，总功率3/组206重叠，最大总/组偏差1.12635%/1.80612%；保持gate_failed。旧中期单载波58500帧重汇总195重复，错误/信息位/符号能量/Goodput与配对归一化恒等式通过，14dB五点均值及t区间重算通过，原图已视觉检查。P1本轮仅核对最终指针/README与L2，未声称全套原数据独立复核。当前修订索引存在运行中旧标签，按实际status和最新正文识别，未修改索引。

首次讨论只讲中期框架与固定幅度能量原图。用户明确理解/科研决定尚无；不能将agent核查当用户批准。其余主题按六批路线继续，不自动转研究开发。新增Markdown检查和追加前缀校验见本轮核验输出。

Rule reflection: no new durable rule。既有规则已覆盖追加维护、证据分层、实际运行状态与指标边界；用户本轮“理解/认可不得推断”的具体协作约束记录在讨论日志，不另造平行规则。


### 本轮发布前核验补充

新增说明材料的首版公式存在转义控制字符，已按追加规则保留首版并用[讨论记录v2](../../学习文档/研究回顾与讨论/追加式阅读与讨论记录-v2.md)作为清洁当前入口。原数据未改。六job的1044行重复记录核验全部80帧，共83520帧；communication_measured=0且BER=NaN。最终当前材料控制字符、成对公式与本地链接检查通过；旧停用首版的格式异常明确保留，不声称全仓历史文件无异常。


## 2026-10-25 GitHub项目现状同步

按用户授权，将当前工作区的源码、诊断与实验入口、L1/L2/L3知识库、阶段文档、学习材料和后续计划整理为Git快照，同步目标为 `NeoChenjf/SPolar16QAM` 的 `master`。当前状态仍为P1已完成、P2首轮功率门禁未通过；正式批次完成6/23个job、83,520帧后停止，后续PMF/通信/模型性能证据尚未形成。当前阅读入口为 `next_plan.md` 末尾和本文件最新研究状态追加段。

本次维护仅补充忽略规则与同步记录，不修改研究实现、不启动MATLAB仿真。既有 `results/`、大体积数据/图表的忽略策略继续生效；新增排除本地agent配置、渲染临时目录、图表缓存、Python缓存、Office锁文件及误落在 `experiments/results/` 的生成结果。原始实验结果仍保留本地，本次Git同步不等于实验产物完整备份。

验证范围为远程分支基线、提交清单、文件大小及敏感内容模式检查，提交后核对远程分支提交号；不将此前源码和科研验收记录表述为本轮重新测试通过。同步结果以实际Git提交和远程校验为准。

Rule reflection: no new durable rule。沿用数据管理、append-only和阶段记录规则。
