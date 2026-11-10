# L3 · p2_summarize_csi_pairs

- method_id: l3_p2_summarize_csi_pairs
- file_path: 16QAM_Polar/v2/analysis/p2_summarize_csi_pairs.m
- module: analysis
- health: exploratory

`summary=p2_summarize_csi_pairs(T,n_boot,seed)` 校验各基线同一组信道且每信道选项、档位与特征一致，按信道聚类对BER、Goodput及无量纲代理差值做描述性重采样。相同seed复用相同信道索引；数据来源和独立性由调用者负责，输出不作为正式门禁。依赖 l3_p2_paired_channel_bootstrap。

MATLAB已有两个测试信道与四基线产生12条描述汇总，删除一条配对行被拒；两信道区间没有可靠覆盖保障。
