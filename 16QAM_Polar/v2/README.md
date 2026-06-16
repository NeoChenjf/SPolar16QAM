# v2 - 16QAM 概率整形极化码仿真系统

**版本**：v2.0  
**创建日期**：2026-03-02

## 目录结构

```
v2/
├── config.m                  # 全局参数唯一入口
├── setup_paths.m             # 路径初始化（会自动加入 diagnostics/ 与 experiments/）
├── run_single.m              # 单点快速测试脚本
├── run_sweep.m               # p × SNR 全网格扫参脚本
├── run_sc_theory_vs_sim.m    # SC 理论 vs 仿真主入口
├── run_sc_ga_only_curve.m    # SC 编码侧 GA 理论曲线主入口
├── README.md                 # 本文件
│
├── core/                     # 核心仿真函数
│   ├── sim_shaped_polar_16qam.m   # 统一端到端仿真（合并 get_16test 系列）
│   ├── compute_energy.m           # 理论能量计算
│   ├── compute_goodput.m          # Goodput 计算
│   └── compute_cost.m             # 代价函数
│
├── polar/                    # 极化码内核（从 ShapedPolarS 复制）
│   ├── GA.m                       # Gaussian Approximation
│   ├── polar_encoder.m            # 极化编码
│   ├── SC_decoder.m               # SC 译码
│   ├── SCL_decoder.m              # SCL 译码
│   ├── get_llr_layer.m / get_bit_layer.m / get_GN.m
│   └── phi.m / phi_inverse.m / derivative_phi.m
│
├── modulation/               # 调制解调
│   ├── parallel_to_serial_bits.m  # 4路并转串
│   ├── llr_16qam_gray_LSE.m       # 精确 LLR（均匀先验）
│   └── llr_16qam_gray_LSE_prior.m # 精确 LLR（非均匀先验）
│
├── analysis/                 # 绘图函数
│   ├── plot_ber_vs_snr.m
│   ├── plot_goodput_vs_snr.m
│   ├── plot_pareto.m
│   ├── plot_mi_vs_snr.m
│   └── plot_cost_curves.m
│
├── diagnostics/              # 诊断与快速核查脚本
│   ├── diagnose_mc_simulation.m
│   ├── quick_layer1_test.m / quick_layer2_test.m
│   └── test_*.m
│
├── experiments/              # 阶段性专项实验脚本
│   ├── layer1_layer2/        # 调制层 / 先验一致性专项
│   └── sc_checks/            # SC 局部复验、SCL 对比等专项
│
└── results/                  # 实验结果（按时间戳子目录）
```

## 顶层保留原则

`v2/` 顶层现在只保留“日常主入口 + 基础配置”：

- `config.m`
- `setup_paths.m`
- `run_single.m`
- `run_sweep.m`
- `run_sc_theory_vs_sim.m`
- `run_sc_ga_only_curve.m`

其余一次性诊断、专项复验、SCL 对比、Layer1/Layer2 对账脚本已下沉到 `diagnostics/` 和 `experiments/`，避免顶层继续堆积。

## 快速开始

### 1. 验证（几分钟）
在 MATLAB 中：
```matlab
cd('v2目录路径');
setup_paths;
run_single;
```
会对 p=0.3, SNR=[0,5,10,15,20], 100帧 跑一次快速测试。

### 2. 正式扫参（数小时）
```matlab
cd('v2目录路径');
setup_paths;
run_sweep;
```
会对 config.m 中定义的所有 p × SNR 组合跑完整仿真。

### 3. SC 理论-仿真对照
```matlab
cd('v2目录路径');
setup_paths;
run_sc_theory_vs_sim;
```

### 4. 纯 GA 理论曲线
```matlab
cd('v2目录路径');
setup_paths;
run_sc_ga_only_curve;
```

### 5. 运行已下沉的专项脚本
`setup_paths` 会自动把 `diagnostics/` 和 `experiments/` 加入 MATLAB 路径，因此仍可在 `v2` 根目录直接调用，例如：

```matlab
cd('v2目录路径');
setup_paths;
diagnose_mc_simulation;
run_local_12db_check;
```

### 6. 自动寻找 SC 瀑布区
当固定窗口（例如 11~13 dB）出现全零误码时，先用该脚本自动粗扫较低 SNR，寻找 BER 落在 `1e-4 ~ 1e-1` 的有效瀑布区：

```matlab
cd('v2目录路径');
setup_paths;
run_find_waterfall_and_refine;
```

默认只执行快速粗扫定位并停止，输出 `coarse_scan.csv`、`waterfall_window.csv`、`run_log.txt` 和 `progress_log.txt`。确认窗口合理后，再在脚本中设置 `run_local_refine=true` 做局部加密。

### 7. 修改参数
主流程参数仍只建议优先改 `config.m`。专项脚本的局部实验参数留在各自脚本内部覆盖。

## 与旧代码的关系

| 旧文件 | v2 对应 | 变化 |
|--------|---------|------|
| get_16test.m | core/sim_shaped_polar_16qam.m | 合并 + 修复 frozen_bits bug |
| get_16test_customSNR.m | 同上 | 合并 |
| gettest_MI.m | 同上 | 合并（MI 现在总是计算） |
| test260127.m | run_sweep.m + analysis/ | 拆分为扫参 + 绘图 |
| test260127cost.m | run_sweep.m + compute_cost.m | 拆分 |
| draw_16test.m | run_sweep.m | 合并 |

旧代码完全不动，保留在原位置。
