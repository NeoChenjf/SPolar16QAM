# L2 · run_16qam_energy_tradeoff

入口：`16QAM_Polar/v2/experiments/rectifier/run_16qam_energy_tradeoff.m`，参数mode默认smoke，可选resume_source。Windows命令：`scripts/run_matlab_local.ps1 "run_16qam_energy_tradeoff('smoke')"`。

调用真实sim_shaped_polar_16qam完整SNR向量，逐帧采集及逐SNR检查点；完成块恢复写入新目录。配对统计→CSV/MAT→四图→数值审计→SHA256清单。默认5p×3SNR×3seed×2帧；formal为5p×13SNR×3seed×300帧，必须用户单独授权。

产物包含params、results、frame/repetition/summary/working_points、源代码快照、日志、checkpoint、figure_manifest、hash清单及PNG/PDF/FIG。验证入口：test_energy_tradeoff、test_energy_tradeoff_recovery、verify_energy_tradeoff_results。MATLAB R2020b实测；未宣称Octave图表API兼容。
