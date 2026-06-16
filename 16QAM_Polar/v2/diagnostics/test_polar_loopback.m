%% TEST_POLAR_LOOPBACK - 诊断步骤 2：极化码无噪声回环测试
% 功能：验证极化编码器和 SC 译码器是否工作正常
% 测试：在无噪声或极高 SNR 下，编码后码字应能完美译回
%
% 原理：
%   1. 生成随机信息位
%   2. 填充冻结位（全 0）
%   3. 极化编码
%   4. 模拟"无噪声信道"（正常 LLR = ±inf，用大数代替）
%   5. SC 译码
%   6. 检查是否能恢复原信息位

clc;

%% 参数
cfg = config();
cfg.snr_mode = 'fixed_esn0';
N = cfg.N;              % 1024
nTests = 10;            % 测试 10 次
p_test = 0.5;           % 中性值

fprintf('\n极化码无噪声回环测试\n');
fprintf('参数: N=%d, p=%.1f, nTests=%d\n', N, p_test, nTests);
fprintf('======================================\n\n');

% 预计算译码辅助结构
lambda_offset = 2.^(0:log2(N));
llr_layer_vec = get_llr_layer(N);
bit_layer_vec = get_bit_layer(N);

% 保存结果
max_errors = 0;
total_bits = 0;
fail_count = 0;

rng(42, 'twister');

%% 主测试循环
for iTest = 1:nTests
    % 生成随机信息位
    h = -p_test*log2(p_test) - (1-p_test)*log2(1-p_test);
    K = ceil((N - ceil(N*(1-h))) / 2);
    
    info_bits = randi([0 1], K, 1);
    code = zeros(N, 1);
    
    % 生成冻结位配置（用极小 SNR 对应的极差虚拟信道）
    channels = GA(0.0001, N);  % 极小的噪声（近似无噪声下的虚拟信道）
    [~, ch_ordered] = sort(channels, 'descend');
    
    S_size = ceil(N * (1 - h));
    % 与主链路一致：先选 K+S 个可译码位（SI 集合），再从中划分 I 集合
    SI_set = sort(ch_ordered(1:K+S_size), 'ascend');
    I_set = sort(ch_ordered(S_size+1:S_size+K), 'ascend');
    
    frozen_bits = ones(N, 1);
    frozen_bits(SI_set) = 0;  % 非冻结位（S+I）
    
    % 填充信息位
    code(I_set) = info_bits;
    
    % 极化编码
    x_enc = polar_encoder(code);
    
    % "无噪声信道"：用极大 LLR 表示 (±1000 表示接近完美)
    llr_perfect = (1 - 2*x_enc) * 1000;
    
    % SC 译码
    decoded_full = SC_decoder(llr_perfect, K+S_size, frozen_bits, ...
                              lambda_offset, llr_layer_vec, bit_layer_vec);
    
    % SC_decoder 输出长度为 (K+S)，对应 SI_set 顺序；先回填再提取 I_set
    code_hat = zeros(N, 1);
    code_hat(SI_set) = decoded_full;
    decoded_info = code_hat(I_set);
    
    % 检查错误
    n_errors = sum(decoded_info ~= info_bits);
    total_bits = total_bits + K;
    max_errors = max(max_errors, n_errors);
    
    if n_errors > 0
        fail_count = fail_count + 1;
        fprintf('❌ 测试 %d: %d 位错误 (K=%d)\n', iTest, n_errors, K);
    else
        fprintf('✓ 测试 %d: 完美恢复 (K=%d)\n', iTest, K);
    end
end

fprintf('\n=== 诊断结论 ===\n');
fprintf('总测试位数: %d\n', total_bits);
fprintf('最大单次错误: %d\n', max_errors);
fprintf('失败测试数: %d / %d\n', fail_count, nTests);

if max_errors == 0 && fail_count == 0
    fprintf('✓ 极化编码/译码正常\n');
    fprintf('  所有无噪声测试都完美恢复\n');
else
    fprintf('❌ 极化编码/译码有问题\n');
    fprintf('  建议检查:\n');
    fprintf('    1. polar_encoder 或 SC_decoder 的实现逻辑\n');
    fprintf('    2. frozen_bits 配置是否正确\n');
    fprintf('    3. 信息位/冻结位的索引映射\n');
end

fprintf('\n✓ 极化码无噪声回环测试完成\n\n');
