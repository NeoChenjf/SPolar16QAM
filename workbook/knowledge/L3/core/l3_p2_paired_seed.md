# L3 · p2_paired_seed

- **method_id**: l3_p2_paired_seed
- **file_path**: 16QAM_Polar/v2/core/p2_paired_seed.m
- **module**: core
- **health**: degraded（单元测试通过，未接入正式实验）

## Signature

`value = p2_paired_seed(purpose,seed,realization,snr_index,frame,group,role)`；role为channel、noise、payload、auxiliary或donor。channel要求snr/frame/group为0；noise要求group=0且snr/frame正；三种数据角色要求group=1..3且snr/frame正。

## Purpose / Math

映射为 `2*p2_seed(...,slot)+variant`：payload用slot 1..3，auxiliary/donor用slot 4..6但variant为0/1；noise和channel用slot 0并以frame及SNR键区分。省略case以便候选共享指定角色随机种子。

## Numerical Notes

种子不同是确定性状态标识，不构成不同伪随机流统计独立性的数学证明。参数purpose/seed/索引范围继承p2_seed；界限不合法拒绝。调用方须实际使用相应seed、正确传递h/n并保留有效指纹。旧p2_seed和旧批次完全不变。

## Dependencies

- l3_ref: l3_p2_seed

## Verification status

MATLAB `test_p2_paired_seed`通过，覆盖11个不同角色键的唯一性、重复一致、最大参数及错误角色/键；未完成全域穷举或正式集成。


## 2026-11-06 策略专用角色

strategy_training/9211及strategy_test/9212映射到旧混合键power_validation的8211/8212保留槽；新映射对直接power_validation使用8211/8212明确报pairedseed:ReservedSeed，避免角色碰撞。其他旧p2_seed和已完成旧批不变。仅代表性键验证，不证明伪随机流统计独立。
