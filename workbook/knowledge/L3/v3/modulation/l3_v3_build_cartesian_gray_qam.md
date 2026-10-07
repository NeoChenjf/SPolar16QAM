# L3 · build_cartesian_gray_qam

- **method_id**: l3_v3_build_cartesian_gray_qam
- **file_path**: 16QAM_Polar/v3/modulation/build_cartesian_gray_qam.m
- **module**: v3 modulation
- **health**: planned-smoke-pending

## Signature
输入：`M∈{8,16,32,64}`。输出：Cartesian Gray-QAM 星座、标签、I/Q分解与固定均匀缩放。

## Contract
`mI=ceil(log2(M)/2)`、`mQ=floor(log2(M)/2)`；标签按 `[I MSB..LSB,Q MSB..LSB]`；均匀 PMF 下缩放后平均能量为1。

