# P4有限域离线压缩 · p4_lookup_minsum
- method_id: l3_p4_lookup_minsum
- flow_id: l2_p4_lookup_minsum
- file_path / entry_script: 16QAM_Polar/v2/analysis/p4_lookup_minsum.m
- module: analysis
- runtime: minutes
- needs_user_run: false
- health: healthy（功能检查；科学误差另见独立报告）
## Signature / Inputs
p4_lookup_minsum(H,N0,locations,state,bank)；build_p4_lookup(out)。固定幅度1、原3个H/标签20和28/p.5和.3；离线预测order80/B8192/seed112100004。
## Purpose / Math / Pipeline
只复制冻结模型36组分路SC/genie预测及数值标准误，绝不使用测试BER拟合。K加权导出BER。严格比较H、N0、locations、实际N/K/I/S/F、p、kind、source_fingerprint；域外valid=false和NaN，不近邻插值。source_fingerprint为cell，使用isequal。重复查找值须完全一致。
## Dependencies
build使用l3_p4_lookup_minsum；读取冻结预测与A0离线资产。lookup无外部方法依赖。
## Outputs
frozen_lookup.mat、36点一致/域外拒绝测试与lookup_timing.csv。预加载查询成本和首次加载成本分开，离线积分成本保留。
## Acceptance / Numerical Notes
域内36点值完全一致；改变H/N0/map/实际I且保留旧fingerprint/整形kind均拒绝。有限表不表示任意H快速模型；独立误差见P4报告，不自造通过线。
## Evidence / Weekly Report
results/20261110_191153_p4_independent；周报/阶段B/B4：full-chain策略验证.md。
