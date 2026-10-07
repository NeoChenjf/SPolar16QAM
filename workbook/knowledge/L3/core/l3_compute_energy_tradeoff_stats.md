# L3 · compute_energy_tradeoff_stats

输入double n×10：seed,p,SNR,frames,symbols,sum_abs2,errors,info_bits,BLER_weighted,R。拒绝重复键、缺基线、非正功率分母、非法计数、非三seed。

输出rep追加P_mean,baseline_P_mean,E_unit,BER,Goodput；summary每(p,SNR)汇总三seed的BER/G/E均值、标准差及df=2的t区间；points提供Pareto/角色/归一化坐标/距离。CI基于每seed配对比值。列结构见代码注释与loop协调协议。输入NaN不允许；结果不覆盖原始数据。
