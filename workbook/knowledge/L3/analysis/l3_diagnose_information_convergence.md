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

## 2026-11-18 16:30 数值扩展分析预登记
主批结束后仅追加6次数值调用：旧开发H8/标签28/弱组，p=.1/.5，order320、B16384、原三个固定seed；与旧80/160结果配对比较。新增通信0、独立无编码符号0；不调参、不换预测、不改变本批选择，320不当真值。复用diagnose_information_convergence并增可选orders/particles参数，默认行为不变。该分析用于判断先前阶差是否随阶数继续缩小，不设事后通过门槛；只在通信批停止后运行以免竞争计时。

## 320阶补充诊断及交付

固定旧开发H8/标签28/弱组、16384粒子与三个种子。p=.1的80/160/320阶平均BER依次为6.6824%、7.1144%、6.9671%；p=.5依次为6.9047%、7.5037%、7.2571%。相邻阶差从0.4320与0.5989个百分点缩至0.1473与0.2466个百分点，方向反转。增加阶数降低了两个开发点的相邻差异，误差界和全域收敛仍缺证据。新增6次数值调用，通信0。近邻决策继续由完整SC证书判断。

本批原始MAT、日志和两版runner保留本地，新收尾同步代码、文档和小型证据表图。无删除。复现分析依次运行 analyze_information_certified_frontier、analyze_certified_uncertainty.py、summarize_certified_frontier.py；320阶参数见前述预登记。
