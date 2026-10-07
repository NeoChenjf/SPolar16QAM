# L3 — `frozen_gray_pam_relation`

- **签名**：`[T,metadata] = frozen_gray_pam_relation(k)`，k=1/2/3。
- **定义**：统一登记v3实际使用的Gray-PAM关系。PAM2为唯一单位关系；PAM4用`[1 1;0 1]`，令一个latent位分离内/外层、另一个保持符号对称，可精确表达energy-lambda族；PAM8复用版本化optimized GF(2)矩阵。
- **边界**：PAM4矩阵是显式energy-family关系，不宣称为auto搜索唯一解；PAM8仍按approximate-pass解释。
- **健康度**：relation registry诊断通过。
