# L2 · 16QAM BER 高 SNR 探索性粗扫

- **flow_id**: l2_16qam_ber_high_snr_coarse
- **entry_script**: `16QAM_Polar/v2/experiments/rectifier/run_16qam_ber_high_snr_coarse.m`
- **runtime**: minutes
- **needs_user_run**: false
- **validates**: `l1_16qam_energy_tradeoff`（高 SNR 有限样本 BER 收敛观察；不更新正式曲线结论）

## Purpose

以低预算延伸任务二的五个整形参数BER曲线，记录每个$p$首次观测零信息位错误的SNR点，并区分有限样本零错误与理论BER为零。

## Pipeline

| # | step | l3_ref | 说明 |
|---|------|--------|------|
| 1 | 读入配置并覆盖实验局部参数 | 内联 | `N=1024`，SC，`fixed_esn0`，匹配LLR方差，20帧/点，seed=4242；不修改`config.m` |
| 2 | 编码、16QAM调制、AWGN、软解调及译码 | `l3_sim_shaped_polar_16qam` | $p=[0.5,0.4,0.3,0.2,0.1]$，SNR标签20/25/30/35/40 dB |
| 3 | 条件延伸 | `l3_sim_shaped_polar_16qam` | 某$p$在40 dB仍有错误时，该$p$补扫45和50 dB |
| 4 | 重算BER与零错误上界，输出CSV/MAT和图 | 内联 | 按实际信息位数加权核验；零错上界为$1-0.05^{1/N_{info}}$ |

## Outputs

时间戳结果目录含`coarse_ber.csv`、`coarse_ber.mat`、README、运行日志，以及BER PNG/PDF。每点记录四路BER、总错误数、信息位数、加权BER和（零错误时）95%单侧上界。

## Acceptance

- CSV总BER与四路BER按各路$K_b$加权重算一致；信息位分母为`frames × sum(K)`。
- 全零错误点仅标作“本样本未观察到错误”，报告上界，不记作理论BER=0或误码地板证据。
- 图使用对数BER轴，零错位置绘制95%上界标记；探索结果不与正式三seed、300帧曲线合并。

## Weekly Report

- `周报/高阶调制/README.md`
