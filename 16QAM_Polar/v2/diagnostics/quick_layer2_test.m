%% QUICK_LAYER2_TEST - Layer2修复后的快速验证

clear; clc; setup_paths();
cfg = config();

%% 快速单点测试
p = 0.3;
snr_db = 10;
sigma = 10^(-snr_db/20);
nSym = 5000;

prior_b1 = 0.5;
prior_b2 = p;
prior_b3 = 0.5;
prior_b4 = p;
prior_bits = [prior_b1, prior_b2, prior_b3, prior_b4];

rng(2026, 'twister');

% 生成数据
b1 = rand(nSym, 1) < prior_bits(1);
b2 = rand(nSym, 1) < prior_bits(2);
b3 = rand(nSym, 1) < prior_bits(3);
b4 = rand(nSym, 1) < prior_bits(4);
tx_bits = double([b1, b2, b3, b4]);

% 用修复后的方式转成列向量
tx_bits_col = zeros(nSym*4, 1);
tx_bits_col(1:4:end) = tx_bits(:, 1);
tx_bits_col(2:4:end) = tx_bits(:, 2);
tx_bits_col(3:4:end) = tx_bits(:, 3);
tx_bits_col(4:4:end) = tx_bits(:, 4);

% 调制
tx_sym = qammod(tx_bits_col, cfg.M, cfg.mapping, 'InputType', 'bit', 'UnitAveragePower', cfg.unit_avg_power);

% 信道
sigma_noise = sqrt(cfg.snr_ref_power) * sigma;
noise = sigma_noise .* (randn(nSym, 1) + 1j*randn(nSym, 1));
rx_sym = tx_sym + noise;

% LLR计算
llr_mis = llr_16qam_gray_LSE(rx_sym, sigma_noise);

% 拆分比特
llr_mis_bits = zeros(nSym, 4);
for b = 1:4
    llr_mis_bits(:, b) = llr_mis(b:4:end);
end

fprintf('===== Layer2 修复后验证 =====\n\n');

for b = 1:4
    x_true = tx_bits(:, b);
    pb1 = prior_bits(b);
    pb0 = 1 - pb1;
    
    L = llr_mis_bits(:, b);
    
    % BER
    xhat = double(L < 0);
    ber = mean(xhat ~= x_true);
    
    % MI（新公式）
    Lc = min(max(L, -60), 60);
    
    % 两种约定
    p1_a = 1 ./ (1 + exp(-Lc));
    p0_a = 1 - p1_a;
    
    p0_b = 1 ./ (1 + exp(-Lc));
    p1_b = 1 - p0_b;
    
    % MI计算
    eps0 = 1e-12;
    logp_ratio_a = zeros(nSym, 1);
    idx0 = (x_true == 0);
    idx1 = ~idx0;
    logp_ratio_a(idx0) = log2(max(p0_a(idx0), eps0)) - log2(pb0);
    logp_ratio_a(idx1) = log2(max(p1_a(idx1), eps0)) - log2(pb1);
    I_a = mean(logp_ratio_a);
    
    logp_ratio_b = zeros(nSym, 1);
    logp_ratio_b(idx0) = log2(max(p0_b(idx0), eps0)) - log2(pb0);
    logp_ratio_b(idx1) = log2(max(p1_b(idx1), eps0)) - log2(pb1);
    I_b = mean(logp_ratio_b);
    
    I = max(max(I_a, I_b), 0);
    if ~isfinite(I)
        I = 0;
    end
    
    fprintf('Bit %d (pb1=%.2f):\n', b, pb1);
    fprintf('  MI = %.4f bits\n', I);
    fprintf('  BER = %.3e\n', ber);
    
    if ber < 0.25 && I > 0.2
        fprintf('  ✓ 看起来正常！\n');
    elseif ber > 0.4 || I < 0
        fprintf('  ⚠️  异常！\n');
    end
    fprintf('\n');
end

fprintf('✓ 验证完成\n');
