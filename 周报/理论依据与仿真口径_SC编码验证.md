# SC 编码侧 BER 定量分析：理论边界、近似口径与仿真验证

> 所属阶段：阶段 A 单载波系统收口  
> 文档定位：编码侧 BER 定量分析的严谨路线图  
> 当前结论：有限长 polar code + SC 译码 + 概率整形下，没有一个简单闭式 BER 公式能完整覆盖当前系统  
> 覆盖范围：主线限定在单载波 code-only / full-chain 理论口径；多载波只作为后续扩展入口

本文重写的目的，是把阶段 A 中“概率整形参数 `p` 如何影响 SC 编码侧 BER”这件事讲得更严谨。早期文档把 GA 可靠性排序、Bhattacharyya 近似和 Monte Carlo 仿真放在一起，容易给人一种错觉：似乎已经有一个可直接预测有限长 SC BER 的闭式公式。

更准确的说法是：

> GA / Bhattacharyya / density evolution 一类方法可以给出 polar bit-channel 的可靠性排序、误差上界或趋势近似；真实有限长 `N=1024`、SC 逐位译码、概率整形改变 `S/I/F` 集合后的 BER，仍需要 Monte Carlo 或更精细的有限长模型验证。

---

## 1. 核心问题：为什么原有定量分析不够严谨

阶段 A 的 code-only 问题可以写成：

```text
p
-> H(p)
-> S(p), K(p), F(p)
-> 信息位集合 I(p)
-> polar encoder
-> BPSK-AWGN
-> SC decoder
-> 信息位 BER
```

这里的困难在于，`p` 不是只改变某一个参数。它同时改变：

1. 整形位数量 `S(p)`；
2. 信息位数量 `K(p)`；
3. 冻结位数量 `F(p)`；
4. 信息位集合 `I(p)` 在 polar 虚拟信道排序中的位置；
5. 最终 BER 的加权分母；
6. full-chain 中的 16QAM 符号概率和 bit-level LLR 信道。

因此，如果只写一个类似

$$
\mathrm{BER}(p,\gamma)\approx \frac{1}{K(p)}\sum_{i\in\mathcal I(p)} q(u_i(\gamma))
$$

它最多是一个工程近似，而不是完整定量理论。它没有完整刻画有限长 SC 译码的错误传播，也没有刻画 16QAM BICM LLR 信道和概率整形先验之间的关系。

本文采用分层口径：

| 层级 | 作用 | 能说明什么 | 不能说明什么 |
| --- | --- | --- | --- |
| Polar 理论上界 | 基于 bit-channel 可靠性 | 信息集合越可靠，误错风险越低 | 不能给出精确有限长 BER |
| GA / Bhattacharyya 近似 | 构造可靠性排序 | `p` 改变信息位落点后的趋势 | 不能替代 SC Monte Carlo |
| code-only BPSK 仿真 | 隔离几何因素 | 编码侧是否被 `p` 损伤 | 不能说明完整 16QAM 收益 |
| full-chain 16QAM 仿真 | 系统最终口径 | BER / Goodput / Energy tradeoff | 不能直接反推出闭式理论 |

---

## 2. BPSK-AWGN polar code 的理论对象

最基础的 polar code 理论从一个二进制输入信道开始：

$$
W: X\rightarrow Y,\qquad X\in\{0,1\}.
$$

在 BPSK-AWGN 口径下：

$$
x=1-2u,
$$

$$
y=x+n,\qquad n\sim\mathcal N(0,\sigma^2).
$$

接收端 LLR 为：

$$
L(y)=\log\frac{P(Y=y|U=0)}{P(Y=y|U=1)}
=\frac{2y}{\sigma^2}.
$$

polar transform 把原始信道 `W` 极化成 `N` 个虚拟信道：

$$
W_N^{(1)}, W_N^{(2)},\ldots,W_N^{(N)}.
$$

每个虚拟信道有不同可靠性。构造 polar code 时，需要把位置分成：

1. 信息位集合 $\mathcal I$；
2. 冻结位集合 $\mathcal F$；
3. 在概率整形口径下，还会多出整形位集合 $\mathcal S$。

普通 polar code 的基本想法是：把信息位放在更可靠的虚拟信道上，把冻结位放在较差的虚拟信道上。

---

## 3. SC 译码下能写出的上界与近似

对于 polar code，经典理论中常用 Bhattacharyya 参数描述虚拟信道可靠性：

$$
Z(W_N^{(i)}).
$$

在 SC 译码下，一个常见 block error 上界是：

$$
P_{\mathrm{block}}
\le
\sum_{i\in\mathcal I} Z(W_N^{(i)}).
$$

这条式子的含义是：如果信息集合里的虚拟信道都很可靠，那么块错误概率上界会更小。

如果要从 block error 上界转成 bit-level BER 的工程近似，可以写成：

$$
\widehat{\mathrm{BER}}
\approx
\frac{1}{K}
\sum_{i\in\mathcal I}
\widehat P_{e,i}.
$$

若使用 Bhattacharyya 参数的保守形式，可写成：

$$
\widehat{\mathrm{BER}}
\lesssim
\frac{1}{K}
\sum_{i\in\mathcal I}
Z(W_N^{(i)}).
$$

但这里必须强调三点：

1. 这是上界或近似，不是精确 BER 闭式；
2. 它没有完整描述 SC 译码中的错误传播；
3. 对 `N=1024` 的有限长码，数量级可能明显偏离 Monte Carlo。

Fong 和 Tan 在 AWGN polar code 的 scaling exponent / moderate deviations 分析中也采用这种口径：论文定义的是 AWGN 下的平均消息错误概率

$$
P\{\hat W\ne W\},
$$

并给出基于 Bhattacharyya 参数的错误概率上界，而不是有限长 bit BER 的精确公式。其一般形式可以概括为：

$$
P\{\hat W_I\ne W_I\}
\le
\sum_{i=1}^{N}\sum_{k\in J_i}
Z\!\left(
U_{i,k}\mid U_i^{k-1},X_{[i-1]}^n,Y^n
\right).
$$

在单路 polar code 的直观口径下，它对应于：

$$
P_{\mathrm{block}}
\le
\sum_{i\in\mathcal I} Z(W_N^{(i)}).
$$

该文进一步证明 AWGN polar code 可以达到 scaling exponent 上界。例如对某类 AWGN polar code，有：

$$
\frac{1}{n}\sum_{i=1}^{N}|J_i^{SE}|
\ge
C(P)-\frac{t^\*\log n}{n^{1/\beta}},
\qquad
\beta=4.714,
$$

同时平均错误概率满足形如：

$$
P\{\hat W_I\ne W_I\}
\le
\frac{\log n}{n^3}
+ \text{power-outage correction}.
$$

在 moderate deviations 口径下，论文还给出容量 gap 与错误概率衰减的权衡：

$$
\frac{1}{n}\sum_{i=1}^{N}|J_i^{MD}|
\ge
C(P)-\frac{t^\*_{MD}\log n}{n^{(1-\gamma)/\beta}},
$$

$$
P\{\hat W_I\ne W_I\}
\le
(n\log n+e^3)
2^{-n^{\gamma h_2^{-1}\left(\frac{\gamma\beta+\gamma-1}{\gamma\beta}\right)}}.
$$

这些公式说明的是：在 AWGN 下，polar code 的错误概率如何随码长、容量 gap 和构造口径渐近下降。它们不是给定 `N=1024`、`K`、具体信息集合和 SC 译码实现后的 BER 闭式公式。对本文最重要的启发是：

> 文献层面的 AWGN 有限长 polar 结果通常给出 block/message error probability 的上界或渐近衰减规律；若要讨论信息位 BER，最多可用
> $$
> \mathrm{BER}\le P_{\mathrm{block}}
> \le \sum_{i\in\mathcal I}Z(W_N^{(i)})
> $$
> 作为保守边界，而不能把它写成 BER 关于 `N,K` 的精确公式。

GA 的作用也是类似的。GA 将 AWGN 下 LLR 视为高斯随机变量，并递推估计每个虚拟信道的可靠性：

```matlab
sigma = 10^(-snr_dB/20);
channels = GA(sigma, N);
[~, channels_ordered] = sort(channels, 'descend');
```

在本项目中，[polar/GA.m](../16QAM_Polar/v2/polar/GA.m) 给出的 `channels_ordered` 主要用于构造可靠性排序。它能帮助判断“信息位大致落在好信道还是坏信道上”，但不能直接当作有限长 SC BER 的精确公式。

---

## 4. 有限码长 `N=1024` 与 `I/F` 配比如何进入 BER

当前代码的 polar 码长为：

```matlab
N = 1024;
```

对于普通 polar code，如果信息位数为 `K`，则有：

$$
|\mathcal I|=K,\qquad |\mathcal F|=N-K.
$$

BER 的统计对象是信息位：

$$
\mathrm{BER}
=
\frac{\#\text{错误信息位}}
{K\times\#\text{frames}}.
$$

因此，即使信道 SNR 不变，只要 `K` 或 `I` 的位置发生变化，BER 统计对象就已经变了。

有限码长下还有一个关键问题：SC 译码是逐位判决。第 `i` 位译错后，它会作为后续位的已知历史参与计算，可能污染后续 LLR。于是真实误码机制不是简单的“每个 bit-channel 独立出错再求平均”。

这解释了为什么：

1. GA 理论通常可以解释趋势；
2. GA 理论在很多点上低估真实 SC 仿真 BER；
3. `p` 改变后，局部 SNR 点可能出现非单调现象；
4. 需要在有效 waterfall window 中看 Monte Carlo，而不能用全零误码区解释理论偏差。

---

## 5. 概率整形 `p` 如何改变 `S/I/F` 集合与码率上限

当前项目的整形参数结构为：

```matlab
cfg.p_fixed = [0.5, NaN, 0.5, NaN];
```

也就是说，bit1/bit3 固定为均匀分布，bit2/bit4 由统一参数 `p` 控制。

每一路先计算二元熵：

$$
H(p_b)
=
-p_b\log_2p_b
-(1-p_b)\log_2(1-p_b).
$$

整形位数量为：

$$
S_b(p)
=
\lceil N(1-H(p_b))\rceil.
$$

信息位数量为：

$$
K_b(p)
=
\left\lceil
\frac{N-S_b(p)}{2}
\right\rceil.
$$

冻结位数量可以写成：

$$
F_b(p)=N-S_b(p)-K_b(p).
$$

因此，`p` 的影响链条是：

```text
p
-> H(p)
-> S_b(p) increases when p moves away from 0.5
-> K_b(p) decreases
-> F_b(p) changes
-> I_b(p), S_b(p), F_b(p) positions change
-> code-only BER and Goodput ceiling change together
```

系统有效码率为：

$$
R_{\mathrm{total}}(p)
=
\frac{\sum_{b=1}^{4}K_b(p)}{4N}.
$$

这意味着，强整形不仅可能影响 BER，还会降低无误码情况下的 Goodput 上限。

代表性上限如下：

| p | R_total | 理想无误码 Goodput 上限 |
| --- | ---: | ---: |
| 0.5 | 0.500000 | 0.500000 |
| 0.4 | 0.492676 | 0.492676 |
| 0.3 | 0.470215 | 0.470215 |
| 0.2 | 0.430664 | 0.430664 |
| 0.1 | 0.367188 | 0.367188 |

所以不能只问“`p` 变小后 BER 是否下降”。更完整的问题是：

> `p` 变小后，几何/能量收益、编码侧 BER、信息位数量和 Goodput 上限是否共同形成系统收益？

---

## 6. code-only BPSK 仿真口径：它验证什么、不验证什么

code-only BPSK 仿真的目的，是把 16QAM 几何因素暂时拿掉，只看概率整形对 polar 编码侧的影响。

仿真链路为：

```text
信息位
-> S/I/F 集合划分
-> polar_encoder
-> BPSK-AWGN
-> SC_decoder
-> 信息位 BER
```

发射信号：

$$
x=1-2c.
$$

信道：

$$
y=x+\sigma n,\qquad n\sim\mathcal N(0,1).
$$

LLR：

$$
L=\frac{2y}{\sigma^2}.
$$

BER：

$$
\mathrm{BER}_{\mathrm{sim}}
=
\frac{\#\text{错误信息位}}
{\sum_b K_b(p)\times\#\text{frames}}.
$$

它能验证：

1. `p` 改变 `S/I/F` 集合后，编码侧是否被损伤；
2. GA 排序给出的趋势是否大体可信；
3. 有效 waterfall window 在哪里；
4. 哪些 `p` 在有限长 SC 下明显变差。

它不能验证：

1. 16QAM 几何收益；
2. shaped 16QAM 的 bit-level LLR 信道；
3. full-chain Goodput 最优策略；
4. 多载波子载波级 `p_k` 策略。

当前阶段 A 的 code-only 关键结论仍保留：

| p | selected SNR(dB) | BER_sim_mean | CI95 | BER_theory | gap |
| --- | ---: | ---: | ---: | ---: | ---: |
| 0.5 | 2.5 | 1.956e-3 | 1.206e-3 | 3.814e-5 | 1.918e-3 |
| 0.4 | 2.5 | 4.039e-3 | 7.851e-4 | 7.820e-5 | 3.961e-3 |
| 0.3 | 3.0 | 2.209e-3 | 6.801e-4 | 1.039e-4 | 2.105e-3 |
| 0.2 | 3.0 | 5.057e-2 | 5.543e-3 | 4.804e-3 | 4.576e-2 |
| 0.1 | 3.0 | 1.545e-1 | 6.320e-4 | 1.135e-1 | 4.106e-2 |

结论是：

> 在 code-only SC 极化码链路中，小 `p` 尤其 `p<=0.2` 会显著提高编码侧 BER。GA 理论能解释趋势，但多数点低估真实有限长 SC 仿真。

---

## 7. GA 理论、SC 仿真、ratio 对比的正确解释边界

### 7.1 GA / Bhattacharyya 的定位

GA / Bhattacharyya 可用于：

1. 构造 polar 虚拟信道可靠性排序；
2. 判断信息位集合是否落在较可靠位置；
3. 给出趋势解释；
4. 提供误差上界或近似。

不应写成：

> GA 给出了当前 `N=1024`、SC 译码、概率整形 polar code 的精确 BER 公式。

更稳妥的写法是：

> GA 给出 BPSK-AWGN 等效口径下的可靠性排序和 BER 趋势近似，真实 BER 以有限长 SC Monte Carlo 为准。

### 7.2 SC Monte Carlo 的定位

SC Monte Carlo 给出当前实现口径下的真实有限长结果。它显式包含：

1. `N=1024` 有限长；
2. 逐位 SC 判决；
3. 错误传播；
4. 当前 `S/I/F` 集合划分；
5. 当前 LLR 计算口径。

因此，阶段 A 定稿结论应以 Monte Carlo full-chain 为主，以 code-only Monte Carlo 解释编码侧机制。

### 7.3 ratio 对比的定位

ratio 对比可以定义为：

$$
\mathrm{ratio}_{\mathrm{sim}}(p)
=
\frac{\mathrm{BER}_{\mathrm{sim}}(p)}
{\mathrm{BER}_{\mathrm{sim}}(0.5)}.
$$

$$
\mathrm{ratio}_{\mathrm{theory}}(p)
=
\frac{\mathrm{BER}_{\mathrm{theory}}(p)}
{\mathrm{BER}_{\mathrm{theory}}(0.5)}.
$$

它的作用是看趋势是否同向，而不是证明绝对 BER 公式成立。

如果绝对 BER 差距很大，但 ratio 趋势接近，只能说明：

> 当前近似抓住了 `p` 改变信息位可靠性分布的部分相对效应，但没有完整刻画有限长 SC 误差机制。

### 7.4 waterfall window 的要求

BER 理论-仿真偏差必须在有效 waterfall window 中讨论。全零误码窗口不能用于解释偏差。

阶段 A 中，code-only 有效窗口已经从早期误判的 `11~13 dB` 下移到：

```text
1~3 dB
```

这与 workbook 规则一致：BER 异常必须先定位到约 `1e-4 ~ 1e-1` 的有效误码区间。

---

## 8. 接回 16QAM full-chain：几何项、LLR bit-channel、Goodput

code-only BPSK 只能回答编码侧问题。完整 16QAM full-chain 还包含：

```text
probabilistic shaping
-> 16QAM symbol distribution
-> bit-level LLR channel
-> four parallel polar decoders
-> weighted BER
-> R_total(p)
-> Goodput
```

当前阶段 A 的 full-chain Goodput 定义为：

$$
G(p,\gamma)
=
R_{\mathrm{total}}(p)
\left(
1-\mathrm{BER}(p,\gamma)
\right).
$$

16QAM 几何侧有能量 proxy：

$$
E(p)=18-16p.
$$

但完整链路不应写成“code-only BER 乘一个几何比例”就完事。更严格的 full-chain 理论对象应该是 shaped 16QAM BICM bit-level LLR 信道：

$$
W_{b,p}: B_b \rightarrow L_b(Y).
$$

其中：

$$
L_b(Y)
=
\log
\frac{
\sum_{x\in\mathcal X_b^0}P_X(x)p(Y|x)
}{
\sum_{x\in\mathcal X_b^1}P_X(x)p(Y|x)
}.
$$

然后再进入：

```text
shaped 16QAM BICM bit-channel
-> per-bit-level polar construction
-> SC error bound / density evolution / equivalent GA
-> weighted BER
-> Goodput
```

这条路线已在 [整体定量分析16QAM.md](整体定量分析16QAM.md) 中作为后续理论增强任务记录。本文只把它作为阶段 A code-only 口径接回 full-chain 的边界说明，不在本文展开。

---

## 9. 多载波扩展路线：只作为 B 阶段理论入口

多载波 OFDM 场景中，平均 SNR 会进一步变成子载波级等效 SNR：

$$
\gamma_k=\gamma_{\mathrm{avg}}|H_k|^2.
$$

因此，B 阶段的理论链条会变成：

```text
subcarrier reliability gamma_k
-> bit-level shaped 16QAM channel W_{b,p,k}
-> polar construction or grouped reliability rule
-> p_k / role assignment
-> BER / Goodput / Energy
```

但这已经超出本文范围。本文只提供阶段 A 单载波 code-only / full-chain 的严谨解释边界。OFDM + 概率整形的定量理论应在阶段 B 文档中单独展开。

---

## 10. 当前可写结论与不可写结论

### 10.1 当前可以写

1. 在 BPSK-AWGN code-only 口径下，`p` 会通过 `H(p)` 改变 `S/I/F` 集合、信息位数量和信息位落点。
2. GA / Bhattacharyya 方法可用于构造可靠性排序和解释趋势。
3. 有限长 `N=1024` SC 译码存在错误传播，真实 BER 需要 Monte Carlo 验证。
4. 阶段 A code-only 瀑布区为 `1~3 dB`，不是早期误判的 `11~13 dB`。
5. 小 `p` 尤其 `p<=0.2` 在 code-only SC 中带来明显编码侧 BER 损失。
6. full-chain 结论必须同时考虑编码侧、16QAM 几何/LLR bit-channel 和 `R_total(p)` 上限。

### 10.2 当前不应写

1. 不写“GA 给出了有限长 SC BER 的精确闭式公式”。
2. 不写“ratio 对齐证明理论 BER 定量成立”。
3. 不用全零误码的高 SNR 窗口解释理论-仿真偏差。
4. 不把 code-only BPSK 结论直接等同于 full-chain 16QAM 结论。
5. 不把单载波 code-only 口径直接扩展成 OFDM `p_k` 最优策略。

---

## 11. 参考文献

1. Silas L. Fong and Vincent Y. F. Tan, “Scaling Exponent and Moderate Deviations Asymptotics of Polar Codes for the AWGN Channel,” 2018. 本地文件：[Scaling_Exponent_and_Moderate_Deviations_Asymptotics_of_Polar_Codes_for_the_AWGN_Channel.pdf](../参考文献2026/Scaling_Exponent_and_Moderate_Deviations_Asymptotics_of_Polar_Codes_for_the_AWGN_Channel.pdf)。本文引用其 AWGN polar code 平均错误概率定义、Bhattacharyya 参数上界、scaling exponent 和 moderate deviations 公式，用于说明文献给出的是 block/message error 上界或渐近关系，而非有限长 BER 精确闭式。
2. Erdal Arikan, “Channel Polarization: A Method for Constructing Capacity-Achieving Codes for Symmetric Binary-Input Memoryless Channels,” IEEE Transactions on Information Theory, 2009.
3. Ido Tal and Alexander Vardy, “How to Construct Polar Codes,” IEEE Transactions on Information Theory, 2013.
4. Peter Trifonov, “Efficient Design and Decoding of Polar Codes,” IEEE Transactions on Communications, 2012.

---

## 12. 变更记录与 rule reflection

- **2026-05-26**：补充 Fong 与 Tan 的 AWGN polar scaling exponent / moderate deviations 论文分析，并引用本地 PDF `参考文献2026/Scaling_Exponent_and_Moderate_Deviations_Asymptotics_of_Polar_Codes_for_the_AWGN_Channel.pdf`。新增内容说明该文给出的是平均消息错误概率、Bhattacharyya 参数上界、scaling exponent 和 moderate deviations 渐近关系，不是有限长 SC BER 精确公式；同时补充参考文献节。Rule reflection: no new durable rule
- **2026-05-26**：按“严谨路线图”重写本文档。重写后主线从 BPSK-AWGN polar code 理论对象出发，区分 SC error bound、GA/Bhattacharyya 近似、有限长 SC Monte Carlo、概率整形引起的 `S/I/F` 集合变化，并说明 code-only 结果如何接回 16QAM full-chain。影响范围仅为文档口径更新，不新增 MATLAB 脚本，不重新运行仿真；验证方式为结构检查、口径一致性检查，以及确认不再把 GA 表述为完整精确 BER 公式。Rule reflection: no new durable rule
