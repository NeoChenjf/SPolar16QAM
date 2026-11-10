# L3 · rf_envelope_moments

- **method_id**: l3_rf_envelope_moments
- **file_path**: 16QAM_Polar/v2/analysis/rf_envelope_moments.m
- **module**: analysis
- **health**: degraded（离散计算已测；未接入正式链路或硬件标定）

## Signature

`moments = rf_envelope_moments(envelope)`：有限非空数值向量；输出结构体 `mean_abs2`、`mean_abs4`、`sample_count`。

## Purpose / Math

计算给定离散复包络采样序列的 $N^{-1}\sum |u_n|^2$ 与 $N^{-1}\sum |u_n|^4$。不改变采样率或窗口。

## Numerical Notes

调用方负责定义峰值/RMS、单位、采样、滤波、CP和窗口；结果不是直流功率、RF–DC效率或载波平均后的实RF矩。无效输入和平方溢出分别报rfmoments:InvalidEnvelope及rfmoments:Overflow。原采样四阶矩可能混叠；需要上采样收敛。

## Dependencies

无项目方法依赖；MATLAB内置函数。

## Verification status

`test_rf_envelope_moments` 通过MATLAB R2020b本地包装，覆盖零、恒模、同二阶不同四阶、双音采样反例以及非法输入/溢出。未集成完整链路，未完成波形重采样验证和物理标定。
