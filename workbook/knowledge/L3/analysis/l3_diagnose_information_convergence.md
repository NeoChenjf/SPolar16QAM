# L3 · 信息预测有限档位收敛诊断

- method_id: l3_diagnose_information_convergence
- file_path: 16QAM_Polar/v2/analysis/diagnose_information_convergence.m
- module: analysis
- health: development; descriptive sensitivity only
- date: 2026-11-17

## Signature

`rows=diagnose_information_convergence(source,out,tasks)`，source为既有frozen.mat路径或其struct；tasks每行是[H索引、标签索引、资源组、p索引]。省略tasks时使用历史H5/标签20三组p=.4/.5及H8/标签28弱组p=.1/.5，共8任务。

## Algorithm and outputs

固定交叉求积阶数80/160、粒子数8192/16384、训练模型seed+[0,1,2]。逐调用保存BER、该组对总Goodput的贡献、粒子标准误、总时间和叶分布时间。CSV用17位有效数字；每调用保存checkpoint，全部完成另存complete。已有CSV时拒绝覆盖；不自动恢复或重跑。

## Boundaries

不产生通信帧，不更新PMF，不替换冻结预测，不使用实测BER选参数。Goodput贡献为该组K乘(1−BER)除15680。粒子标准误按四路加权平方和计算，仅为旧接口描述量；它不是求积、模型、输入PMF或全候选同时误差界。阶数升高也不等于已证明更准确。默认96次数值调用，执行方须计入墙钟预算；任务可缩小但不得将子集结论外推全域。

## Dependencies

`p1_predict_minsum`、`setup_paths`、冻结pmfs/states/channels/locations/protocol。


## 2026-11-18 实际验证补充

测试/分析已执行；仅1完整独立H条件，不将公式测试当科研验收。详见loop本轮报告末尾；整体健康度保持degraded。
