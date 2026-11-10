# L3 · p2_validate_future_job

- method_id: l3_p2_validate_future_job
- file_path: 16QAM_Polar/v2/analysis/p2_validate_future_job.m
- module: analysis
- health: draft_only

`report=p2_validate_future_job(job,cfg)` 仅接受 `draft_only` 且无旧power_file的配置，比较job和cfg的码长、OFDM、构造种子/样本、积分阶数、参考点、p/名称/控制、规模及随机域；重建case与清单逐项比较，再进行单job工作量预检。返回状态固定 `draft_only_not_authorized`，不能执行仿真。

它不验证源文件/外部资产哈希、全部配置字段、物理参考功率与噪声、数据是否盲测、墙钟磁盘上限、实际用户授权或未来正式执行器是否遵守清单；不可当正式门禁。

MATLAB合成B批配置得到3600 case-帧；更改CP、使用formal模式或更改case参数被拒。依赖 l3_p2_future_draft_cases 与 l3_p2_preflight_future_workload。


## 2026-11-06 暂停前配置检查补记

predict与diagnose也纳入job/cfg比较；配置生成器使用此检查构建A–F草案。对应测试暂停前通过，仅是draft-only检查，仍不覆盖全部字段、真实资产或正式授权。
