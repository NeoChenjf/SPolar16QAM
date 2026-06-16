# B1：OFDM baseline 阶段文档

> 所属阶段：阶段 B 多载波系统构建  
> 当前任务：建立最小可复现 OFDM full-chain baseline  
> 当前状态：轻量 Monte Carlo 已完成；dense SNR 论文展示入口已准备，待用户本地运行  
> 阶段边界：本轮只完成统一 `p` 的 AWGN OFDM baseline，不进入 Rayleigh、不进入三策略优化

B1 的目标是先把多载波链路跑通。直观上，后续所有 `p_k` 自适应策略都依赖一个稳定的 OFDM 基础链路：如果 IFFT/CP、信道、均衡、LLR 和 SC 解码接口没有先闭环，后续策略收益就无法判断来自资源分配还是来自链路实现误差。

---

## 1. 阶段目标

建立一个最小可复现的 OFDM full-chain baseline，用统一 `p` 验证多载波链路的 BER、Goodput 和能量指标。

第一轮只回答三个问题：

1. 当前单载波 16QAM 概率整形 polar code 能否接入 OFDM 调制链路；
2. 在 AWGN OFDM 口径下，统一 `p` 的 BER / Goodput 曲线是否能稳定生成；
3. 输出格式是否足够支撑后续 Rayleigh 子载波可靠性与三策略对比。

本轮不判断最终多载波最优策略。

---

## 2. 当前状态

已检查 `16QAM_Polar/v2`：当前没有成型的 OFDM baseline 入口；`config.m` 中存在 `cfg.channel = 'AWGN'`，并注明后续可扩展 Rayleigh。

因此 B1 后续需要新增脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m
```

已新增脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m
```

脚本采用 `mfilename('fullpath')` 自举到 `v2` 根目录，不要求 MATLAB 当前文件夹必须预先位于 `16QAM_Polar/v2`。

已新增 dense SNR 包装脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline_dense.m
```

该脚本复用 `run_ofdm_baseline.m` 的 OFDM 链路实现，只覆盖 `snr_grid=8:1:20` 和输出目录标签，用于后续生成论文展示级 AWGN OFDM baseline 曲线。由于属于更密 SNR Monte Carlo，本轮只完成脚本准备和静态检查，不自动运行。

---

## 3. 系统结构

B1 的 full-chain baseline 结构如下：

```text
信息位
-> 概率整形 polar 编码
-> 16QAM Gray 映射
-> OFDM IFFT
-> CP 插入
-> AWGN 信道
-> CP 去除
-> FFT
-> 频域均衡
-> 16QAM LLR 解调
-> 4 路 SC 译码
-> BER / Goodput / Energy
```

第一轮使用 AWGN OFDM 是为了验证多载波调制和解调接口，不把 Rayleigh 频率选择性、子载波分组和 `p_k` 自适应混入同一次实验。

---

## 4. 固定实验口径

第一轮固定轻量参数：

```matlab
p_list = [0.5, 0.3, 0.1];
snr_grid = [8, 12, 16, 20];
n_subcarriers = 64;
cp_ratio = 1/4;
channel_model = 'AWGN';
decoder = 'SC';
num_frames = 100;
seed = 42;
```

参数解释：

| 参数 | 含义 |
| --- | --- |
| `p_list` | 统一整形参数，先不做子载波级 `p_k` |
| `snr_grid` | 轻量 SNR 代表点，用于验证趋势和输出 |
| `n_subcarriers` | OFDM 子载波数 |
| `cp_ratio` | CP 长度比例，第一轮为 `N_cp = n_subcarriers/4` |
| `channel_model` | 第一轮固定 AWGN |
| `decoder` | 沿用阶段 A 的 SC |
| `num_frames` | 轻量验证帧数，不作为最终统计结论 |
| `seed` | 固定随机种子，保证可复现 |

dense SNR 论文展示入口参数：

```matlab
p_list = [0.5, 0.3, 0.1];
snr_grid = 8:1:20;
n_subcarriers = 64;
cp_ratio = 1/4;
channel_model = 'AWGN';
decoder = 'SC';
num_frames = 100;
seed = 42;
```

运行命令：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run('experiments/multicarrier/run_ofdm_baseline_dense.m');
```

预期输出目录：

```text
16QAM_Polar/v2/results/YYYYMMDD_HHMMSS_ofdm_baseline_dense/
```

---

## 5. 指标定义

BER 仍按成功恢复的信息位统计：

$$
\mathrm{BER}=\frac{N_{\mathrm{err}}}{N_{\mathrm{info}}}.
$$

Goodput 沿用阶段 A 口径：

$$
G(p,\gamma)=R_{\mathrm{total}}(p)\left(1-\mathrm{BER}(p,\gamma)\right).
$$

其中：

$$
R_{\mathrm{total}}(p)=\frac{\sum_{b=1}^{4}K_b(p)}{4N}.
$$

能量 proxy 沿用阶段 A 的 16QAM 概率整形均方能量：

$$
E(p)=18-16p.
$$

OFDM 第一轮只做资源归一化说明：CP 会占用额外时域资源，因此后续正式比较 Goodput 时应记录是否采用 CP 开销修正。第一轮 baseline 先输出原始 `R_total` 与可选 `R_total_cp_corrected`，避免把 CP 开销遗漏为后续结论风险。

---

## 6. 输出要求与实现状态

脚本执行时输出目录为：

```text
16QAM_Polar/v2/results/YYYYMMDD_HHMMSS_ofdm_baseline/
```

必须输出：

```text
ofdm_baseline.csv
README.txt
figures/ofdm_ber_vs_snr.png/pdf/fig
figures/ofdm_goodput_vs_snr.png/pdf/fig
figures/ofdm_energy_goodput.png/pdf/fig
```

当前实现已覆盖上述输出：

| 输出 | 状态 |
| --- | --- |
| `ofdm_baseline.csv` | 已实现 |
| `ofdm_baseline.mat` | 已实现 |
| `README.txt` | 已实现 |
| `run_log.txt` | 已实现 |
| `figures/ofdm_ber_vs_snr.png/pdf/fig` | 已实现 |
| `figures/ofdm_goodput_vs_snr.png/pdf/fig` | 已实现 |
| `figures/ofdm_energy_goodput.png/pdf/fig` | 已实现 |

dense SNR 包装脚本沿用相同输出格式，区别是 CSV 预期为 `3 p x 13 SNR = 39` 行，输出目录后缀为 `_ofdm_baseline_dense`。

`ofdm_baseline.csv` 至少包含：

```text
p, snr_db, ber, goodput, r_total, r_total_cp_corrected,
e_theory, e_norm, n_subcarriers, cp_ratio, channel_model,
decoder, num_frames, seed
```

`README.txt` 至少记录：

1. 运行命令；
2. 完整参数；
3. 输出文件说明；
4. 是否使用 CP 开销修正；
5. 与阶段 A 单载波口径的对比边界；
6. 本次结果是否仅为轻量 baseline。

---

## 7. 运行结果与验收

正式运行目录：

```text
16QAM_Polar/v2/results/20260522_174039_ofdm_baseline/
```

运行口径：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run('experiments/multicarrier/run_ofdm_baseline.m');
```

输出文件已确认：

```text
ofdm_baseline.csv
ofdm_baseline.mat
README.txt
run_log.txt
figures/ofdm_ber_vs_snr.png/pdf/fig
figures/ofdm_goodput_vs_snr.png/pdf/fig
figures/ofdm_energy_goodput.png/pdf/fig
```

`ofdm_baseline.csv` 共 12 行，符合 `3 p x 4 SNR`。

关键结果如下：

| p | SNR(dB) | BER | Goodput CP-corrected | E_norm |
| --- | ---: | ---: | ---: | ---: |
| 0.5 | 8 | 4.864e-1 | 0.205434 | 1.00 |
| 0.5 | 12 | 4.394e-1 | 0.224244 | 1.00 |
| 0.5 | 16 | 2.678e-1 | 0.292879 | 1.00 |
| 0.5 | 20 | 1.517e-2 | 0.393934 | 1.00 |
| 0.3 | 8 | 4.565e-1 | 0.204459 | 1.32 |
| 0.3 | 12 | 3.893e-1 | 0.229744 | 1.32 |
| 0.3 | 16 | 2.795e-1 | 0.271029 | 1.32 |
| 0.3 | 20 | 3.732e-2 | 0.362135 | 1.32 |
| 0.1 | 8 | 2.801e-1 | 0.211484 | 1.64 |
| 0.1 | 12 | 1.658e-1 | 0.245053 | 1.64 |
| 0.1 | 16 | 1.360e-1 | 0.253799 | 1.64 |
| 0.1 | 20 | 4.876e-2 | 0.279426 | 1.64 |

运行图如下：

![OFDM baseline BER vs SNR](../../16QAM_Polar/v2/results/20260522_174039_ofdm_baseline/figures/ofdm_ber_vs_snr.png)

![OFDM baseline Goodput vs SNR](../../16QAM_Polar/v2/results/20260522_174039_ofdm_baseline/figures/ofdm_goodput_vs_snr.png)

![OFDM baseline Energy-Goodput](../../16QAM_Polar/v2/results/20260522_174039_ofdm_baseline/figures/ofdm_energy_goodput.png)

B1 baseline 观察：

1. AWGN OFDM 链路已跑通，说明阶段 A 的概率整形 polar code 可以接入最小 OFDM 调制链路；
2. 低中 SNR 下 `p=0.1` BER 明显低于 `p=0.5`，但由于 `R_total` 上限较低，Goodput CP-corrected 只在低 SNR 有局部优势；
3. 最高 CP 修正 Goodput 出现在 `p=0.5, 20 dB`，为 `0.393934`，对应 BER `1.516602e-02`；
4. 该结果仍是轻量 baseline，不能写成最终多载波最优策略结论；
5. B2/B3 应进一步进入 Rayleigh 子载波可靠性和三类策略对比。

### 7.1 BER 曲线反转复盘

用户指出：`16 dB` 和 `20 dB` 附近的 BER 曲线并不完全符合“`p` 越大 BER 越好”的直觉。复查后结论如下。

首先，这不是 OFDM baseline 新引入的明显实现错误。B1 的 AWGN OFDM 结果与阶段 A single-carrier final full-chain 结果在对应 SNR 上高度接近：

| 口径 | p | 16 dB BER | 20 dB BER |
| --- | ---: | ---: | ---: |
| B1 OFDM baseline | 0.5 | 2.678e-1 | 1.517e-2 |
| Stage A final full-chain | 0.5 | 2.642e-1 | 1.335e-2 |
| B1 OFDM baseline | 0.3 | 2.795e-1 | 3.732e-2 |
| Stage A final full-chain | 0.3 | 2.822e-1 | 3.512e-2 |
| B1 OFDM baseline | 0.1 | 1.360e-1 | 4.876e-2 |
| Stage A final full-chain | 0.1 | 1.367e-1 | 4.325e-2 |

这里的 Stage A final full-chain 不是早期 `0/5/10/15/20 dB` 轻量闭环图，而是统一口径 final global curve；其 full-chain SNR 网格为 `8:1:20`，已经满足 `1 dB` 粒度。上表只抽取 `16 dB` 和 `20 dB` 两个点用于和 B1 的轻量 OFDM 点对齐，不表示阶段 A 主图只有稀疏点。

这说明 B1 的 IFFT/CP/FFT 链路在 AWGN 口径下基本保持了阶段 A full-chain 行为，反转主要来自概率整形 polar code 本身的 full-chain 指标结构，而不是 OFDM 调制错误。但 B1 自身仍是 `snr_grid=[8,12,16,20]`、`num_frames=100` 的轻量 OFDM baseline，若要在论文中展示 OFDM 曲线过渡，应后续补充 `1 dB` 粒度的 OFDM/Rayleigh 复验，而不能只依赖 B1 四个 SNR 点。

其次，BER 不是只由 `p` 的大小单调决定。`p` 改变后同时改变：

1. 星座符号概率与不同 bit-level 的可靠性；
2. 每路整形位数量 `S_b(p)`；
3. 信息位数量 `K_b(p)`；
4. 信息集合 `I_b(p)` 在 polar 可靠性排序中的位置；
5. 最终 BER 的加权分母 `sum_b K_b(p)`。

因此，小 `p` 的 BER 可能在中等 SNR 下更低，但这不表示系统整体更好。以 `16 dB` 为例，`p=0.1` 的 BER 为 `1.360e-1`，明显低于 `p=0.5` 的 `2.678e-1`；但它的 CP 修正 Goodput 只有 `0.253799`，低于 `p=0.5` 的 `0.292879`。原因是 `p=0.1` 的 `R_total_cp_corrected=0.29375`，而 `p=0.5` 的上限是 `0.4`。

到 `20 dB` 时，信道足够好，`p=0.5` 的 BER 下降到 `1.517e-2`，同时保留最高码率上限，因此 BER 与 Goodput 都优于强整形方案。这与阶段 A 的最终结论一致：强整形可能在局部 SNR 降低 BER，但 Goodput 上限损失会限制整体收益。

当前判断：

1. `16 dB` 的 `p=0.1` 低 BER 是 full-chain 指标结构下的局部现象，不应视为 OFDM bug；
2. `20 dB` 已回到 `p=0.5` 最优的高 SNR 行为；
3. B1 是 `num_frames=100` 的轻量 baseline，曲线形状只用于发现现象，不用于最终策略排序；
4. 阶段 A 论文级 full-chain 图已经有 `1 dB` 粒度；若后续要把 OFDM 中的类似现象写入论文，需要在 B2/B3 或附加复验中使用 `1 dB` SNR 网格、多 seed / 更高帧数确认。

### 7.2 Dense SNR 入口准备

为使 B1 后续图表与阶段 A 当前论文展示标准一致，已新增 `run_ofdm_baseline_dense.m`。该脚本保持 B1 的 AWGN OFDM、统一 `p=[0.5,0.3,0.1]`、SC decoder 和 CP 修正 Goodput 口径不变，只把 SNR 网格从 `[8,12,16,20]` 改为 `8:1:20`。

本轮未自动运行 dense Monte Carlo，原因是 workbook 规定长 MATLAB 仿真应由用户本地运行，且 dense 网格为 `39` 个 full-chain 点，运行量明显高于当前 `12` 点轻量 baseline。

已完成验证：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
issues1 = checkcode('experiments/multicarrier/run_ofdm_baseline.m','-id');
issues2 = checkcode('experiments/multicarrier/run_ofdm_baseline_dense.m','-id');
disp(issues1);
disp(issues2);
```

结果：两个脚本均未输出具体 issue。

### 7.3 频域图与星座图检查

为检查 OFDM 的功率谱密度、频域资源网格和 16QAM 星座映射是否直观合理，新增一帧级可视化诊断脚本：

```text
16QAM_Polar/v2/experiments/multicarrier/run_ofdm_visual_check.m
```

运行命令：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run('experiments/multicarrier/run_ofdm_visual_check.m');
```

结果目录：

```text
16QAM_Polar/v2/results/20260524_163654_ofdm_visual_check/
```

诊断参数：

```matlab
p_list = [0.5, 0.3, 0.1];
snr_db = 20;
n_subcarriers = 64;
cp_ratio = 1/4;
channel_model = 'AWGN';
seed = 42;
```

该脚本只生成每个 `p` 的一帧 OFDM 诊断图，不计算 BER / Goodput，不作为 Monte Carlo 统计结果。

功率谱密度面板：

![OFDM PSD panel](../../16QAM_Polar/v2/results/20260524_163654_ofdm_visual_check/figures/ofdm_psd_panel.png)

该图横坐标为归一化频率 `cycles/sample`，纵坐标为归一化功率谱密度 `PSD (dB)`。PSD 面板采用 `2 x 3` 六宫格：三列分别对应 `p=0.5`、`p=0.3`、`p=0.1`，每列上方为同一 `p` 下的 TX OFDM 时域信号 PSD，下方为 AWGN 后 RX OFDM 时域信号 PSD。为展示 guard band 和“低-平台-低”的频谱轮廓，该 PSD 图使用 `4x` 过采样和频域居中补零；这只影响可视化，不改变 `run_ofdm_baseline.m` 中的 BER/Goodput 仿真链路。

频域资源网格辅助面板：

![OFDM frequency-resource panel](../../16QAM_Polar/v2/results/20260524_163654_ofdm_visual_check/figures/ofdm_frequency_panel.png)

星座图面板：

![OFDM constellation panel](../../16QAM_Polar/v2/results/20260524_163654_ofdm_visual_check/figures/ofdm_constellation_panel.png)

单独面板：

```text
figures/ofdm_visual_check_p050.png/pdf/fig
figures/ofdm_visual_check_p030.png/pdf/fig
figures/ofdm_visual_check_p010.png/pdf/fig
```

检查结论：PSD 面板用于查看 OFDM 信号在频率轴上的功率谱密度；频域资源网格辅助面板用于查看 64 子载波与 16 个 OFDM symbol 的资源网格形状；星座图面板展示 TX 与 AWGN 后 RX 星座点云，用于直观确认 16QAM Gray 映射、IFFT/CP/FFT 回到频域后的符号分布没有明显异常。该检查只说明可视化链路形态正常，不替代 BER/Goodput baseline。

---

## 8. 验收标准

B1 可验收的条件：

1. `experiments/multicarrier/run_ofdm_baseline.m` 能从 `v2` 根目录运行；
2. 不修改 `config.m`，所有覆盖参数写入 `cfg_local`；
3. 结果目录为 timestamped `results/YYYYMMDD_HHMMSS_ofdm_baseline/`；
4. CSV 行数为 `3 p x 4 SNR = 12`；
5. 三张图和 `README.txt` 全部落盘；
6. README 明确写明 AWGN OFDM、统一 `p`、SC decoder、轻量帧数；
7. 文档不把 B1 结果写成最终多载波结论。

当前验收进展：

| 条目 | 状态 | 说明 |
| --- | --- | --- |
| 脚本入口 | 已完成 | `experiments/multicarrier/run_ofdm_baseline.m` |
| 不修改 `config.m` | 已完成 | 参数均写入 `cfg_local` |
| 输出目录逻辑 | 已完成 | `20260522_174039_ofdm_baseline` |
| CSV 12 行 | 已完成 | `3 p x 4 SNR` |
| 三张图和 README | 已完成 | PNG/PDF/FIG 和 README 均已落盘 |
| 口径说明 | 已完成 | README 写明 AWGN OFDM、统一 `p`、SC、轻量 baseline |
| MATLAB 静态检查 | 已完成 | `checkcode` 返回空结构体字段 `message/line/column/fix/id`，无具体 issue 条目 |
| B1 结论边界 | 已完成 | 仅作为 baseline，不写最终多载波最优 |
| dense SNR 脚本 | 已完成，待运行 | `run_ofdm_baseline_dense.m`，预期 `3 p x 13 SNR = 39` 行 |
| 频域/星座诊断 | 已完成 | `20260524_163654_ofdm_visual_check`，包含 2x3 六宫格 4x 过采样 PSD、频域资源网格和星座图 |

静态检查命令：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
issues = checkcode('experiments/multicarrier/run_ofdm_baseline.m','-id');
disp(issues);
```

正式运行命令：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run('experiments/multicarrier/run_ofdm_baseline.m');
```

---

## 9. 后续入口

B1 完成后进入两步：

1. B2：Rayleigh 与子载波可靠性画像，输出 `|H_k|^2`、等效 `gamma_k` 和 MI / BER proxy；
2. B3：三类策略同口径对比：
   - 好信道偏信息；
   - 好信道偏能量整形；
   - 差子载波纯传能。

---

## 10. 变更记录

- **2026-05-24**：调用 rule reflection hook 对 B1 频谱图画图规则进行收束。结论：该问题属于可复用的 Stage B OFDM 图形规范，已更新 `workbook/code-experiment-standards.md`，新增 PSD 频率轴/PSD 纵轴、guard band 可见性、TX/RX 同列六宫格布局、可视化过采样/补零需写入 README 与周报的规则。Rule reflection: added/updated `workbook/code-experiment-standards.md` because OFDM spectrum plotting rules are reusable across Stage B diagnostics.
- **2026-05-24**：按用户要求将 B1 PSD 图改为带 guard band 的频谱展示。`run_ofdm_visual_check.m` 使用 `4x` 过采样和频域居中补零生成 `ofdm_psd_panel.png/pdf/fig`，横坐标为归一化频率、纵坐标为归一化 PSD(dB)，可显示两侧低、中间平台的 OFDM 频谱轮廓；重新运行输出 `16QAM_Polar/v2/results/20260524_162953_ofdm_visual_check/`。该处理仅用于 PSD 可视化，不改变 BER/Goodput 仿真链路。Rule reflection: no new durable rule
- **2026-05-24**：按用户要求将 B1 PSD 面板调整为 `2 x 3` 六宫格。三列对应 `p=0.5/0.3/0.1`，每列上方为 TX PSD、下方为 RX PSD；`README.txt` 同步记录该布局。`run_ofdm_visual_check.m` 静态 `checkcode` 无具体 issue，并重新运行输出 `16QAM_Polar/v2/results/20260524_163654_ofdm_visual_check/`。Rule reflection: no new durable rule
- **2026-05-24**：新增 B1 OFDM 可视化诊断脚本 `16QAM_Polar/v2/experiments/multicarrier/run_ofdm_visual_check.m`，生成 `p=[0.5,0.3,0.1]`、`20 dB`、64 子载波、CP=1/4 的一帧频域资源网格和 TX/RX 星座图。脚本 `checkcode` 无具体 issue，已运行输出 `16QAM_Polar/v2/results/20260524_161926_ofdm_visual_check/`；该结果只作为链路形态检查，不替代 BER/Goodput Monte Carlo。Rule reflection: no new durable rule
- **2026-05-24**：继续 B1，新增 dense SNR 包装脚本 `16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline_dense.m`。脚本复用 B1 OFDM baseline 链路，固定 `p=[0.5,0.3,0.1]`、`snr_grid=8:1:20`、AWGN、SC、`num_frames=100`，预期输出 `_ofdm_baseline_dense` 结果目录；由于属于更密 Monte Carlo，本轮未自动运行。`run_ofdm_baseline.m` 同步支持 `ofdm_baseline_overrides`，两个脚本 `checkcode` 均无具体 issue。Rule reflection: no new durable rule
- **2026-05-23**：补充 SNR 粒度边界。阶段 A final full-chain 主图已为 `8:1:20` 的 `1 dB` 粒度；B1 的 `8/12/16/20 dB` 只作为轻量 OFDM baseline，若论文展示 OFDM 曲线过渡需另做 `1 dB` 粒度复验。
- **2026-05-22**：补充 BER 曲线反转复盘。B1 的 `16/20 dB` BER 形状与阶段 A single-carrier final full-chain 结果高度接近，判断不是 OFDM 新 bug；该现象来自 `p` 同时改变星座概率、`K_b(p)`、信息集合和 BER 加权分母，需用 Goodput 而非 BER 单独评价。
- **2026-05-22**：补充 B1 运行图到阶段文档，包含 `ofdm_ber_vs_snr.png`、`ofdm_goodput_vs_snr.png`、`ofdm_energy_goodput.png`。
- **2026-05-22**：B1 正式轻量运行完成。结果目录 `16QAM_Polar/v2/results/20260522_174039_ofdm_baseline/`，CSV 共 12 行，README、MAT、run_log 和三张 PNG/PDF/FIG 图均已生成。最高 CP 修正 Goodput 为 `p=0.5, 20 dB` 的 `0.393934`；`p=0.1` 在低中 SNR 有 BER / Goodput 局部优势，但不作为最终多载波策略结论。
- **2026-05-22**：确认 `checkcode` 结果。MATLAB 返回空结构体字段 `message/line/column/fix/id`，未列出具体 issue，判定静态检查通过。
- **2026-05-22**：实现 `16QAM_Polar/v2/experiments/multicarrier/run_ofdm_baseline.m`。脚本完成 AWGN OFDM full-chain baseline：概率整形 polar 编码、16QAM、IFFT/CP、AWGN、去 CP/FFT、LLR、SC 译码、BER/Goodput/Energy 输出；新增 CP 修正 Goodput 字段；静态 `checkcode` 通过。正式 Monte Carlo 尚未运行。
- **2026-05-22**：新建 B1 阶段文档。明确第一轮任务为 OFDM baseline 文档准备，不新增脚本、不运行 MATLAB；固定参数、输出要求、验收标准和后续 B2/B3 入口。
- **Rule reflection**：no new durable rule。
