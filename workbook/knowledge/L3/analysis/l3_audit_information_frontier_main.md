# L3 · 三路主实验完整性审计

- method_id为l3_audit_information_frontier_main。
- file_path为16QAM_Polar/v2/analysis/audit_information_frontier_main.m。
- module为analysis，health为healthy，仅验证列明的有限断言。

## Signature

audit_information_frontier_main(out)只读取结果，核验44条件、5500候选配置、275000正式帧及30次复验预算、错误和I分母、矩约束与独立参照，写completion_audit.json。

## Math / Algorithm

逐候选/组与冻结I集合核对每帧K，检查0≤错误≤分母及M4≥M2²，统计零错误候选与长时间计时，核查六帧参考SC及频域等价。

## Numerical Notes

审计通过只证断言范围，不证明模型准确、随机过程独立、四阶模型物理适用或代码无缺陷。

## Dependencies

冻结协议、逐条件通信与预测、数值和二极管诊断输出。
