# L3 方法契约提取指南（MATLAB 科研代码）

## 扫描锚点

| 字段 | 扫描锚点 | 提取目标 |
|------|----------|----------|
| signature | `function [out] = name(in1, in2, ...)` + 头部注释块 | 输入/输出参数名、类型、含义 |
| purpose | 函数头部 `% NAME - ...` 第一行 | 一句话功能 |
| math_definition | 注释里的公式、关键运算（`sign·min`、`(1-2û)a+b`、`exp(-d/denom)`、`phi^{-1}`） | 数学/算法定义 |
| numerical_notes | `max(·, eps)`、`realmin`、log-sum-exp、`epsilon` 放宽、`persistent` 缓存 | 数值稳定性坑 |
| dependencies | 函数体内调用的其它 `.m`（`GA(...)`, `polar_encoder(...)`, `SC_decoder(...)`, `phi(...)`） | 转成 `l3_ref` |
| health | 注释里"修复了...bug""legacy""近似模型""不替代蒙特卡洛""@Deprecated 等价" | healthy/degraded/broken + 理由 |

## 本项目真实示例锚点
- `core/sim_shaped_polar_16qam.m`：`switch cfg.decoder` 分支 → 依赖 4 个译码器；`E_theory = 18-16*p`。
- `core/estimate_ber_hat_sc_dual.m`：注释明示"近似模型，不替代蒙特卡洛" → `health: degraded`。
- `modulation/llr_16qam_gray_LSE.m`：`LSE_neg` 子函数 → numerical_notes 记 log-sum-exp。
- `polar/phi_inverse.m`：`if x1 > 1e2; epsilon = 10` → numerical_notes 记自适应放宽。
- `polar/GA.m`：调用 `phi` / `phi_inverse` → dependencies。

## 约束
1. 不要提取 getter/setter 式无意义代码；MATLAB 里关注核心数学运算与依赖。
2. 公式保真，不改口径。
3. 一函数一文件，文件名 `l3_{函数名}.md`，放对应 `{module}` 子目录，保证与 .m 1:1 对应（checker 据此算覆盖率）。
