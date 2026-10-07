# L1 · OOK 数能同传 shaped polar 复现

- **domain_id**: l1_ook_shaped_polar
- **maturity**: active
- **rks_score**: 60

## Research Question

原始 OOK `0/1` 发射口径下，shaped polar code 如何通过 shaping set 控制码字中 `1` 的比例，并在 BER / Goodput / 发射能量 proxy 之间形成数能折中。

## Hypotheses

- H1: `S=ceil(N(1-h(p)))` 的 shaping set 构造可以复现 `ShapedPolarS/gettest.m` 的 OOK shaped-polar 基本链路 → `l2_ook_reproduce_smoke`
- H2: OOK 发射能量 proxy 可用编码后 `1` 的均值衡量，但 smoke 全零错误点不能用于稳定排序 → `l2_ook_reproduce_smoke`

## Core Quantities

| 符号 | 定义 | 单位 | 计算位置 |
| --- | --- | --- | --- |
| `S` | `ceil(N*(1-h(p)))` | bit | `l3_simulate_ook_shaped_polar` |
| `K` | `ceil((N-S)/2)` | bit | `l3_simulate_ook_shaped_polar` |
| BER | 信息位误比特率 | - | `l3_simulate_ook_shaped_polar` |
| BLER | 信息块错误率 | - | `l3_simulate_ook_shaped_polar` |
| Energy proxy | OOK 码字中 `1` 的平均比例 | - | `l3_simulate_ook_shaped_polar` |
| Goodput proxy | `K/N*(1-BER)` | bit/resource | `l3_simulate_ook_shaped_polar` |

## Theoretical Boundaries

- OOK 复现线沿用旧 `gettest.m` 的遗留 LLR 口径，不等同于当前 16QAM v2 主线。
- `p=0.5` 时 `h(p)=1`，`S=0`，退化为无 shaping 的 baseline。
- 小样本 smoke 中出现全零错误时，只能说明该点过高或帧数不足，不能作为 BER 机制结论。

## Pitfalls（护栏）

- ⚠️ 判定 Goodput 前必须核对 `K/N` 码率上界 — 见 `workbook/mandatory-rules.md` §7。
- ⚠️ 全零 BER 点不能用于解释 BER 异常或策略排序 — 见 `workbook/mandatory-rules.md` §8。
- ⚠️ 长复现 sweep 需要用户授权 — 见 `workbook/mandatory-rules.md` §3。

## Collaborators

- → `l1_polar_coding`: GA 排序、SC shaping 和 SC decoding 复用 polar code 机制。
- → `l1_metrics_tradeoff`: BER / Goodput / Energy proxy 的 tradeoff 解释需要同口径曲线。
- → `l1_probabilistic_shaping`: `p` 通过 entropy 和 prior LLR 控制 shaping bits。

## Code Anchors

- `l3_simulate_ook_shaped_polar` (`16QAM_Polar/OOK/simulate_ook_shaped_polar.m`)
- `16QAM_Polar/OOK/run_ook_reproduce_smoke.m`
