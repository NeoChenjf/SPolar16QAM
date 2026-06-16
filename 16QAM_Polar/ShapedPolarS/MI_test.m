% MI_test.m
% 基于 gettest.m 的整形极化码流程，做“无信道”的统计对比。
%
% 关注三种阶段的“比特信息量”（更准确说是：比特熵/分布）。
%   1) 预编码产生的整形位（S 集合上的 shaped bits）
%   2) 填入信息位后的 polar 输入向量 code（I+S+F）
%   3) 极化编码后的 encoded_bits
%
% 另外新增统计：以 X=编码前 bit（code），Y=编码后 bit（encoded_bits），
% 估计逐位置互信息 I(code(j);encoded_bits(j))，并给出全体/子集均值。

clearvars -except MI_TEST_NUMRUNS MI_TEST_PLIST; clc;

%% 路径设置：将“研究生毕设”目录及子目录加入路径
thisFile = mfilename('fullpath');
thisDir  = fileparts(thisFile);
projDir  = fileparts(fileparts(fileparts(thisDir))); % ...\研究生毕设
addpath(genpath(projDir));

%% 参数（无信道，关注编码/填充阶段的比特熵与分布）
N = 1024;                              % 码长
p_list_default = [0.5 0.3 0.21 0.16 0.1];         % 整形目标概率（P(bit=1)=p）
numRuns_default = 1000;                           % 蒙特卡洛样本数（增大以稳定熵估计）

if exist('MI_TEST_PLIST', 'var') && ~isempty(MI_TEST_PLIST)
    p_list = MI_TEST_PLIST;
else
    p_list = p_list_default;
end

if exist('MI_TEST_NUMRUNS', 'var') && ~isempty(MI_TEST_NUMRUNS)
    numRuns = MI_TEST_NUMRUNS;
else
    numRuns = numRuns_default;
end

%% 结果结构
results = struct();
results.N = N;
results.p_list = p_list;
results.entries = [];

%% 固定参数（极化解码）
lambda_offset = 2.^(0:log2(N));            % 分段向量
llr_layer_vec = get_llr_layer(N);          % LLR计算层向量
bit_layer_vec = get_bit_layer(N);          % 比特返回层向量

fprintf('MI_test (no channel): N=%d, p=%s, runs=%d\n', N, mat2str(p_list), numRuns);

for ip = 1:numel(p_list)
    p = p_list(ip);
    % 整形位数 S_size 按二元熵 h(p)
    h_p = (-(p)*log2(max(p, eps)) + (-(1-p))*log2(max(1-p, eps)));
    S_size = ceil(N * (1 - h_p));
    S_size_complementary = N - S_size;
    K = ceil(S_size_complementary/2);      % 信息位数

    fprintf('\n[p=%.3f] S_size=%d, K=%d\n', p, S_size, K);

    % 可靠度设计（GA），取任意 sigma 仅用于排序（不影响无信道分布）
    sigma_dummy = 1; % 仅用于 GA 排序
    channels = GA(sigma_dummy, N);
    [~, channels_ordered] = sort(channels, 'descend');
    S_bits = sort(channels_ordered(1:S_size), 'ascend');
    I_bits = sort(channels_ordered(S_size+1 : S_size+K), 'ascend');
    % SandI_bits 在无信道统计中不需要

    % 累积统计
    p1_shaped = zeros(N,1);    % 对应位置的 1 概率（整形位生成后，其他位为 0）
    p1_code_in = zeros(N,1);   % 填入信息后的码字（polar 输入）
    p1_encoded = zeros(N,1);   % 极化编码后的比特分布

    % 互信息统计：逐位置联合计数 (code, encoded_bits)
    c00 = zeros(N,1); % code=0, enc=0
    c01 = zeros(N,1); % code=0, enc=1
    c10 = zeros(N,1); % code=1, enc=0
    c11 = zeros(N,1); % code=1, enc=1

    for runIdx = 1:numRuns
        % 预编码：根据 BSC(p) 的 LLR 生成整形位
        frozen_bits = ones(N,1);
        frozen_bits(S_bits) = 0;           % S 集合作为“信息位”来生成整形
        llr_all = ones(N,1) * log((1-p)/max(p, eps));
        shaped_bits = SC_decoder(llr_all, S_size, frozen_bits, lambda_offset, llr_layer_vec, bit_layer_vec);

        % 信息位随机比特
        origin_data = randsrc(K, 1, [0 1; 0.5 0.5]);

        % 组合编码输入
        code = zeros(N,1);
        code(I_bits) = origin_data;
        code(S_bits) = shaped_bits;

        % 极化编码
        encoded_bits = polar_encoder(code);

        % 累计分布（经验概率）
        p1_shaped(S_bits) = p1_shaped(S_bits) + double(shaped_bits==1);
        p1_code_in = p1_code_in + double(code==1);
        p1_encoded = p1_encoded + double(encoded_bits==1);

        % 逐位置联合计数，用于 I(code(j);encoded_bits(j))
        x = (code ~= 0);
        y = (encoded_bits ~= 0);
        c00 = c00 + double(~x & ~y);
        c01 = c01 + double(~x & y);
        c10 = c10 + double(x & ~y);
        c11 = c11 + double(x & y);
    end

    % 归一化获得经验概率
    p1_shaped = p1_shaped / numRuns;
    p1_code_in = p1_code_in / numRuns;
    p1_encoded = p1_encoded / numRuns;

    % 熵计算（逐位置平均熵与整体平均）
    H_shaped = mean(bit_entropy(p1_shaped(S_bits)));
    H_code_in = mean(bit_entropy(p1_code_in));
    H_encoded = mean(bit_entropy(p1_encoded));

    % 逐位置互信息 I(code(j);encoded_bits(j))
    I_pos = bit_mi_from_counts(c00, c01, c10, c11, numRuns);
    nonfrozen_bits = unique([S_bits(:); I_bits(:)]);
    I_mean_all = mean(I_pos);
    I_mean_nonfrozen = mean(I_pos(nonfrozen_bits));
    I_mean_S = mean(I_pos(S_bits));
    I_mean_I = mean(I_pos(I_bits));

    entry = struct('p', p, 'S_size', S_size, 'K', K, ...
        'p1_shaped', p1_shaped, 'p1_code_in', p1_code_in, 'p1_encoded', p1_encoded, ...
        'H_shaped', H_shaped, 'H_code_in', H_code_in, 'H_encoded', H_encoded, ...
        'I_code_to_encoded_pos', I_pos, ...
        'I_code_to_encoded_mean_all', I_mean_all, ...
        'I_code_to_encoded_mean_nonfrozen', I_mean_nonfrozen, ...
        'I_code_to_encoded_mean_S', I_mean_S, ...
        'I_code_to_encoded_mean_I', I_mean_I);
    results.entries = [results.entries, entry]; %#ok<AGROW>

    fprintf('  H(shaped on S)=%.3f bits; H(code in)=%.3f bits; H(encoded)=%.3f bits\n', ...
        H_shaped, H_code_in, H_encoded);

    fprintf('  I(code;enc) mean: all=%.3f, nonfrozen=%.3f, S=%.3f, I=%.3f (bits/pos)\n', ...
        I_mean_all, I_mean_nonfrozen, I_mean_S, I_mean_I);
end

save('results_MI_test_no_channel.mat', 'results');
disp('MI_test 无信道统计完成，结果已保存为 results_MI_test_no_channel.mat');

%% 局部函数：比特熵
function H = bit_entropy(p1)
    p0 = 1 - p1;
    H = -(p1.*log2(max(p1, eps)) + p0.*log2(max(p0, eps)));
end

function I = bit_mi_from_counts(c00, c01, c10, c11, numRuns)
% 逐位置互信息 I(X;Y)，X,Y∈{0,1}。
% 输入为每个位置上的联合计数（长度 N 的向量），numRuns 为总样本数。
    p00 = c00 / numRuns; p01 = c01 / numRuns;
    p10 = c10 / numRuns; p11 = c11 / numRuns;

    px0 = p00 + p01; px1 = p10 + p11;
    py0 = p00 + p10; py1 = p01 + p11;

    I = zeros(size(p00));
    I = I + p00 .* log2(max(p00, eps) ./ max(px0 .* py0, eps));
    I = I + p01 .* log2(max(p01, eps) ./ max(px0 .* py1, eps));
    I = I + p10 .* log2(max(p10, eps) ./ max(px1 .* py0, eps));
    I = I + p11 .* log2(max(p11, eps) ./ max(px1 .* py1, eps));
end
