# 运行环境搭建（Environment Setup）

本机（Apple M3 Pro / arm64）**无 MATLAB License**，统一用免费的 **GNU Octave** 运行
`16QAM_Polar/v2/` 仿真，并通过 `scripts/run_matlab.sh` 让 agent 一键调用。本文件是
环境的**可复现配置 + 已知差异清单**，换机时照此复现。

## 一句话类比
Octave 之于 MATLAB，像"另一家厂的同款仪器"——大部分旋钮一样，但少数刻度（这里是
`qammod/qamdemod` 的口径、随机数发生器）出厂校准不同，必须先对表（`check_env`）再做实验。

---

## 1. 安装（Homebrew，arm64 原生）

```bash
brew install octave
# 通信/信号 package（含 qammod/qamdemod/de2bi/bi2de/bitrevorder）
# 依赖顺序：control → signal → communications
octave --eval "pkg install -forge control signal communications"
octave --eval "pkg load communications signal; disp('pkg ok')"
```

> 若 `pkg install -forge` 因 Forge 源问题失败，可从 https://gnu-octave.github.io/packages/
> 下载对应 `.tar.gz` 后 `pkg install <file>.tar.gz`。

实测搭建状态（2026-06-17，Apple M3 Pro / arm64，**端到端已跑通**）：

| 组件 | 版本 / 状态 |
|------|------|
| Octave | **11.3.0（已装，`brew install octave`，arm64 原生）** |
| communications | 已用 `pkg install -nodeps communications-1.2.7.tar.gz` 装上（提供 `de2bi`/`bi2de`）；但其 `qammod/qamdemod` **签名与 MATLAB 不兼容**，已被 compat 层遮蔽 |
| signal / control | 未装，**不需要**（项目只用内置 `fft`；`bitrevorder` 由 compat 层提供） |

> **关键决定：用 compat 兼容层，而非依赖 Octave 的 communications qammod。**
> Octave communications 的 `qammod` 不接受 `'gray'`/`'UnitAveragePower'`/`'InputType'`/`'OutputType','llr'`
> 等 MATLAB name-value 参数（直接报 "too many inputs"），且 `bitrevorder` 属 signal package
> （需 control 编译，含 Fortran）。因此在 `16QAM_Polar/v2/compat/octave/` 实现了 MATLAB 口径一致的
> `qammod.m` / `qamdemod.m` / `bitrevorder.m` / `sgtitle.m`，`setup_paths.m` **仅在 Octave 下**
> 用 `-begin` 把该目录加到路径最前以遮蔽 package 同名函数。**MATLAB 下这些 compat 文件不生效**，用原生。
>
> compat 正确性已通过自洽闭环验证：16 个星座点 qammod→qamdemod(llr)→硬判决全部还原对应 bit（0 失配）、
> bitrevorder 与标准位反转一致、bit 往返一致、平均功率归一化=1。

下载来源备查（如需在别处复装 communications）：
- communications 1.2.7：SourceForge（`downloads.sourceforge.net/.../communications-1.2.7.tar.gz`，可能超时，多镜像/本地 `curl` 后 `pkg install -nodeps 本地tar.gz`）
- signal 1.4.7：GitHub（`github.com/gnu-octave/octave-signal/releases/download/1.4.7/signal-1.4.7.tar.gz`）——本项目用不到

---

## 2. 怎么跑（agent 一键调用）

统一入口 `scripts/run_matlab.sh`：自动 `cd v2` + `pkg load` + `setup_paths` + 非交互执行 + 退出码透传。

```bash
scripts/run_matlab.sh check_env             # 环境自检（先跑这个）
scripts/run_matlab.sh run_single            # 端到端冒烟（分钟级）
scripts/run_matlab.sh test_qamdemod_bug     # qamdemod 口径专项
scripts/run_matlab.sh 'p=0.3; disp(p)'      # 任意 Octave 语句
```

不要直接 `cd` 进 v2 手敲 octave——用包装脚本保证 package 与路径一致、可复现。

---

## 3. 已知 Octave ↔ MATLAB 差异清单（重要，避免误判为 bug）

| # | 差异 | 影响 | 应对 |
|---|------|------|------|
| D1 | **随机数发生器实现不同** | 即使固定 `cfg.seed`，Octave 与 MATLAB **不会**产生逐比特相同结果 | 验证看**统计趋势**（BER-SNR 曲线形状/量级），不要求与历史 MATLAB 结果逐点对齐 |
| D2 | **qammod/qamdemod 签名不兼容** | Octave communications 的 qammod 不接受 `'gray'`/`'UnitAveragePower'`/`'InputType'`/`'OutputType','llr'`，直接报 "too many inputs" | **已解决**：`compat/octave/qammod.m`+`qamdemod.m` 复刻 MATLAB 口径（qamdemod LLR 复用项目 `llr_16qam_gray_LSE`），`setup_paths` 仅 Octave 下遮蔽 package 同名函数 |
| D3 | **`bitrevorder` 属 signal package** | 不装 signal/control 时未定义 | **已解决**：`compat/octave/bitrevorder.m` 标准位反转实现，不依赖 package |
| D4 | **`sgtitle` Octave 无此函数** | 绘图收尾报 "sgtitle undefined" | **已解决**：`compat/octave/sgtitle.m` 兼容版（headless 下静默跳过，不影响数值） |
| D5 | **`de2bi/bi2de` 来自 communications package** | 未 load 时未定义 | 用 `run_matlab.sh`（已 `pkg load communications`，该 package 已 `-nodeps` 装上） |
| D6 | **GBK 注释告警** | `phi.m`/`phi_inverse.m` 含非 UTF-8 中文注释 → Octave 提示 "Invalid UTF-8 byte sequences have been replaced" | 纯告警，不影响计算；如需消除可把这些 `.m` 转存为 UTF-8 |
| D7 | 部分绘图/字体行为 | 图样式细节可能不同 | 只影响外观，不影响数值结论 |

> D1/D2 是科研复现里最容易被误读成"算法出 bug"的两点，特此显著标注。

---

## 4. 分级验证（验证 > 安装；任一级失败先修再往下）

```bash
scripts/run_matlab.sh check_env           # 1) 环境 + 口径
scripts/run_matlab.sh test_qamdemod_bug   # 2) qamdemod LLR 专项
scripts/run_matlab.sh test_polar_loopback # 3) 链路（弱调制依赖）
scripts/run_matlab.sh run_single          # 4) 端到端冒烟
```
成功判据：`check_env` 全绿（或已切到 `llr_16qam_gray_LSE` 后通过）；`run_single` BER 随 SNR
单调下降、聚焦 BER∈[1e-4,1e-1] 瀑布区（高 SNR 全零非异常，见 `mandatory-rules.md` §8）。

---

## 5. Octave 兼容层（compat/octave/，已实施）

为消除 D2/D3/D4 的不兼容，在 `16QAM_Polar/v2/compat/octave/` 实现了 MATLAB 口径一致的替代：

| 文件 | 作用 |
|------|------|
| `qammod.m` | 16QAM Gray 调制（integer/bit 输入、UnitAveragePower），I=高2bit、Q=低2bit、Gray 电平映射 |
| `qamdemod.m` | 16QAM 解调；`OutputType='llr'` 直接复用项目 `llr_16qam_gray_LSE`，与 qammod 共用同一星座 |
| `bitrevorder.m` | 位反转重排（GA.m 用），不依赖 signal package |
| `sgtitle.m` | 多子图总标题兼容（headless 静默跳过） |

接入方式（`setup_paths.m`）：
```matlab
if exist('OCTAVE_VERSION','builtin') ~= 0
    addpath(fullfile(project_root,'compat','octave'), '-begin');  % 仅 Octave，放最前遮蔽 package
end
```
**MATLAB 下不加这个目录**，用原生 Communications Toolbox —— 算法代码零改动、可回退。

正确性验证（已通过）：16 星座点 qammod→qamdemod(llr)→硬判决 0 失配；bitrevorder/bit 往返一致；
`run_single` 端到端 BER 随 SNR 单调下降。若改了 compat 或换码长，重跑 `check_env` + 上述闭环即可。

---

## 6. 长跑约束
`run_sweep` 等长/高算力仿真仍须用户授权后再跑（`mandatory-rules.md` §3）。`run_matlab.sh`
只负责"能跑"，不替用户决定跑长任务。
