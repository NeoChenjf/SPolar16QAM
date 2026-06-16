%% TEST_QAMDEMOD_BUG - 直接检测 qamdemod 的 LLR bug
% qamdemod 在单符号上的 LLR 输出是否正确

clear; clc;

fprintf('qamdemod LLR bug 检测\n');
fprintf('===========================================\n\n');

%% 单个 16QAM 符号测试（无噪声）
fprintf('【测试 1】无噪声情况下的 LLR 符号检查\n\n');

% 16QAM Gray 映射下的 16 个星座点
% Gray 顺序: 0,1,3,2,6,7,5,4,12,13,15,14,10,11,9,8
% 对应二进制: 0000,0001,0011,0010,0110,0111,0101,0100,1100,1101,1111,1110,1010,1011,1001,1000

constellation = qammod(0:15, 16, 'gray', 'UnitAveragePower', false);

fprintf('星座点及其 Gray 编码:\n');
fprintf('Index | Binary | Real | Imag | LLR_bit1(无噪声)| 预期\n');
fprintf('------|--------|------|------|---------------|---------\n');

for idx = 0:15
    sym = constellation(idx+1);
    
    % Gray 映射的二进制
    bits_gray = de2bi(idx, 4, 'left-msb');
    
    % 使用 qamdemod 计算 LLR (无噪声 = 极大 SNR)
    llr_noiseless = qamdemod(sym, 16, 'gray', ...
        'OutputType', 'llr', ...
        'UnitAveragePower', false, ...
        'NoiseVariance', 1e-6);  % 极小噪声
    
    % Bit 1 (MSB) 的 LLR
    bit1_llr = llr_noiseless(1);
    bit1_value = bits_gray(1);
    
    % 符号期望: bit1=0 时 LLR 应为正, bit1=1 时 LLR 应为负
    expected_sign = 1 - 2*bit1_value;  % 0->+1, 1->-1
    actual_sign = sign(bit1_llr);
    
    match_str = '✓';
    if actual_sign ~= expected_sign
        match_str = '❌ MISMATCH';
    end
    
    fprintf('%5d | %s | %+6.2f | %+6.2f | %+13.4f | %d->%s\n', ...
        idx, sprintf('%d%d%d%d', bits_gray(1), bits_gray(2), bits_gray(3), bits_gray(4)), ...
        real(sym), imag(sym), bit1_llr, expected_sign, match_str);
end

fprintf('\n');

%% 收集所有符号的 bit1 LLR 符号匹配度
fprintf('【测试 2】所有 16 个符号的 bit1 LLR 符号检查\n\n');

bit1_errors = 0;
for idx = 0:15
    sym = constellation(idx+1);
    bits_gray = de2bi(idx, 4, 'left-msb');
    bit1_value = bits_gray(1);
    
    llr_noiseless = qamdemod(sym, 16, 'gray', ...
        'OutputType', 'llr', ...
        'UnitAveragePower', false, ...
        'NoiseVariance', 1e-8);
    
    bit1_llr = llr_noiseless(1);
    expected_sign = 1 - 2*bit1_value;
    actual_sign = sign(bit1_llr);
    
    if actual_sign ~= expected_sign
        bit1_errors = bit1_errors + 1;
        fprintf('❌ Symbol %2d (bit1=%d): LLR=%.4f (sign=%d, expected %d)\n', ...
            idx, bit1_value, bit1_llr, actual_sign, expected_sign);
    end
end

if bit1_errors == 0
    fprintf('✓ 所有 16 个符号的 bit1 LLR 符号正确\n');
else
    fprintf('❌ %d/%d 符号的 bit1 LLR 符号错误\n', bit1_errors, 16);
end

fprintf('\n=== 结论 ===\n');
if bit1_errors > 0
    fprintf('⚠️ qamdemod 的 Gray 映射或 LLR 符号定义可能有问题\n');
    fprintf('   建议: 用自定义 LLR 替代 qamdemod\n');
else
    fprintf('✓ qamdemod 正常，符号问题源自别处\n');
end

fprintf('\n');
