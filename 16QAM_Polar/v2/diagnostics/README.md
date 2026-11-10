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


## 2026-11-09 当前保留与退役入口

旧正文中的 `quick_layer1_test`、`quick_layer2_test` 已退役；连同 `check_ofdm_per_bit_ber`、`test_bpsk_direct`、`test_llr_inspection`、`test_qamdemod_bug` 及三个固定结论的B4b验收器移出活跃路径。原源码见[清单](../../../治理记录/20261109/retired-manifest.json)及同目录ZIP。

当前保留 `check_env`、`diagnose_mc_simulation` 及其BPSK/回环/SC基线依赖、`test_source_entropy_partition`、`multicarrier/test_*`、`rectifier/test_*` 和通用结果校验器。旧打印式诊断适合人工排障，不能把“完成”文字当作自动测试通过。

`experiments/sc_checks/run_local_12db_check.m` 同轮归档；通用SC理论对照和瀑布区入口保留。退役脚本需先恢复原位置，不能直接从ZIP或其他目录运行。
