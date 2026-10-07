# Next Plan — 通用 GrayQAM loop

## 当前结论

开题计划第一项的文档入口已经统一到[README](README.md)，并形成可直接制作中期汇报的[中期PPT材料](中期PPT材料.md)。v2固定16QAM基线与v3通用Gray QAM扩展均已纳入资料索引。v3技术门禁已经全部完成：8/16/32/64QAM四个同构工作单元均通过A标签、B PMF、C环回、D AWGN和E能量门禁；本loop不再追加实验。

## 当前状态

- 星座、Gray 标签、relation、latent MAP/LSE LLR及无噪声环回已通过。
- source-MC+GA的全M PMF门禁已通过；8/16/32QAM由energy smoke提供正式证据，64QAM由N=1024补充实验提供正式证据。
- energy-lambda真实码字smoke已通过：四种M的模型与经验能量均随lambda显著增加，8组相邻经验差下界全部大于0。
- 64QAM正式PMF结果`20260903_221630_pmf_formal64`通过：三个lambda点TV上界为0.01877/0.02680/0.03310，均≤0.05。
- AWGN BER refine已通过：12条曲线均有5–7个有效D点，最低有效错误数104，D列全部完成。
- relation registry和全M有限噪声latent LLR直接参考对照通过。
- 四个工作单元及跨M技术门禁全部完成，无红色或黄色问题。
- 文档、代码入口、结果目录和PPT推荐图表已完成映射；代码、数据和图片仍保留在`16QAM_Polar/`。

## 补充诊断：N=256与N=1024受控对照

为回答有限长实现与理想模型差距是否随码长缩小，已运行
`run_gray_qam('blocklength_compare')`，结果目录为
`16QAM_Polar/v3/results/20260916_225430_energy_lambda_blocklength_formal/`。该入口固定其他统计与构造条件，只改变
`N=256/1024`。12个`M × lambda`点的PMF TV 95%上界全部下降，12点中11点的经验能量绝对理论差缩小；
码长增加改善分布逼近，但未消除model→empirical构造差距。结果只回答PMF/发送能量逼近，不扩张为N=1024 BER或跨lambda最优结论。

## 下一工作单元

1. 中期汇报直接从[中期PPT材料](中期PPT材料.md)取文字，并按图表索引从`16QAM_Polar/`取图；技术上不需要继续运行MATLAB。
2. 当前BER refine只证明D门禁，不能据3次重复宣称稳定lambda最优。
3. 若下一目标是论文级BER/Goodput/Energy权衡与最优工作点，应重新预登记重复次数、置信区间和比较口径，并新开loop。
4. 若下一目标转向OFDM、多用户、APSK或整流器非线性模型，也应新开loop。

## 与开题后续阶段的边界

- OFDM、Rayleigh信道和子载波级资源分配属于开题计划第二项，不写入本loop的完成清单。
- USRP、无辅助载波接收架构、非线性整流器和端到端实测属于后续阶段，不写成当前成果。
- 本loop的能量指标仅为平均发送RF能量代理量，不能写成整流效率或实测收获能量。

## 何时新开 loop

仅当工作单元、统一协议或终止条件发生实质变化时新建 loop，例如转向 cross-QAM/APSK、OFDM、多用户或整流器非线性模型。当前阶段不满足这些条件。
