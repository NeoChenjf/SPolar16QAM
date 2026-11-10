# L3 · run_stratified_loss_extract
- **method_id**: l3_run_stratified_loss_extract
- **file_path**: 16QAM_Polar/v2/diagnostics/run_stratified_loss_extract.m
- **module**: analysis
- **signature**: 无参本批离线入口；输出CSV/MAT/JSON，无新增通信。
- **purpose**: 固定H首错条件损失分层及跨参考标签oracle迁移。
- **math_definition**: I错误=I首错指示+首错后I错误；表按H/p/组/路/位置区间估条件损失，源事件至少10；支持集偏差按支持路I位数归一，未覆盖给0至剩余I位物理范围。
- **numerical_notes**: NaN标无首错；200次帧bootstrap仅描述性且固定支持集合；源/目标不同标签独立重采样。非线上模型。
- **dependencies**: 已存summary MAT、MATLAB基础读写或Python标准库。
- **health**: healthy，本批运行完成；S首错零事件层不可评价。
