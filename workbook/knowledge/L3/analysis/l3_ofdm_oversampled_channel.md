# L3 · ofdm_oversampled_channel

- **method_id**: l3_ofdm_oversampled_channel
- **file_path**: 16QAM_Polar/v2/analysis/ofdm_oversampled_channel.m
- **module**: analysis
- **health**: degraded（理想逐符号插值及整数tap时延，非物理滤波/器件实测）

## Signature

`rx = ofdm_oversampled_channel(grid,h,cp_len,factor)`：频域grid、有限信道向量、CP长度、过采样倍数；输出复包络时域列向量。

## Purpose / Math

调用逐符号频域插值，串接CP块；将h的相邻tap插入 $L-1$ 零后线性卷积，截断到发射窗口长度。原采样点应等于ofdm_channel_roundtrip无噪接收信号。

## Numerical Notes

对应整数原采样周期tap时延；不模拟连续时间滤波器或非整数传播延迟，Nyquist约定负频。不能当作经过模拟前端或已标定的RF电压。CP不足、信道非法分别抛对应错误。

## Dependencies

- l3_ref: l3_ofdm_oversampled_symbol

## Verification status

MATLAB `test_ofdm_oversampled_channel` 对AWGN及复多径、L=1/2/4逐采样匹配现有OFDM线性卷积，并覆盖错误输入。原型三S链路N32 smoke通过原采样匹配及矩记录；尚未做连续时间滤波/硬件验证。
