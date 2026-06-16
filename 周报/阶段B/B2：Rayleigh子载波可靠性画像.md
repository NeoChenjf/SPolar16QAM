# B2：Rayleigh 子载波可靠性画像

> 所属阶段：阶段 B 多载波系统构建  
> 当前任务：在 OFDM baseline 后加入 Rayleigh 多径信道，输出子载波可靠性画像  
> 当前状态：脚本入口已新增，轻量画像运行已完成  
> 阶段边界：本轮只做可靠性画像，不做 `p_k` 优化，不做 BER/Goodput Monte Carlo

B2 的核心直觉是：OFDM 把频率选择性信道拆成多个子载波后，每个子载波看到的信道增益不同。只有先知道哪些子载波可靠、哪些子载波差，后续才能讨论“好信道偏信息”“好信道偏能量整形”或“差子载波纯传能”。

---

## 1. 阶段目标

建立 Rayleigh OFDM 子载波可靠性画像脚本，输出每个子载波的频域增益、等效 SNR 和 MI proxy。

第一轮只回答三个问题：

1. Rayleigh 多径信道下 `|H_k|^2` 是否能稳定生成并落盘；
2. 每个子载波的等效 SNR `gamma_k` 是否能形成明显可靠性差异；
3. 是否能给 B3 的三类策略提供初步分组依据。

本轮不判断最终多载波策略优劣。

---

## 2. 新增脚本

```text
16QAM_Polar/v2/experiments/multicarrier/run_rayleigh_subcarrier_profile.m
```

运行命令：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run('experiments/multicarrier/run_rayleigh_subcarrier_profile.m');
```

脚本会自举到 `v2` 根目录，不要求 MATLAB 当前文件夹必须预先位于 `16QAM_Polar/v2`。

---

## 3. 固定实验口径

第一版轻量画像参数：

```matlab
n_subcarriers = 64;
cp_ratio = 1/4;
channel_taps = 16;
num_realizations = 20;
snr_grid = 0:5:20;
seed = 42;
```

参数解释：

| 参数 | 含义 |
| --- | --- |
| `n_subcarriers` | OFDM 子载波数，沿用 B1 baseline |
| `cp_ratio` | CP 长度比例，`N_cp = 16` |
| `channel_taps` | Rayleigh 多径 tap 数，第一版与 CP 长度一致 |
| `num_realizations` | 信道 realization 数，用于观察可靠性分布 |
| `snr_grid` | 平均 SNR 网格，仅用于计算等效 `gamma_k` |
| `seed` | 固定随机种子，保证可复现 |

---

## 4. 随机 Rayleigh 信道的严谨性口径

B2 中的 Rayleigh 信道是随机生成的，但严谨性不来自“某一条随机信道本身”，而来自“采用标准统计信道模型，并在多个 realization 上观察统计规律”。

需要区分两件事：

1. 单条随机信道 realization 只能用于可视化和调试；
2. Rayleigh 信道模型下的多 realization 统计，才可以用于说明频率选择性衰落会造成子载波可靠性差异。

因此，B2 当前不能写成：

> 随机生成一条 Rayleigh 信道，证明某种子载波策略最优。

更严谨的写法是：

> 本阶段采用标准复高斯 Rayleigh 多径模型，代表无直达径、丰富散射环境。固定随机种子用于复现实验；通过多个信道 realization 统计 `|H_k|^2`、等效 `gamma_k` 和 MI proxy 的均值与分位范围，用于验证 Rayleigh OFDM 中确实存在可利用的子载波可靠性差异。

当前 `num_realizations = 20` 是轻量画像口径，只适合作为 B3 proxy 策略分组输入，不适合作为论文最终统计结论。若后续要把该部分写成论文级结果，应升级为：

```matlab
num_realizations = 100 / 500 / 1000;
seed_list = [1, 2, 3, ...];
```

并报告均值、分位区间或置信区间，而不是只展示单条 realization 曲线。

一个简单类比是：不是用一次掷骰子的结果证明骰子规律，而是先说明骰子的概率模型，再通过多次掷骰子的统计分布验证模型下的趋势。B2 现在处在“模型画像与策略原型”阶段，后续 B3/B4 若要做策略优劣判断，必须进入多 seed / 多 realization 的 full-chain 验证。

---

## 5. 指标定义

Rayleigh 多径信道：

$$
h_\ell \sim \mathcal{CN}(0, 1/L), \quad \ell=0,\ldots,L-1.
$$

频域子载波增益：

$$
H_k=\mathrm{FFT}(h)_k,\qquad |H_k|^2.
$$

其中，`H_k` 是第 `k` 个子载波看到的复数信道系数，包含两部分信息：

1. 幅度：该子载波上的信号会被放大或衰减多少；
2. 相位：该子载波上的信号会被旋转多少。

`|H_k|^2` 是 `H_k` 的模平方，也就是第 `k` 个子载波的信道功率增益。直观上，它回答的是：同样发射功率经过这个子载波后，接收端还能剩下多少有效信号功率。

| `|H_k|^2` 情况 | 直观含义 | 对通信的影响 |
| --- | --- | --- |
| `|H_k|^2 > 1` | 该子载波被信道增强 | 等效 SNR 更高，更适合承载信息 |
| `|H_k|^2 ≈ 1` | 接近平均信道增益 | 可靠性接近平均水平 |
| `|H_k|^2 < 1` | 该子载波发生衰落 | 等效 SNR 更低，误码风险更高 |

一个简单类比是：OFDM 的 64 个子载波像 64 条并行车道，`|H_k|^2` 就是每条车道的通行质量。质量高的车道更适合传信息，质量低的车道可能更适合降低信息负载、加强能量整形，或者在后续策略中改为纯传能。

在 Rayleigh 多径下，不同路径叠加会造成频率选择性衰落，所以 `|H_k|^2` 会随子载波编号起伏。B2 画像的重点就是先把这种起伏量化出来。

等效子载波 SNR：

$$
\gamma_k=\gamma_{\mathrm{avg}} |H_k|^2.
$$

MI proxy：

$$
I_k^{\mathrm{proxy}}=\log_2(1+\gamma_k).
$$

注意：该 MI proxy 是 Shannon-like 可靠性 proxy，不是 coded 16QAM bit-level MI，也不替代后续 polar full-chain BER / Goodput。

---

## 6. 输出要求

脚本输出目录：

```text
16QAM_Polar/v2/results/YYYYMMDD_HHMMSS_rayleigh_subcarrier_profile/
```

必须输出：

```text
subcarrier_reliability.csv
subcarrier_reliability_summary.csv
rayleigh_subcarrier_profile.mat
README.txt
run_log.txt
figures/subcarrier_gain_profile.png/pdf/fig
figures/subcarrier_snr_profile.png/pdf/fig
figures/subcarrier_mi_profile.png/pdf/fig
figures/subcarrier_group_profile.png/pdf/fig
```

`subcarrier_reliability.csv` 字段：

```text
realization, subcarrier, snr_dB, h_abs2, gamma_linear,
gamma_dB, mi_proxy_log2_1_plus_gamma, reliability_rank,
reliability_group
```

`reliability_group` 暂按每个信道 realization 内的 `|H_k|^2` 排名三等分：

| 分组 | 含义 |
| --- | --- |
| `high` | 高可靠子载波 |
| `mid` | 中等可靠子载波 |
| `low` | 低可靠子载波 |

---

## 7. 图怎么看

`subcarrier_gain_profile`：

![Subcarrier gain profile](../../16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/figures/subcarrier_gain_profile.png)

- 横坐标是子载波编号；
- 纵坐标是 `|H_k|^2 (dB)`；
- 蓝线是多次 realization 的均值；
- 浅色带是 10%-90% 分位范围；
- 用于观察 Rayleigh 频率选择性是否造成明显子载波增益差异。

`subcarrier_snr_profile`：

![Subcarrier SNR profile](../../16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/figures/subcarrier_snr_profile.png)

- 展示某个 realization 在最高平均 SNR 点下的 `gamma_k (dB)`；
- 用于直观看哪些子载波是好信道、哪些是差信道。

`subcarrier_mi_profile`：

![Subcarrier MI profile](../../16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/figures/subcarrier_mi_profile.png)

- 展示 `log2(1+gamma_k)` proxy；
- 用于给后续信息承载能力排序提供直观依据。

`subcarrier_group_profile`：

![Subcarrier group profile](../../16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/figures/subcarrier_group_profile.png)

- 按 `|H_k|^2` 排名把子载波分成 `high/mid/low` 三组；
- 该图只是 B3 策略分组依据，不代表最终 `p_k` 已确定。

---

## 8. 验收标准

| 条目 | 状态 | 说明 |
| --- | --- | --- |
| B2 脚本入口 | 已完成 | `run_rayleigh_subcarrier_profile.m` |
| 输出目录逻辑 | 已完成 | `20260524_171245_rayleigh_subcarrier_profile` |
| CSV/MAT/README | 已完成 | `subcarrier_reliability.csv`、summary CSV、MAT、README、run_log 均已落盘 |
| 四张画像图 | 已完成 | gain/SNR/MI/group profile 的 PNG/PDF/FIG 均已落盘 |
| 静态检查 | 已完成 | `checkcode` 无具体 issue |
| B2 结论边界 | 已完成 | 只做画像，不做 `p_k` 优化 |

运行目录：

```text
16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/
```

关键输出：

```text
subcarrier_reliability.csv
subcarrier_reliability_summary.csv
rayleigh_subcarrier_profile.mat
README.txt
run_log.txt
figures/subcarrier_gain_profile.png/pdf/fig
figures/subcarrier_snr_profile.png/pdf/fig
figures/subcarrier_mi_profile.png/pdf/fig
figures/subcarrier_group_profile.png/pdf/fig
```

摘要数值：

| SNR(dB) | mean \|H_k\|^2 | p10 \|H_k\|^2 | p50 \|H_k\|^2 | p90 \|H_k\|^2 | mean gamma(dB) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 1.0960 | 0.1091 | 0.7407 | 2.5639 | -2.1725 |
| 5 | 1.0960 | 0.1091 | 0.7407 | 2.5639 | 2.8275 |
| 10 | 1.0960 | 0.1091 | 0.7407 | 2.5639 | 7.8275 |
| 15 | 1.0960 | 0.1091 | 0.7407 | 2.5639 | 12.8275 |
| 20 | 1.0960 | 0.1091 | 0.7407 | 2.5639 | 17.8275 |

检查结论：`|H_k|^2` 的 10%-90% 分位区间约为 `0.1091~2.5639`，说明 Rayleigh 频率选择性已经形成明显子载波可靠性差异。该结果可作为 B3 分组策略的输入，但不能单独推出某类 `p_k` 策略最优。

---

## 9. 后续入口

B2 配套学习文档：

```text
周报/阶段B/Rayleigh相关知识.md
```

该文档用于解释 Rayleigh 信道、AWGN 对比、OFDM 中的 `H_k` / `|H_k|^2` / `gamma_k`，以及这些概念如何支撑 B2 画像和 B3 策略分组。

B2 完成后进入 B3：三类策略同口径对比。

1. 好信道偏信息：高可靠子载波倾向 `p=0.5`，低可靠子载波降低信息承载或偏能量；
2. 好信道偏能量整形：高可靠子载波使用更强整形，低可靠子载波保持较稳信息口径；
3. 差子载波纯传能：低可靠子载波不承载信息，作为传统对照 baseline。

B3 开始前必须先确认 B2 的分组规则、SNR 口径和输出 CSV 字段稳定。

---

## 10. 变更记录

- **2026-05-26**：补充“随机 Rayleigh 信道的严谨性口径”。明确 B2 的随机信道不是用单条 realization 证明策略有效，而是采用标准 Rayleigh 统计信道模型，并通过多 realization 观察 `|H_k|^2`、等效 `gamma_k` 和 MI proxy 的分布；当前 `20` 个 realization 只适合作为轻量画像和 B3 proxy 输入，论文级结论需要多 seed / 更多 realization 与置信区间。Rule reflection: no new durable rule
- **2026-05-26**：更新阶段 B 学习文档 `周报/阶段B/Rayleigh相关知识.md`，补充“为什么可以用 `|H_k|^2` 判断子载波好坏”的理论说明。新增内容明确 Rayleigh 信道不是直接转化为 AWGN，而是在 CP 足够、OFDM 正交、CSI 可用和频域均衡后，每个子载波可等效为不同 SNR 的 AWGN 子信道；high/mid/low 分组基于 `|H_k|^2` 或 `gamma_k` 排序。Rule reflection: no new durable rule
- **2026-05-24**：新增阶段 B 学习文档 `周报/阶段B/Rayleigh相关知识.md`。该文档按学习文档结构介绍 Rayleigh 信道、AWGN 与 Rayleigh 的联系和区别、Rayleigh 在 OFDM 中的运用、`H_k`/`|H_k|^2`/`gamma_k` 的含义，以及它们如何支撑 B2 可靠性画像和 B3 子载波策略对比。Rule reflection: no new durable rule
- **2026-05-24**：补充 `|H_k|^2` 概念讲解。说明 `H_k` 是第 `k` 个子载波的复数信道系数，`|H_k|^2` 是信道功率增益，决定同一平均 SNR 下该子载波的等效 `gamma_k`；并加入“并行车道”类比和 high/mid/low 子载波分组直觉。该更新只增强报告解释，不改变实验脚本和结果。Rule reflection: no new durable rule
- **2026-05-24**：按用户要求将 B2 首轮结果图嵌入阶段文档第 6 节，包含 `subcarrier_gain_profile`、`subcarrier_snr_profile`、`subcarrier_mi_profile` 和 `subcarrier_group_profile` 四张 PNG 图，图片均指向 `16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/figures/`。Rule reflection: no new durable rule
- **2026-05-24**：完成 B2 轻量画像运行。命令为 `cd('16QAM_Polar/v2'); setup_paths; run('experiments/multicarrier/run_rayleigh_subcarrier_profile.m');`，输出 `16QAM_Polar/v2/results/20260524_171245_rayleigh_subcarrier_profile/`。CSV/MAT/README/run_log 和四张画像图均已生成；`checkcode` 无具体 issue。`|H_k|^2` 的 10%-90% 分位区间约为 `0.1091~2.5639`，可支撑 B3 的 high/mid/low 子载波分组，但不作为最终策略结论。Rule reflection: no new durable rule
- **2026-05-24**：新建 B2 阶段文档与脚本入口 `16QAM_Polar/v2/experiments/multicarrier/run_rayleigh_subcarrier_profile.m`。脚本固定 `64` 子载波、CP=1/4、`16` tap Rayleigh、`20` 个 realization、`snr_grid=0:5:20`，输出 `|H_k|^2`、等效 `gamma_k`、`log2(1+gamma_k)` MI proxy 与 high/mid/low 可靠性分组。本轮只做画像，不做 polar BER/Goodput Monte Carlo，也不做 `p_k` 优化。Rule reflection: no new durable rule
