# L3 · verify_b4b_strict_smoke

- **method_id**: l3_verify_b4b_strict_smoke
- **file_path**: 16QAM_Polar/v2/diagnostics/multicarrier/verify_b4b_strict_smoke.m
- **module**: diagnostics / multicarrier
- **health**: healthy（2026-09-17 authoritative smoke PASS）

## Signature

`report = verify_b4b_strict_smoke(result_dir)`

读取B4b smoke或受限pilot目录，核对必需文件、CSV键、行数、有限性、资源恒等式、进度日志和图表，并把审计结论写入`audit.txt`。

## Contract

- repetition表必须覆盖`realization × SNR × strategy`且键唯一。
- summary表必须覆盖`SNR × strategy`；channel表必须覆盖每个realization的64个子载波。
- `effective_rate`、Goodput、padding比例和信息子载波比例必须可由原始计数重建。
- `progress_log.txt`的START与DONE数量必须一致。
- BER `.fig`的主纵轴必须为对数刻度；零错原始值保留于CSV，但不能破坏对数图。
- 若summary含`ber_zero_error_upper95`，审计会重建累计错误/信息位数并验证其95%零错上界恒等式。
- smoke审计通过只证明实现、产物与统计口径自洽，不证明策略排序。

## Validation

对`results/20260917_112216_b4_strict_ofdm_rayleigh_smoke/`运行结果：36条重复记录、18条汇总记录、128条信道记录，START/DONE各36，49个OFDM符号，padding 2.0408%，全部检查PASS。对高SNR pilot同样通过：90条重复记录、18条汇总记录、320条信道记录，START/DONE各90。
