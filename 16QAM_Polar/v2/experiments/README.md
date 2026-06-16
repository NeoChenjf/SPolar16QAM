# experiments

`experiments/` 存放阶段性专项脚本，避免与 `v2` 顶层主入口混在一起。

目录约定：

- `layer1_layer2/`：调制层 BER / MI 对账、符号先验一致性分析
- `sc_checks/`：SC 局部复验、SCL 对比、局部专项核查

当前主文件：

- `layer1_layer2/run_layer1_uncoded_ber_reconcile_v2.m`
- `layer1_layer2/run_layer2_mi_reconcile_v2.m`
- `layer1_layer2/analyze_symbol_prior_alignment.m`
- `sc_checks/run_local_12db_check.m`
- `sc_checks/run_single_scl.m`
- `sc_checks/run_sweep_scl.m`

使用方式：

```matlab
cd('16QAM_Polar/v2');
setup_paths;
run_local_12db_check;
```

说明：

- 这些脚本仍可直接调用，但不再占用 `v2` 顶层；
- 若某个专项脚本成熟为长期主流程，再考虑提升回顶层。
