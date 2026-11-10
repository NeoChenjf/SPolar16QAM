# L3 · p2_validate_common_predictions

- method_id: l3_p2_validate_common_predictions
- file_path: 16QAM_Polar/v2/analysis/p2_validate_common_predictions.m
- module: analysis
- health: exploratory

## Signature / scope

`p2_validate_common_predictions(run_dir)` 根据各raw保存的 states、refs 和子载波布局重新运行 GA 预测，按K加权并使用该批配置校准系数，与表中原始及校准预测逐行比较。它只检验从已保存输入到表值的内部一致性；未重建 PMF/LLR 参考、证明其物理正确、验证计时或独立性。未运行新仿真。

## Verification

MATLAB R2020b 对校准及seen探索各27行通过。合成篡改拒绝路径未单独测试；正式测试门禁还须角色、输入、来源与独立性验证。

## 2026-11-06 负向回归补充

`test_p2_validate_common_predictions` 复制一条真实探索raw和配置到临时目录：原预测可通过，将复制表中的预测值加0.1后以 `predictionraw:Mismatch` 拒绝；MATLAB退出0。此测试只覆盖表值改动，不验证对抗式同时修改raw和表、PMF/refs 来源或独立性。
