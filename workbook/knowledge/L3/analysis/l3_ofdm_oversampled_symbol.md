# L3 · ofdm_oversampled_symbol

- **method_id**: l3_ofdm_oversampled_symbol
- **file_path**: 16QAM_Polar/v2/analysis/ofdm_oversampled_symbol.m
- **module**: analysis
- **health**: degraded（仅理想逐符号插值已测；实际发射滤波、信道及跨块瞬态未验证）

## Signature

`wave = ofdm_oversampled_symbol(grid, cp_len, factor)`：偶数行有限数值频域矩阵、0至N−1整数CP长度、1至64整数插值倍数；返回每列含放大factor倍CP的复时域样本。

## Purpose / Math

频域以MATLAB FFT顺序零填充，Nyquist bin明确定义为负频率；$L$倍插值取 $L\operatorname{ifft}(X_{padded})$，保持原IFFT采样值及幅度；按插值样本复制CP。

## Numerical Notes

此函数不执行模拟滤波、波形窗、信道卷积或跨块滤波插值；不可直接当作完整物理整流输入。factor=1时同已有ifft；Nyquist正负频率在原采样不可区分，负频率是约定而非从数据可识别事实。非法grid、CP、factor分别报ofdmoversample:InvalidGrid、InvalidCP、InvalidFactor；非有限结果报Overflow。

## Dependencies

无项目方法依赖，使用MATLAB内置函数。

## Verification status

MATLAB `test_ofdm_oversampled_symbol` 通过：L=1/2/4原采样点、CP、双音四阶差异及非法输入。尚无接收通道/滤波/连续波形验证。
