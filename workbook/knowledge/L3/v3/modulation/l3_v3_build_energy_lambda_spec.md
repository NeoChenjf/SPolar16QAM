# L3 — `build_energy_lambda_spec`

- **签名**：`built = build_energy_lambda_spec(qam,lambda,relation_I,relation_Q)`。
- **目标**：固定均匀星座缩放下 `P_X(x)∝exp(lambda*|x|^2)`；Cartesian 能量可分，因此分别构造 I/Q轴目标并拟合 latent `p`。
- **默认关系**：统一由`frozen_gray_pam_relation`登记：1-bit单位、2-bit energy-family精确关系`[1 1;0 1]`、3-bit冻结optimized GF(2) relation。
- **输出**：target/model轴与符号PMF、p、KL/TV、match status、目标/模型RF能量代理和两轴 solver详情。
- **门禁**：exact=`KL≤1e-10,TV≤1e-8`；approximate-pass=`KL≤0.02,TV≤0.05`；否则fail。
- **健康度**：implemented-pending-runtime。
