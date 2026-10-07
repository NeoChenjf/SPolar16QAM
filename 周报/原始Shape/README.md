# 原始Shape

> 目标：用于整理和复现 OOK 场景下的 polar 码相关资料、脚本记录与结果说明。

## 2026-09-02：OOK loop 文档统一中文命名

- **修改内容**：`学习文档/shaped_polar验证loop/` 内迁移为 `需求澄清.md`、`loop设计.md`、`协调协议.md`、`进度表.md`、`问题记录.md`、`next_plan.md`，并更新内部交接链接；`最新认知与执行基线.md`保留为补充认知文档。
- **影响范围**：仅文档命名与交接入口，不修改 OOK 代码、参数或历史结果。
- **验证**：仓库内已无旧 loop 文件名引用；未运行仿真。
- **Rule reflection**：no new durable rule。

本文件夹作为“原始 Shape / OOK polar 码复现”的周报入口。后续材料建议按以下类型归档：

1. 原始论文或算法口径摘录；
2. OOK 调制与 polar 编码链路说明；
3. 复现实验脚本路径、参数和运行命令；
4. 复现结果图、表格与问题记录；
5. 与当前 16QAM 概率整形 polar code 工作的差异对照。

当前已建立 OOK shaped polar 复现 scaffold，并新增贴近 `gettest.m` 数据格式的入口。

2026-08-25 起，正式的 OOK shaped-polar 正确性验证将迁入 `16QAM_Polar/v2/experiments/ook_shaped_polar/`；其澄清与后续计划文档统一位于 `学习文档/shaped_polar验证loop/`。本轮仅验证 2018 年 higher-order shaped-polar 论文第二节的二元整形机制，固定采用 SC precoder 与 SC decoder，`p=P_X(1)=[0.5,0.6,0.7,0.8,0.9]`；`ShapedPolarS/` 与本目录旧 OOK 脚本继续只作为 legacy 对照，不能直接作为论文正确性证据。

2026-08-25：已建立该验证线的 loop 设计、共同口径协议、逐 `p` 进度看板和问题记录，均位于 `学习文档/shaped_polar验证loop/`。本 loop 先以 `p=0.5` 无整形基线打样，再按 `p=0.6/0.7/0.8/0.9` 逐单元验证；每个单元以独立码字的 `p_encoded` 均值、标准差和 95% CI 判定，而不是仅看单条 legacy 统计。待用户确认 loop 设计后才进入实现。 

2026-08-26：用户确认采用 BSC+GA 分工：`S_set` 由 BSC(`q=1-p`) 构造，`I_set/F_set` 在每个 BER 横轴 SNR 点由 GA 重构并排除 `S_set`。同时保留 legacy 的逐码字 `spow` 噪声归一化与 SC-only 口径；图表必须标为逐 SNR 自适应构造，不能误读为同一码跨 SNR 曲线。loop 协议已补充消息条件化 precoder、固定 `N=1024/K=ceil((N-S)/2)`、BSC Bhattacharyya 构造和 CI 样本精度要求。 

2026-08-26：用户确认 v2 wrapper 输出的未平滑 OOK BER/BLER 曲线符合预期。新增 `学习文档/shaped_polar验证loop/最新认知与执行基线.md` 作为该验证线的当前优先入口：先审计 `gettest.m` 的单-GA、SC、spow 归一化 baseline；BSC+GA 改为后续独立对照，`drawtest.m` 的五次平滑仅保留为历史视觉展示。Rule reflection: no new durable rule.

2026-08-26：按用户要求新增 `16QAM_Polar/v2/experiments/ook_shaped_polar/run_ook_shapedpolar_legacy_plot.m`。该入口只包装并调用 `ShapedPolarS/gettest.m`，输出 `p=[0.5,0.7,0.9]` 的 BER/BLER 对数审计图、CSV、MAT、README 和日志到 v2 时间戳结果目录；它用于检查 legacy 关键链路，不作为 BSC+GA 或论文级结果。当前本机 Windows `bash.exe` 会话不可用，WSL 命令参数又被 shell 去引号，尚未实际生成结果图；代码未进入 Octave 执行。Rule reflection: no new durable rule.

2026-08-26：修复 OOK legacy 审计入口的历史目录定位错误。`run_ook_shapedpolar_legacy_plot.m` 原先从 `v2` 根目录回退两级，错误拼接为项目根下的 `ShapedPolarS`；现改为回退一级，正确定位 `16QAM_Polar/ShapedPolarS`。未改变 gettest 链路、参数或统计口径。验证方式：由 MATLAB 报错路径与目标目录逐项对照；待重新运行入口验证。Rule reflection: no new durable rule.

---

## 1. 复现入口

参考旧脚本：

```text
16QAM_Polar/ShapedPolarS/gettest.m
16QAM_Polar/ShapedPolarS/drawtest.m
```

新增代码：

```text
16QAM_Polar/OOK/simulate_ook_shaped_polar.m
16QAM_Polar/OOK/run_ook_gettest_style.m
16QAM_Polar/OOK/run_ook_reproduce_smoke.m
16QAM_Polar/OOK/README.md
```

完整 gettest-style 运行命令：

```matlab
cd('16QAM_Polar/OOK');
run('run_ook_gettest_style.m');
```

完整默认参数：

| 参数 | 值 |
| --- | --- |
| `p_list` | `[0.5, 0.7, 0.9]` |
| `N` | 1024 |
| `snr_grid` | `-5:0.5:10` |
| `num_frames` | 1000 |
| `seed` | 42 |
| `regenerate_each_frame` | true |

说明：该完整入口接近旧 `gettest.m` 的运行量，默认属于长仿真。本轮已在用户授权后完成一次完整运行。

完整运行结果目录：

```text
16QAM_Polar/OOK/results/20260704_164200_ook_gettest_style/
```

格式 smoke 命令：

```matlab
ook_overrides = struct('snr_grid', [-5 0 5 10], ...
                       'num_frames', 5, ...
                       'result_tag', 'ook_gettest_style_snr_m5_to_10_smoke');
run('run_ook_gettest_style.m');
```

格式 smoke 结果目录：

```text
16QAM_Polar/OOK/results/20260704_162754_ook_gettest_style_snr_m5_to_10_smoke/
```

---

## 2. 复现口径

第一版复现保留 `gettest.m` 的核心思路：

```text
S = ceil(N * (1 - h(p)))
K = ceil((N - S) / 2)
GA 排序生成 S/I/F
SC decoder 根据 shaping prior 生成 shaping bits
polar_encoder 得到 OOK 0/1 发射序列
AWGN 加噪
SC decoder 恢复信息位
统计 BER / BLER
```

新增 `run_ook_gettest_style.m` 输出更贴近旧脚本的数据格式：

```text
BER  : length(p_list) x length(SNR)
BLER : length(p_list) x length(SNR)
```

对应文件：

```text
ook_gettest_style_BER_matrix.csv
ook_gettest_style_BLER_matrix.csv
ook_gettest_style_curves.mat
figures/ook_gettest_style_BER.png/pdf/fig
figures/ook_gettest_style_BLER.png/pdf/fig
```

BER/BLER 图均使用对数坐标。原始 CSV/MAT 保留 0 值，绘图时仅为了 log-scale 可见性把 0 显示在 `1e-5`。

---

## 3. 完整运行结果与图片分析

BER 对数图：

![OOK gettest-style BER](../../16QAM_Polar/OOK/results/20260704_164200_ook_gettest_style/figures/ook_gettest_style_BER.png)

图片分析：该图采用 `drawtest.m` 类似的 `semilogy` 口径，横轴按参考图固定为 `SNR=-5~10 dB`，纵轴显式设置为 `10^0` 到 `10^-5` 的对数刻度。`p=0.5/0.7/0.9` 三条 SC 曲线均在低 SNR 约 `0.5` 附近，随后出现明显瀑布区：`p=0.5` 约在 `1~3 dB` 下降，`p=0.7` 约在 `2~4 dB` 下降，`p=0.9` 约在 `6~8 dB` 下降。该结果说明在当前 OOK shaped-polar 复现口径下，p 越大，曲线整体右移；高 SNR 处的 0 BER 是 1000 帧内未观测到错误，不能解释为真实 BER 为 0。

BLER 对数图：

![OOK gettest-style BLER](../../16QAM_Polar/OOK/results/20260704_164200_ook_gettest_style/figures/ook_gettest_style_BLER.png)

图片分析：BLER 图与 BER 图趋势一致，但因为 BLER 统计的是整帧是否出错，曲线更靠近 `1` 并在瀑布区后快速落到底部显示下限。完整运行中，`p=0.5` 的 BLER 在 `3 dB` 约为 `3.0e-3`，`4 dB` 后未观测到块错误；`p=0.7` 在 `4 dB` 约为 `4.0e-3`，`4.5 dB` 后未观测到块错误；`p=0.9` 约在 `6~8 dB` 间完成下降。该图支持“不同 p 对应不同工作 SNR 窗口”的复现结论。

BER 矩阵关键片段：

| p | -5 dB | 0 dB | 2 dB | 3 dB | 4 dB | 7 dB | 8 dB | 10 dB |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0.5 | 4.984e-1 | 4.679e-1 | 1.895e-2 | 3.750e-4 | 0 | 0 | 0 | 0 |
| 0.7 | 4.996e-1 | 4.982e-1 | 2.969e-1 | 3.534e-2 | 9.512e-4 | 0 | 0 | 0 |
| 0.9 | 4.985e-1 | 5.000e-1 | 5.000e-1 | 5.012e-1 | 4.948e-1 | 4.856e-2 | 0 | 0 |

---

## 4. 当前边界

当前可以写：

1. OOK 复现目录已建立；
2. `gettest.m` 的核心 shaped polar / OOK / SC decoding 思路已被整理为可复现入口；
3. `run_ook_gettest_style.m` 已支持 `p=[0.5,0.7,0.9]`、`SNR=-5:0.5:10`、`BER/BLER` 矩阵和对数图；
4. 完整 `num_frames=1000` 运行已完成，输出矩阵、MAT、PNG/PDF/FIG 均可用于后续复现讨论。

当前不能写：

1. 不能把 1000 帧中高 SNR 的 0 BER/BLER 解释为真实误码概率为 0；
2. 不能把全零 BER 点解释为算法优势；
3. 不能把 legacy OOK LLR 口径等同于当前 16QAM LLR 口径；
4. 当前 OOK 复现只包含 SC 曲线，尚未加入参考图中的 SCL / SCL-CRC 曲线。

## 变更记录

- **2026-08-26**：新增 `学习文档/高阶调制理论/方法.md`，依据《Shaped Polar Codes for Higher Order Modulation》梳理论文的 `2^m`-ASK 编码结构、4-ASK 的跨层 XOR 变换、MB 分布参数和带联合符号先验的 demapper；同时明确方形 16QAM 应按两个独立 4-ASK 轴扩展，当前 v2 的四路独立编码尚非论文的严格高阶构造。本轮未修改 MATLAB 代码、未运行仿真。Rule reflection: no new durable rule
- **2026-07-04**：在用户授权后运行完整 OOK gettest-style 复现，参数为 `p=[0.5,0.7,0.9]`、`SNR=-5:0.5:10`、`num_frames=1000`，结果目录为 `16QAM_Polar/OOK/results/20260704_164200_ook_gettest_style/`。同步重画 BER/BLER 对数图，显式设置 `YScale=log` 与 `10^-5~10^0` 刻度；图片分析已从 smoke 口径更新为完整结果口径。Rule reflection: updated `workbook/troubleshooting-history.md` because MATLAB log-scale plots need explicit tick settings to avoid misleading visual review
- **2026-07-04**：按用户参考图修正 OOK gettest-style SNR 显示范围。`run_ook_gettest_style.m` 默认 SNR 从 `-5:0.5:18` 改为 `-5:0.5:10`，BER/BLER 对数图横轴固定为 `[-5,10]`，零值显示下限从 `1e-8` 改为 `1e-5`；重新运行 `snr=[-5,0,5,10]`、`num_frames=5` 格式 smoke，结果目录为 `16QAM_Polar/OOK/results/20260704_162754_ook_gettest_style_snr_m5_to_10_smoke/`。Rule reflection: no new durable rule
- **2026-07-04**：按用户要求改为 `p_list=[0.5,0.7,0.9]` 并新增 gettest-style 复现入口 `run_ook_gettest_style.m`。该入口默认 `SNR=-5:0.5:10`、`num_frames=1000`，输出 `BER/BLER` 的 `p x SNR` 矩阵、MAT 曲线和对数 BER/BLER 图；本轮只用 `snr=[-5,0,5,10]`、`num_frames=5` 跑格式 smoke，结果目录为 `16QAM_Polar/OOK/results/20260704_162754_ook_gettest_style_snr_m5_to_10_smoke/`。同时修复 `simulate_ook_shaped_polar.m` 的 override 参数未生效问题。Rule reflection: no new durable rule
- **2026-07-04**：完成第一版 OOK shaped polar 复现 scaffold。新增 `16QAM_Polar/OOK/`，包含 `simulate_ook_shaped_polar.m`、`run_ook_reproduce_smoke.m`、README 和局部 `.gitignore`；运行 MATLAB smoke 输出 `16QAM_Polar/OOK/results/20260704_154041_ook_shaped_polar_smoke/`，生成 CSV/MAT/README/run_log 和 BER/Goodput/Energy-Goodput 图。同步按 `.claude/skills` 的 spec-harness 思路新增 OOK 的 L1/L2/L3 最小知识库记录。Rule reflection: no new durable rule
- **2026-07-04**：新建 `周报/原始Shape/` 入口，用于后续复现 OOK 的 polar 码。Rule reflection: no new durable rule



