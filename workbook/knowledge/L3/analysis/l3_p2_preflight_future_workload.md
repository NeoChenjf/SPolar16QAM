# L3 · p2_preflight_future_workload

- method_id: l3_p2_preflight_future_workload
- file_path: 16QAM_Polar/v2/analysis/p2_preflight_future_workload.m
- module: analysis
- health: draft_only

`report=p2_preflight_future_workload(jobs,max_case_frames)` 根据job字段信道数×参考点数×候选数×帧数计数；限制于候选键域尺寸，拒绝重复job ID或split、用途与候选split不对应、超出case-帧上限。函数不使用rng、不运行实验，状态始终 `draft_only_not_authorized`。

不检查具体p列表、S去重、噪声/功率与码率、split历史、资产、源码、用时、磁盘、批准或正式入口可用性；不能把通过预检解释成方案科学有效、正式冻结或授权。case-帧上限不是墙钟上限。

MATLAB对A–F草案计算得到67120；67119上限、重复split及旧seen域被拒。依赖 l3_p2_candidate_validation_seed。

## 2026-11-06 可选case清单检查

若job提供 `case_manifest`，预检会要求条数与num_cases一致、id唯一及基础字段存在。MATLAB通过展开清单检查并拒绝删除一项的清单；仍不验证该清单与正式执行代码或科研条件一致。依赖 l3_p2_future_draft_cases。
