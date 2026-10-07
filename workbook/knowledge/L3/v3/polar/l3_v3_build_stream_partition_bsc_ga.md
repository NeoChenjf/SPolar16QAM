# L3 — `build_stream_partition_bsc_ga`

- **签名**：`stream = build_stream_partition_bsc_ga(N,p,sigma_design)`。
- **定义**：按BSC(min(p,1-p))可靠性选 `|S|=ceil(N(1-H2(p)))` 个S；从剩余位置按AWGN-GA可靠性选K个I，其余为F。
- **护栏**：S/I/F互斥且并集为全部N；p与1-p必须有相同S。
- **健康度**：pending-runtime。
