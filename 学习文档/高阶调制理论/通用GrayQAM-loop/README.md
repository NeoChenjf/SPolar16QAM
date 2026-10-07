# 开题计划第一项：高阶调制极化码仿真框架

> 本目录是开题计划第一项的**单一文档资料入口**。制作中期 PPT 时，先读本文，再读
> [中期PPT材料](中期PPT材料.md)；只有取图、核查数据或查看实现时，才按本文链接进入
> `16QAM_Polar/`。代码、结果表、日志和图片不复制到本目录。

## 1. 一句话理解

这项工作先在 v2 中闭环固定 16QAM 概率整形极化码，再在 v3 中把同一思想推广为可由
调制阶数 `M` 驱动的 8/16/32/64QAM 通用框架。可以把它理解为：先把一辆 16QAM
“样车”跑通，再把其中可复用的编码、星座、软解调和评价模块改造成同一条生产线。

开题计划中的原表述为：

> 文献调研，建立高阶调制极化码仿真框架。

当前可核验的完成表述为：

> 已完成固定 16QAM 单载波概率整形极化码闭环，并建立面向 8/16/32/64QAM 的通用
> Cartesian Gray QAM shaped-polar 仿真框架，覆盖编码、调制、复 AWGN、先验感知软解调、
> SC 译码以及 BER、BLER、Goodput 和发送端射频能量代理量统计。

## 2. 范围与边界

### 本项已经覆盖

- 单载波、复 AWGN、Cartesian Gray QAM；
- v2 固定 16QAM 四路极化码基线；
- v3 面向 8/16/32/64QAM 的 multi-stream BICM 扩展；
- 概率整形、Gray-PAM/QAM、GF(2) relation、完整符号先验 MAP/LSE LLR；
- source-MC+GA 构造、消息条件化 SC precoder、SC decoder；
- 星座/标签、PMF、无噪声环回、有限 SNR BER、能量单调五类门禁；
- BER、BLER、Goodput、码率和平均发送 RF 能量代理量。

### 本项明确不包含

- OFDM、Rayleigh 衰落和子载波资源分配，它们属于开题计划第二项；
- USRP、无辅助载波接收架构和端到端硬件测试，它们属于后续研究阶段；
- 非线性整流器模型、实测直流功率或实测整流效率；
- 参考论文“单个整体 polar codeword 分块后继续极化”的严格有限长复现；
- SCL 的论文级对照和跨调制阶数“最优整形参数”结论。

因此，文档中的“能量”均指**固定均匀星座缩放下的平均发送 RF 能量代理量**，不能写成
“实测收获能量”或“整流效率”。v3 应称为 **multi-stream BICM extension**，不能称为与
参考论文单整体 polar graph 有限长等价。

## 3. v2 → v3 研究演进

| 阶段 | 解决的问题 | 实现与验证 | 当前结论 |
| --- | --- | --- | --- |
| v2 固定16QAM基线 | 概率整形如何同时影响星座能量、编码可靠性和有效码率 | 四路极化编码、Gray 16QAM、AWGN、先验软解调、SC译码及统一口径 Monte Carlo | 已完成单载波16QAM闭环；强整形存在局部收益，但未形成全局 Goodput 最优 |
| v3 通用Gray QAM | 如何摆脱固定四路和硬编码bit位置，将框架推广到多个调制阶数 | `M` 驱动的Gray-PAM/QAM、latent概率、relation、source-MC+GA、完整先验LLR和统一结果结构 | 8/16/32/64QAM均通过A—E技术门禁，跨M接口完成 |

### v2 固定16QAM关键结果

- 统一口径：单载波、16QAM、概率整形 polar code、SC译码、`fixed_esn0`。
- `p=0.5` 为无整形基线，`p` 越小整形越强、平均发送能量越高，但有效码率上限降低。
- 统一口径 final global curve 中，`p=0.5, 20 dB` 的最高 Goodput 为 `0.493325`；
  `p=0.1, 20 dB` 为 `0.351307`。
- 在 `10 dB` 局部点，`p=0.1` 的 Goodput 为 `0.294712`，高于 `p=0.5` 的
  `0.263812`，说明强整形可在部分中低 SNR 区间形成局部收益。
- 阶段结论不是“整形无效”，而是：几何能量收益、编码侧可靠性损失和有效码率上限共同
  决定系统 Goodput，统一整形参数没有在当前单载波 SC 口径下形成全局最优。

### v3 通用化关键结果

- 8/16/32/64QAM 四个工作单元均通过 A星座/标签、B PMF、C无噪声环回、D AWGN BER、
  E能量单调门禁。
- energy-lambda smoke 中，四种 `M` 的模型能量和真实码字经验能量均随 `lambda` 增大；
  8组相邻经验能量差的单侧95% bootstrap下界均大于0。
- 64QAM正式PMF补充实验中，`lambda=0/0.25/0.5` 的经验PMF TV置信上界分别为
  `0.01877/0.02680/0.03310`，均不超过正式阈值 `0.05`。
- N=256/1024受控补充对照中，12个`M × lambda`点的经验PMF TV 95%上界在N=1024下
  全部下降，12点中11点的经验能量绝对理论差缩小；较长码字改善分布逼近，但没有消除
  model到empirical的有限长构造差距。
- BER refine 的12条 `M × lambda` 曲线均取得5—7个有效瀑布区点，最低有效错误数104，
  证明有限 SNR 链路和门禁口径可执行；这不等于已经证明某个 `lambda` 稳定最优。

## 4. 阅读导航

### 做中期PPT

1. [中期PPT材料](中期PPT材料.md)：六页内容、讲述顺序、图表路径和答辩边界；
2. 本文第3节：核对 v2→v3 主线和核心数字；
3. 本文第6节：从 `16QAM_Polar/` 取图。

### 核查设计与实现

| 文档 | 作用 |
| --- | --- |
| [需求澄清](需求澄清.md) | v3目标、范围、工作单元和验收条件 |
| [loop设计](loop设计.md) | 架构、执行顺序、验证机制和终止条件 |
| [协调协议](协调协议.md) | 输入输出、星座、概率、LLR、SNR、能量和结果目录的统一口径 |
| [进度表](进度表.md) | v2/v3总览及v3逐项完成证据 |
| [问题记录](问题记录.md) | 关键问题、修复决策和闭环证据 |
| [next_plan](next_plan.md) | 当前完成状态、研究边界和后续分流 |
| [高阶调制理论方法](../方法.md) | v2与v3理论差异及方法演进 |
| [多载波任意GrayQAM能量分布可调理论说明](多载波任意GrayQAM能量分布可调理论说明.md) | 答辩用理论说明：从能量倾斜PMF、Polar实现到OFDM分组/子载波级能量分配 |

## 5. 实现与证据索引

| 内容 | 文档证据 | 代码/结果证据（保留在 `16QAM_Polar/`） |
| --- | --- | --- |
| v2系统结构与最终结论 | [阶段A：单载波关键结论](../../../周报/阶段A：单载波关键结论.md) | [`sim_shaped_polar_16qam.m`](../../../16QAM_Polar/v2/core/sim_shaped_polar_16qam.m)；[`final global curves`](../../../16QAM_Polar/v2/results/20260521_150555_phaseA_sc_final_global_curves/) |
| v2论文展示图 | [阶段A第5—6节](../../../周报/阶段A：单载波关键结论.md#5-蒙特卡洛验证) | [`phaseA_sc_mechanism_figures`](../../../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/) |
| v3通用框架 | [需求澄清](需求澄清.md)、[loop设计](loop设计.md)、[协调协议](协调协议.md) | [v3 README](../../../16QAM_Polar/v3/README.md)、[`run_gray_qam.m`](../../../16QAM_Polar/v3/run_gray_qam.m) |
| v3逐项完成状态 | [进度表](进度表.md)、[next_plan](next_plan.md) | [v3 results](../../../16QAM_Polar/v3/results/) |
| v3开发与验证时间线 | [问题记录](问题记录.md) | [高阶调制周报](../../../周报/高阶调制/README.md) |

## 6. PPT推荐图表

所有结果图片仍保存在 `16QAM_Polar/` 中，本目录只提供索引，不复制图片文件。

| 优先级 | 图表 | 推荐用途 | 文件 |
| --- | --- | --- | --- |
| 必选 | v2 full-chain Goodput—Energy | 展示单载波信息—能量权衡 | [phaseA_fullchain_goodput_energy.png](../../../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_fullchain_goodput_energy.png) |
| 可选 | v2 full-chain BER | 展示不同 `p` 的完整链路BER | [phaseA_fullchain_ber_sim_vs_snr.png](../../../16QAM_Polar/v2/results/20260523_175018_phaseA_sc_mechanism_figures/figures/phaseA_fullchain_ber_sim_vs_snr.png) |
| 必选 | v3能量随lambda变化 | 展示四种调制阶数的能量单调门禁 | [energy_vs_lambda.png](../../../16QAM_Polar/v3/results/20260902_224303_energy_lambda_smoke/energy_vs_lambda.png) |
| 补充 | v3 N=256/1024能量对照 | 区分理论目标、latent模型与有限长真实码字 | [energy_blocklength_compare.png](../../../16QAM_Polar/v3/results/20260916_225430_energy_lambda_blocklength_formal/energy_blocklength_compare.png) |
| 补充 | v3 N=256/1024 PMF TV对照 | 展示码长增加后的分布逼近改善 | [pmf_tv_blocklength_compare.png](../../../16QAM_Polar/v3/results/20260916_225430_energy_lambda_blocklength_formal/pmf_tv_blocklength_compare.png) |
| 必选 | v3 BER refine | 展示8/16/32/64QAM有限SNR链路均进入有效瀑布区 | [ber_refine.png](../../../16QAM_Polar/v3/results/20260903_210444_ber_refine/ber_refine.png) |
| 可选 | 64QAM正式PMF | 展示目标、模型与经验分布的一致性 | [pmf_formal64.png](../../../16QAM_Polar/v3/results/20260903_221630_pmf_formal64/pmf_formal64.png) |

## 7. 可说与不可说

### 可以说

- 已建立覆盖8/16/32/64QAM的通用单载波高阶调制极化码仿真框架。
- v2完成了16QAM概率整形在BER、Goodput和发送RF能量代理量之间的统一口径闭环。
- v3四种调制阶数均完成星座、分布、环回、有限SNR BER和能量单调验证。
- 当前技术门禁表明框架可运行、分布可控、能量趋势可复现，并揭示通信性能与能量之间的权衡。

### 不可以说

- 已经得到实测整流效率或完成USRP验证；
- 已完成OFDM/Rayleigh子载波级优化；
- v3严格复现了参考论文的单整体polar graph；
- 3次BER重复已经证明某一整形参数在所有调制阶数下稳定最优；
- 强整形在全部SNR区间优于均匀基线。

## 8. 资料维护规则

- 本文是开题计划第一项的固定入口；新增阶段性结论先更新本文和[中期PPT材料](中期PPT材料.md)。
- 详细契约、问题和逐项状态继续分别写入现有六份loop文档，避免在README中复制开发流水账。
- 代码、数据、日志和图片继续写入 `16QAM_Polar/v2/` 或 `16QAM_Polar/v3/` 的时间戳结果目录。
- 若研究转向OFDM/Rayleigh、USRP或非线性整流器，应进入对应的新阶段文档，不扩张本目录范围。
