# L3 · analyze_fixed_h_batch
- **method_id**: l3_analyze_fixed_h_batch
- **file_path**: 16QAM_Polar/v2/diagnostics/analyze_fixed_h_batch.m
- **module**: analysis
- **signature**: analyze_fixed_h_batch()，无返回值，结果保存时间戳results或本批固定结果目录。
- **purpose**: 固定H独立实现核验及A1/A2描述分析，非预测训练。
- **math_definition**: 编码参照为二进制子集矩阵；递归min-sum f/g及部分和异或；帧内BER=I错误/I位数，普通-genie先配对，100帧t区间系数1.984。具体对象以本函数源码为准。
- **dependencies**: SC_decoder、polar_encoder、GA、p2_transmit_block、p2_decode_block、ofdm_common_noise_roundtrip、sc_decode_forced_full（按源码实际调用）；MATLAB通信工具箱。
- **numerical_notes**: 零LLR判0；轨迹容差1e-10；区间描述性非同时/跨H；空S分母不表示概率零。目录绑定本批，不应自动重跑实验。
- **health**: healthy（本批已运行）；非所有配置证明。run_fixed_h_existing曾发生行列比较误报，列向量规范后通过。
