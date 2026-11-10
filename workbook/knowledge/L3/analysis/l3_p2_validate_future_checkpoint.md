# L3 · p2_validate_future_checkpoint

- method_id: l3_p2_validate_future_checkpoint
- file_path: 16QAM_Polar/v2/analysis/p2_validate_future_checkpoint.m
- module: analysis
- health: diagnostic_only

`p2_validate_future_checkpoint(run_dir,T,completed)` 核对短诊断入口checkpoint的case键、行数、参考点/信道/case和raw文件集合；正常通信角色还从raw重算误码、分母、Goodput及部分功率/矩。已完成缺raw或未提交raw均拒绝，不删除文件；无噪PMF角色仅验证文件集合，不验证计数内容。它不验证攻击式同步篡改、帧内checkpoint或正式规模。

已接入 l2_p2_future_diagnostic 的循环前检查，不修改旧共同环境入口。MATLAB临时副本测试：原始部分checkpoint可恢复并重现、缺raw通过运行入口被拒、额外未提交raw被拒、改变配置被拒。依赖 l3_p2_validate_common_raw_metrics。

## 2026-11-06 无噪PMF计数检查补充

不再仅核文件集合：无噪条目检查NaN通信指标与每组每帧16标签计数非负整数且总和为N。复制fixture将BER改0、标签计数加1均被拒。仅检查计数基本约束，不能检测保持总数的标签篡改或证明来源。

## 2026-11-06 checkpoint原始文件摘要补充

新诊断入口保存每个已完成raw的SHA-256，与completed一起写入checkpoint；恢复前按case键逐项重算摘要。无摘要的旧checkpoint被拒，旧源码快照与历史数据不改写。复制无噪PMF raw后将一个标签计数移到另一标签、保持每帧总数不变，被 `futurecheckpoint:HashMismatch` 拒绝；NaN检查、缺raw/孤立raw及通信部分恢复回归通过。

摘要与checkpoint处于同一可写目录，若两者同时被改变不能提供可信防篡改或冻结时间证明；原始文件保存后、checkpoint提交前中断仍按孤立raw停止等待审查。正式规模、帧内断点和其他异常尚未验收。
