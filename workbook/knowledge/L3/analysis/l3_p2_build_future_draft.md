# L3 · p2_build_future_draft

- method_id: l3_p2_build_future_draft
- file_path: 16QAM_Polar/v2/analysis/p2_build_future_draft.m
- module: analysis
- health: draft_only

`result=p2_build_future_draft(base)` 生成A–F逐批配置与case草案，经p2_validate_future_job和p2_preflight_future_workload核对，总数67120 case-帧。只接受拟议N1024/64/CP16/16tap几何，输出draft_only_not_authorized，不调用RNG或仿真。

暂停前MATLAB测试通过：六批工作量、draft-only/无旧power_file、错误码长和参考网格修改拒绝。未完成完整代码审查、全部字段/真实资产/源码/物理参考绑定；base可能携带旧路径或兼容seed，不能作为正式配置。依赖l3_p2_validate_future_job、l3_p2_future_draft_cases、l3_p2_preflight_future_workload。
