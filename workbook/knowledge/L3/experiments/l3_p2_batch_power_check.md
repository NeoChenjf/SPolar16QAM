

# L3 · p2_batch_power_check

- **method_id**: l3_p2_batch_power_check
- **file_path**: 16QAM_Polar/v2/experiments/multicarrier/p2_batch_power_check.m
- **module**: experiments
- **health**: healthy（调度/读取接口，正式后续分支仍待运行）

## Signature / Purpose

见同名源文件头；提前读取三个独立正式验证seed，按冻结目标比较各seed/信道/SNR/配置的时域总功率与分量；任一误差>1%不通过，阻止后续依赖。最终验收仍由原audit再核对。

## Math / Numerical Notes

沿用批准协议，不改变科学参数。校准阶段不测通信；统计门禁不因文件存在或启动而通过。仅执行已批准首轮预算。

## Dependencies

MATLAB文件/表内置接口；只读已冻结数据

## Evidence

批次16QAM_Polar/v2/results/20261025_011808_p2_approved_batch保存实际调度源码哈希、日志和状态。首job已执行；恢复唯一性拒绝规则为源码静态核查，后续功率预检等待正式验证输出。

Revision metadata: revision_id=l3_p2_batch_power_check_v1_20261025; current_status=current; supersedes=[].
