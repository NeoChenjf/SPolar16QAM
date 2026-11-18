

# L3 · p2_llr_reference

- **method_id**: l3_p2_llr_reference
- **file_path**: 16QAM_Polar/v2/analysis/p2_llr_reference.m
- **module**: analysis
- **health**: degraded

## Signature

`function ref = p2_llr_reference(pmf, sigma, scale, order)`

## Purpose / Math

在实际联合PMF和当前均匀先验LLR下作二维Gauss-Hermite求积，计算逐sigma/逐标签位的符号错误、signed LLR均值方差、偏度与条件均值。高斯投影m=2 max(mu,0)^2/variance为工程近似。

## Numerical Notes

候选近似，尚未通过独立正式性能/速度门槛；不称为精确理论。 所有构造和统计消费实际I；随机辅助不计有效K；源条件化与接收度量分开。禁止用相关标签的平均边缘乘积替代实际联合PMF。

## Dependencies

无项目外部方法依赖；使用MATLAB内置功能。

## Verification status

合同测试及小pilot入口见l2_p2_mechanism；正式1%功率、3×80 PMF及独立模型门槛等待预算，不因生成契约自动升级证据。

Revision metadata: revision_id=p2_52d75da2a5cf_20261024; current_status=current; supersedes=[].


## 2026-11-10 信息估计P1开发对照补充
本轮固定实际I/S/F、幅度和资源映射；原始GA与校准输出分开，未拟合校准。联合PMF只是实际均匀likelihood LLR积分权重，不是在生产LLR插入成形先验。ga_mean=2mean²/variance是候选投影，不是匹配min-sum分布定理。实际位置sigma与N0映射已追踪。144单元开发对照出现显著绝对概率失配，独立边缘min-sum参照改善；不据此改构造或宣称通用GA失败。
证据：results/20261110_182159_p1_reliability；信息估计P0-P3开发交付-2026-11-10.md。候选仍未P4独立验证或速度验收，health=degraded保持。
