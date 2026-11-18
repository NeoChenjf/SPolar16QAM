# L3 · goodput_certificate

- **method_id**: l3_goodput_certificate
- **file_path**: 16QAM_Polar/v2/analysis/goodput_certificate.m
- **module**: analysis
- **health**: degraded — 有限样本余项成本过高，保留诊断，非正式调度证书。

## Signature
`[lower,upper,radius]=goodput_certificate(G,G0,K,K0,D,nlooks,nmethods)`。G/G0为独立配对整帧Goodput向量；K/K0为设计信息位数，D为资源分母，后两项为预登记多重性。输出均值Z的界及半径。

## Purpose
固定查看档位下，给5%相对Goodput约束提供有限样本经验Bernstein诊断界。

## Math / Algorithm
令 $Z=G-0.95G_0$，$a=-0.95K_0/D$，$b=K/D$，$\delta=0.05/(124n_{looks}n_{methods}2)$。

$$
r=\sqrt{2s_Z^2\log(2/\delta)/n}+7(b-a)\log(2/\delta)/(3(n-1)).
$$

将均值加减r剪裁到[a,b]；n小于2返回理论范围。依据Maurer与Pontil2009 Theorem4。

## Numerical Notes
逐位误差不当独立样本；只覆盖固定H/噪声下候选、方法及已登记查看次数，不覆盖跨H或真实Pareto位置。输入必须满足设计范围。

## Dependencies
无（MATLAB内置数值函数）。

## Health
已有专用测试脚本；执行记录由主阶段报告追加，不预宣称独立验证。开发诊断保留，不替代正式下注证书。


## 2026-11-18 实际验证补充

测试/分析已执行；仅1完整独立H条件，不将公式测试当科研验收。详见loop本轮报告末尾；整体健康度保持degraded。
