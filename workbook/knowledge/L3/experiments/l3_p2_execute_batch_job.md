

# L3 · p2_execute_batch_job

- **method_id**: l3_p2_execute_batch_job
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/p2_execute_batch_job.m
- **module**: experiments
- **health**: healthy（调度/读取接口，正式后续分支仍待运行）

## Signature / Purpose

见同名源文件头；恢复唯一匹配的协议/批准/job，调用已绑定的注册入口，UTF8写出结果目录标记。多个候选时拒绝猜测。

## Math / Numerical Notes

沿用批准协议，不改变科学参数。校准阶段不测通信；统计门禁不因文件存在或启动而通过。仅执行已批准首轮预算。

## Dependencies

l3_run_p2_registered_job

## Evidence

批次16QAM_Polar/v2/results/20261025_011808_p2_approved_batch保存实际调度源码哈希、日志和状态。首job已执行；恢复唯一性拒绝规则为源码静态核查，后续功率预检等待正式验证输出。

Revision metadata: revision_id=l3_p2_execute_batch_job_v1_20261025; current_status=current; supersedes=[].
