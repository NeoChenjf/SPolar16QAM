# L3 · analyze_b4_equal_power_p1

- **method_id**: l3_analyze_b4_equal_power_p1
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/analyze_b4_equal_power_p1.m
- **module**: experiments
- **health**: healthy（formal P1实际数据审计后更新）

## Signature
`analyze_b4_equal_power_p1(p1_root)`；输入为含冻结系数CSV和正式结果路径的时间戳P1目录。

## Purpose
校验固定帧数、重复键、发送功率门限，并生成策略汇总、配对差值bootstrap区间、逐信道违反率与非支配点。

## Math / Algorithm
以realization为簇配对均匀p=.5参考；2000次有放回簇bootstrap估差值95%区间。BER>.1、Goodput<.25记为逐信道违反，并计算Wilson区间。两个指标同时满足才记录共同满足。

## Dependencies
- `readtable`, `writetable`, MATLAB绘图函数；不改变仿真/译码数据。

## Health
healthy — 仅汇总分析；正式输入门禁及图表数据审计仍须对实际结果运行。


## 2026-10-11 P1分析执行记录

对正式CSV执行行数、唯一键、固定50帧、策略均值功率和power_mode门禁；输出策略汇总、2000次信道簇配对bootstrap差值、逐信道Wilson区间、候选集合内Pareto点及非配对历史对照。零BER和BLER绘图使用有限样本单侧95% Poisson上界。零错误只表示该测试分母内没有观察到错误；配对统计簇是30个信道实现。

最终图位于`16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261010_235754/figures/`。视觉复核确认校准前未缩放功率与最终校准验证分成独立坐标面板；配对差值图已使用可读标签。历史图明确注明不同发送功率和构造，不能配对推断。

Revision metadata: revision_id=analyze_b4_equal_power_p1_formal_20261011; current_status=current; supersedes=[analyze_b4_equal_power_p1_v1].

## 2026-10-11 当前方法契约快照

- **method_id**: l3_analyze_b4_equal_power_p1
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/analyze_b4_equal_power_p1.m
- **health**: healthy; audited formal inputs and figures for P1.

Revision metadata: revision_id=analyze_b4_equal_power_p1_contract_snapshot_20261011; current_status=current; supersedes=[analyze_b4_equal_power_p1_formal_20261011].

## 2026-10-11 最终图表输出修订

- **method_id**: l3_analyze_b4_equal_power_p1
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/analyze_b4_equal_power_p1.m
- **final_result_path**: `16QAM_Polar/v2/results/20261010_220626_b4_equal_power_p1/analysis_rerun_20261011_002445/`
- **figure_review**: Pareto按SNR分面，非支配点使用较大黑描边标出；避免长策略标签跨面板遮挡。
- **health**: healthy; 1260条正式计数审计通过，全部最终PNG/PDF/FIG已生成。

Revision metadata: revision_id=analyze_b4_equal_power_p1_final_figures_20261011; current_status=current; supersedes=[analyze_b4_equal_power_p1_contract_snapshot_20261011].
