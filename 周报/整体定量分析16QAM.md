# 整体定量分析16QAM

> 任务定位：阶段 A 之后的理论增强任务  
> 目标：尝试建立更严格的 16QAM 概率整形 polar code full-chain 定量理论  
> 当前状态：研究路线与可执行分解，不替代 `阶段A：单载波关键结论.md` 的 Monte Carlo 结论

---

## 1. 为什么需要这个文档

阶段 A 已经得到单载波 SC 口径下的系统结论：强整形在中低 SNR 可出现局部 Goodput tradeoff，但没有形成稳定全局最优。这个结论的最终数值依据是统一口径 Monte Carlo full-chain 仿真。

但是，若论文或答辩中被追问：

1. full-chain Goodput 是否只是仿真结果；
2. 理论 BER 为什么不能和仿真更接近；
3. 概率整形、16QAM LLR、polar construction、SC 误差上界之间是否能形成更严格的定量链路；

仅靠当前 `estimate_ber_hat_sc_dual.m` 的 GA/BPSK 等效近似是不够的。因此，本文件单独记录一个更严格的理论增强路线。

核心目标不是“强行调参让理论贴合仿真”，而是重新定义理论对象：

```text
p
-> 16QAM shaped bit-level LLR channel
-> bit-level reliability / Bhattacharyya / mutual information
-> polar construction
-> SC error bound
-> weighted BER
-> Goodput
```

---

## 2. 理论基础

### 2.1 Polar code 与 SC 误差上界

Polar code 的基本对象是二进制输入离散无记忆信道 $W$。经过信道极化后，第 $i$ 个 bit-channel 可表示为 $W_N^{(i)}$。在 SC 译码下，一个常用的 block error 上界是信息集合中 bit-channel 可靠性指标的求和，例如：

$$
P_{\mathrm{block}}
\le
\sum_{i\in\mathcal I} Z(W_N^{(i)}),
$$

其中 $Z(\cdot)$ 是 Bhattacharyya 参数。实际 BER 可进一步用信息位加权平均或 bit-channel error probability 近似：

$$
\widehat{\mathrm{BER}}
\approx
\frac{1}{K}
\sum_{i\in\mathcal I}
\widehat P_{e,i}.
$$

这部分理论对应 polar code 的基本框架和构造问题。

### 2.2 BICM 与 16QAM bit-level LLR 信道

完整 16QAM 链路不是 BPSK-AWGN 信道，而是 bit-interleaved coded modulation 形式。对每个符号 $X\in\mathcal X$，接收信号为：

$$
Y=X+N,\qquad N\sim\mathcal{CN}(0,N_0).
$$

对于第 $b$ 个 bit-level，解调器输出 LLR：

$$
L_b(Y)
=
\log
\frac{
\sum_{x\in\mathcal X_b^0} P_X(x)\,p(Y|x)
}{
\sum_{x\in\mathcal X_b^1} P_X(x)\,p(Y|x)
}.
$$

这里必须注意：概率整形时 $P_X(x)$ 不是均匀分布。若 LLR 仍按均匀先验计算，理论口径就会和仿真口径不一致。

因此，更严格的 full-chain 理论应先建立每个 `p`、每个 bit-level 的等效二进制软输出信道：

$$
W_{b,p}: B_b \rightarrow L_b(Y).
$$

### 2.3 概率整形与码率上限

当前项目中：

```matlab
cfg.p_fixed = [0.5, NaN, 0.5, NaN];
```

所以 bit2/bit4 由 `p` 控制，bit1/bit3 固定均匀。每路信息位数量为：

$$
K_b(p)
=
\left\lceil
\frac{N-\lceil N(1-H(p_b))\rceil}{2}
\right\rceil.
$$

系统有效码率为：

$$
R_{\mathrm{total}}(p)
=
\frac{\sum_{b=1}^{4}K_b(p)}{4N}.
$$

最终 Goodput 必须写成：

$$
G(p,\gamma)
=
R_{\mathrm{total}}(p)
\,\left(
1-\mathrm{BER}(p,\gamma)
\right).
$$

所以严格理论不能只预测 BER，还必须保留 `K_b(p)` 和 `R_total(p)`。

---

## 3. 更严格 full-chain 理论应如何建立

### 3.1 第一步：建立 shaped 16QAM bit-level 信道

对每个候选 `p` 和每个 SNR：

1. 构造 16QAM Gray 星座 $\mathcal X$；
2. 根据 `p_fixed=[0.5,p,0.5,p]` 得到每个符号概率 $P_X(x)$；
3. 对每个 bit-level `b` 计算软输出 LLR 分布 $p(L_b|B_b=0)$ 和 $p(L_b|B_b=1)$；
4. 由该分布计算可靠性指标。

可选可靠性指标：

| 指标 | 用途 | 难度 |
| --- | --- | --- |
| bit-level MI $I(B_b;L_b)$ | 评估每路信息承载能力 | 中 |
| Bhattacharyya 参数 $Z(W_{b,p})$ | 进入 polar SC 上界更自然 | 中高 |
| LLR 均值/方差等效 GA 参数 | 便于复用现有 GA construction | 中 |
| 数值密度演化 | 最严格但实现较重 | 高 |

第一轮建议从 bit-level MI 和 LLR 等效 GA 参数开始，不直接上完整密度演化。

### 3.2 第二步：基于 bit-level 信道做 polar construction

当前 `sim_shaped_polar_16qam.m` 中，四路都使用同一个 BPSK-AWGN GA 排序：

```matlab
sigma = 10^(-snr_dB/20);
channels = GA(sigma, N);
[~, channels_ordered] = sort(channels, 'descend');
```

更严格的做法应该是：对每个 bit-level `b`，使用该路自己的 $W_{b,p}$ 可靠性构造：

$$
\{W_{b,p,N}^{(i)}\}_{i=1}^{N}.
$$

然后分别得到：

$$
\mathcal S_b(p,\gamma),\quad
\mathcal I_b(p,\gamma),\quad
\mathcal F_b(p,\gamma).
$$

这会带来一个重要变化：当前工程中 `S/I/F` 集合主要由 `p` 和 BPSK GA 排序决定；严格理论中，集合还会被 16QAM bit-level LLR 信道质量改变。

### 3.3 第三步：计算 SC 误差上界或 BER 近似

对于每个 bit-level：

$$
\widehat{\mathrm{BER}}_b(p,\gamma)
\approx
\frac{1}{K_b(p)}
\sum_{i\in\mathcal I_b(p,\gamma)}
\widehat P_{e,b,i}(p,\gamma).
$$

若使用 Bhattacharyya 参数，可以先给出上界形式：

$$
P_{\mathrm{block},b}
\le
\sum_{i\in\mathcal I_b(p,\gamma)}
Z(W_{b,p,N}^{(i)}).
$$

若需要 BER 而不是 BLER，可使用更保守的 bit-level 平均近似：

$$
\widehat{\mathrm{BER}}_b
\lesssim
\frac{1}{K_b(p)}
\sum_{i\in\mathcal I_b(p,\gamma)}
Z(W_{b,p,N}^{(i)}).
$$

这不是严格等号，但比当前“BPSK GA + 几何比例修正”更接近 full-chain 对象。

### 3.4 第四步：合成 full-chain BER 与 Goodput

四路加权 BER：

$$
\widehat{\mathrm{BER}}_{\mathrm{full}}(p,\gamma)
=
\frac{
\sum_{b=1}^{4}
K_b(p)\widehat{\mathrm{BER}}_b(p,\gamma)
}{
\sum_{b=1}^{4}K_b(p)
}.
$$

最终 Goodput：

$$
\widehat G(p,\gamma)
=
R_{\mathrm{total}}(p)
\,\left(
1-\widehat{\mathrm{BER}}_{\mathrm{full}}(p,\gamma)
\right).
$$

到这里，理论链条才真正和 full-chain 仿真对象对齐：

```text
16QAM shaped LLR bit-channel
-> polar bit-channel reliability
-> SC error bound
-> weighted BER
-> Goodput
```

---

## 4. 和当前理论模型的区别

当前 `estimate_ber_hat_sc_dual.m` 的核心是：

```text
BPSK-AWGN GA code-side BER
*
16QAM geometry relative ratio
```

它适合做机制解释，但不是严格 full-chain 定量理论。主要差异如下：

| 维度 | 当前模型 | 严格理论增强模型 |
| --- | --- | --- |
| 信道对象 | BPSK-AWGN 等效信道 | shaped 16QAM BICM LLR 位信道 |
| bit-level 差异 | 主要由 `p_fixed` 掩码体现 | 每个 bit-level 都有独立 LLR 分布 |
| 几何影响 | 后乘一个相对比例 | 直接进入 LLR 信道分布 |
| polar construction | 复用 GA 排序 | 基于 $W_{b,p}$ 重新构造 |
| 误差估计 | 经验 BER 近似 | SC 上界或密度演化近似 |
| Goodput | 可算但 BER 近似较粗 | BER 与 `R_total` 同口径合成 |

因此，下一步不应该继续调 `ratio_scale` 或 `independent_union`，而应该重建理论输入信道。

---

## 5. 推荐实现路线

### 5.1 最小可行版本

建议先实现一个诊断脚本，而不是立刻改主仿真：

```text
16QAM_Polar/v2/experiments/theory_quant/run_16qam_bicm_bit_channel_probe.m
```

第一版只做：

1. 输入 `p_list=[0.5,0.4,0.3,0.2,0.1]`；
2. 输入 `snr_grid=8:1:20`；
3. 对每个 `p,SNR,b` 估计 bit-level MI；
4. 输出 `bicm_bit_channel_metrics.csv`；
5. 绘制 `MI_b_vs_SNR` 和 `MI_total_vs_SNR`；
6. 与 Monte Carlo full-chain 的 `MI_total` 对比。

这个版本不直接预测 BER，只先确认理论 bit-level LLR 信道是否和仿真中的 `mutualinfo_llr` 指标对齐。

### 5.2 第二版：LLR 等效 GA 参数

在 bit-level LLR 分布可信后，尝试为每个 $W_{b,p}$ 构造等效 GA 参数：

$$
\mu_{b,p,\gamma}
\approx
J^{-1}(I(B_b;L_b)).
$$

然后把每路等效可靠性送入 polar GA construction，得到每路独立排序。

这一版的目标是输出：

```text
polar_bit_reliability_by_b_p_snr.csv
```

并检查：

1. `p` 是否改变 bit2/bit4 的可靠性排序；
2. 该排序是否解释 code-only 与 full-chain 中的 BER 差异；
3. `p=0.1` 在中低 SNR 的局部优势是否能从 bit-level MI 中看出来。

### 5.3 第三版：SC 上界与 BER/Goodput

在每路 polar bit-channel 可靠性可用后，输出：

```text
theory_fullchain_ber_bound.csv
theory_fullchain_goodput_bound.csv
```

并绘制：

```text
figures/theory_bound_vs_mc_ber.png/pdf/fig
figures/theory_bound_vs_mc_goodput.png/pdf/fig
```

这一版才有资格尝试回答：

> 理论定量曲线是否能在趋势和数量级上接近 full-chain Monte Carlo？

---

## 6. 验收标准

第一阶段不要求理论 BER 直接对齐 Monte Carlo。验收标准应分层：

| 阶段 | 验收目标 | 不要求 |
| --- | --- | --- |
| bit-channel probe | 理论 bit-level MI 与仿真 MI_total 趋势一致 | 不要求 BER |
| equivalent GA | 每路可靠性排序随 `p` 和 SNR 合理变化 | 不要求 Goodput 对齐 |
| SC bound | BER 上界趋势和数量级接近 Monte Carlo | 不要求逐点重合 |
| Goodput theory | 能解释 `p=0.1` 局部 tradeoff 与 `p=0.5` 全局 best | 不要求替代 Monte Carlo |

若理论上界始终偏松，也可以作为论文中的负结果：说明 full-chain 定量分析需要更精细的密度演化或仿真校准。

---

## 7. 风险和难点

1. **LLR 先验口径**：概率整形下，LLR 是否使用 shaped prior 会显著影响理论和仿真一致性。
2. **BICM mismatched decoding**：若解调 LLR 与实际先验不匹配，应按 mismatched BICM 口径解释。
3. **SC 误差传播**：bit-channel 独立误差近似不能完整刻画 SC 的路径依赖。
4. **有限长效应**：$N=1024$ 下的理论上界可能偏松，不能期待闭式曲线逐点贴合 Monte Carlo。
5. **复杂度**：完整密度演化或 LLR 分布离散化会比当前 GA 模型重很多。

因此，本任务应采用渐进路线：先验证 bit-level LLR 信道，再尝试 polar reliability，最后才进入 BER/Goodput。

---

## 8. 与阶段 A 文档的关系

`阶段A：单载波关键结论.md` 的当前结论不因本任务启动而改变：

1. 阶段 A 的系统结论仍以统一口径 Monte Carlo full-chain 为准；
2. 当前理论模型仍用于机制解释，不作为闭式定量预测；
3. 本文档是后续理论增强路线，用于尝试把 full-chain 定量理论补强。

如果本任务后续成功，应回填：

1. `周报/阶段A：单载波关键结论.md` 的“可能的质疑和回答”；
2. `next_plan.md` 的理论增强任务进展；
3. 对应脚本结果目录和 README。

---

## 9. 参考文献入口

以下文献用于支撑本任务的理论路线：

1. Erdal Arikan, “Channel Polarization: A Method for Constructing Capacity-Achieving Codes for Symmetric Binary-Input Memoryless Channels,” IEEE Transactions on Information Theory, 2009. DOI: `10.1109/TIT.2009.2021379`。参考入口：[arXiv](https://arxiv.org/abs/0807.3917)、[Bilkent repository](https://repository.bilkent.edu.tr/items/fcbc8657-48c9-41ab-9281-568028c7bd91)。
2. Ido Tal and Alexander Vardy, “How to Construct Polar Codes,” IEEE Transactions on Information Theory, 2013. 参考入口：[arXiv](https://arxiv.org/abs/1105.6164)、[Technion record](https://cris.technion.ac.il/en/publications/how-to-construct-polar-codes/)。
3. Giuseppe Caire, Giorgio Taricco, and Ezio Biglieri, “Bit-Interleaved Coded Modulation,” IEEE Transactions on Information Theory, 1998. DOI: `10.1109/18.669123`。参考入口：[Politecnico record](https://iris.polito.it/handle/11583/1406542)。
4. Alfonso Martinez, Albert Guillen i Fabregas, Giuseppe Caire, and Frans Willems, “Bit-Interleaved Coded Modulation Revisited: A Mismatched Decoding Perspective,” 2008. 参考入口：[arXiv](https://arxiv.org/abs/0805.1327)。
5. Georg Böcherer, Patrick Schulte, and Fabian Steiner, probabilistic amplitude shaping / coded modulation related work. 参考入口：[probabilistic shaping overview](https://www.nowpublishers.com/article/DownloadSummary/CIT-111)。

---

## 10. 变更记录

- **2026-05-22**：创建本文档，作为 16QAM 概率整形 polar code full-chain 定量理论增强任务的独立入口；明确研究目标、理论基础、分阶段实现路线、验收标准、风险边界和参考文献。未运行 MATLAB；验证方式为文档结构检查、Goodput 乘法公式检查，以及与 `阶段A：单载波关键结论.md` 的口径一致性检查。Rule reflection: no new durable rule
