function xxx = parallel_to_serial_bits(xxx1, xxx2, xxx3, xxx4)
% 将四个并行比特流按 16-QAM 每符号4比特的顺序转为串行比特流
% 输入：
%   xxx1, xxx2, xxx3, xxx4 : 列向量，长度 N，每个元素为 0 或 1
%   分别代表每个符号的第1、2、3、4个比特
% 输出：
%   xxx : 列向量，长度 4*N，按 [b1; b2; b3; b4] 顺序串行排列

    % 确保输入为列向量
    xxx1 = xxx1(:);
    xxx2 = xxx2(:);
    xxx3 = xxx3(:);
    xxx4 = xxx4(:);
    
    % 检查长度一致
    N = length(xxx1);
    assert(isequal(N, length(xxx2), length(xxx3), length(xxx4)), ...
        'All input bit streams must have the same length.');

    % 按列拼接：每列是一个符号的 4 个比特 [b1; b2; b3; b4]
    bits_matrix = [xxx1, xxx2, xxx3, xxx4]';  % 4 x N
    
    % 按列优先（column-major）转为向量：先第一列（符号1），再第二列（符号2）...
    xxx = bits_matrix(:);  % 自动按列展开，即 [b1_1; b2_1; b3_1; b4_1; b1_2; ...]
end

