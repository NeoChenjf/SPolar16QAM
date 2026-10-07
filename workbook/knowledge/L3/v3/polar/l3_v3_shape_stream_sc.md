# L3 — `shape_stream_sc`

- **签名**：`[u,x] = shape_stream_sc(payload,stream)`
- **契约**：先固定 `u(I)=payload`、`u(F)=0`，再仅让 SC 决定 `u(S)`；最终输出 `x=uG_N`。
- **护栏**：禁止复用脱离 payload 的 shaping bits；函数在返回前断言 I/F 约束未被破坏。
- **健康度**：smoke-pass（`test_unit0_forced_sc`，2026-08-26）。
