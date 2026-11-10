# L3 · p2_paired_strategy_ci

- method_id: l3_p2_paired_strategy_ci
- file_path: 16QAM_Polar/v2/analysis/p2_paired_strategy_ci.m
- module: analysis
- health: exploratory

## Signature and scope

`intervals=p2_paired_strategy_ci(asset_file,test_dir,baseline_ids,n_boot,seed)` 先调用冻结资产与原始配对审计，再按信道对齐计算选择策略减基线的 BER、CP Goodput 和无量纲矩代理差值，调用整信道 bootstrap。相同随机种子用于各指标和基线，以维持共同重采样索引。代理不是标定直流功率；本函数不宣布验收或收益。

## Dependencies / verification

依赖 l3_p2_evaluate_strategy_asset 与 l3_p2_paired_channel_bootstrap。已在探索性的独立两信道测试数据上调用四基线并通过审计；两信道区间没有可靠覆盖保障。噪声只保存运行时哈希而非原数组。
