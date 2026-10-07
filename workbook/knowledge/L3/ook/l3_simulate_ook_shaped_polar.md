# L3 · simulate_ook_shaped_polar

- **method_id**: l3_simulate_ook_shaped_polar
- **file_path**: 16QAM_Polar/OOK/simulate_ook_shaped_polar.m
- **module**: ook
- **health**: healthy

## Signature

**输入**

| 参数 | 类型 | 含义 |
| --- | --- | --- |
| `p` | scalar double | OOK shaping probability parameter |
| `opts` | struct | `N`, `snr_grid`, `num_frames`, `seed`, `regenerate_each_frame` |

**输出**

| 参数 | 类型 | 含义 |
| --- | --- | --- |
| `result` | struct | BER/BLER/Goodput/Energy/K/S/SNR 等复现指标 |

## Purpose

复现 legacy `ShapedPolarS/gettest.m` 的 OOK shaped-polar 端到端链路，并输出可记录的指标。

## Math / Algorithm

1. 计算二元熵：

```text
h(p) = -p log2(p) - (1-p) log2(1-p)
S = ceil(N * (1 - h(p)))
K = ceil((N - S) / 2)
```

2. 对每个 SNR 使用 legacy `GA(sigma,N)` 排序，最高可靠 `S` 位作为 shaping set，之后 `K` 位作为 information set。
3. shaping prior LLR 为：

```text
LLR_shape = log((1-p)/p)
```

4. 调用 legacy `SC_decoder` 得到 shaping bits，填入 polar 输入向量 `u(S)`；随机信息位填入 `u(I)`；`polar_encoder(u)` 得到 OOK `0/1` 发射序列。
5. OOK 信道：

```text
y = x + sigma_noise * randn(N,1)
sigma_noise = sqrt(mean(x.^2)/(2*10^(SNR/10)))
LLR = (1 - 2*y)/(2*sigma_design^2)
```

6. SC 解码 `S ∪ I`，从 `I` 集合抽取信息位并统计 BER/BLER。
7. Goodput proxy：

```text
G = K/N * (1 - BER)
```

Energy proxy 为编码后 OOK `1` 的平均比例。

## Numerical Notes

- `regenerate_each_frame=true` 默认每帧重新生成信息位和 shaping bits；这比旧 `gettest.m` 更适合 smoke 统计。
- LLR 公式保留 legacy 口径，用于复现，不代表当前 16QAM v2 主线的严格 LLR 推导。
- 小帧数下高 SNR 很容易全零错误，不能据此解释 BER 机制或排序。

## Dependencies

- legacy `GA`
- legacy `SC_decoder`
- legacy `polar_encoder`
- legacy `get_llr_layer`
- legacy `get_bit_layer`

## Health

healthy — 已通过 `run_ook_gettest_style.m` 格式 smoke；2026-07-04 修复 opts override 被 local_defaults 清空的问题。当前完整 `num_frames=1000` 复现仍需用户授权运行。

