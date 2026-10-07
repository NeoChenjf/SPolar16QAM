# L3 — `bsc_bhattacharyya`

- **签名**：`reliability = bsc_bhattacharyya(q,N)`。
- **定义**：以BSC(q)的初始Bhattacharyya参数 `2sqrt(q(1-q))` 进行Arıkan递推；`W+`精确取平方，`W-`用 `min(1,2Z-Z²)` 上界。输出负Z，数值越大越可靠。
- **边界**：这是解析Bhattacharyya proxy，不是论文对每个虚拟信道的Monte Carlo估计。
- **健康度**：pending-runtime。
