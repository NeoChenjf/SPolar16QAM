# L1 · 多载波 OFDM（Multicarrier OFDM）— Stage B

- **domain_id**: l1_multicarrier_ofdm
- **maturity**: active（B4b严格OFDM-Rayleigh smoke与两轮瀑布区pilot已通过，正式统计待开展）
- **rks_score**: 80

## Research Question
将单载波成形极化码系统扩展到多载波 OFDM 后，如何在频选信道上按子载波分配
「信息传输 / 能量成形 / 纯能量传输」策略，最大化信息-能量协同收益？

## Hypotheses
- H1: 最小 OFDM 全链路基线（均匀 p、AWGN、SC）能跑通并复现单载波量级结果 → 由 l2_ofdm_baseline 验证。
- H2（验证中）: 按子载波信道质量分配策略，可优于均匀策略。B4b六策略严格物理链路smoke与pilot已通过，pilot把普通策略的有效窗口定位为24—40 dB、纯能量策略定位为20—24 dB；**仍须正式多realization统计后才可下结论**。

## Core Quantities
| 符号 | 定义 | 单位 | 计算位置 |
|------|------|------|----------|
| n_subcarriers | 子载波数 | — | run_ofdm_baseline（64） |
| cp_ratio | 循环前缀比例 | — | run_ofdm_baseline（1/4） |
| 子载波频响 | `|H_k|²`及high/mid/low分组 | — | B2/B4b channel CSV |
| OFDM帧资源 | 49个OFDM符号、padding 2.0408% | — | B4b smoke |
| 接收能量代理 | Rayleigh后、AWGN前时域均方 | 相对功率 | B4b repetition CSV |

## Theoretical Boundaries
- 基线：均匀 p、AWGN OFDM、SC 译码、轻量代表性网格。
- B4b采用三组独立polar块映射到真实子载波，不等同于64套逐子载波独立polar码。
- smoke为2个realization×1帧，只验证链路与量级；两轮pilot为5个realization×2帧，仅用于冻结SNR网格，不提供稳定排序。

## Pitfalls（护栏）
- ⚠️ **Stage B 核心硬规则**：不得在与三个计划基线（好信道信息、好信道能量成形、坏信道纯能量传输）
  对照前宣称某多载波策略"最优"（`AGENTS.md` Non-Negotiables / 阶段B文档）。
- ⚠️ B4b正式统计规模已由pilot预登记为20—40 dB六点；checkpoint/resume与零错上界已通过微型控制路径验证，仍必须完成30 realization统计；不得由pilot曲线推断稳定交叉或Pareto前沿。

## Collaborators
- ← l1_channel_snr：每子载波信道条件不同。
- ← l1_metrics_tradeoff：策略对比沿用同一套指标。
- ← l1_probabilistic_shaping / l1_polar_coding：单载波核心被 OFDM 复用。

## Code Anchors
- l2_ofdm_baseline（experiments/multicarrier/run_ofdm_baseline.m）
- l2_b4b_strict_ofdm_rayleigh_smoke（experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m）
- l3_ofdm_channel_roundtrip（core/ofdm_channel_roundtrip.m）
- experiments/multicarrier/run_subcarrier_strategy_compare.m, run_rayleigh_subcarrier_profile.m（计划纳入 L2/L3）
- 周报/阶段B/B1：OFDM baseline阶段文档.md

## 2026-10-09 构造契约追加

新版本为`source_entropy_S_GA_IF`：每一路保持原K和S数量；固定源熵估计选择S；每个通信SNR在剩余位置重新GA排序选I/F；逐帧按payload和F=0调用v3精确源SC强制构造。源熵估计seed与评价seed必须分离。接收端仍是现有SC/LLR契约，不能将source precoder准确性等同于接收度量匹配。正式PMF门禁和码长对照见本轮时间戳结果；本次不更新最优性能结论。

## 2026-10-09 H2版本边界追加

既有smoke/pilot与2026-09正式B4结果使用旧GA集合构造，仅作为旧版物理链路证据保留。source-entropy-S/逐SNR-GA-I/F版本的OFDM正式统计与新策略选择仍待运行；其独立seed1042/2042验证必须在训练规则冻结后执行。此构造修订不改变三个计划基线的比较义务，不等同于等功率优化。

## 2026-10-09 纯能量基线语义修正

旧版bad_channel_energy_only虽然把low组排除在BER/Goodput分母外，却仍为该组随机生成信息位并发射，故旧图中的“纯能量”名称与载荷不一致。新版本仅对low组固定零payload，仍使用该组p=.1、原S/I/F构造和消息条件化整形；该组不计为信息子载波。新断言和正式统计验证通过，旧B4数据保留为旧定义，不与新版本合并。

## 2026-10-09 B4独立验证边界

新构造训练和两个独立Rayleigh split均为30个信道实现；seed42训练后才冻结一般policy与guardband候选，seed1042/2042结果不参与选择。按训练约束回退的20/24 dB点不计作通过，28–40 dB在当前SNR、资源和发射功率口径下满足指定BER/Goodput区间门槛。不得据此声称任意CSI或等功率条件下必然增益；接收RF均方也不等价于直流收能。


## 2026-10-10 追加：固定16QAM主线与等功率P1

当前研究分工为16QAM主线负责多载波策略、BER/BLER/Goodput及硬件验证；多QAM只作为整形方法可扩展性的支撑验证。新P1使用固定OFDM时域平均发射功率，策略缩放系数对SNR/信道/帧全局冻结。旧版B4中p=.1更高的发送功率不能证明等功率下仍有接收RF优势。P1结果待正式运行与分析后追加。


Revision metadata: revision_id=l1_multicarrier_ofdm_scope_20261010; current_status=current; supersedes=[baseline].


## 2026-10-11 当前有效补充：等功率P1结论

被更新的旧结论：H2曾处于“正式统计待完成”，旧策略结果也含策略间发射功率差异。新证据：固定16QAM、64子载波/CP16、三组N=1024、六策略、每策略单一冻结幅度系数、固定目标时域功率1；正式seed3142覆盖30信道、7个SNR、每重复固定50帧。正式均值TX功率门禁通过，独立校准验证偏差≤1%。数据与配对结果链接见`workbook/knowledge/L2/l2_b4_equal_power_p1.md`末尾。

新结论仅适用于六个既有策略和本轮信道/译码/资源口径。24 dB好信道信息策略相对uniform p=.5有配对BER下降，但Goodput与接收RF均方也下降；32 dB好信道能量策略增加接收RF均方，但BER上升、Goodput下降。没有策略在三个指标上普遍支配均匀策略，故H2整体标记为`inconclusive`，不是支持或反驳所有环境下的普遍命题。接收RF均方不代表DC输出；30信道比例不是总体可靠性保证。多QAM仅为整形外推支撑，不属于多载波主线。

Revision metadata: revision_id=l1_multicarrier_p1_equal_power_20261011; current_status=current; supersedes=[l1_multicarrier_ofdm_p1_20261010].

## 2026-10-11 当前修订快照：H2状态

⚠️ H2“按子载波信道质量分配策略，可优于均匀策略”的最新正式证据来自固定平均发射功率P1六策略比较。结果只在部分指标和SNR呈现方向性变化，且存在通信—RF折中；尚无策略普遍占优，因此当前状态为`inconclusive`。边界和样本协议见当前L2`l2_b4_equal_power_p1.md`。

Revision metadata: revision_id=l1_multicarrier_p1_current_snapshot_20261011; current_status=current; supersedes=[l1_multicarrier_p1_equal_power_20261011].


## 2026-10-24 当前研究快照：随机辅助S与P2

- **domain_id**: l1_multicarrier_ofdm
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

Revision metadata: revision_id=p2_038f888b61ec_20261024; current_status=current; supersedes=[l1_multicarrier_p1_current_snapshot_20261011].
