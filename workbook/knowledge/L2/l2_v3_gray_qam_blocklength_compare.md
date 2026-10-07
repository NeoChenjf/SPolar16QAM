# L2：v3 Gray QAM码长对照

## 目标

在统一 `energy_lambda` 口径下，只改变极化码码长，比较 `N=256` 与 `N=1024`
相对理想目标分布、latent可实现模型和真实发送码字的PMF及平均发送RF能量代理量。

## 入口

```matlab
summary = run_gray_qam('blocklength_compare_smoke');
summary = run_gray_qam('blocklength_compare');
```

实现文件：`16QAM_Polar/v3/run_gray_qam_blocklength_compare.m`。

## 固定条件

- `M=[8 16 32 64]`；
- `lambda=[0 0.25 0.5]`；
- `N=[256 1024]`；
- 两个N使用相同帧数、`source_mc_samples`、`source_mc_seed`、运行seed和SNR口径；
- `fixed_n0`，`SNR=120 dB`，用于隔离PMF/能量实现，不提供BER结论。

## 三层对象

1. `target`：解析目标 `P_X proportional to exp(lambda*|x_scaled|^2)`；
2. `model`：latent概率关系能够表示的拟合PMF；
3. `empirical`：有限长shaped-polar真实发送码字的经验PMF。

## 输出

时间戳结果目录包含：

- `blocklength_compare.csv`与运行中partial CSV；
- 每个`M/lambda/N`的target/model/empirical PMF CSV；
- `results.mat`、`checkpoint.mat`、README和运行/进度日志；
- 能量对照图和PMF TV对照图的PNG/PDF/FIG。

## 验证边界

- smoke只验证接口、维度、输出和N=1024执行路径；
- 正式结果用于判断码长是否改善PMF与能量逼近；
- 本入口不比较N=1024 BER，不代表整流效率，也不用于宣布lambda最优。

## 2026-09-16正式结果

- 结果目录：`16QAM_Polar/v3/results/20260916_225430_energy_lambda_blocklength_formal/`；
- 12个`M × lambda`点的empirical-target TV 95%上界在N=1024下均低于N=256；
- 12点中11点的经验能量绝对理论差缩小；
- 码长增加改善分布逼近，但未消除model→empirical构造差距；
- 结果仍不包含N=1024 BER证据。
