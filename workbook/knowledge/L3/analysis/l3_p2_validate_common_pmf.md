# L3 · p2_validate_common_pmf

- method_id: l3_p2_validate_common_pmf
- file_path: 16QAM_Polar/v2/analysis/p2_validate_common_pmf.m
- module: analysis
- health: exploratory

## Scope

`p2_validate_common_pmf(asset_file)` 检查非正式PMF资产及来源配置、case、源码快照和原始计数，逐配置和参考点重算各组16标签PMF并校验帧数。它验证当前资产与当前原始文件一致；不证明两者在过去未被共同更改，也不证明训练样本代表性或PMF有效性。

## Verification

MATLAB对现有探索资产通过，复制资产后改变一个概率被拒；未更改旧数据。依赖 l3_p2_verify_common_snapshot。
