# 代码与实验地图

## 当前主线

[v2](v2/)是固定16QAM的活跃MATLAB实现。[setup_paths.m](v2/setup_paths.m)添加core、polar、modulation、analysis以及递归的diagnostics、experiments。当前治理不移动这些函数或更改路径。

- core：仿真链路及派生指标。
- polar、modulation：极化编码译码、概率成形和LLR。
- experiments、diagnostics：阶段实验与检查入口；旧入口仍可能承担复现责任，不能据无直接调用删除。
- results：时间戳实验数据、冻结协议、源码快照与结果；保持原位置。

## 原位置历史归档

本目录根部旧`.m`脚本、ShapedPolarS、OOK及旧results保留为历史复现材料。v3仅保留为已有方法外推支撑，不扩展为多载波主线。不要在运行v2时把整个16QAM_Polar递归加入MATLAB路径，以免旧版同名函数遮蔽当前实现。

发现12组旧实现与v2源码完全相同的文件。为保留旧脚本独立依赖环境，本次没有删掉这些副本；哈希相同不代表可以安全移除。当前入口及研究边界见[根目录说明](../README.md)。


## 2026-11-10 当前维护热点与使用边界

[全仓治理记录](../治理记录/20261110_repo_governance/README.md)列出精确证据。`v2/experiments/multicarrier/run_p2_common_environment.m`、`run_p2_v2_batch.m`、`run_p2_v2_strategy_batch.m`是高相似维护热点，尚未重构。strategy入口的realization_offset实际影响多类随机键，不能简单替换成另一入口。v2_batch由E1后续入口调用，strategy_batch由策略训练/测试入口调用；静态引用不能穷尽MATLAB手动入口与历史复现。

当前研究先核查真实仿真链与统计可信度，见[研究路线末尾](../学习文档/硬件前信息与非线性收能定量分析及瑞利策略优化-loop/当前研究路线-2026-11-10.md)。治理本身不启动该计划，不修改结果目录、源码快照或v1/v3/OOK历史实现。
