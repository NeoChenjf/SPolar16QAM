# L3 · p2_verify_common_snapshot

- **method_id**: l3_p2_verify_common_snapshot
- **file_path**: 16QAM_Polar/v2/analysis/p2_verify_common_snapshot.m
- **module**: analysis
- **health**: degraded（快照与清单一致性已测，不提供外部签名或清单真实性）

## Signature

`summary=p2_verify_common_snapshot(run_dir)`：逐行读取source_sha256.tsv，检查编号源码副本文件名和SHA256及external原始文件SHA256，返回源码数、外部数和pass。缺失、额外副本、名称或哈希不匹配立即报错。

## Purpose / Math

比较每个实际文件的SHA256与运行时清单；不从现在的源码替换历史快照。

## Numerical Notes

清单本身需要由上游冻结资产绑定；该方法不证明清单真实性。external文件必须存在于清单记录的路径，移动工作区需经有版本的可复现迁移方案，不绕过检查。

## Dependencies

无项目方法依赖。

## Verification status

训练和测试目录各50个源码副本与1个外部模板全部核对；合成源码/外部文件篡改和缺失测试通过。
