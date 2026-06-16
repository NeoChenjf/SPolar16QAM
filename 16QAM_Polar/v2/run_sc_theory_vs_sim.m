%% RUN_SC_THEORY_VS_SIM
% 目的：清晰分离"GA理论预测"与"SC实际仿真"，用比值对齐验证p的净影响
%
% 设计思想：
% 1) 理论侧：GA 推断各虚拟信道可靠性，计算信息位所在位置的平均 BER（渐近估计）
% 2) 仿真侧：polar_encoder + BPSK-AWGN + SC_decoder 的真实蒙特卡洛仿真
% 3) 对齐：用比值对齐（相对p=0.5），突出p的趋势，规避绝对量级系统差异
% 4) 校准：可选的基线增益校准，仅用作工程工具，明确标注非理论

clear; clc; close all;
setup_paths();
cfg = config();

%% ===== 参数配置 =====
% 模式开关
run_local_12db_mode = true;           % === 任务A加密模式开关 ===

if run_local_12db_mode
    p_list = [0.5, 0.4, 0.3, 0.2, 0.1];
    snr_grid = 11:0.25:13;            % 局部加密 SNR 范围
    num_frames_min = 1000;            % 局部加密每个点最少帧数（保证统计稳定性）
    num_frames_max = 5000;
    min_total_bit_errors = 300;
    n_rep_local = 3;                  % 重复实验次数
else
    p_list = [0.5, 0.4, 0.3, 0.2, 0.1];  % 正常模式整形参数扫描范围
    snr_grid = -20:2:10;                  % 正常模式 SNR 范围
    num_frames_min = 300;
    num_frames_max = 3000;
    min_total_bit_errors = 200;
    n_rep_local = 1;
end

% 校准开关与参数
enable_calibration = true;            % 是否启用基线增益校准（工程工具）
calib_gain_min = 0.5;                 % 增益下界（防止过小）
calib_gain_max = 10.0;                % 增益上界（防止低SNR过补偿）
pe_floor = 1e-12;                     % 理论BER下限

cfg.decoder = 'SC';
cfg.seed = 20260420;
rng(cfg.seed, 'twister');

N = cfg.N;
nP = numel(p_list);
nS = numel(snr_grid);

%% ===== 输出目录 =====
out_dir = fullfile(cfg.output_dir, [datestr(now, 'yyyymmdd_HHMMSS') '_sc_theory_vs_sim']);
fig_dir = fullfile(out_dir, 'figures');
mkdir(fig_dir);

%% ===== 预计算辅助结构 =====
lambda_offset = 2.^(0:log2(N));
llr_layer_vec = get_llr_layer(N);
bit_layer_vec = get_bit_layer(N);

%% ================================================================================
%  第一部分：THEORY SIDE - GA理论计算
%  说明：基于高斯近似，计算各虚拟信道可靠性，估计信息位集合的平均BER
%  这是渐近意义下的理论估计，NOT真实SC译码结果
%% ================================================================================

fprintf('\n========== THEORY SIDE: GA-based BER estimation ==========\n');
ber_theory = zeros(nP, nS);  % 理论BER

for ip = 1:nP
    p = p_list(ip);
    fprintf('\nTheory: p=%.2f\n', p);
    
    opts = struct();
    opts.disable_geom = true;    % 只看编码侧，不加入几何因子
    opts.pe_floor = pe_floor;
    opts.alpha_rel = 1.0;
    opts.code_high_eta = 0.8;
    opts.code_high_mid_db = 14.0;
    opts.code_high_slope_db = 2.0;
    
    % 调用理论模型（返回的是 GA 推断的虚拟信道可靠性基础上的平均项误码率）
    m = estimate_ber_hat_sc_dual(p, snr_grid, cfg, opts);
    ber_theory(ip, :) = m.BER_hat;
end

fprintf('\n>>> Theory calculation complete.\n');

%% ================================================================================
%  第二部分：SIMULATION SIDE - 真实SC仿真
%  说明：完整的 polar_encoder + BPSK-AWGN + SC_decoder 链路
%  这是真实的蒙特卡洛验证，包含有限码长与SC判决传播的真实效应
%% ================================================================================

fprintf('\n========== SIMULATION SIDE: Monte Carlo with real encoder/decoder ==========\n');
ber_sim_all = zeros(n_rep_local, nP, nS);
frame_counts_all = zeros(n_rep_local, nP, nS);
error_counts_all = zeros(n_rep_local, nP, nS);

% p 向量（4路对应bit1-4，后两路由p控制）
p_vec = cfg.p_fixed;  % 通常为 [0.5, p, 0.5, p]

for rep = 1:n_rep_local
    if n_rep_local > 1
        fprintf('\n--- Simulation Repetition %d/%d ---\n', rep, n_rep_local);
    end
    for ip = 1:nP
        p = p_list(ip);
        fprintf('\nSimulation: p=%.2f\n', p);
        
        % 设置当前p对应的向量
        p_vec_cur = cfg.p_fixed;
        p_vec_cur(isnan(p_vec_cur)) = p;
        
        for is = 1:nS
            snr_db = snr_grid(is);
            sigma = 10^(-snr_db / 20);
            
            % ===== 预处理：确定各路的 S/I/F 集合 =====
            channels = GA(sigma, N);
        [~, channels_ordered] = sort(channels, 'descend');
        
        K_vec = zeros(1, 4);
        S_vec = zeros(1, 4);
        SI_set = cell(1, 4);
        I_set = cell(1, 4);
        S_set = cell(1, 4);
        frozen_bits_dec = zeros(N, 4);
        shaped_bits = cell(1, 4);
        
        for b = 1:4
            pb = p_vec_cur(b);
            if pb > 0 && pb < 1
                hb = -pb*log2(pb) - (1-pb)*log2(1-pb);
            else
                hb = 0;
            end
            S_vec(b) = ceil(N * (1 - hb));
            K_vec(b) = ceil((N - S_vec(b)) / 2);
            
            % 选择信息位：最可靠的K个位置
            I_pos = channels_ordered(S_vec(b) + 1 : S_vec(b) + K_vec(b));
            S_pos = channels_ordered(1 : S_vec(b));
            
            I_set{b} = sort(I_pos);
            S_set{b} = sort(S_pos);
            SI_set{b} = sort(channels_ordered(1 : S_vec(b) + K_vec(b)));
            
            frozen_bits_dec(:, b) = ones(N, 1);
            frozen_bits_dec(SI_set{b}, b) = 0;  % SI都作为"非冻结位"（能编码）
            shaped_bits{b} = randsrc(S_vec(b), 1, [0 1; 0.5 0.5]);
        end
        
        % ===== 蒙特卡洛主循环 =====
        bit_err_acc = zeros(4, 1);
        total_frames = 0;
        
        while true
            total_frames = total_frames + 1;
            
            for b = 1:4
                % 生成信息比特
                info = randi([0, 1], K_vec(b), 1);
                
                % 组装编码输入
                u = zeros(N, 1);
                u(I_set{b}) = info;
                u(S_set{b}) = shaped_bits{b};
                
                % === 编码 ===
                x = polar_encoder(u);  % 极化编码，输出1024比特
                
                % === 调制-信道-解调 ===
                tx = 1 - 2*x;                                    % BPSK
                y = tx + sigma * randn(N, 1);                   % AWGN
                llr = 2 * y / max(sigma^2, eps);                % LLR计算
                
                % === 译码 ===
                decoded = SC_decoder(llr, K_vec(b) + S_vec(b), frozen_bits_dec(:,b), ...
                                     lambda_offset, llr_layer_vec, bit_layer_vec);
                
                u_hat = zeros(N, 1);
                u_hat(SI_set{b}) = decoded;
                info_hat = u_hat(I_set{b});
                
                % === 误码计数 ===
                bit_err_acc(b) = bit_err_acc(b) + sum(info_hat ~= info);
            end
            
            % 自适应停止：当总位错误数达到阈值 或 超过最大帧数 时停止
            total_err_now = sum(bit_err_acc);
            if (total_frames >= num_frames_min && total_err_now >= min_total_bit_errors) || ...
               (total_frames >= num_frames_max)
                break;
            end
        end
        
        % 计算仿真BER（4路加权平均）
        ber_per_bit = zeros(4, 1);
        for b = 1:4
            ber_per_bit(b) = bit_err_acc(b) / max(K_vec(b) * total_frames, 1);
        end
        ber_sim_all(rep, ip, is) = sum(K_vec(:) .* ber_per_bit(:)) / max(sum(K_vec), 1);
        
        frame_counts_all(rep, ip, is) = total_frames;
        error_counts_all(rep, ip, is) = sum(bit_err_acc);
        
        fprintf('  SNR=%+4.1f dB | BER_sim=%.3e | BER_theory=%.3e | frames=%d | errors=%d\n', ...
            snr_db, ber_sim_all(rep, ip, is), ber_theory(ip, is), total_frames, sum(bit_err_acc));
    end
end
end

% 计算取平均后的最终仿真BER
ber_sim = squeeze(mean(ber_sim_all, 1));
frame_counts = squeeze(sum(frame_counts_all, 1)); % 累加帧数
error_counts = squeeze(sum(error_counts_all, 1)); % 累加错误数
if nP == 1
    ber_sim = ber_sim(:).';
    frame_counts = frame_counts(:).';
    error_counts = error_counts(:).';
elseif nS == 1
    ber_sim = ber_sim(:);
    frame_counts = frame_counts(:);
    error_counts = error_counts(:);
end

fprintf('\n>>> Simulation complete.\n');

%% ================================================================================
%  第三部分：ALIGNMENT - 比值与校准
%  说明：用 p=0.5 作为基线，计算相对比值（消除绝对量级差异，突出趋势）
%        可选基线校准，仅作工程工具，明确标注为非理论
%% ================================================================================

fprintf('\n========== ALIGNMENT: Ratio-based normalization & optional calibration ==========\n');

% 相对比值（以p=0.5为基线）
ratio_sim = zeros(nP, nS);
ratio_theory = zeros(nP, nS);
ratio_theory_cal = zeros(nP, nS);
calib_gain = ones(1, nS);
calib_gain_raw = ones(1, nS);
ber_theory_cal = ber_theory;  % 初始值等于原理论值

idx_ref = find(abs(p_list - 0.5) < 1e-12, 1);
if isempty(idx_ref)
    error('p_list 必须包含 0.5 作为归一化基线。');
end

% 先计算比值（理论-仿真、校准前）
for is = 1:nS
    b_sim_ref = ber_sim(idx_ref, is);
    b_th_ref = ber_theory(idx_ref, is);
    
    for ip = 1:nP
        if b_sim_ref > 1e-15
            ratio_sim(ip, is) = ber_sim(ip, is) / b_sim_ref;
        else
            ratio_sim(ip, is) = nan;
        end
        ratio_theory(ip, is) = ber_theory(ip, is) / max(b_th_ref, eps);
    end
end

% 可选：基线增益校准（工程工具，非理论推导）
if enable_calibration
    fprintf('>>> Applying baseline calibration (engineering tool, NOT theory)...\n');
    fprintf('    Using p=0.5 as reference to compute SNR-dependent gains.\n');
    
    for is = 1:nS
        b_sim_ref = ber_sim(idx_ref, is);
        b_th_ref = ber_theory(idx_ref, is);
        
        if b_sim_ref <= 1e-15 || b_th_ref <= 1e-15
            calib_gain_raw(is) = 1.0;
        else
            calib_gain_raw(is) = b_sim_ref / b_th_ref;
        end
        
        % 施加增益限幅（防止低SNR过补偿）
        calib_gain(is) = min(max(calib_gain_raw(is), calib_gain_min), calib_gain_max);
    end
    
    % 对所有p的理论值应用增益
    for ip = 1:nP
        ber_theory_cal(ip, :) = ber_theory(ip, :) .* calib_gain;
        ber_theory_cal(ip, :) = min(0.5, max(pe_floor, ber_theory_cal(ip, :)));
    end
    
    % 重新计算校准后的比值
    for is = 1:nS
        b_th_cal_ref = ber_theory_cal(idx_ref, is);
        for ip = 1:nP
            ratio_theory_cal(ip, is) = ber_theory_cal(ip, is) / max(b_th_cal_ref, eps);
        end
    end
    
    calib_info = sprintf('calib_gain[%.1f, %.1f]', calib_gain_min, calib_gain_max);
else
    fprintf('>>> Calibration disabled.\n');
    ratio_theory_cal = ratio_theory;
    calib_info = 'none';
end

%% ===== 导出表格 =====
fprintf('\n========== OUTPUT: Exporting results ==========\n');
rows = nP * nS;
[P_grid, S_grid] = ndgrid(p_list, snr_grid);

if run_local_12db_mode
    % ===== 任务A 局部加密模式导出 =====
    
    % 1. 导出汇总均值曲线 (local_12db_curve.csv)
    T_mean = table();
    T_mean.p = P_grid(:);
    T_mean.snr_dB = S_grid(:);
    T_mean.ber_sim_mean = reshape(ber_sim, rows, 1);
    
    % 统计信息 (重复实验的标准差和95%置信区间)
    if n_rep_local > 1
        ber_sim_std = squeeze(std(ber_sim_all, 0, 1));
        if nP == 1
            ber_sim_std = ber_sim_std(:).';
        elseif nS == 1
            ber_sim_std = ber_sim_std(:);
        end
        n_sqrt = sqrt(n_rep_local);
        ci_95 = 1.96 .* ber_sim_std ./ n_sqrt;
        
        T_mean.ber_sim_std = reshape(ber_sim_std, rows, 1);
        T_mean.ber_sim_ci95 = reshape(ci_95, rows, 1);
    else
        ber_sim_std = zeros(nP, nS);
        ci_95 = zeros(nP, nS);
        T_mean.ber_sim_std = zeros(rows, 1);
        T_mean.ber_sim_ci95 = zeros(rows, 1);
    end
    
    T_mean.ber_theory = reshape(ber_theory, rows, 1);
    T_mean.gap = T_mean.ber_sim_mean - T_mean.ber_theory;
    writetable(T_mean, fullfile(out_dir, 'local_12db_curve.csv'));
    
    % 2. 导出所有重复实验的原始数据 (local_12db_repetitions.csv)
    rep_rows = n_rep_local * nP * nS; %#ok<NASGU>
    [Rep_g, P_g, S_g] = ndgrid(1:n_rep_local, p_list, snr_grid);
    T_rep = table();
    T_rep.rep_idx = Rep_g(:);
    T_rep.p = P_g(:);
    T_rep.snr_dB = S_g(:);
    T_rep.ber_sim = ber_sim_all(:);
    T_rep.frames = frame_counts_all(:);
    T_rep.errors = error_counts_all(:);
    writetable(T_rep, fullfile(out_dir, 'local_12db_repetitions.csv'));
    
    % 3. 导出 12 dB 自动摘要 (local_12db_summary.csv)
    idx_12 = find(abs(snr_grid - 12.0) < 1e-12, 1);
    if isempty(idx_12)
        error('局部 12 dB 模式必须包含 SNR=12.0 dB。当前 snr_grid=%s', mat2str(snr_grid));
    end
    
    monotonic_violations = zeros(nP, 1);
    for ip = 1:nP
        monotonic_violations(ip) = sum(diff(ber_sim(ip, :)) > 0);
    end
    
    summary_rows = cell(nP, 1);
    for ip = 1:nP
        gap_now = ber_sim(ip, idx_12) - ber_theory(ip, idx_12);
        ci_now = ci_95(ip, idx_12);
        if n_rep_local <= 1
            summary_rows{ip} = 'need_repetition_for_ci';
        elseif gap_now > ci_now
            summary_rows{ip} = 'sim_above_theory_beyond_ci_sc_waterfall_likely';
        elseif abs(gap_now) <= ci_now
            summary_rows{ip} = 'gap_within_ci_statistical_fluctuation_plausible';
        elseif gap_now < -ci_now
            summary_rows{ip} = 'sim_below_theory_no_upward_anomaly';
        else
            summary_rows{ip} = 'needs_more_repetitions';
        end
    end
    
    T_summary = table();
    T_summary.p = p_list(:);
    T_summary.snr_dB = repmat(snr_grid(idx_12), nP, 1);
    T_summary.ber_sim_mean = ber_sim(:, idx_12);
    T_summary.ber_sim_std = ber_sim_std(:, idx_12);
    T_summary.ber_sim_ci95 = ci_95(:, idx_12);
    T_summary.ber_theory = ber_theory(:, idx_12);
    T_summary.gap_12 = T_summary.ber_sim_mean - T_summary.ber_theory;
    T_summary.abs_gap_over_ci95 = abs(T_summary.gap_12) ./ max(T_summary.ber_sim_ci95, eps);
    T_summary.local_monotonic_violations = monotonic_violations;
    T_summary.conclusion = summary_rows;
    writetable(T_summary, fullfile(out_dir, 'local_12db_summary.csv'));
    
    % 4. 绘图 (local_12db_curve.png/pdf/fig)
    figure('Position', [80 80 800 600], 'Visible', 'off');
    colors = lines(nP);
    hold on;
    for ip = 1:nP
        % 仿真曲线（实线+圆圈，带误差棒）
        if n_rep_local > 1
            errorbar(snr_grid, ber_sim(ip, :), ci_95(ip, :), '-o', 'Color', colors(ip, :), ...
                'LineWidth', 1.8, 'MarkerSize', 5, 'DisplayName', sprintf('Sim (mean\\pm95%%CI) p=%.1f', p_list(ip)));
        else
            semilogy(snr_grid, ber_sim(ip, :), '-o', 'Color', colors(ip, :), ...
                'LineWidth', 1.8, 'MarkerSize', 5, 'DisplayName', sprintf('Sim p=%.1f', p_list(ip)));
        end
        % 理论曲线（虚线）
        semilogy(snr_grid, ber_theory(ip, :), '--', 'Color', colors(ip, :), ...
            'LineWidth', 1.5, 'DisplayName', sprintf('Theory p=%.1f', p_list(ip)));
    end
    hold off;
    grid on;
    set(gca, 'YScale', 'log'); % 强制对数坐标
    xlabel('SNR (dB)', 'FontSize', 12);
    ylabel('BER', 'FontSize', 12);
    title('Local 12dB Anomaly Check: Theory vs SIM', 'FontSize', 13);
    legend('Location', 'southwest', 'FontSize', 9, 'NumColumns', 2);
    
    exportgraphics(gcf, fullfile(fig_dir, 'local_12db_curve.png'), 'Resolution', 300);
    exportgraphics(gcf, fullfile(fig_dir, 'local_12db_curve.pdf'), 'ContentType', 'vector');
    savefig(gcf, fullfile(fig_dir, 'local_12db_curve.fig'));
    close;
    
    % 5. README
    fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
    if fid < 0
        error('无法创建 README.txt: %s', fullfile(out_dir, 'README.txt'));
    end
    fprintf(fid, '=== Task A: Local 12 dB Theory-vs-Simulation Check ===\n\n');
    fprintf(fid, 'RUN COMMAND\n');
    fprintf(fid, '  cd(''16QAM_Polar/v2''); setup_paths; run_sc_theory_vs_sim;\n\n');
    fprintf(fid, 'SCOPE\n');
    fprintf(fid, '  Same-entry validation through run_sc_theory_vs_sim.m.\n');
    fprintf(fid, '  Theory side: estimate_ber_hat_sc_dual(..., disable_geom=true).\n');
    fprintf(fid, '  Simulation side: polar_encoder + BPSK-AWGN + SC_decoder.\n');
    fprintf(fid, '  No new BER formula or model is introduced in this local check.\n\n');
    fprintf(fid, 'PARAMETERS\n');
    fprintf(fid, '  run_local_12db_mode: true\n');
    fprintf(fid, '  p_list:              %s\n', mat2str(p_list));
    fprintf(fid, '  snr_grid:            %s\n', mat2str(snr_grid));
    fprintf(fid, '  n_rep_local:         %d\n', n_rep_local);
    fprintf(fid, '  frame range:         %d ~ %d\n', num_frames_min, num_frames_max);
    fprintf(fid, '  min_total_errors:    %d\n', min_total_bit_errors);
    fprintf(fid, '  rng seed:            %d\n\n', cfg.seed);
    
    fprintf(fid, '12 dB AUTO SUMMARY\n');
    fprintf(fid, '  %-6s %-14s %-14s %-14s %-14s %-12s %s\n', ...
        'p', 'ber_sim_mean', 'ber_theory', 'gap_12', 'ci95', '|gap|/ci', 'conclusion');
    for ip = 1:nP
        fprintf(fid, '  %-6.2f %-14.6e %-14.6e %-14.6e %-14.6e %-12.3f %s\n', ...
            T_summary.p(ip), T_summary.ber_sim_mean(ip), T_summary.ber_theory(ip), ...
            T_summary.gap_12(ip), T_summary.ber_sim_ci95(ip), ...
            T_summary.abs_gap_over_ci95(ip), T_summary.conclusion{ip});
    end
    fprintf(fid, '\nINTERPRETATION RULE\n');
    fprintf(fid, '  gap_12 = ber_sim_mean - ber_theory.\n');
    fprintf(fid, '  If gap_12 > ci95, simulation is above theory beyond the repetition CI;\n');
    fprintf(fid, '  this supports finite-length SC waterfall/error-propagation as the likely explanation.\n');
    fprintf(fid, '  If |gap_12| <= ci95, statistical fluctuation remains a plausible explanation.\n');
    fprintf(fid, '  If monotonic violations appear in 11~13 dB, increase n_rep_local to 5 before final wording.\n\n');
    
    fprintf(fid, 'OUTPUT FILES\n');
    fprintf(fid, '  local_12db_curve.csv        : all local SNR mean/std/CI/theory/gap values\n');
    fprintf(fid, '  local_12db_repetitions.csv  : raw data for every repetition\n');
    fprintf(fid, '  local_12db_summary.csv      : 12 dB extracted summary and conclusion labels\n');
    fprintf(fid, '  figures/local_12db_curve.*  : curve with 95%% CI error bars\n');
    fclose(fid);
    
else
    % ===== 正常模式导出（沿用原有逻辑） =====
    
    % 主表：绝对与相对指标
T = table();
T.p = P_grid(:);
T.snr_dB = S_grid(:);
T.ber_sim = reshape(ber_sim, rows, 1);
T.ber_theory = reshape(ber_theory, rows, 1);
T.ber_theory_cal = reshape(ber_theory_cal, rows, 1);
T.abs_gap = abs(T.ber_sim - T.ber_theory);
T.abs_gap_cal = abs(T.ber_sim - T.ber_theory_cal);
T.ratio_sim = reshape(ratio_sim, rows, 1);
T.ratio_theory = reshape(ratio_theory, rows, 1);
T.ratio_theory_cal = reshape(ratio_theory_cal, rows, 1);
T.ratio_gap = abs(T.ratio_sim - T.ratio_theory);
T.ratio_gap_cal = abs(T.ratio_sim - T.ratio_theory_cal);
T.frames_used = reshape(frame_counts, rows, 1);
T.errors_total = reshape(error_counts, rows, 1);

writetable(T, fullfile(out_dir, 'sc_theory_vs_sim_full.csv'));

% 校准表
T_cal = table(snr_grid(:), calib_gain_raw(:), calib_gain(:), ...
    'VariableNames', {'snr_dB', 'calib_gain_raw', 'calib_gain_used'});
writetable(T_cal, fullfile(out_dir, 'calibration_gains.csv'));

% 关键SNR切片（便于快速查看）
snr_key = [-20, -10, -4, 0, 2, 4, 10];
rows_key = [];
for i = 1:numel(snr_key)
    s = snr_key(i);
    idx = find(snr_grid == s, 1);
    if isempty(idx)
        continue;
    end
    for ip = 1:nP
        rows_key = [rows_key; 
            p_list(ip), s, ...
            ber_sim(ip, idx), ber_theory(ip, idx), ber_theory_cal(ip, idx), ...
            ratio_sim(ip, idx), ratio_theory(ip, idx), ratio_theory_cal(ip, idx)];
    end
end

T_key = array2table(rows_key, 'VariableNames', ...
    {'p', 'snr_dB', 'ber_sim', 'ber_theory', 'ber_theory_cal', ...
     'ratio_sim', 'ratio_theory', 'ratio_theory_cal'});
writetable(T_key, fullfile(out_dir, 'key_snr_table.csv'));

%% ===== 绘图：BER-SNR曲线（绝对值） =====
figure('Position', [80 80 1200 600], 'Visible', 'off');
colors = lines(nP);
hold on;

for ip = 1:nP
    % 仿真曲线（实线+圆圈）
    semilogy(snr_grid, ber_sim(ip, :), '-o', 'Color', colors(ip, :), ...
        'LineWidth', 1.8, 'MarkerSize', 5, 'DisplayName', sprintf('Sim p=%.1f', p_list(ip)));
    
    % 理论曲线（虚线）
    semilogy(snr_grid, ber_theory(ip, :), '--', 'Color', colors(ip, :), ...
        'LineWidth', 1.5, 'DisplayName', sprintf('Theory p=%.1f', p_list(ip)));
    
    % 校准理论曲线（虚线+x）
    if enable_calibration
        semilogy(snr_grid, ber_theory_cal(ip, :), '-.', 'Color', colors(ip, :), ...
            'LineWidth', 1.3, 'Marker', 'x', 'DisplayName', sprintf('Cal p=%.1f', p_list(ip)));
    end
end

hold off;
grid on;
xlabel('SNR (dB)', 'FontSize', 12);
ylabel('BER', 'FontSize', 12);
title('SC Theory vs Simulation: Absolute BER Comparison', 'FontSize', 13);
legend('Location', 'southwest', 'FontSize', 9, 'NumColumns', 2);
exportgraphics(gcf, fullfile(fig_dir, 'ber_absolute.png'), 'Resolution', 300);
exportgraphics(gcf, fullfile(fig_dir, 'ber_absolute.pdf'), 'ContentType', 'vector');
close;

%% ===== 绘图：Ratio vs p（相对值） =====
figure('Position', [80 80 1200  600], 'Visible', 'off');
snr_key_plot = [-20, -4, 0, 4, 10];
colors_snr = lines(numel(snr_key_plot));
hold on;

for i_snr = 1:numel(snr_key_plot)
    s = snr_key_plot(i_snr);
    idx_s = find(snr_grid == s, 1);
    if isempty(idx_s)
        continue;
    end
    
    % 仿真比值
    plot(p_list, ratio_sim(:, idx_s), '-o', 'Color', colors_snr(i_snr, :), ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'DisplayName', sprintf('Sim SNR=%d', s));
    
    % 理论比值
    plot(p_list, ratio_theory(:, idx_s), '--', 'Color', colors_snr(i_snr, :), ...
        'LineWidth', 1.3, 'DisplayName', sprintf('Theory SNR=%d', s));
end

yline(1.0, 'k:', 'LineWidth', 1.2, 'DisplayName', 'ratio=1 (p=0.5 baseline)');
hold off;
grid on;
xlabel('Shaping parameter p', 'FontSize', 12);
ylabel('BER ratio to p=0.5', 'FontSize', 12);
title('Relative Effect of p: Theory vs Simulation', 'FontSize', 13);
legend('Location', 'bestoutside', 'FontSize', 9);
set(gca, 'XDir', 'reverse');
exportgraphics(gcf, fullfile(fig_dir, 'ratio_vs_p.png'), 'Resolution', 300);
exportgraphics(gcf, fullfile(fig_dir, 'ratio_vs_p.pdf'), 'ContentType', 'vector');
close;

%% ===== README Documentation =====
fid = fopen(fullfile(out_dir, 'README.txt'), 'w');
fprintf(fid, '=== SC Theory vs Simulation: Full Documentation ===\n\n');
fprintf(fid, 'SCOPE\n');
fprintf(fid, '  Pure encoding-side analysis (geometry isolated via BPSK-AWGN).\n');
fprintf(fid, '  p_list: [0.5  0.4  0.3  0.2  0.1]\n');
fprintf(fid, '  SNR grid: -20:2:10 dB\n');
fprintf(fid, '  Decoder: SC (successive cancellation)\n\n');

fprintf(fid, 'THEORY SIDE (estimate_ber_hat_sc_dual.m)\n');
fprintf(fid, '  - GA (Gaussian Approximation) computes virtual channel reliabilities per SNR.\n');
fprintf(fid, '  - For each p, selects top-K reliable bit positions as information bits.\n');
fprintf(fid, '  - BER estimate is average of per-bit error rates over I-set.\n');
fprintf(fid, '  - This is asymptotic/theoretical estimate, NOT real SC decoding result.\n\n');

fprintf(fid, 'SIMULATION SIDE (Monte Carlo with polar_encoder + SC_decoder)\n');
fprintf(fid, '  - Full link: info → encode → BPSK-AWGN → decode → BER count\n');
fprintf(fid, '  - 4 parallel bit streams, weighted average for total BER.\n');
fprintf(fid, '  - Adaptive stopping: min %d frames or %d bit errors.\n', ...
    num_frames_min, min_total_bit_errors);
fprintf(fid, '  - This captures real SC effects: error propagation, finite-length, etc.\n\n');

fprintf(fid, 'ALIGNMENT STRATEGY\n');
fprintf(fid, '  - Ratio-based (RECOMMENDED): normalize all to p=0.5 baseline.\n');
fprintf(fid, '    → ratio_sim vs ratio_theory should align if trends agree.\n');
fprintf(fid, '    → abs_gap may be large, but ratio_gap should be small if structure OK.\n');
fprintf(fid, '  - Gain calibration (OPTIONAL, engineering tool):\n');
fprintf(fid, '    → g(SNR) = BER_sim(p=0.5) / BER_theory(p=0.5) at each SNR.\n');
fprintf(fid, '    → Apply to all p: ber_cal = ber_theory * g(SNR).\n');
fprintf(fid, '    → Clamp: g ∈ [%.1f, %.1f] to prevent low-SNR over-fitting.\n', ...
    calib_gain_min, calib_gain_max);
fprintf(fid, '    → STATUS: %s\n\n', calib_info);

fprintf(fid, 'KEY OUTPUT COLUMNS\n');
fprintf(fid, '  ber_sim              Simulated BER (ground truth)\n');
fprintf(fid, '  ber_theory           GA-based theoretical estimate\n');
fprintf(fid, '  ber_theory_cal       Calibrated theory (if enabled)\n');
fprintf(fid, '  ratio_sim            ber_sim / ber_sim(p=0.5)\n');
fprintf(fid, '  ratio_theory         ber_theory / ber_theory(p=0.5)\n');
fprintf(fid, '  ratio_theory_cal     ber_theory_cal / ber_theory_cal(p=0.5)\n');
fprintf(fid, '  abs_gap              |ber_sim - ber_theory| (diagnostic)\n');
fprintf(fid, '  ratio_gap            |ratio_sim - ratio_theory| (KEY metric)\n');
fprintf(fid, '  frames_used          Total frames simulated for this (p,SNR)\n');
fprintf(fid, '  errors_total         Total bit errors accumulated\n\n');

fprintf(fid, 'INTERPRETATION GUIDE\n');
fprintf(fid, '  1. Check ratio_gap: if small, trends agree even if abs_gap large.\n');
fprintf(fid, '  2. If ratio_gap grows at certain SNR, may indicate:\n');
fprintf(fid, '     - GA model breaks down (finite-length effects)\n');
fprintf(fid, '     - SC error propagation dominates over bulk-channel effects\n');
fprintf(fid, '  3. p effect summary: plot ratio_vs_p.png to see p''s relative impact.\n\n');

fprintf(fid, 'FILES\n');
fprintf(fid, '  sc_theory_vs_sim_full.csv : complete data table\n');
fprintf(fid, '  calibration_gains.csv     : raw and clamped gain factors\n');
fprintf(fid, '  key_snr_table.csv         : selected SNR points for quick lookup\n');
fprintf(fid, '  ber_absolute.png/pdf      : BER-SNR curves (sim + theory + cal)\n');
fprintf(fid, '  ratio_vs_p.png/pdf        : relative ratio curves for key SNRs\n\n');

fprintf(fid, 'CONCLUSION\n');
fprintf(fid, '  Theory and simulation differ in absolute magnitude (expected),\n');
fprintf(fid, '  but ratio trends should align if p''s encoding effect is correctly modeled.\n');
fprintf(fid, '  Use ratio-based analysis for conclusions on p dependency.\n');

fclose(fid);
end % 结束 if run_local_12db_mode 的分支

fprintf('\n>>> All outputs saved to: %s\n', out_dir);
fprintf('\n=== SUMMARY ===\n');
fprintf('Theory-side: GA-based BER estimates (asymptotic, average sense)\n');
fprintf('Sim-side:    Real SC decoding with polar_encoder/SC_decoder (finite-length)\n');
fprintf('Alignment:   Ratio-based (recommended) + optional calibration (engineering tool)\n');
fprintf('Key metric:  ratio_gap (should be small if trend structure holds)\n');
