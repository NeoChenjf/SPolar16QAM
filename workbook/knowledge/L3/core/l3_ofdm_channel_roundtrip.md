# L3 · ofdm_channel_roundtrip

- **method_id**: l3_ofdm_channel_roundtrip
- **file_path**: 16QAM_Polar/v2/core/ofdm_channel_roundtrip.m
- **module**: core / multicarrier
- **health**: healthy（2026-09-17 focused test PASS）

## Signature

`result = ofdm_channel_roundtrip(tx_grid, h, sigma_noise_freq, cp_len, options)`

输入频域网格、信道冲激响应、FFT前每实维噪声标准差、CP长度和可选均衡下限/公共单位噪声。输出CP波形、加噪前/含噪接收波形、FFT网格、ZF结果、频响、逐子载波均衡后噪声标准差及发送/接收均方。

## Contract

- CP必须满足`cp_len >= length(h)-1`且小于子载波数。
- 各OFDM符号加CP后按列串行化，整段连续卷积；接收FFT窗丢弃每块CP。
- `sigma_noise_time = sigma_noise_freq/sqrt(Nsc)`，与未归一化FFT配对。
- ZF使用`equalizer_floor`保护近零`H_k`；返回`sigma_equalized=sigma_noise_freq/|H_safe|`供逐子载波LLR使用。
- 主接收能量采样为发送时长窗口内、加噪前的接收信号均方；含噪均方单独返回。

## Validation

`diagnostics/multicarrier/test_ofdm_channel_core.m`覆盖单位冲激和多径无噪声恢复、谱零点有限性、公共噪声确定性、CP过短错误路径及vector-sigma LLR兼容性。
