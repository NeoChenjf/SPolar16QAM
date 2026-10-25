# 阶段 A：单载波关键结论

> 当前口径：单载波、16QAM、概率整形 polar code、SC 译码、`fixed_esn0`  
> 阶段边界：先闭环 SC，不进入 SCL、不引入整流器模型、不启动 OFDM  
> 结论来源：理论机制分析 + 统一口径 Monte Carlo full-chain 验证

阶段 A 的核心结论是：在当前单载波 SC 链路下，强概率整形没有稳定转化为全局 Goodput 最优。小 `p` 会改变星座概率和平均能量，但也会改变极化码的 `S/I/F` 集合、降低有效信息位规模，并在 SC 译码下带来编码侧可靠性损失。统一口径 final global curve 显示，`p=0.5, 20 dB` 取得最高 Goodput `0.493325`，而 `p=0.1` 的最高 Goodput 为 `0.351307`。

---

## 1. 整体系统结构分析

阶段 A 研究的是单载波完整链路：

```text
信息位
-> 概率整形 polar 编码
-> 16QAM Gray 映射
-> AWGN 信道
-> 16QAM LLR 解调
-> 4 路 SC 译码
-> BER / Goodput
```

当前整形参数结构为：

```matlab
cfg.p_fixed = [0.5, NaN, 0.5, NaN];
```

也就是说，bit1/bit3 固定为均匀分布，bit2/bit4 由统一参数 `p` 控制。`p=0.5` 是无整形基线；`p` 越小，整形越强。

每一路的整形位数和信息位数由二元熵决定：

$$
H(p_b)=-p_b\log_2p_b-(1-p_b)\log_2(1-p_b),
$$

$$
S_b(p)=\lceil N(1-H(p_b))\rceil,
\qquad
K_b(p)=\left\lceil\frac{N-S_b(p)}{2}\right\rceil.
$$

系统有效码率为：

$$
R_{\mathrm{total}}(p)=\frac{\sum_{b=1}^{4}K_b(p)}{4N}.
$$

Goodput 定义为：

$$
G(p,\gamma)=R_{\mathrm{total}}(p)\left(1-\mathrm{BER}(p,\gamma)\right).
$$

这个定义决定了阶段 A 的主线：小 `p` 即使改善某些 SNR 点的 BER，也必须先克服 `R_total(p)` 下降带来的 Goodput 上限损失。

代表性码率上限如下：

| p | R_total | 理想无误码 Goodput 上限 |
| --- | --- | --- |
| 0.5 | 0.500000 | 0.500000 |
| 0.4 | 0.492676 | 0.492676 |
| 0.3 | 0.470215 | 0.470215 |
| 0.2 | 0.430664 | 0.430664 |
| 0.1 | 0.367188 | 0.367188 |

因此，`p=0.1` 即使在局部 SNR 上 BER 较低，Goodput 最高也不能超过 `0.367188`；而 `p=0.5` 的上限是 `0.5`。

---

## 2. 编码侧理论分析

编码侧的问题是：`p` 不只是改变星座概率，还改变极化码内部哪些位置是整形位、信息位和冻结位。小 `p` 使二元熵下降，整形位数量增加，信息位数量减少，信息集合 $\mathcal I_b(p)$ 也随之移动。

在当前工程口径中，每路集合划分可以写成：

$$
\mathcal S_b(p),\quad \mathcal I_b(p),\quad \mathcal F_b(p),
$$

其中：

1. $\mathcal S_b(p)$ 是整形位集合；
2. $\mathcal I_b(p)$ 是信息位集合；
3. $\mathcal F_b(p)$ 是冻结位集合。

GA 理论使用虚拟信道可靠性 $u_i(\gamma)$ 估计位误码率：

$$
\widehat P_{e,i}(\gamma)\approx\frac{1}{2}\phi(u_i(\gamma)).
$$

第 `b` 路 code-only BER 可写成：

$$
\widehat{\mathrm{BER}}^{\mathrm{code}}_b(p,\gamma)
=
\frac{1}{K_b(p)}
\sum_{i\in\mathcal I_b(p)}
\widehat P_{e,i,b}(p,\gamma).
$$

系统 code-only BER 为：

$$
\widehat{\mathrm{BER}}^{\mathrm{code}}_{\mathrm{sys}}(p,\gamma)
=
\frac{
\sum_{b=1}^{4}K_b(p)\widehat{\mathrm{BER}}^{\mathrm{code}}_b(p,\gamma)
}{
\sum_{b=1}^{4}K_b(p)
}.
$$

有效 code-only 瀑布区不是早期误判的 `11~13 dB`，而是 `1~3 dB`。`11~13 dB` 已经接近全零误码，不能用于解释理论-仿真偏差。早期 waterfall 图仅作为过程性检查，不再放入阶段 A 定稿主文档图片。

代表性点：

| p | selected SNR(dB) | BER_sim_mean | CI95 | BER_theory | gap |
| --- | --- | --- | --- | --- | --- |
| 0.5 | 2.5 | 1.956e-3 | 1.206e-3 | 3.814e-5 | 1.918e-3 |
| 0.4 | 2.5 | 4.039e-3 | 7.851e-4 | 7.820e-5 | 3.961e-3 |
| 0.3 | 3.0 | 2.209e-3 | 6.801e-4 | 1.039e-4 | 2.105e-3 |
| 0.2 | 3.0 | 5.057e-2 | 5.543e-3 | 4.804e-3 | 4.576e-2 |
| 0.1 | 3.0 | 1.545e-1 | 6.320e-4 | 1.135e-1 | 4.106e-2 |

编码侧结论：

1. 小 `p` 尤其 `p<=0.2` 会显著提高 SC code-only BER；
2. GA 理论能解释趋势，但多数点低估真实 SC 仿真；
3. 偏差主要来自有限长 SC 译码、误差传播以及 GA 平均模型与真实译码过程之间的差异；
4. 编码侧损失是阶段 A 中小 `p` 难以形成全局 Goodput 优势的重要原因。

---

## 3. 几何侧理论分析

16QAM Gray 星座中，概率整形通过改变各比特层的 `0/1` 概率改变符号分布。当前只控制 bit2/bit4，所以 `p` 主要改变内层、中层和外层点出现概率。

![16QAM Gray 星座图](figures/16qamGray.png)

未归一化平均能量为：

$$
E(p)=18-16p.
$$

基线 `p=0.5` 时：

$$
E(0.5)=10.
$$

归一化能量比为：

$$
E_{\mathrm{norm}}(p)=\frac{E(p)}{10}.
$$

因此，`p` 越小，外圈符号概率越高，未归一化平均能量越大：

| p | E(p) | E_norm |
| --- | --- | --- |
| 0.5 | 10.0 | 1.00 |
| 0.4 | 11.6 | 1.16 |
| 0.3 | 13.2 | 1.32 |
| 0.2 | 14.8 | 1.48 |
| 0.1 | 16.4 | 1.64 |

在高 SNR 近邻近似下，可以把几何侧误码风险写成一个相对修正项。旧口径使用：

$$
R_{\mathrm{geo}}(p)
=
\frac{P_b^{\mathrm{ML}}(p,\gamma)}
{P_b^{\mathrm{ML}}(0.5,\gamma)}
\approx
\frac{2+2p}{3}.
$$

由于当前仅 bit2/bit4 由 `p` 控制，定义受控路掩码：

$$
m_b=
\begin{cases}
1, & b\in\{2,4\},\\
0, & b\in\{1,3\}.
\end{cases}
$$

则每路几何修正为：

$$
R_{\mathrm{geo},b}(p)
=
1+m_b\left(R_{\mathrm{geo}}(p)-1\right).
$$

几何侧的直观结论是：小 `p` 可能在部分 SNR 区间降低受控 bit 路的调制层相对误码风险，但这个收益不能单独决定 full-chain BER，因为编码侧和码率侧也同时变化。

---

## 4. 整体链路理论分析

整体链路不是“几何侧好不好”或“极化码强不强”单独决定的，而是三类因素叠加：

1. 几何/能量项变化；
2. 编码侧 $\mathcal S/\mathcal I/\mathcal F$ 集合变化；
3. $R_{\mathrm{total}}(p)$ 上限变化。

一种一阶相对风险近似是：

$$
\widehat{\mathrm{BER}}^{\mathrm{full}}_{\mathrm{ratio}}(p,\gamma)
=
\frac{
\sum_{b=1}^{4}
K_b(p)
\widehat{\mathrm{BER}}^{\mathrm{code}}_b(p,\gamma)
R_{\mathrm{geo},b}(p)
}{
\sum_{b=1}^{4}K_b(p)
}.
$$

这条公式只适合作为相对风险缩放，不能理解为两个独立误码事件的精确联合概率。若把编码侧错误和几何侧错误看作两类近似独立错误来源，更保守的并集型合成是：

$$
P_{e,b}^{\mathrm{union}}(p,\gamma)
=
1-
\left(1-P_{e,b}^{\mathrm{code}}(p,\gamma)\right)
\left(1-P_{e,b}^{\mathrm{geo}}(p,\gamma)\right).
$$

上式在程序实现中对应：

```text
P_union = 1 - (1 - P_code) * (1 - P_geo)
```

当前已补充理论合成敏感性检查。诊断结果：

1. `ratio_scale` 在 `10 dB` 会把理论 BER 压到 `1e-12` 附近；
2. `independent_union` 会把 `10 dB` 理论 BER 拉回到 `1e-3` 量级；
3. 但统一口径 Monte Carlo 中 `p=0.5, 10 dB` 的 BER_mean 约为 `4.724e-1`，`p=0.1, 10 dB` 约为 `1.974e-1`；
4. 因此理论-仿真大偏差不能只归因于 BER 合成形式，还包括 GA/BPSK 等效编码侧模型与真实 16QAM LLR 位信道不一致、SC 误差传播和有限长效应。

纯理论 full-chain 曲线只作为机制建模过程结果保存，不再作为阶段 A 定稿主文档图片，也不能作为定量验证图。

整体理论分析的稳妥定位是：

> 理论模型用于解释 `p` 如何同时作用于几何项、编码侧可靠性和有效码率上限；当前理论 BER 不作为 Monte Carlo full-chain BER 的精确闭式预测。

---

## 5. 蒙特卡洛验证

阶段 A 的系统级 Goodput 定量结论来自统一口径 Monte Carlo full-chain 仿真：

$$
G_{\mathrm{MC}}(p,\gamma)
=
R_{\mathrm{total}}(p)
\left(
1-\mathrm{BER}_{\mathrm{MC}}(p,\gamma)
\right).
$$

其中 $R_{\mathrm{total}}(p)$ 是解析确定的码率项，$\mathrm{BER}_{\mathrm{MC}}$ 来自完整 16QAM + polar + SC 链路仿真。

### 5.1 轻量 full-chain 闭环

轻量闭环参数：

```matlab
decoder = 'SC';
snr_mode = 'fixed_esn0';
p_list = [0.5,0.4,0.3,0.2,0.1];
snr_grid = [0,5,10,15,20];
num_frames = 100;
seed = 42;
```

结果目录：

- `16QAM_Polar/v2/results/20260520_231445_singlecarrier_sc_closure/`

轻量闭环只支持方向判断，因为 SNR 网格较稀疏、帧数较小、seed 单一。它暴露了两个需要复验的问题：code-only 中 `p=0.4` 局部反转，以及 full-chain 中 `p=0.1, 10 dB` 的局部异常。

注意：该轻量闭环的 `snr_grid=[0,5,10,15,20]` 过于稀疏，不能作为论文主图，也不应用来判断 `16 dB` 附近的曲线过渡或交叉位置。讨论 full-chain BER/Goodput 随 SNR 的连续变化时，应优先使用 5.3 节的统一口径 final global curve。

### 5.2 异常点复验

收尾复验结果目录：

- `16QAM_Polar/v2/results/20260521_141330_phaseA_sc_closure_check/`

code-only 复验显示，`p=0.5` 在 `[2.75,3.0,3.25] dB` 三个点的平均 BER 均低于 `p=0.4`，所以旧图中 `p=0.4` 在 `3 dB` 更低的现象不作为稳定机制写入主结论。

full-chain 复验显示，`p=0.1` 在 `8-14 dB` 的 BER/Goodput 确实存在局部优势；但由于 `R_total(0.1)` 较低，三组 seed 的最高 Goodput 均出现在 `p=0.5, 16 dB`。

阶段 A 汇总叠加图仅作为过程性解释图保存，不再放入定稿主文档。

### 5.3 统一口径 final global curve

最终论文级统一口径结果目录：

- `16QAM_Polar/v2/results/20260521_150555_phaseA_sc_final_global_curves/`

机制图重绘结果目录：

- `16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/`

参数：

```matlab
source final global: p=[0.5,0.4,0.3,0.2,0.1]
paper-facing display: p=[0.5,0.3,0.1]
code-only:  SNR=1:0.25:3.25, n_rep=5
full-chain: SNR=8:1:20, seeds=[42,43,44], num_frames=300
```

其中 full-chain 主图已采用 `1 dB` 粒度，不再使用早期轻量闭环的 `5 dB` 粒度。若论文中需要解释 `p=0.1` 与 `p=0.5` 的局部 BER/Goodput 关系，应引用本节三值重绘后的 full-chain BER / Goodput 图，而不是 5.1 节的稀疏闭环图。

为避免把理论模型和 Monte Carlo 数据混在一张图中，code-only BER 拆成 theory-only 与 simulation-only 两张图；同时补充 geometry-only BER proxy，形成“几何侧 -> 编码侧 -> full-chain”的完整对照链条。geometry-only 图是 16QAM 近邻/Q 函数 proxy，不是 Monte Carlo 仿真。论文展示图统一只显示 `p=0.5,0.3,0.1` 三种情况；旧的五条线图仅作为历史结果保留，不再展示。

![Geometry-only 16QAM BER proxy](../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_geometry_only_ber_vs_snr.png)

![Code-only SC BER theory](../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_codeonly_ber_theory_vs_snr.png)

![Code-only SC BER simulation](../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_codeonly_ber_sim_vs_snr.png)

![Full-chain SC BER simulation](../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_fullchain_ber_sim_vs_snr.png)

![Full-chain SC Goodput simulation](../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_fullchain_goodput_sim_vs_snr.png)

![Full-chain Goodput-Energy](../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_fullchain_goodput_energy.png)

统一口径 best Goodput：

| p | best SNR(dB) | best Goodput | BER at best | R_total | E_norm |
| --- | --- | --- | --- | --- | --- |
| 0.5 | 20 | `0.493325` | `1.335e-2` | `0.500000` | `1.00` |
| 0.3 | 20 | `0.463265` | `1.478e-2` | `0.470215` | `1.32` |
| 0.1 | 20 | `0.351307` | `4.325e-2` | `0.367188` | `1.64` |

关键局部点：

| p | SNR(dB) | BER_mean | Goodput_mean | 解释 |
| --- | --- | --- | --- | --- |
| 0.5 | 10 | `4.724e-1` | `0.263812` | 基线在中低 SNR 受 BER 限制 |
| 0.1 | 10 | `1.974e-1` | `0.294712` | 强整形在中低 SNR 存在局部 Goodput 优势 |
| 0.5 | 20 | `1.335e-2` | `0.493325` | 高 SNR 下基线凭借更高 `R_total` 取得全局最优 |
| 0.1 | 20 | `4.325e-2` | `0.351307` | 强整形 BER 不高，但 `R_total` 上限明显较低 |

统一口径结论：小 `p` 在中低 SNR 可形成局部 BER/Goodput 优势，但单载波 SC 的全局 best Goodput 仍由 `p=0.5` 取得；强整形没有成为全局最优策略。

关于 code-only 图的画法边界：理论图用于展示模型预期的单调结构；仿真图应通过更密 SNR、更多帧数/seed 和误差条来检验该结构，不能人为调整数据或曲线顺序来“贴合理论”。如果仿真图局部不满足理论单调性，应记录为统计波动、有限长/SC 误差传播或模型口径偏差的待解释现象，而不是直接改图。

---

## 6. 主要结论

阶段 A 可写入论文的主结论如下：

1. **编码侧**：小 `p` 尤其 `p<=0.2` 会显著提高 SC code-only BER。原因是整形位增加、信息位减少，$\mathcal I_b(p)$ 被迫移动到可靠性不同的位置。
2. **几何侧**：小 `p` 提高外圈符号概率和平均能量，理论上可能在部分 SNR 区间带来调制层相对收益。
3. **码率侧**：小 `p` 会降低 $R_{\mathrm{total}}(p)$，直接压低 Goodput 上限。这是 Goodput 解释中必须显式写出的第三个机制。
4. **整体链路**：小 `p` 的几何收益必须同时抵消编码侧 BER 损失和码率上限损失，才能形成系统级 Goodput 提升。
5. **Monte Carlo 结论**：在当前单载波 SC、`fixed_esn0` 口径下，强整形存在中低 SNR 局部 tradeoff，但没有形成稳定全局最优。
6. **阶段过渡**：阶段 B 不应简单沿用“全链路统一小 `p`”策略，而应转向多载波/子载波级自适应，只在信道条件、能量需求和可靠性余量允许的位置使用更强整形。

论文建议表述：

> 单载波 SC 链路中，概率整形的几何收益、编码侧可靠性损失和有效码率上限下降共同决定系统 Goodput。统一口径 Monte Carlo 结果表明，强整形可在中低 SNR 形成局部收益，但没有在阶段 A 口径下超过均匀基线的全局最高 Goodput。因此，后续工作应从统一整形参数转向多载波/子载波自适应整形。

论文一建议图表清单：

| 编号 | 图表 | 来源 | 用途 |
| --- | --- | --- | --- |
| Fig.1 | 16QAM Gray 星座与概率整形分布 | `周报/figures/16qamGray.png` | 说明 `p` 如何改变星座概率和能量 |
| Fig.2 | `E(p)=18-16p` 与 `E_norm` 表 | 本文第 3 节 | 给出能量收益解析基准 |
| Fig.3 | geometry-only 16QAM BER proxy | `20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_geometry_only_ber_vs_snr.png` | 隔离几何侧概率整形收益 |
| Fig.4 | code-only SC BER theory | `20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_codeonly_ber_theory_vs_snr.png` | 展示编码侧理论单调预期 |
| Fig.5 | code-only SC BER simulation | `20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_codeonly_ber_sim_vs_snr.png` | 检验编码侧实际仿真表现 |
| Fig.6 | full-chain SC BER vs SNR | `20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_fullchain_ber_sim_vs_snr.png` | 展示完整链路 BER 表现 |
| Fig.7 | full-chain SC Goodput vs SNR | `20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_fullchain_goodput_sim_vs_snr.png` | 展示信息端收益 |
| Fig.8 | Goodput-Energy Pareto | `20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_fullchain_goodput_energy.png` | 展示能量与有效信息传输权衡 |

---

## 7. 可能的质疑和回答

**质疑 1：最终 Goodput 还是靠 Monte Carlo，不是真正闭式理论定量分析。**

回答：这个质疑成立。阶段 A 不应声称当前解析模型已经精确预测 full-chain Goodput。当前 Goodput 的最终数值结论来自统一口径 Monte Carlo full-chain 仿真：

$$
G_{\mathrm{MC}}(p,\gamma)
=
R_{\mathrm{total}}(p)
\left(1-\mathrm{BER}_{\mathrm{MC}}(p,\gamma)\right).
$$

其中 $R_{\mathrm{total}}(p)$ 是解析确定的，$\mathrm{BER}_{\mathrm{MC}}$ 来自完整链路仿真。因此阶段 A 的 Goodput 是“统一仿真口径下的定量结果”，不是“闭式 BER 理论推出的定量结果”。理论部分承担的是机制解释：说明 `p` 同时影响几何项、编码侧可靠性和码率上限。

**质疑 2：理论和仿真差异不能简单用有限码长或 AWGN/BPSK 差异解释。**

回答：同意。当前理论模型至少包含三层近似：编码侧使用 GA/BPSK 等效可靠性，full-chain 实际接收的是 16QAM bit-wise LLR；几何侧使用近邻/Q 函数或相对风险修正，不能完整替代 `qamdemod` 的软信息分布；SC 译码存在有限长误差传播，不能由独立 bit-channel BER 简单相乘或相加完全描述。因此本文不把理论-仿真差异单独归因于某一个因素，而把理论模型定位为机制分解模型。

**质疑 3：理论分析有没有论文支撑，凭什么按这个结构分解？**

回答：本文第 2-4 节不是提出新的严格 BER 定理，而是把已有通信理论框架组织到当前系统中。理论依据包括：极化码与 SC 译码的 channel polarization 框架；极化码构造中的 bit-channel 可靠性、密度演化和 Gaussian approximation；16QAM bit-wise LLR 的 BICM 建模；概率整形/PAS 中关于符号分布、平均能量和有效信息率的分析。本文的贡献是把这些机制在当前 `p_fixed=[0.5,NaN,0.5,NaN]` 的单载波 SC 系统中闭环，并用 Monte Carlo 验证系统级结论。

**质疑 4：为什么不继续把理论调到和仿真一致？**

回答：不应通过经验调参强行让理论曲线贴合 Monte Carlo。若要做真正严格的 full-chain 定量理论，需要重新建立 16QAM BICM LLR 位信道，对每个 `p` 和每个 bit-level 计算可靠性，再基于这些位信道做 polar construction 和 SC 误差上界估计，最后按 $K_b(p)$ 加权进入 BER 与 Goodput。这是阶段 A 之后的理论增强任务，不作为当前单载波 SC 收口的阻塞项。

建议论文边界表述：

> 本文解析模型用于刻画概率整形参数 `p` 对几何项、极化码信息位集合以及系统有效码率的共同作用。由于完整链路采用 16QAM bit-wise LLR 与有限长 SC 译码，当前解析 BER 不作为 Monte Carlo BER 的精确闭式预测；系统级 Goodput 结论以统一口径 full-chain 仿真为准，理论模型用于解释趋势和机制边界。

---

## 附录 A. 关键文件与结果

结果目录：

- `16QAM_Polar/v2/results/20260520_180719_sc_waterfall_refine/`
- `16QAM_Polar/v2/results/20260520_231445_singlecarrier_sc_closure/`
- `16QAM_Polar/v2/results/20260521_141330_phaseA_sc_closure_check/`
- `16QAM_Polar/v2/results/20260521_145529_phaseA_sc_summary_figures/`
- `16QAM_Polar/v2/results/20260521_150555_phaseA_sc_final_global_curves/`
- `16QAM_Polar/v2/results/20260522_144919_phaseA_sc_theory_fullchain_curves/`
- `16QAM_Polar/v2/results/20260522_144919_phaseA_sc_theory_combine_sensitivity/`
- `16QAM_Polar/v2/results/20260523_151621_phaseA_sc_mechanism_figures/`
- `16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/`

脚本入口：

- `16QAM_Polar/v2/experiments/sc_checks/run_find_waterfall_and_refine.m`
- `16QAM_Polar/v2/experiments/singlecarrier/run_singlecarrier_sc_closure.m`
- `16QAM_Polar/v2/experiments/singlecarrier/run_phaseA_sc_closure_check.m`
- `16QAM_Polar/v2/experiments/singlecarrier/run_phaseA_sc_summary_figures.m`
- `16QAM_Polar/v2/experiments/singlecarrier/run_phaseA_sc_final_global_curves.m`
- `16QAM_Polar/v2/experiments/singlecarrier/run_phaseA_sc_theory_fullchain_curves.m`
- `16QAM_Polar/v2/experiments/singlecarrier/run_phaseA_sc_theory_combine_sensitivity.m`
- `16QAM_Polar/v2/experiments/singlecarrier/run_phaseA_sc_mechanism_figures.m`

---

## 附录 B. 变更记录

- **2026-05-23**：统一 code-only theory 与 code-only simulation 两张图的纵轴为对数坐标；重新运行机制图脚本输出 `16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/`，并将阶段 A 展示路径更新到该目录。Rule reflection: no new durable rule
- **2026-05-23**：按论文展示标准将阶段 A 所有主图统一限制为 `p=0.5,0.3,0.1` 三种情况；重新运行 `run_phaseA_sc_mechanism_figures.m` 输出 `16QAM_Polar/v2/results/20260523_151621_phaseA_sc_mechanism_figures/`，并将阶段 A 文档展示图全部切换到该三值版本。Rule reflection: no new durable rule
- **2026-05-23**：新增阶段 A 机制图重绘脚本 `run_phaseA_sc_mechanism_figures.m`，基于已有 final global CSV 生成 geometry-only BER、code-only theory-only、code-only simulation-only、full-chain simulation-only 图；文档主图逻辑改为几何侧、编码侧、full-chain 三层对照。第一次输出 `20260523_151000_phaseA_sc_mechanism_figures/` 为中间产物，后续已统一替换为三值展示版本。Rule reflection: no new durable rule
- **2026-05-23**：精简阶段 A 定稿主文档图片，只保留星座图和统一口径 final global curve 四张最终结果图；移除早期 waterfall、轻量闭环、收尾复验、汇总叠加、纯理论/敏感性诊断图在正文中的展示引用，历史结果目录仍保留可追溯。Rule reflection: no new durable rule
- **2026-05-23**：明确阶段 A 论文级 full-chain 图应采用统一口径 final global curve，其 full-chain SNR 已为 `8:1:20`；早期 `0/5/10/15/20 dB` 轻量闭环图只保留为方向检查，不用于解释曲线过渡。Rule reflection: no new durable rule
- **2026-05-22**：按“整体系统结构分析、编码侧理论分析、几何侧理论分析、整体链路理论分析、蒙特卡洛验证、主要结论、可能的质疑和回答”七章结构整体重构阶段 A 文档；保留已有公式、图表、结果目录和专家质疑口径，删除流水账式阶段推进章节。影响范围仅为 `周报/阶段A：单载波关键结论.md`；验证方法为标题编号、图表路径、结果目录和核心结论一致性检查。Rule reflection: no new durable rule
- **2026-05-22**：新增“专家质疑与答辩口径”内容，回应 Goodput 定量来源和理论支撑边界问题。
- **2026-05-22**：根据理论 full-chain 曲线与 Monte Carlo 偏差，修正 BER 合成表述；新增 `independent_union = 1-(1-P_code)(1-P_geo)` 诊断口径。
- **2026-05-22**：补充纯理论 full-chain SC BER/Goodput 曲线小节。
- **2026-05-22**：新增整体 BER 近似口径，将 code-only 路级 BER、16QAM 几何侧修正、每路信息位数加权和 Goodput 公式整合为统一理论说明。
- **2026-05-21**：回填统一口径 final global curve 结果，确认 `p=0.5` 在 `20 dB` 取得最高 Goodput。
- **2026-05-21**：新增阶段 A 汇总叠加图和统一口径 final global curve 脚本。
- **2026-05-21**：回填阶段 A SC 收尾复验结果，确认 `p=0.4` code-only 局部反转未复现，`p=0.1` full-chain 中低 SNR 有局部 tradeoff。
- **2026-05-21**：创建本文档，作为阶段 A 单载波关键结论主文档。

## 2026-10-09 新构造及数据版本边界

阶段A code-only 与 full-chain 新构造采用固定源熵 $S$，逐SNR依据GA在剩余位置重选 $I/F$；整形器每帧根据真实payload生成 $S$。构造seed、独立源熵holdout和PMF门禁证据见[最新构造记录](../../学习文档/shaped_polar验证loop/最新认知与执行基线.md)。旧曲线仍为旧集合规则，不能直接与后续等功率方案混比。

阶段A full-chain正式重建共用16QAM能量权衡正式数据；当前一批因发现“逐SNR重选I/F”要求而中止并保留检查点，尚无有效新正式性能图。code-only正式曲线随后单独运行，不重复full-chain长跑。

## 2026-10-09 Stage A link correction

本页上一节的“最新构造记录”相对路径多退了一层；正确链接为[最新构造记录](../学习文档/shaped_polar验证loop/最新认知与执行基线.md)。


## 2026-10-09 近似模型索引修正

在理论/模拟复核中发现，上一版估计器只跳过GA排序中的$|S|$个位置，没有按源熵选出的实际$S$索引剔除，故不能用于新构造的I集合。已修正为逐SNR排除实际S索引后选I；full-chain Monte Carlo链路不调用该估计器，本次正式性能统计不受这一修正影响。旧理论估计暂不引用，F19应以修正代码重跑并与新构造模拟比较。规则反思：本次发现“数量相同不代表集合相同”的假设越界；新增复核点是构造/估计器必须共享具体集合索引，并在L2/L3契约写明适用分支。


Rule reflection: added/updated [workbook/quality-assurance.md] with the invariant that estimators must use explicit S/I/F indices; set cardinality alone does not establish identical partition placement.

## 2026-10-09 19:35 正式单载波曲线重建（append-only）

新结果目录：`16QAM_Polar/v2/results/20261009_183509_16qam_energy_tradeoff_formal/`；阶段A展示图派生目录：`16QAM_Polar/v2/results/20261009_193403_phaseA_figures_from_energy_tradeoff/`。本轮数据为N=1024、每个seed/p/SNR点300帧、seed 42/43/44、p={0.5,0.4,0.3,0.2,0.1}、SNR标签8–20 dB，共58,500帧；CSV/MAT、帧计数、去重、误码/能量分母、工作点join及图文件审计通过。实际Es/N0=标签−3.0103 dB，能量以p=0.5归一，属于加噪前RF代理量，非直流收能。

14 dB标签下，p从0.5降到0.1时归一RF能量由1.000升至1.615，但BER由0.381升至0.315，Goodput由0.310降至0.251；20 dB标签下BER依次约为0.0134、0.0302、0.0544、0.0802、0.0996。观察到成形提高能量代理量的同时牺牲通信性能；这不是等发射功率比较，也未证明直流收益。三seed t区间仅是有限重复的描述区间。

重建图：F04 full-chain BER、F05 Goodput—RF能量、F06 BER—SNR、F07 全SNR能量—p及14 dB专图、F08 BER—能量、F09 Goodput—能量/Pareto。F04/F05/F07的PNG/PDF/FIG位于派生目录；F06/F08/F09位于正式结果目录。PMF证据仍见F02/F03，不与本段混为同一批实验。

后续先完成code-only F19及OFDM pilot/正式与独立验证；随后按项目计划进入等功率P1。不得将本轮固定星座幅度下的能量差称为等功率收益或RF-DC效率。

Rule reflection: no new durable rule. The MATLAB R2020b path-concatenation failure was a local implementation defect; existing `fullfile()`/character-path guidance is sufficient. The failure and recovery are recorded in `workbook/troubleshooting-history.md`.

## 2026-10-09 F19 code-only理论差距重建

F19由source-entropy S集合、余位GA选I、实际I索引直接传入BER估计后重建。结果：`16QAM_Polar/v2/results/20261009_193607_phaseA_sc_final_global_curves/`保存五次重复及实际理论集合，后处理图/汇总在`20261009_202540_phaseA_codeonly_gap_analysis/`。在SNR标签3 dB，仿真/理论BER比值p=.5/.4/.3/.2/.1约131/66.6/22.9/9.78/1.37；3.25 dB约91.8/129/33.4/11.2/1.52。当前近似模型对p≥.2的绝对BER明显过于乐观，不适合直接当优化约束；小p走势相对接近但仍不能视为精确预测。普通SC接收度量没有额外源先验，码长/集合与构造改变均须控制，冻结位F=0不是唯一已证实原因。F19已通过集合索引、5重复、原始错误/帧数、图数值及视觉检查。

接下来P2拆开验证实际源PMF下的匹配接收度量与bit-channel可靠性，并记录模型适用边界；不以新增闭式BER为这轮完成条件。

## 2026-10-09 新构造曲线与模型边界追加

阶段A当前正式图已由`20261009_183509_16qam_energy_tradeoff_formal`与派生目录`20261009_193403_phaseA_figures_from_energy_tradeoff`重建。195个配置重复点、58,500帧完成数值审计和PNG/PDF/FIG视觉复核；p=.1在标签14 dB下的BER/Goodput/RF均方代理分别为.315/.251/1.615，p=.5为.381/.310/1。由于固定星座缩放使发射功率随p变化，结果不能解释为等功率收益。该SNR标签对应Es/N0标签−3.0103 dB。

F19 code-only正式比较显示当前GA/SC近似对绝对BER可能严重乐观（p≥.2的sim/theory比值约9.78至131以上，随点变化）；它目前不适合作绝对BER约束预测。此前不正确的S集合近似已修复，但源熵构造选择本身不代表接收LLR/译码器匹配，也不支持“冻结全零单因素解释”。结果与适用边界、后续P2任务见清单最终快照。


## 2026-10-24 当前状态追加：辅助S方案恢复推进，正式预算待确认

用户已同意尝试独立随机S与独立供体S并继续原路径，取代前文“暂停新增对照”的中间状态。已完成独立P2实现、17配置短pilot、21组生成矩阵覆盖审计、3seed×8码字/S统计、原接收端回归与检查点/版本拒绝测试。源MC直接复用P1的200样本seed9001模板；未改共享config或旧正式结果。

随机S修复原S冻结0对照的非均匀问题：p=.3/.1实际24码字TV(均匀)=.00688/.00903，供体S为.04236/.31283。供体不是均匀目标。小校准尚未通过正式1%门禁；模型仅实现并完成合成/短训练smoke，未达独立精度或速度科研验收。冻结S旧对照只留诊断，不称GA错误或原整形PMF失败。

当前阅读入口：学习文档/等功率机制与P2当前结论.md；唯一任务入口：学习文档/等功率机制对照与P2执行清单.md；正式预算：学习文档/P2正式实验预算与执行顺序.md。首轮23job、414366帧，实测点估计18.8小时、建议预留23—30小时；具体批准前不启动。

本轮当前完成的是代码/理论诊断/材料准备。正式1%功率、3×80 PMF、单载波代表点、独立模型预测及正式图均未完成。P2之后才进入P3的27组合；P4非线性收能、CSI/削顶及P5 USRP、CRC/净吞吐/RF–DC标定仍开放。多QAM仅为外推支撑。

Rule reflection: added/updated workbook/quality-assurance.md，因为辅助S对照必须保留接收掩码、独立供体及有效载荷语义，并禁止把未测量通信记为零错误。所有Markdown采用追加；本上下文自审，不声称独立reviewer。源码自审/简化后最终检查另见清单最新快照。

Revision metadata: revision_id=p2_a34a6d110af5_20261024; current_status=current; supersedes=[baseline_p2_a34a6d110af5].


## 2026-10-25 学习文档归档路径补充

本段仅更新阅读位置，原研究结论和历史路径文字保留。当前文档位置：

- [等功率机制对照与P2执行清单.md](../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制对照与P2执行清单.md)
- [等功率机制与P2当前结论.md](../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/等功率机制与P2当前结论.md)
- [P2正式实验预算与执行顺序.md](../学习文档/多载波OFDM瑞利信道-loop/机制对照与P2/P2正式实验预算与执行顺序.md)

Revision metadata: revision_id=learning_relocation_ef46896787_20261025; current_status=current; supersedes=[p2_a34a6d110af5_20261024].
