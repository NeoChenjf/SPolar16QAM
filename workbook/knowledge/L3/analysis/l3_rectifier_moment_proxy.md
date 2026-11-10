# L3 · rectifier_moment_proxy

- **method_id**: l3_rectifier_moment_proxy
- **file_path**: 16QAM_Polar/v2/analysis/rectifier_moment_proxy.m
- **module**: analysis
- **health**: degraded（数学数值测试通过，器件参数/物理带宽/标定未验证）

## Signature

`result=rectifier_moment_proxy(envelope,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)`；输入为峰值复包络及明确物理标尺、纯实匹配输入电阻、调用者提供A/V²和A/V⁴系数及适用RF功率范围。

## Purpose / Math

在载波周期平均和包络缓变假设下，$M_2=V_u^2 E|u|^2/2$，$M_4=3V_u^4 E|u|^4/8$，$P_{RF}=M_2/R$，代理 $z=k_2M_2+k_4M_4$。结果含rf_input_power_w、两个电压矩、current_proxy_a、status和is_dc_power=false。

## Numerical Notes

仅适用于峰值包络约定和调用者提供的阻抗/系数/有效范围；程序不验证器件、匹配、偏置、载波/滤波或系数来源。范围外输出状态out_of_range、代理NaN；输入功率范围内也不证明二极管模型真实。代理不是已校准DC电流/功率或整流效率；不模拟饱和/击穿。

## Dependencies

- l3_ref: l3_rf_envelope_moments

## Verification status

MATLAB test_rectifier_moment_proxy通过已知峰值幅度和同均方不同四阶、零输入、范围拒绝及无效参数。尚未结合真实器件或信道波形验收。
