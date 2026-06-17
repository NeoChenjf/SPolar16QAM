# L3 · parallel_to_serial_bits

- **method_id**: l3_parallel_to_serial_bits
- **file_path**: 16QAM_Polar/v2/modulation/parallel_to_serial_bits.m
- **module**: modulation
- **health**: healthy

## Signature
**输入**：`xxx1, xxx2, xxx3, xxx4`（各 N×1 列向量，每符号的第 1/2/3/4 比特）
**输出**：`xxx`（4N×1，按 [b1;b2;b3;b4] 逐符号串行排列）

## Purpose
把 4 路并行极化码比特流，按 16QAM 每符号 4 比特的顺序拼成串行比特流，供 `qammod` 调制。

## Math / Algorithm
- 拼成 `4×N` 矩阵 `[xxx1 xxx2 xxx3 xxx4]'`，按列优先展开（column-major）：
  `[b1_1;b2_1;b3_1;b4_1; b1_2;...]`。
- 与 `qammod(...,'InputType','bit')` 的比特序约定一致。

## Numerical Notes
- `assert` 四路长度一致，否则报错。

## Dependencies
无

## Health
healthy
