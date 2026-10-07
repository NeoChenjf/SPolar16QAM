# L3 · select_auto_gf2_relation

- **method_id**: l3_v3_select_auto_gf2_relation
- **file_path**: 16QAM_Polar/v3/modulation/select_auto_gf2_relation.m
- **module**: v3 modulation
- **health**: planned-smoke-pending

## Purpose
在轴自身均匀能量归一化的预登记 lambda 网格上枚举 `GL(k,2)` 并优化 latent p，以平均 KL、最坏 KL、字典序冻结 relation。

## Boundary
搜索矩阵只能称 optimized GF(2) relation，不等同论文已给出的 polar relation。

