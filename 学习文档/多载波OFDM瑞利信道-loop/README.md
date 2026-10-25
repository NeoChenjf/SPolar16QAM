# 多载波OFDM瑞利信道分析loop

> 状态：B4b严格OFDM-Rayleigh正式统计、配对分析与低复杂度约束码本均已完成并通过审计。  
> 建立日期：2026-09-17  
> 上游结论：单载波通用GrayQAM与固定16QAM通信—能量联合链路均已闭合，主线转入多载波。

## 目标

在现有B1—B4a基础上，建立严格包含IFFT/CP、频率选择性Rayleigh多径、去CP/FFT、逐子载波均衡、软解调和polar译码的OFDM full-chain，并在同一物理与统计口径下比较六类策略。

## 接手顺序

1. [需求澄清](需求澄清.md)
2. [loop设计](loop设计.md)
3. [协调协议](协调协议.md)
4. [进度表](进度表.md)
5. [问题记录](问题记录.md)
6. [next_plan](next_plan.md)
7. [中期PPT材料](中期PPT材料.md)

代码与阶段真相源仍在：

- `16QAM_Polar/v2/experiments/multicarrier/`
- `周报/阶段B/`
- `workbook/mandatory-rules.md`

## 已确认的首版架构

2026-09-17用户确认采用A方案：high/mid/low分组三套独立polar块，真实映射到各组子载波。它保留真实OFDM-Rayleigh物理链路，又避免第一版直接引入逐子载波64套独立polar码的复杂度。

能量口径已确认：Rayleigh多径后的加噪前接收信号均方作为多载波策略主比较指标；含噪接收均方另存为诊断字段；发送端QAM/OFDM均方同步保存并用于公平性检查。所有字段都是能量代理量，不称RF—DC整流效率。

装帧规则已采用推荐方案：每组保持`N=1024` polar块，共同装入一个OFDM时频网格；帧长由最长组决定，空余资源显式标记为padding，Goodput按整个帧和CP计算。

首版还冻结两项推荐默认：从B1抽取共享OFDM核心，避免AWGN/Rayleigh两套逻辑漂移；纯能量组发送真实`p=0.1`整形波形，但payload记为0且不计入BER/Goodput。

## 当前实现与smoke证据

- 共享物理核心：`16QAM_Polar/v2/core/ofdm_channel_roundtrip.m`
- B4b入口：`16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m`
- 聚焦诊断：`16QAM_Polar/v2/diagnostics/multicarrier/test_ofdm_channel_core.m`
- smoke审计：`16QAM_Polar/v2/diagnostics/multicarrier/verify_b4b_strict_smoke.m`
- 权威结果：`16QAM_Polar/v2/results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/`

smoke覆盖`[8,14,20] dB × 2 realizations × 1 frame × 6 strategies`，计算耗时4.42秒；36个策略重复键、18个汇总点、128条信道记录以及CSV/MAT/日志/四图均通过审计。共同帧为49个OFDM符号，padding为2.0408%。这些证据只关闭实现与smoke门禁，不支持稳定策略排序。

随后完成两轮受限pilot：`[20,24,28,32] dB`（20.4秒）和`[32,36,40] dB`（15.3秒），各为5个realization、每点2帧、六策略。普通策略的有效瀑布区落在24—40 dB；纯能量策略在20—24 dB已进入有效区，28 dB以上出现聚合零错，正式统计必须报告上界。权威pilot目录分别为`20260917_194823_b4_strict_ofdm_rayleigh_pilot/`和`20260917_194950_b4_strict_ofdm_rayleigh_pilot_high_snr/`。

正式统计目录为`20260917_210504_b4_strict_ofdm_rayleigh_formal`；配对统计与低复杂度码本目录为`20260917_215938_b4b_paired_policy_analysis`。默认码本以BER上区间不超过0.1、Goodput下区间不低于0.25为约束，可行后最大化接收能量；20 dB回退到`uniform_p05`，24—40 dB选择`uniform_p01`。该规则是六个已验证策略间的低复杂度选择，不宣称连续全局最优，后续重点转为独立样本验证和论文材料收束。

## 2026-10-09 整形构造版本更新与结果边界

阶段B的新实验固定 $K$ 与 $|S|$，按 Bernoulli 源条件熵选取 $S$，再在剩余位置按各信道SNR下的通信GA可靠性选 $I/F$；每帧用当前消息和全零冻结位条件化生成整形位。源熵估计与构造参数在每个 $p$ 固定，不逐帧或逐SNR重估。原B4的GA前缀集合和保护带策略仅为历史版本，须由新训练集重新估计，不沿用旧码本。

构造层证据已通过：$N=1024$五个$p$的联合PMF pooled单侧95%上界为0.0080–0.0262，三个逐seed最大上界为0.0146–0.0274；$N=256/1024$的新消息条件化数据均通过TV≤0.05门禁。独立源熵图和码长对照图见本目录的[偏差定位结论](整形分布偏差定位结论.md)末尾修订及[重建清单](../shaped_polar验证loop/理论更新与图重建/整形理论更新与仿真图重建清单.md)。这些证据不代表OFDM通信改善，也不支撑等功率收益。

正式OFDM六策略数据、约束码本和seed1042/2042验证仍待运行；必须按新构造重新训练、在独立seed上验证，并报告约束不满足率。未完成前，不把旧保护带规则称为当前策略。


## 2026-10-09 纯能量基线语义修正（待smoke验收）

代码审计发现，旧版bad_channel_energy_only虽然把low组排除在BER/Goodput分母外，却仍为该组随机生成信息位并发射，故旧图中的“纯能量”名称与载荷不一致。新版本仅对low组固定零payload，仍使用该组p=.1、原S/I/F构造和消息条件化整形；该组不计为信息子载波。加入零payload断言后再进行B4 pilot/正式运行。历史B4数据保留，但只代表旧定义，不能与修正版本直接合并或作同一baseline结论。

## 2026-10-09 新构造B4正式统计与独立验证

正式训练：`16QAM_Polar/v2/results/20261009_203109_b4_source_entropy_formal/`，seed42、30个Rayleigh realization、SNR标签[20,24,28,32,36,40] dB、六策略、每重复至少5帧、达到200个错误则停、最多50帧。训练重复表1080行、汇总36行、信道表1920行；唯一键、START/DONE、rate/Goodput/padding恒等式、信息子载波比例、逐组payload计数与图审计通过，low组纯能量策略payload one总数为0。正式输出为F10–F15。

训练策略由训练集独立生成：一般最大能量码本在20/24 dB按预定规则回退到最大Goodput的uniform_p05，28–40 dB选uniform_p01。保护带候选在未查看验证集前冻结（训练BER上界≤.08、Goodput下界≥.27，优先最大接收能量；无可行项时最大Goodput回退）。

一般码本的独立验证seed1042目录为`results/20261009_211124_b4_source_entropy_holdout1042/`，分析`results/20261009_223148_b4b_fixed_policy_holdout_analysis/`：28/32/36/40 dB通过原BER上界≤.10和Goodput下界≥.25；20/24 dB是训练时已标注的最大Goodput回退，不算通信门槛通过。符合门槛点的接收能量代理相对uniform_p05为正，幅度约0.0096绝对功率单位（须注意该数据不是等功率实验）。

保护带候选seed2042独立验证目录为`results/20261009_223251_b4_source_entropy_guardband2042/`，分析`results/20261009_230741_b4b_guardband_policy_test_analysis/`：28–40 dB均通过原BER/Goodput门槛；低SNR的20/24仍按预注册规则回退最大Goodput，未声称通过约束。逐SNR策略为28 dB good_channel_information、32 dB good_channel_energy_shaping、36/40 dB uniform_p01；接收RF均方代理相对uniform_p05差值约0.00224/0.00833/0.01063/0.01063。seed2042未参与冻结，结果未用于调参。

边界：三批图均沿用原信道、功率、噪声、Goodput资源分母，用于隔离构造变化。接收能量是加噪前时域均方代理，不等于整流器直流输出；当前策略间发射符号功率不同，也不证明等功率收益。独立样本只支持这套信道/门槛/候选策略的有限验证，不代表任意单次CSI保证。保护带候选通过不意味着整个研究目标完成。

图索引：训练F10–F15位于`20261009_210714_b4b_source_entropy_training_policy_analysis/figures/`；一般码本F16/F17位于`20261009_223148_b4b_fixed_policy_holdout_analysis/figures/`；保护带F18位于`20261009_230741_b4b_guardband_policy_test_analysis/figures/`。各图有PNG/PDF/FIG，数值CSV与MAT同目录。


## 2026-10-24 等功率机制对照与P2追加

本文件的旧码本、保护带与28—40 dB可行结论属于原发送功率/训练协议，不直接迁移到当前等功率优化。P1六策略正式结果仍有效；本轮五个全信息策略对照新增随机S与供体S，保留原S/I/F、LLR与SC，按I统计有效载荷。纯能量策略仅保留原P1边界参照，不宣称新的策略最优。

旧S冻结0对照非均匀，不能与新随机S混称。新随机S已完成生成矩阵证明与3seed×8码字探索；正式1%功率、3×80 PMF及独立模型预测门禁仍待预算批准。当前参考图和理论说明见[结论入口](机制对照与P2/等功率机制与P2当前结论.md)；新增图不是旧F10—F18的正式替代。

Revision metadata: revision_id=p2_30a5059b71a5_20261024; current_status=current; supersedes=[baseline_p2_30a5059b71a5].


## 2026-10-25 学习文档归档路径补充

本段仅更新阅读位置，原研究结论和历史路径文字保留。当前文档位置：

- [等功率机制与P2当前结论.md](机制对照与P2/等功率机制与P2当前结论.md)
- [整形理论更新与仿真图重建清单.md](../shaped_polar验证loop/理论更新与图重建/整形理论更新与仿真图重建清单.md)

Revision metadata: revision_id=learning_relocation_613c2e5a2e_20261025; current_status=current; supersedes=[p2_30a5059b71a5_20261024].
