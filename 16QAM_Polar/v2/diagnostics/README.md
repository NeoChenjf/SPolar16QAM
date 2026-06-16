# diagnostics

`diagnostics/` 存放排障、基线核查、快速冒烟验证脚本，不作为日常主入口。

当前内容包括：

- `diagnose_mc_simulation.m`：蒙特卡洛主诊断流程
- `quick_layer1_test.m`、`quick_layer2_test.m`：快速修复验证
- `test_*.m`：BPSK、回环、LLR、标准基线等单项诊断

使用方式：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
diagnose_mc_simulation;
```

说明：

- 顶层已不再直接堆放这些脚本；
- `setup_paths.m` 会自动把本目录加入 MATLAB 路径，因此仍可从 `v2` 根目录直接调用。
