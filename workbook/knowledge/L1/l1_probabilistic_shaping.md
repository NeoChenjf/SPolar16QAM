# L1 · 概率成形（Probabilistic Shaping）

- **domain_id**: l1_probabilistic_shaping
- **maturity**: active
- **rks_score**: 80

## Research Question
在 16QAM 上对部分比特施加非均匀概率（成形），能否在保持/可控牺牲信息速率的前提下，
系统性地改变平均符号能量，从而服务于「信息-能量协同传输」的权衡？

## Hypotheses
- H1: 减小成形参数 p（偏离 0.5）会**降低平均符号能量** E(p)=18−16p，可为能量收获腾出预算 → 由 l2_run_single / l2_run_sweep 验证。
- H2: 成形在压低码率上界 R=ΣK/(4N) 的同时，存在使 Goodput-能量代价最优的 p 区间 → 由 l2_run_sweep 验证。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| p | 成形参数（受控比特为 1 的概率口径） | — | config.p_fixed / p_candidates |
| h(p) | 比特熵 −p·log2 p −(1−p)·log2(1−p) | bit | l3_sim_shaped_polar_16qam |
| E(p) | 平均符号能量 = 18 − 16p（归一化前） | 能量 | l3_compute_energy |
| S | 整形位数 = ceil(N(1−h)) | — | l3_sim_shaped_polar_16qam |

## Theoretical Boundaries
- 归一化能量 `E_norm = (18−16p)/10`，基线 E(0.5)=10。
- 半径类别概率：内 `p²`、中 `2p(1−p)`、外 `(1−p)²`。
- 源极化整形：整形位由 SC 在先验 `ln((1−p)/p)` 下确定性生成。

## Pitfalls（护栏）
- ⚠️ 判定成形后吞吐优劣前，先核对码率上界 R=ΣK/(4N)——成形本就压低上界，不能与基线直接比绝对 Goodput。见 `workbook/mandatory-rules.md` §7。
- ⚠️ 成形改变 SNR 口径含义（Es/N0 vs Eb/N0），对照前确认 `cfg.snr_mode`。

## Collaborators
- → l1_polar_coding：h(p) 决定 S/I/F 集合大小与冻结位布局。
- → l1_16qam_modulation_llr：成形先验进入软解调（symbol prior）与译码先验（bit prior）。
- → l1_metrics_tradeoff：E(p) 是能量轴，Goodput 是信息轴。

## Code Anchors
- l3_compute_energy（core/compute_energy.m）
- l3_sim_shaped_polar_16qam（整形位生成 prepare_one_bit）
- l3_SC_decoder_prior / l3_SCL_decoder_prior（先验译码）


## 2026-10-09 研究假设追加：source-entropy S 的可复现有限长证据

- H3（有限长、指定参数范围）：在N∈{256,1024}、p∈{0.1,0.2,0.3,0.4,0.5}及固定原K/|S|下，独立源样本评估应显示source-entropy所选S的源条件熵低于旧GA计数分段；消息条件化整形的经验联合PMF TV单侧95%上界应不超过0.05。由l2_b4b_source_entropy_holdout_audit、l2_b4b_shaping_mechanism_audit及l2_b4b_blocklength_comparison验证。该假设只覆盖已测有限码长/参数及相应MC门限，不声称渐近收敛或普遍最优。

- 护栏追加：source conditional entropy由有限源码字估计；训练seed与评价seed必须分离。S的位置由源熵估计，I/F仍按每SNR的信道GA选择。通过PMF门禁不意味着接收LLR度量匹配，也不证明BER预测准确或RF-DC收益。


## Code anchors for H3

- l2_b4b_source_entropy_holdout_audit
- l2_b4b_shaping_mechanism_audit
- l2_b4b_blocklength_comparison
- l2_b4b_partition_snapshot_supplement (provenance completion only)
- l3_build_source_entropy_partition
- l3_rebuild_b4b_partition_snapshot_supplement

## 2026-10-09 固定16QAM新构造证据状态

Source-entropy S与余位GA I/F已通过显式集合和条件payload无噪声合同测试。单载波及OFDM正式图已经按该构造重建。能量结论仍受不同p发射符号功率影响，当前接收均方是RF代理；需固定平均发射功率后才能判断P1增益。BER近似理论在F19条件下对p≥.2低估明显，不能用作绝对可靠性约束；接收度量/GA模型需在P2拆分核验。详细数据入口和假设限制见本轮图重建清单。


## 2026-10-24 当前研究快照：随机辅助S与P2

- **domain_id**: l1_probabilistic_shaping
- **maturity**: active
- **rks_score**: 由结构扫描报告给出，不是科研完成率。

## Research Question

固定16QAM和发送时域功率后，区分整形消息配合、频域功率分布与通信代价，并检验实际I驱动的近似预测。

## Hypothesis status

既有l1_multicarrier_ofdm#H2仍为inconclusive：原P1六策略呈现折中，无普遍占优。既有l1_probabilistic_shaping#H3保持其原构造/PMF有限范围；新随机S证明与3×8诊断不能替代原假设或正式通信验收。

## Core Quantities / Boundaries

S是变换前辅助变量，p描述目标输出标签。S冻结0与独立随机S不是同一对照；同K同I不能保证均匀。随机S使用原I∪S且只计I有效载荷；其输入自由度增加，不能宣称同代码本大小。donor S保留独立S向量统计，输出不保证均匀。原星座关系E_norm=(18−16p)/10意味着p降低时未缩放能量增加；旧H1的“降低”方向文字不再采用，但不据此升级普遍性能主张。

多载波Goodput仍为实际I位数除以4×资源网格再乘CP因子及(1−BER)。BLER沿用B4四路联合组块口径。RF为加噪前时域均方，非DC。

## Pitfalls

⚠️ 按workbook/mandatory-rules.md核对瀑布区、码率上界及长跑授权；按workbook/quality-assurance.md检查实际集合、payload语义和未测量计数。近似模型必须冻结后独立验证，源条件熵不等于S边缘熵；相关边缘不能直接相乘。原P1三类基线保留，不能用新pilot宣称最优。只读引用/文件存在不等于验收。

## Code Anchors

l2_p2_mechanism、l2_p2_auxiliary_preflight、l3_p2_distribution_reference、l3_p2_uniformity_contract、l3_p2_predict_ga。

## Evidence status

精确集合覆盖和小码长穷举已核验；3seed×8码字只探索。正式1%功率、3×80 PMF和独立预测均待本轮预算确认，未将任何历史not_assessed自动改为supporting。

Revision metadata: revision_id=p2_1bb1d23189ab_20261024; current_status=current; supersedes=[baseline_08fb05905251].


# L1 · 概率成形（Probabilistic Shaping）

- **domain_id**: l1_probabilistic_shaping
- **maturity**: active
- **rks_score**: 80

## Research Question
在 16QAM 上对部分比特施加非均匀概率（成形），能否在保持/可控牺牲信息速率的前提下，
系统性地改变平均符号能量，从而服务于「信息-能量协同传输」的权衡？

## Hypotheses
- H1: 减小成形参数 p（偏离 0.5）会**降低平均符号能量** E(p)=18−16p，可为能量收获腾出预算 → 由 l2_run_single / l2_run_sweep 验证。
- H2: 成形在压低码率上界 R=ΣK/(4N) 的同时，存在使 Goodput-能量代价最优的 p 区间 → 由 l2_run_sweep 验证。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| p | 成形参数（受控比特为 1 的概率口径） | — | config.p_fixed / p_candidates |
| h(p) | 比特熵 −p·log2 p −(1−p)·log2(1−p) | bit | l3_sim_shaped_polar_16qam |
| E(p) | 平均符号能量 = 18 − 16p（归一化前） | 能量 | l3_compute_energy |
| S | 整形位数 = ceil(N(1−h)) | — | l3_sim_shaped_polar_16qam |

## Theoretical Boundaries
- 归一化能量 `E_norm = (18−16p)/10`，基线 E(0.5)=10。
- 半径类别概率：内 `p²`、中 `2p(1−p)`、外 `(1−p)²`。
- 源极化整形：整形位由 SC 在先验 `ln((1−p)/p)` 下确定性生成。

## Pitfalls（护栏）
- ⚠️ 判定成形后吞吐优劣前，先核对码率上界 R=ΣK/(4N)——成形本就压低上界，不能与基线直接比绝对 Goodput。见 `workbook/mandatory-rules.md` §7。
- ⚠️ 成形改变 SNR 口径含义（Es/N0 vs Eb/N0），对照前确认 `cfg.snr_mode`。

## Collaborators
- → l1_polar_coding：h(p) 决定 S/I/F 集合大小与冻结位布局。
- → l1_16qam_modulation_llr：成形先验进入软解调（symbol prior）与译码先验（bit prior）。
- → l1_metrics_tradeoff：E(p) 是能量轴，Goodput 是信息轴。

## Code Anchors
- l3_compute_energy（core/compute_energy.m）
- l3_sim_shaped_polar_16qam（整形位生成 prepare_one_bit）
- l3_SC_decoder_prior / l3_SCL_decoder_prior（先验译码）


## 2026-10-09 研究假设追加：source-entropy S 的可复现有限长证据

- H3（有限长、指定参数范围）：在N∈{256,1024}、p∈{0.1,0.2,0.3,0.4,0.5}及固定原K/|S|下，独立源样本评估应显示source-entropy所选S的源条件熵低于旧GA计数分段；消息条件化整形的经验联合PMF TV单侧95%上界应不超过0.05。由l2_b4b_source_entropy_holdout_audit、l2_b4b_shaping_mechanism_audit及l2_b4b_blocklength_comparison验证。该假设只覆盖已测有限码长/参数及相应MC门限，不声称渐近收敛或普遍最优。

- 护栏追加：source conditional entropy由有限源码字估计；训练seed与评价seed必须分离。S的位置由源熵估计，I/F仍按每SNR的信道GA选择。通过PMF门禁不意味着接收LLR度量匹配，也不证明BER预测准确或RF-DC收益。


## Code anchors for H3

- l2_b4b_source_entropy_holdout_audit
- l2_b4b_shaping_mechanism_audit
- l2_b4b_blocklength_comparison
- l2_b4b_partition_snapshot_supplement (provenance completion only)
- l3_build_source_entropy_partition
- l3_rebuild_b4b_partition_snapshot_supplement

## 2026-10-09 固定16QAM新构造证据状态

Source-entropy S与余位GA I/F已通过显式集合和条件payload无噪声合同测试。单载波及OFDM正式图已经按该构造重建。能量结论仍受不同p发射符号功率影响，当前接收均方是RF代理；需固定平均发射功率后才能判断P1增益。BER近似理论在F19条件下对p≥.2低估明显，不能用作绝对可靠性约束；接收度量/GA模型需在P2拆分核验。详细数据入口和假设限制见本轮图重建清单。


## 2026-10-24 当前研究快照：随机辅助S与P2

- **domain_id**: l1_probabilistic_shaping
- **maturity**: active
- **rks_score**: 由结构扫描报告给出，不是科研完成率。

## Research Question

固定16QAM和发送时域功率后，区分整形消息配合、频域功率分布与通信代价，并检验实际I驱动的近似预测。

## Hypothesis status

既有l1_multicarrier_ofdm#H2仍为inconclusive：原P1六策略呈现折中，无普遍占优。既有l1_probabilistic_shaping#H3保持其原构造/PMF有限范围；新随机S证明与3×8诊断不能替代原假设或正式通信验收。

## Core Quantities / Boundaries

S是变换前辅助变量，p描述目标输出标签。S冻结0与独立随机S不是同一对照；同K同I不能保证均匀。随机S使用原I∪S且只计I有效载荷；其输入自由度增加，不能宣称同代码本大小。donor S保留独立S向量统计，输出不保证均匀。原星座关系E_norm=(18−16p)/10意味着p降低时未缩放能量增加；旧H1的“降低”方向文字不再采用，但不据此升级普遍性能主张。

多载波Goodput仍为实际I位数除以4×资源网格再乘CP因子及(1−BER)。BLER沿用B4四路联合组块口径。RF为加噪前时域均方，非DC。

## Pitfalls

⚠️ 按workbook/mandatory-rules.md核对瀑布区、码率上界及长跑授权；按workbook/quality-assurance.md检查实际集合、payload语义和未测量计数。近似模型必须冻结后独立验证，源条件熵不等于S边缘熵；相关边缘不能直接相乘。原P1三类基线保留，不能用新pilot宣称最优。只读引用/文件存在不等于验收。

## Code Anchors

l2_p2_mechanism、l2_p2_auxiliary_preflight、l3_p2_distribution_reference、l3_p2_uniformity_contract、l3_p2_predict_ga。

## Evidence status

精确集合覆盖和小码长穷举已核验；3seed×8码字只探索。正式1%功率、3×80 PMF和独立预测均待本轮预算确认，未将任何历史not_assessed自动改为supporting。



## 2026-10-25 新增辅助S对照假设

- H4（当前有限集合与实现验收）：N=1024、p=.5/.3/.1、当前源熵S与余位GA-I/F下，在原I与S放独立公平辅助输入、F=0，应得到逐位置均匀标签联合PMF；实际随机S实现仍需通过3seed×80码字、TV单侧95%上界≤.05。有效载荷只计I，接收端不预知S。由l2_p2_mechanism与l2_p2_uniformity_audit验证。

H4当前为inconclusive：21组生成矩阵覆盖与小码长穷举支持其结构部分；正式3×80经验门禁未执行。该新增假设不改写既有H3，不将原整形方案的PMF与随机对照混为一谈，也不主张通信或RF收益。证据入口为results/20261025_000154_p2_uniformity_exact与20261024_232507_p2_auxiliary_preflight。

Revision metadata: revision_id=p2_probabilistic_shaping_auxiliary_h4_20261025; current_status=current; supersedes=[p2_1bb1d23189ab_20261024].


## 2026-10-25 当前有效快照：概率整形与辅助S

- **domain_id**: l1_probabilistic_shaping
- **maturity**: active
- **rks_score**: 仅见结构审计，不代表科学完成度。

## Research Question

固定16QAM、原S/I/F与有效K，比较消息条件化S、独立公平S及独立供体S的输出分布，并接续等功率通信—RF分析。

## Hypothesis status

**H1方向勘误**：原历史声明中的“p降低会降低能量”不采用；按既有E_norm=(18−16p)/10，p降低使未缩放能量增加。它不证明等功率收益。

**H2**：工作点存在性仍受发送功率、码率、接收链路与候选范围限制，不升级为已验证。

**H3**：保留原有限码长/构造与PMF证据范围，不能用本轮新对照代替原验证。

**H4**：当前N1024、p=.5/.3/.1集合中，I∪S独立公平输入且F=0，逐位置标签联合分布应均匀，实际随机S实现还需通过3seed×80码字TV单侧95%≤.05。当前21组矩阵覆盖和小码长穷举已确认结构部分；3×8只探索，因此登记为inconclusive。该编号定义见前一修订，当前段以状态快照维护，不重复建立编号。

## Core Quantities / Boundaries

有效载荷仅I；SC仍判决I∪S。随机S的输入自由度可达K+|S|，不同于原消息条件化代码本。S的跨消息边缘分布不等于输出目标p，源条件熵也不等于该边缘熵。donor S保留独立S向量统计，输出不保证均匀。相关标签的平均边缘不能相乘冒充联合PMF。

## Pitfalls

⚠️ 依workbook/mandatory-rules.md核对瀑布区、码率上界、噪声口径和长跑授权；依quality-assurance.md保持辅助位、接收掩码与统计分母一致。RF时域均方非DC，BLER非CRC，Goodput非净吞吐。近似模型须冻结后独立测试，不以文件或结构分数作科研验收。

## Code Anchors / Evidence

l2_p2_mechanism、l2_p2_uniformity_audit、l3_p2_distribution_reference、l3_p2_uniformity_contract。精确证据：results/20261025_000154_p2_uniformity_exact；探索：results/20261024_232507_p2_auxiliary_preflight。正式功率、PMF、模型精度和速度仍待预算确认。

Revision metadata: revision_id=p2_probabilistic_shaping_clean_snapshot_20261025; current_status=current; supersedes=[p2_probabilistic_shaping_auxiliary_h4_20261025].
