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
