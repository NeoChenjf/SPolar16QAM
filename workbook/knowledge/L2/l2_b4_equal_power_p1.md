# L2 · B4等功率P1正式验证

- **flow_id**: l2_b4_equal_power_p1
- **entry_script**: scripts/run_b4_equal_power_p1.ps1
- **MATLAB_engine**: 16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
- **runtime**: long
- **needs_user_run**: true（本轮由用户对本计划的明确授权启动）
- **validates**: l1_multicarrier_ofdm#H2（只评价固定功率策略差异，不自动判定整体最优）

## 目的与口径

在包含CP和padding的发射时域全样本平均功率固定为1时，复核六种现有多载波策略的BER、信息块BLER、Goodput和加噪前接收RF均方。多QAM仅作外推支撑，不参与本流程。

复用原B4 Rayleigh、64子载波、CP16、三组N=1024及Polar/SC链路。每策略一个由独立校准数据确定的固定幅度系数；所有SNR、信道、帧共用。噪声复功率为$N_0=1/10^{SNR_{dB}/10}$，每实维标准差为$\sqrt{N_0/2}$。六策略使用配对信道、噪声及基础payload随机流。

## 流程与验收

1. 集合与非零payload无噪声回归；校准时只统计未缩放时域功率。
2. 每策略以seed7001/7002/7003、各候选SNR、每点12帧估计全网格平均功率，冻结全局尺度。
3. 独立seed7101/7102/7103按同网格验证，功率均值相对1偏差不超过1%；失败时按预登记预算扩大。
4. seed42、5信道×2帧pilot定位瀑布区，测试前冻结包含原20—40 dB网格的正式点。
5. seed3142正式统计，30独立信道×六策略×正式SNR，每重复固定50帧，完整记录checkpoint。
6. 以信道实现为统计簇做2000次配对bootstrap；BER、BLER、Goodput及RF均值区间按30个信道报告；约束违反比例给Wilson区间。

## 证据边界

BER≤0.1与Goodput≥0.25只用于历史衔接。Goodput不等于CRC净吞吐；BLER不等于CRC包失败率；接收RF均方不等于整流器DC输出。30信道的描述性比例不构成总体失约率保证。

结果路径、源码哈希、原始数据、图、验收记录在本文件末尾追加；计划或脚本存在不代表实验已经执行。

## 2026-10-10 修订：P1时域噪声与FFT后σ换算

第2节的$N_0$指时域复噪声样本功率。为通过现有OFDM函数生成该噪声，传给函数的FFT后每实维σ应为$\sqrt{N_{sc}N_0/2}$，函数内部除以$\sqrt{N_{sc}}$后得到时域每实维$\sqrt{N_0/2}$。首版换算少了$\sqrt{N_{sc}}$，导致时域噪声功率偏低18.06 dB；相关中断批次有明确无效标记。修正后的噪声功率单元回归和整链路smoke已通过。待校准门禁和新正式运行全部完成后，补入新证据路径及验收状态。

Revision metadata: revision_id=b4_equal_power_p1_noise_conversion_20261010; current_status=current; supersedes=[b4_equal_power_p1_v1].


## 2026-10-11 正式P1结果与验收记录

正式结果：`16QAM_Polar/v2/results/20261010_220806_b4_equal_power_p1_formal/`；控制与校准入口：`16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/`；当前最终分析：该目录下`analysis_rerun_20261010_235754/`。首个噪声σ错误版本已中止并单独标记无效，不纳入结果。

正式数据通过结构核验：1260条唯一“策略×信道×SNR”记录，所有重复均固定50帧，每策略210条；正式SNR为16、20、24、28、32、36、40 dB。所有策略跨正式样本的平均发射时域功率相对目标1偏差均小于1%，最大约0.64%。独立功率验证最后一次使用7101/7111/7121样本组，每seed 84帧（7个SNR各12帧），偏差≤1%；前两次独立验证超限后，校准扩至每seed 322帧（7个SNR各46帧）。与计划文本中的80/160/320/640总帧数略有差异，按每SNR整分配后为84/168/322/644；未改变1%门限或使用测试集校准。

配对结果以同一30个信道实现作簇，bootstrap 2000次。24 dB时good-channel-information相对uniform p=.5的BER差为-0.02485，95% CI [-0.02897,-0.02038]；Goodput差为-0.02984，CI [-0.03176,-0.02791]；接收RF均方差为-0.13337，CI [-0.14750,-0.11962]。这表示BER下降伴随Goodput和接收RF代理量降低。32 dB时good-channel-energy-shaping的接收RF均方差为+0.13474，CI [+0.12119,+0.14835]；BER差为+0.01038，CI [+0.00725,+0.01371]；Goodput差为-0.04524，CI [-0.04614,-0.04443]。它提高接收RF代理量，同时使通信指标变差。测试的六策略集合内没有策略在BER、Goodput和接收RF三个维度全面支配uniform p=.5；候选Pareto集合保留均匀基线与能量向好信道倾斜策略等折中点。

seed3142下纯能量策略在32与40 dB没有观察到信息比特/信息块错误。每个SNR仍只有1500帧、3000个信息块（两路信息组）；BER Poisson 95%上界约5.03e-6、BLER上界约9.99e-4，不得写成零错误概率或CRC包可靠性。Goodput不等于CRC净吞吐；加噪前接收RF均方不等于整流器DC输出。历史非等功率结果只作口径对照，不作配对检验。

分析图目录包含功率校准/验证、BER、信息块BLER、Goodput、接收RF均方、配对差值、Pareto、逐信道门槛和历史口径对照，每图有PNG/PDF/FIG。P1支持“存在候选策略间的通信-RF权衡”，但不支持“自适应策略普遍优于均匀基线”或全局最优。

验收：固定功率门禁通过；通道/噪声/LLR缩放回归通过；样本键及帧数核验通过；图表视觉复核通过。后续P2仍需匹配可靠性模型，P3仍需27组合独立训练/验证。多QAM仍仅为整形外推支撑，不扩展为多载波/Goodput研究。

Revision metadata: revision_id=b4_equal_power_p1_formal_20261011; current_status=current; supersedes=[b4_equal_power_p1_noise_conversion_20261010].

## 2026-10-11 追加勘误：最终功率验证seed

上方结果记录中“7101/7111/7121”不是三个最终seed。最后一次独立验证实际使用seed **7121、7122、7123**；每seed共84帧（7个SNR×12帧）。此勘误只修正seed描述，不改变通过1%门限的功率结果或正式测试数据。

Revision metadata: revision_id=b4_equal_power_p1_validation_seed_correction_20261011; current_status=current; supersedes=[b4_equal_power_p1_formal_20261011].

## 2026-10-11 追加：扫描器入口标识与Acceptance契约

为匹配机器扫描器的相对路径契约，本L2流程的`entry_script`为`16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m`，PowerShell预算/校准编排器为`orchestration_script`：`scripts/run_b4_equal_power_p1.ps1`。此前L2首段将编排器写在entry_script，现由本补充明确区分。

## Acceptance

- 发射功率按CP/padding均计入的时域全样本计算；校准样本和独立验证样本隔离，正式测试不参与策略尺度选择。
- 固定SNR时六策略使用相同物理复噪声；FFT/ZF与LLR使用和实际信号幅度一致的噪声口径。
- 独立验证策略均值偏离目标≤1%；正式统计每策略/信道/SNR固定50帧，所有六策略使用配对信道。
- 只报告本轮候选策略集合、当前16QAM资源和构造口径；BER/Goodput门限是历史衔接指标，不构成逐信道可靠性或应用门槛。
- 接收RF均方不等于DC输出；BLER不等于CRC包失败，Goodput不等于CRC净吞吐；有限样本零错误须报告分母和上界。

Revision metadata: revision_id=b4_equal_power_p1_acceptance_contract_20261011; current_status=current; supersedes=[b4_equal_power_p1_validation_seed_correction_20261011].

## 2026-10-11 当前修订快照：机器入口和护栏

- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
- **orchestration_script**: scripts/run_b4_equal_power_p1.ps1
- **validates**: l1_multicarrier_ofdm#H2；当前证据状态为inconclusive，不证明一般意义的策略优势。

## Acceptance

在CP/padding均计入的时域平均TX功率下进行策略比较；策略全局尺度由独立校准集冻结，独立验证的六策略均值偏差≤1%。固定SNR下各策略共享复噪声；实际FFT/ZF噪声方差及TX幅度尺度传递至LLR。正式样本由30信道、固定50帧组成，策略使用配对信道。只对当前六策略候选集合和16QAM口径做结论；RF均方不是DC输出，BLER不是CRC包错，Goodput不是CRC净吞吐。BER≤0.1与Goodput≥0.25只用于历史衔接；描述性信道比例不构成应用保证。

Revision metadata: revision_id=b4_equal_power_p1_current_snapshot_20261011; current_status=current; supersedes=[b4_equal_power_p1_acceptance_contract_20261011].

## 2026-10-11 最终图表与分析路径快照

- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
- **orchestration_script**: scripts/run_b4_equal_power_p1.ps1
- **validates**: l1_multicarrier_ofdm#H2（当前证据状态inconclusive）。
- **formal_data**: `16QAM_Polar/v2/results/20261010_220806_b4_equal_power_p1_formal/`
- **final_analysis**: `16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261011_002445/`
- **figures**: 该目录下`figures/`，含每SNR独立panel的Pareto图；当前`LATEST_ANALYSIS_PATH.txt`指向该目录。

## Acceptance

功率定义包含CP/padding；每策略一条冻结幅度系数，独立验证均值误差≤1%；固定SNR时策略共享物理复噪声和配对信道；正式每重复固定50帧。有限零错误报告95%上界；BLER不是CRC包错，Goodput不是净包吞吐，接收RF均方不是DC输出。结论仅适用于本轮六策略与16QAM链路，不能称全局最优或逐信道保证。

Revision metadata: revision_id=b4_equal_power_p1_final_figures_20261011; current_status=current; supersedes=[b4_equal_power_p1_current_snapshot_20261011].

## 2026-10-11 最终逐seed功率审计快照

- **entry_script**: 16QAM_Polar/v2/experiments/multicarrier/run_b4_strict_ofdm_rayleigh_validation.m
- **orchestration_script**: scripts/run_b4_equal_power_p1.ps1
- **validates**: l1_multicarrier_ofdm#H2；证据状态inconclusive。
- **formal_data**: `16QAM_Polar/v2/results/20261010_220806_b4_equal_power_p1_formal/`
- **final_analysis**: `16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261011_002445/`
- **power_seed_audit**: `power_per_seed_audit.csv`包含3个校准seed及3个独立验证seed的每策略功率。

## Acceptance

最后验证seed 7121/7122/7123的18个“seed×策略”观测全部在目标±1%内，最大绝对偏差为0.62%；校准seed7001/7002/7003的独立原始均值用于冻结幅度系数，不按目标误差解释。正式样本固定30信道、50帧，配对共用物理噪声和信道。零错误报告95%有限样本上界。RF均方不是DC，BLER不是CRC包错，Goodput不是CRC净吞吐；结论只覆盖六策略候选集。

Revision metadata: revision_id=b4_equal_power_p1_per_seed_power_audit_20261011; current_status=current; supersedes=[b4_equal_power_p1_final_figures_20261011].
