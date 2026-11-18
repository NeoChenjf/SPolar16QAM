# L3 · goodput_betting_certificate

- **method_id**: l3_goodput_betting_certificate
- **file_path**: 16QAM_Polar/v2/analysis/goodput_betting_certificate.m
- **module**: analysis
- **health**: degraded — 理论假设明确，专用测试与独立实验状态以阶段末尾记录为准。

## Signature
`[lower,upper,detail]=goodput_betting_certificate(G,G0,K,K0,D,nmethods)`。独立配对整帧G/G0，设计位数K/K0及分母D；输出均值Z的全时界，detail记录固定下注比例、阈值、样本数。

## Purpose
在同一固定H/噪声下，统一保护124非基线候选及3方法的Goodput可行认证，允许按数据停机。

## Math / Algorithm
$Z=G-0.95G_0$，$a=-0.95K_0/D$，$b=K/D$，固定$f\in\{0.1,0.25,0.5,0.9\}$。

$$
W_n^+(\mu)=\tfrac14\sum_f\prod_{t=1}^n[1+f(Z_t-\mu)/(\mu-a)].
$$

负向使用$f(\mu-Z_t)/(b-\mu)$。每尾$\delta=0.05/(124n_{methods}2)$。真实iid均值处财富是非负鞅，Ville不等式加联合界覆盖所有时间。按单调财富64步二分反演，clip到理论范围；空样本返回[a,b]。下界不小于0才认证。

## Numerical Notes
log1p、logsumexp防溢出；二分下界取保守左端，上界取右端。不要求候选间独立，但要求每候选配对帧iid、固定H与噪声。95%指每H候选集合全时保护，不指跨H、真实前沿位置或能量器件准确度。无BER拟合或目标真值输入。

## Dependencies
无（MATLAB内置数值函数）。

## Health
专用测试包含常量财富闭式、反射、样本量、多重性及非法输入；测试通过与数学证明及独立研究验证分开记录。主实验仍待独立结果，不预填成功。


## 2026-11-18 实际验证补充

测试/分析已执行；仅1完整独立H条件，不将公式测试当科研验收。详见loop本轮报告末尾；整体健康度保持degraded。
