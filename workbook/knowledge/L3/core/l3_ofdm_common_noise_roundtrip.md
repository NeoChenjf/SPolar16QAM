# L3 · ofdm_common_noise_roundtrip

- **method_id**: l3_ofdm_common_noise_roundtrip
- **file_path**: 16QAM_Polar/v2/core/ofdm_common_noise_roundtrip.m
- **module**: core
- **health**: degraded（确定性单元测试通过，尚未接入新正式链路）

## Signature

`result = ofdm_common_noise_roundtrip(grid, h, N0, cp_len, noise_unit)`：数值频域网格、信道向量、每复时域样本噪声功率、CP及显式单位复噪声向量；返回底层OFDM链路结构。调用方负责样本实虚维标准正态、跨case配对及独立seed管理。

## Purpose / Math

固定物理噪声功率，用 $\sigma_{freq}=\sqrt{N_{sc}N_0/2}$ 调用原有信道；输入noise_unit由调用方复用，不基于候选功率重新缩放。

## Numerical Notes

CP必须覆盖信道且短于FFT，noise长度必须是线性卷积总长度；N0可为零。ZF floor沿用底层默认值。此接口不验证输入噪声统计分布，也不自动生成随机种子、冻结PMF或保证用户传入的h/n被不同方案复用。

## Dependencies

- l3_ref: l3_ofdm_channel_roundtrip

## Verification status

`test_ofdm_common_noise_roundtrip` MATLAB退出0，覆盖不同波形功率下相同噪声样本、FFT/ZF换算、无噪环回和非法噪声/N0/CP。尚未接入正式入口；未进行统计方差或真实全链路实验。

## 2026-11-06 噪声尺度统计补充

MATLAB `test_ofdm_common_noise_statistics` 固定seed、512 OFDM符号验证时域、FFT和ZF归一功率分别与理论尺度相差约0.89%、0.89%、0.89%；使用预定5%宽松smoke阈值。该测试只覆盖一个信道与噪声值，不代替正式物理协议或独立统计验收。
