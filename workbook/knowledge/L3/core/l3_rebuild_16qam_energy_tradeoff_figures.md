# L3 · rebuild_16qam_energy_tradeoff_figures

实现位于analysis目录。输入已完成结果目录，从point_summary/working_points CSV及params读取，写四张PNG/PDF/FIG和figure_manifest。CI仅在BER–SNR、能量–p显示；权衡图全SNR均值；Pareto按键连接。零误码用显示下限标识，原值保留。现验证MATLAB R2020b。正式13SNR视觉QA在formal后执行。
