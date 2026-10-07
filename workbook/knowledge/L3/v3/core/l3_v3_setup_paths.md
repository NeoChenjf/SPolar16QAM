# L3 · v3 setup_paths

- **method_id**: l3_v3_setup_paths
- **file_path**: 16QAM_Polar/v3/setup_paths.m
- **module**: v3 core
- **health**: partial-smoke-pass

## Purpose
加载 v3 模块及只读复用的 v2 polar 基础函数；不加载 v2 的 16QAM-only modulation compat。

## Dependencies
`v2/polar/get_llr_layer.m`、`get_bit_layer.m`、`polar_encoder.m` 等。

## Path guard
`v3_root` 的直接父目录是 `16QAM_Polar`，所以 v2 polar 固定从
`fullfile(fileparts(v3_root),'v2','polar')` 加载；不得再向上跳到研究项目根。
