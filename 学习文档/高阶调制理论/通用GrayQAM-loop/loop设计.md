# Loop 设计 — 通用 GrayQAM

> 来源：[需求澄清](需求澄清.md) ｜ 工具栈：MATLAB（GNU Octave 兼容）｜ 状态：技术门禁完成，资料已归档  
> 统一入口：先阅读[开题计划第一项资料总览](README.md)。需要实现级细节时，再依次阅读本文件、[协调协议](协调协议.md)、[进度表](进度表.md)、[问题记录](问题记录.md) 和 [next_plan](next_plan.md)。

## 核心思想

建立一个与调制阶数解耦的 `multi-stream shaped polar → axis relation → Cartesian Gray QAM` 仿真内核。先完成共用的 Gray-PAM/关系/PMF/latent-MAP-LLR 底座，然后让 8、16、32、64QAM 四个同构单元逐一走完相同的“构造—环回—统计—AWGN—能量”协议。protocol 是口径裁判，board 是进度真相源。

该架构每个 latent bit-level 使用一条长度 `N` 的 polar stream，是面向通用 QAM 的 BICM 多流扩展；它不等价于论文把单个整体 polar codeword 分组后继续极化的有限长图。论文严格复现与等价性证明不属于本 loop。

## 工作单元清单

| # | 单元 | `m=log2(M)` | I 轴 | Q 轴 | 关键风险 |
| ---: | --- | ---: | --- | --- | --- |
| 1 | Cartesian Gray 8QAM | 3 | 4-PAM/2 bit | 2-PAM/1 bit | 矩形标签与只有一轴可整形。 |
| 2 | Cartesian Gray 16QAM | 4 | 4-PAM/2 bit | 4-PAM/2 bit | 与 v2 共同正确口径回归。 |
| 3 | Cartesian Gray 32QAM | 5 | 8-PAM/3 bit | 4-PAM/2 bit | 8-PAM 关系与非对称流数。 |
| 4 | Cartesian Gray 64QAM | 6 | 8-PAM/3 bit | 8-PAM/3 bit | 双轴多层关系及复杂度。 |

四行必须与 board 一一对应。共享底座是所有单元的前置门禁，不单独冒充第五个完成单元。

## 范围边界

### 在范围内

- 新根目录 `16QAM_Polar/v3/`，v2 不修改。
- 单载波 Cartesian Gray 8/16/32/64QAM、复 AWGN、SC-only。
- `M`、`shaping_spec`、`snr_dB`、`cfg` 驱动的统一函数。
- I/Q Gray-PAM 构造、GF(2) 关系、目标/模型/经验 PMF、先验 MAP LLR、SC 编解码及 SWIPT 指标。
- smoke 与完整实验均输出时间戳结果目录；full run 必须由用户授权。

### 明确不做

- OFDM/Rayleigh、SCL/CRC、cross-QAM/APSK、任意二维 DM、硬件整流器模型。
- 把 v2 四路独立成形复制为 v3 正式模式。
- 用 `qammod/qamdemod` 的 16QAM-only Octave 兼容实现充当通用调制底座。

## 硬约束 vs 自由度

### 硬约束

- `M∈{8,16,32,64}` 且 `m=log2(M)`；默认 `m_I=ceil(m/2)`、`m_Q=floor(m/2)`，较高阶 PAM 放 I 轴。轴分解必须写入结果元数据。
- Gray 标签、bit 顺序、I/Q 角色由生成的星座表推导；不得硬编码“第 2/4 位是幅度位”。
- 每个符号时刻有 `m` 条长度 `N` 的 polar codeword；同时报告 `R_code=sum(K_b)/(mN)` 与 `R_bpcu=sum(K_b)/N`，先核对码率上界再解释 Goodput。
- `relation` 是 GF(2) 可逆关系。`[]` 规范化为单位矩阵；`'auto'` 只能解析为在预登记设计网格上枚举/优化并冻结的矩阵。只有论文明确给出且验证过的矩阵才可命名 `paper_*`。
- 发送端固定使用列向量 `b=Tz (mod 2)`。接收端不得从单独的 `L(b_j|y)` 逆推 `z`；demapper 必须直接按 `z(x)=T^{-1}b(x)` 枚举星座，输出每个 latent bit 的精确 bit-metric MAP LLR。
- 模型 PMF 必须由 `p + relation + Gray labels` 枚举得到；demapper 使用完整符号先验并采用稳定 LSE。
- 每帧 shaping必须消息条件化：先写入当前payload `I` 与冻结值 `F`，再用SC求 `S`；接收端只冻结 `F`、联合解码 `I∪S`、仅从 `I` 统计payload。
- 星座缩放固定为均匀 PMF 下的平均能量基准；不得按每个 shaped PMF 再归一化。
- `fixed_n0` 与 `fixed_esn0` 必须分开记录。能量单调验收使用 `fixed_n0`；编码公平对照可补 `fixed_esn0`，但不能混图后作同口径结论。
- 先静态、单元、无噪声、smoke，再允许 full；长跑需用户授权。所有结果写 `16QAM_Polar/v3/results/YYYYMMDD_HHMMSS_*`，含参数、seed、CSV/MAT、README、日志、PNG/PDF/FIG。
- 每次实现后同步 board、protocol（契约变化时）、issues、L1/L2/L3 与 `周报/高阶调制/README.md`。issues 连续编号，解决后回改标题状态。

### 自由度

- v3 内部模块文件名和纯函数拆分，可在不改变 protocol 的前提下调整。
- 求 `p_i` 可使用网格、多起点约束优化或解析式；必须保存目标函数、边界、初值、收敛状态和最终 KL。
- smoke 的帧数、SNR 粗扫网格和图形样式由 build agent 选择，但不得绕过五项验收。
- 4-PAM/8-PAM 的 `auto` relation 必须完成可逆性、目标网格优化、冻结规则和 latent demapper 测试。若使用任意搜索矩阵，产物称“optimized GF(2) relation”，不得称论文 polar relation。

## 共享底座门禁

开始第一个单元前，先建立并验证以下能力：

1. `M → (M_I,M_Q,m_I,m_Q)` 的 Cartesian 分解与输入校验；
2. 任意 `2^k`-PAM 的几何点、反射 Gray 标签、bit 角色及固定均匀能量缩放；
3. `p/relation → axis PMF → QAM PMF` 的枚举器、归一化和 KL；
4. 可逆 GF(2) 关系的正向/逆向标签枚举，以及固定 relation 的设计网格选择证据；
5. 任意 M 点、任意符号先验、按 latent labels 分组的稳定 MAP/LSE bit metric；
6. 与调制阶数无关的 `m` 路 polar stream 组装、指标和结果结构。

任一门禁未通过，不开始 8QAM 单元。

## 每单元执行流程

1. **构造**：由 `M` 自动生成轴分解、星座、标签、均匀缩放和 bit 角色；解析目标、`p` 与关系。
2. **静态/错误路径**：检查维度、GF(2) 可逆性、概率归一化、非法 M/p/relation/PMF/SNR；保存 validation table。
3. **模型核对**：枚举模型 PMF，保存目标 PMF、模型 PMF、KL、TV distance、理论能量与 solver 状态。
4. **无噪声环回**：真实随机信息先约束 `I/F` 再由SC求 `S`，之后进入axis relation、Gray QAM、无噪声latent demapper/译码；要求信息位零错误、活动集为 `I∪S`、所有bit顺序一致，并专项检查改变payload后不得复用旧shaping bits。
5. **经验 PMF**：以独立帧为统计簇，保存每帧 PMF/能量，再用跨帧 cluster bootstrap/同时区间验证经验分布；不得把同一码字内部位置当 iid 样本。
6. **AWGN smoke**：粗扫找到 BER 约 `1e-4~1e-1` 的瀑布区；保存 errors/frames，不用全零点作结论。
7. **能量单调**：在固定星座缩放与 `fixed_n0` 下扫描有序正 `lambda`，验证平均能量单调不减，同时报告码率上界和 Goodput。
8. **留痕**：输出 README/CSV/MAT/图/日志；更新 board/issues/知识库/周报。契约变化则回归所有已完成单元的最小 smoke。

## 迭代顺序

`Unit 0 理论/统计门禁 → 共享底座 → 8QAM → 16QAM → 32QAM → 64QAM → 跨 M 统一入口测试`。

Unit 0 必须固定：多流架构边界、canonical Gray 表、`b=Tz` 方向、auto relation 选择规则、latent MAP LLR、BSC对 `p>0.5` 的对称处理、码率/Goodput、SNR公式和机器阈值。Unit 0不是第五个调制单元，而是所有单元的共同理论前置。

- 8QAM先证明矩形分解、4-PAM relation 和单轴成形。
- 16QAM补齐双 4-PAM 轴，并以 v2 做限定回归。
- 32QAM只有在 8-PAM relation/decoder 已获得数学与测试证据后开始。
- 64QAM复用两个已验证的 8-PAM 轴，最后检查复杂度与双轴联合 PMF。

## 验证机制

- **正确路径**：五项验收全部通过；经验 PMF按独立帧 cluster bootstrap检查；无噪声零信息错误；瀑布区达到最小错误数；能量差值满足置信条件。
- **错误路径**：非法 `M`、非标量/非有限概率、不可逆关系、PMF负数/不归一、维度错配、未知模式、噪声参数非法，以及把 `S` 标成接收端冻结位/未先写当前 `I` 就求 `S`，均须报可诊断错误。
- **边界路径**：`lambda=0` 均匀退化、`relation=[]` 单位退化、8QAM 的 BPSK 轴无幅度 shaping、强正/负 lambda 的稀有符号、零概率的 log-domain 处理。
- **回归**：16QAM先登记 v2→v3 canonical 标签的置换/取反双射，再比较星座/固定缩放、均匀 latent metric与无噪声环回；multi-stream relation shaped结果不要求复制 v2 legacy BER。

机器退出码为 0 只是最低门槛；业务裁判是 protocol、原始统计和五项验收。

## 终止条件与人工验收

loop 仅在以下条件同时满足时结束：

1. board 中 8/16/32/64 四行五项验收均为完成；
2. 同一入口只改 `M` 即依次完成四个 smoke，输出结构兼容；
3. 无未解释红色 issue，黄色 issue 明确不影响验收边界；
4. L1/L2/L3、结果 README、protocol、board 与周报同步；
5. 用户审核星座/PMF/KL/BER/能量材料并明确确认完成。

## 每轮交接自检

- 三类路径真的验证了吗，而不只是脚本退出 0？
- board、protocol、issues、知识库和周报同步了吗？
- 现在换人，只读本目录和最新结果 README 能继续吗？
