

# L3 · run_p2_registered_job

- **method_id**: l3_run_p2_registered_job
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/run_p2_registered_job.m
- **module**: experiments
- **health**: healthy

## Signature

`function out = run_p2_registered_job(protocol_file, approval_file, job_id, artifacts)`

## Purpose / Math

只执行协议中唯一job，核对批准记录、协议/源码/源模板哈希；不能自行创建批准记录或启动后续任务。

## Numerical Notes

实现/短验证状态与正式科研验收分开；未运行的正式分支不声称已通过。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

l3_p2_default_config, l3_run_p2_mechanism

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_08ae3dcbc763_20261024; current_status=current; supersedes=[].
