# L3 · p2_paired_channel_bootstrap

- method_id: l3_p2_paired_channel_bootstrap
- file_path: 16QAM_Polar/v2/analysis/p2_paired_channel_bootstrap.m
- module: analysis
- health: exploratory

## Signature and scope

`result=p2_paired_channel_bootstrap(delta,n_boot,seed)` 对已配对的独立信道差值进行整信道重采样；调用方负责证实配对与信道独立。返回均值与百分位区间；少于两信道返回 NaN 区间。所有区间仅为描述，不构成验收。保存并恢复全局 RNG。

## Verification

MATLAB R2020b 测试覆盖确定性、RNG 恢复、单信道及非法输入；不证明少样本区间覆盖率。
