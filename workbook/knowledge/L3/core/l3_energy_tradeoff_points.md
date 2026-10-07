# L3 · energy_tradeoff_points

输入有限n×2 double（Goodput,能量）；两目标均最大化。输出front、三角色通信/能量/折中、min-max归一化坐标、理想点距离。尺度容差1e-12；零跨度设1；折中只选非支配点；并列全部保留。纯函数，无RNG或IO。测试包含已知支配与完全并列样例。
