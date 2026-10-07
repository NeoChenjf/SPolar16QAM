# L3 — `build_stream_partition_ga`

- **签名**：`stream = build_stream_partition_ga(N,p,sigma_design)`
- **契约**：以 `|S|=ceil(N(1-H_2(p)))`，按 v2 `GA` 可靠性降序依次指定 S、I、F，`K=floor((N-|S|)/2)`。
- **边界**：这是首个可运行 smoke 的 GA 近似构造，不是论文 BSC 严格构造；每流保存构造标签和设计 sigma。
- **健康度**：planned-smoke-pending。
