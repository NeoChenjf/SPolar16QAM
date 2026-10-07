# L3 — `test_unit0_noiseless_roundtrip`

- **检查**：8/16/32/64QAM，各两帧随机非零消息，在 120 dB 有限 sigma 下完整链路 BER/联合 BLER 为零，并校验码率字段。
- **已验证**：旧版均匀identity链路四种M已由用户运行PASS。
- **新增覆盖**：两个seed（17/29），非均匀p及1-p，真实非空S/I，以及由`frozen_gray_pam_relation`统一登记的PAM2/4/8关系；全星座latent标签/LLR符号与payload完整环回。
- **边界**：120 dB的有限噪声近似无噪声测试；不检验实际经验PMF、能量单调性或有限SNR AWGN性能。PAM4关系是energy-lambda族的显式精确关系，PAM8关系保持optimized/approximate口径。
- **健康度**：smoke-pass（2026-08-28用户MATLAB输出：4个均匀基线及16个shaped/relation组合均PASS）。
