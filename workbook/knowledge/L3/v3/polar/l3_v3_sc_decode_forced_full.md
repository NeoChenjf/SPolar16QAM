# L3 · sc_decode_forced_full

- **method_id**: l3_v3_sc_decode_forced_full
- **file_path**: 16QAM_Polar/v3/polar/sc_decode_forced_full.m
- **module**: v3 polar
- **health**: planned-smoke-pending

## Purpose
SC 译码返回完整 `u`，并允许任意已知位置。发送端用它在当前 `I/F` 约束下求 `S`；接收端只能将 `F` 标为已知。

## Guardrail
不允许先求 S 后覆盖 I；通信 decoder 的活动集是 `I∪S`，仅 I 是 payload。

## 2026-10-09 契约修订追加

本节补充原契约，不改写历史字段。函数签名为`[u_hat, decision_llr] = sc_decode_forced_full(llr, known_mask, known_bits, prior_llr, options)`；前三项为N维列向量，prior_llr默认0，options默认空结构。`options.exact=true`启用精确f节点；给定N个[0,1) uniforms时，未知位置按条件概率抽样，且必须启用exact。函数不自行生成随机数。

默认模式保留min-sum硬判决。精确模式采用

$$
f(a,b)=\operatorname{sgn}(a)\operatorname{sgn}(b)\min(|a|,|b|)+\log(1+e^{-|a+b|})-\log(1+e^{-|a-b|}).
$$

g节点为$b+(1-2u)a$，抽样概率为$P(U_i=1\mid U_{<i})=1/(1+e^{L_i})$。精确源概率要求有限输入、正确源先验及prior_llr=0；不要把min-sum logistic当作精确概率。

验证边界：N=2、4的所有u前缀、p=0.1/0.3/0.5与独立枚举似然差小于1e-10；大码长无噪声信息位回环通过。非有限LLR不属于精确模式契约。
