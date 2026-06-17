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

实测搭建状态（2026-06-17，Apple M3 Pro / arm64）：

| 组件 | 版本 / 状态 |
|------|------|
| Octave | **11.3.0（已装，`brew install octave`，arm64 原生）** |
| control | ⏳ 未装 |
| signal | ⏳ 未装 |
| communications | ⏳ **未装** —— `pkg install -forge` 一次性解析三包时，卡在 communications 的 SourceForge 下载超时并整批回滚 |

> **已知源问题**：`communications` 官方只托管在 SourceForge
> (`downloads.sourceforge.net/.../communications-1.2.7.tar.gz`)，本网络环境下载超时；
> `signal` 新版有 GitHub 源（`github.com/gnu-octave/octave-signal/releases/download/1.4.7/signal-1.4.7.tar.gz`，可达）。
> 续装建议：逐个装、给 SourceForge 长超时/多镜像重试，或先 `curl` 下到本地再 `pkg install 本地tar.gz`。
> communications package 未就绪前，`qammod/qamdemod/de2bi/bi2de/bitrevorder` 不可用，
> 端到端仿真跑不了；可先用项目纯数学 `llr_16qam_gray_LSE`（不依赖 package）做局部验证。

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
| D2 | **qammod/qamdemod 口径** | `'gray'` 比特序 / `'UnitAveragePower'` 归一化 / `'OutputType','llr'`+`'NoiseVariance'` 的 LLR，Octave 不保证与 MATLAB 逐位一致 | 以 `check_env` 的 (d) 校验为准；若 qamdemod LLR 口径不一致，仿真改用项目自带纯数学 `llr_16qam_gray_LSE`（见第 5 步） |
| D3 | **`de2bi/bi2de` 来自 package** | 未 `pkg load communications` 时报"未定义" | 用 `run_matlab.sh` 调用（已自动 load）；或手动 `pkg load communications` |
| D4 | 部分绘图/字体行为 | 图样式细节可能不同 | 只影响外观，不影响数值结论 |

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

## 5. qamdemod 口径不一致时的兜底（按需，仅当第 4 步实测到差异）

项目自带纯数学 LLR `modulation/llr_16qam_gray_LSE.m` 不依赖 qamdemod 的 LLR 实现，跨环境一致。
若 `check_env`/`run_single` 发现 Octave qamdemod LLR 口径不对：

- 在 `core/sim_shaped_polar_16qam.m` 的 LLR 计算处加**环境开关**（`exist('OCTAVE_VERSION','builtin')`）：
  Octave 走 `llr_16qam_gray_LSE`，MATLAB 保持 `qamdemod`。
- 改动最小、可回退；按硬规则记入 `周报` 与 `workbook/troubleshooting-history.md`。

---

## 6. 长跑约束
`run_sweep` 等长/高算力仿真仍须用户授权后再跑（`mandatory-rules.md` §3）。`run_matlab.sh`
只负责"能跑"，不替用户决定跑长任务。
