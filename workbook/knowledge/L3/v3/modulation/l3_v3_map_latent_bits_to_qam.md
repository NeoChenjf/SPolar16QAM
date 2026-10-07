# L3 — `map_latent_bits_to_qam`

- **签名**：`[tx,label_bits,symbol_index] = map_latent_bits_to_qam(z_bits,qam,model)`
- **契约**：将每个符号时刻的 latent 流 `z` 依次按 `b_I=T_Iz_I`、`b_Q=T_Qz_Q` 变为 canonical Gray labels，并唯一查表映射到固定缩放的 QAM 点。
- **护栏**：不依赖“第几位是幅度位”的固定索引；输入必须二进制且列数等于 `m`。
- **健康度**：planned-smoke-pending。
