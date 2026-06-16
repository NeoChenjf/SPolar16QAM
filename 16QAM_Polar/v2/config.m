function cfg = config()
% CONFIG - 全局实验参数唯一入口
%
% 用法：cfg = config();
%
% 所有仿真脚本/函数通过 cfg 结构体获取参数，
% 修改参数只需改此文件，无需逐文件修改。

    %% ===== 极化码参数 =====
    cfg.N = 1024;                   % 极化码块长（比特）
    cfg.M = 16;                     % 16QAM 调制阶数
    cfg.bits_per_symbol = 4;        % log2(M)

    %% ===== 整形参数 =====
    % p_fixed(k) = NaN 表示该路由 p 控制；否则固定为该值
    % 当前设定：bit1/bit3 固定 0.5，bit2/bit4 由 p 控制
    cfg.p_fixed = [0.5, NaN, 0.5, NaN];

    % 扫参用候选 p 值
    cfg.p_candidates = [0.50, 0.45, 0.40, 0.35, 0.30, 0.25, 0.21, 0.16, 0.13, 0.10];

    %% ===== 信道与 SNR =====
    cfg.SNR_dB = -5:1:25;           % 信噪比范围（dB）
    cfg.channel = 'AWGN';           % 信道类型（后续可扩展 Rayleigh）
    % SNR 定义模式：
    %   'fixed_esn0' - 每个 p 按当前符号功率缩放噪声（保持 Es/N0 一致，符号级 SNR）
    %   'fixed_n0'   - 固定噪声功率，不随 p 改变（保留星座能量变化效应，比特级 SNR）
    % 
    % 详细说明：
    % - fixed_esn0 模式：N0 = Es_frame / 10^(SNR_dB/10)，SNR_dB 指符号级 SNR (Es/N0)
    % - fixed_n0 模式：N0 = snr_ref_power / 10^(SNR_dB/10)，SNR_dB 指比特级 SNR (Eb/N0)
    % - 两种模式下的理论 BER 均使用标准 Gray 16QAM 公式：BER = (3/8)*Q(sqrt(2*Eb/N0))
    cfg.snr_mode = 'fixed_esn0';
    % fixed_n0 模式下的参考功率（通常取基线 p=0.5 的单位归一化功率）
    cfg.snr_ref_power = 1.0;
    % LLR 噪声方差口径：
    %   false - 使用匹配口径 NoiseVariance = 2*sigma_noise^2（推荐）
    %   true  - 兼容旧实现 NoiseVariance = 2*sigma^2（仅用于复现实验）
    cfg.llr_use_legacy_noisevar = false;

    %% ===== 蒙特卡洛仿真 =====
    cfg.num_frames = 1000;          % 每个 (p, SNR) 点的仿真帧数
    cfg.seed = 42;                  % 随机种子（0 = 不固定）

    %% ===== 译码器选择 =====
    cfg.decoder = 'SC';             % 'SC' | 'SCL'
    cfg.SCL_L = 8;                  % SCL 列表大小
    cfg.use_CRC = false;            % 是否使用 CRC 辅助
    cfg.CRC_poly = [1 0 1 1];       % CRC 生成多项式

    %% ===== 调制 =====
    cfg.mapping = 'gray';           % 星座映射方式
    cfg.unit_avg_power = true;      % qammod 是否归一化平均功率

    %% ===== 输出 =====
    cfg.output_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
    cfg.timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    %% ===== 16QAM 星座参数（用于解析能量计算）=====
    % 归一化前的轴值 ±1, ±3
    cfg.r1 = 1;
    cfg.r2 = 3;
    % E(p) = 18 - 16p（归一化前）; 基线 E(0.5) = 10
    cfg.E_baseline = 10;            % 均匀分布时的平均符号能量

end
