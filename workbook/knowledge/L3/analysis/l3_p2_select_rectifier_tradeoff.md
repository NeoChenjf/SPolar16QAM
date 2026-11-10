# L3 · p2_select_rectifier_tradeoff

- method_id: l3_p2_select_rectifier_tradeoff
- file_path: 16QAM_Polar/v2/analysis/p2_select_rectifier_tradeoff.m
- module: analysis
- health: exploratory

`result=p2_select_rectifier_tradeoff(run_dir,max_ber,min_goodput,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)` 只接受短策略训练角色，以显式假设的整流电流代理选择27组候选；候选在任一训练信道超出给定范围时整体不可选，保留无可行状态。信息门槛、标尺、系数和范围均为调用方假设，不是已核实的器件或业务指标。输出是固定方案的训练选择，不是CSI自适应，不是DC功率或正式优势。

MATLAB对既有两训练信道×每候选1帧输入，用假设1 V/单位、50Ω、文献示例系数和宽区间选择combo_01；极窄区间全部无可行。结果仅接口检查，无独立有效性。依赖 l3_p2_rectifier_metrics_from_run。

## 2026-11-06 训练信道子集

新增可选 `training_channels` 参数，约束为训练批中互不重复的有效信道；选择与范围排除只在指定子集计算。未指定时保持原全训练信道行为。重复子集测试拒绝，探索用途不变。
