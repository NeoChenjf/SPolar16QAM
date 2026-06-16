function [BER,BLER,spow,I1,I2,I3,I4,I_total] = gettest_MI(p)

% 设置p1调整最外面一圈的出现次数多少。
% 16qam的gray映射要求第二位和第四位都为0时，最外面一圈的概率增加
p1 = 0.5;   % 全部
p2 = p;     % 内圈
p3 = 0.5;
p4 = p;

N = 1024;
M = 16;                % 16QAM
SNR = -5:5:30;
lambda_offset = 2.^(0:log2(N));
llr_layer_vec = get_llr_layer(N);
bit_layer_vec = get_bit_layer(N);

%%%%%%%%%%%%%%% 总的 BER 和 BLER 数组，最后用来统计
BER = zeros(1,length(SNR));
BLER = zeros(1,length(SNR));
energy = zeros(1,length(SNR));   % 平均符号功率

%%%%%%%%%%%%%%% 互信息数组（每一位一条曲线）
I1 = zeros(1,length(SNR));
I2 = zeros(1,length(SNR));
I3 = zeros(1,length(SNR));
I4 = zeros(1,length(SNR));
I_total = zeros(1,length(SNR));

%%%%%%%%%%%%% 第1个bit
h_p1 = -p1*log2(p1) - (1-p1)*log2(1-p1);
S_size1 = ceil(N*(1-h_p1));
S_size_complementary1 = N - S_size1;
K1 = ceil(S_size_complementary1/2);

BER1 = zeros(1,length(SNR));
BLER1 = zeros(1,length(SNR));

%%%%%%%%%%%%% 第2个bit
h_p2 = -p2*log2(p2) - (1-p2)*log2(1-p2);
S_size2 = ceil(N*(1-h_p2));
S_size_complementary2 = N - S_size2;
K2 = ceil(S_size_complementary2/2);

BER2 = zeros(1,length(SNR));
BLER2 = zeros(1,length(SNR));

%%%%%%%%%%%%% 第3个bit
h_p3 = -p3*log2(p3) - (1-p3)*log2(1-p3);
S_size3 = ceil(N*(1-h_p3));
S_size_complementary3 = N - S_size3;
K3 = ceil(S_size_complementary3/2);

BER3 = zeros(1,length(SNR));
BLER3 = zeros(1,length(SNR));

%%%%%%%%%%%%% 第4个bit
h_p4 = -p4*log2(p4) - (1-p4)*log2(1-p4);
S_size4 = ceil(N*(1-h_p4));
S_size_complementary4 = N - S_size4;
K4 = ceil(S_size_complementary4/2);

BER4 = zeros(1,length(SNR));
BLER4 = zeros(1,length(SNR));

for i = 1:length(SNR)

    sigma = 10^(-SNR(i)/20);

    channels = GA(sigma,N);
    [~,channels_ordered] = sort(channels,'descend');

    %%%%%%%%%%%%%%%%%%%%%% 第一路 bit：构造 S/I/F 集
    S_bits1 = sort(channels_ordered(1:S_size1),'ascend');
    I_bits1 = sort(channels_ordered(S_size1+1:S_size1+K1),'ascend');
    SandI_bits1 = sort(channels_ordered(1:S_size1+K1),'ascend');
    F_set1 = sort(channels_ordered(S_size1+1+K1:end),'ascend');

    S_set1 = S_bits1;
    I_set1 = I_bits1;
    SandI_set1 = SandI_bits1;

    % 生成 shaping bits（通过 SC_decoder 在“源极化”意义上产生）
    llr1_src = ones(N,1);
    llr1_src(:) = log((1-p1)/p1);

    frozen_bits1 = ones(N,1);
    frozen_bits1(S_set1) = 0;
    shaped_bits1 = SC_decoder(llr1_src, S_size1, frozen_bits1, lambda_offset, llr_layer_vec, bit_layer_vec);

    code1 = zeros(N,1);
    origin_data1 = randsrc(K1,1,[0 1;0.5 0.5]);
    code1(I_set1) = origin_data1;
    code1(S_set1) = shaped_bits1;

    xxx1 = polar_encoder(code1);

    % 用于信道译码（I 与 S 都是“非冻结”）
    frozen_bits1 = ones(N,1);
    frozen_bits1(I_set1) = 0;
    frozen_bits1(S_set1) = 0;

    %%%%%%%%%%%%%%%%%%%%%% 第二路 bit
    S_bits2 = sort(channels_ordered(1:S_size2),'ascend');
    I_bits2 = sort(channels_ordered(S_size2+1:S_size2+K2),'ascend');
    SandI_bits2 = sort(channels_ordered(1:S_size2+K2),'ascend');
    F_set2 = sort(channels_ordered(S_size2+1+K2:end),'ascend');

    S_set2 = S_bits2;
    I_set2 = I_bits2;
    SandI_set2 = SandI_bits2;

    llr2_src = ones(N,1);
    llr2_src(:) = log((1-p2)/p2);

    frozen_bits2 = ones(N,1);
    frozen_bits2(S_set2) = 0;
    shaped_bits2 = SC_decoder(llr2_src, S_size2, frozen_bits2, lambda_offset, llr_layer_vec, bit_layer_vec);

    code2 = zeros(N,1);
    origin_data2 = randsrc(K2,1,[0 1;0.5 0.5]);
    code2(I_set2) = origin_data2;
    code2(S_set2) = shaped_bits2;

    xxx2 = polar_encoder(code2);

    % 修复：这里原来误写成 I_set1/S_set1
    frozen_bits2 = ones(N,1);
    frozen_bits2(I_set2) = 0;
    frozen_bits2(S_set2) = 0;

    %%%%%%%%%%%%%%%%%%%%%% 第三路 bit
    S_bits3 = sort(channels_ordered(1:S_size3),'ascend');
    I_bits3 = sort(channels_ordered(S_size3+1:S_size3+K3),'ascend');
    SandI_bits3 = sort(channels_ordered(1:S_size3+K3),'ascend');
    F_set3 = sort(channels_ordered(S_size3+1+K3:end),'ascend');

    S_set3 = S_bits3;
    I_set3 = I_bits3;
    SandI_set3 = SandI_bits3;

    llr3_src = ones(N,1);
    llr3_src(:) = log((1-p3)/p3);

    frozen_bits3 = ones(N,1);
    frozen_bits3(S_set3) = 0;
    shaped_bits3 = SC_decoder(llr3_src, S_size3, frozen_bits3, lambda_offset, llr_layer_vec, bit_layer_vec);

    code3 = zeros(N,1);
    origin_data3 = randsrc(K3,1,[0 1;0.5 0.5]);
    code3(I_set3) = origin_data3;
    code3(S_set3) = shaped_bits3;

    xxx3 = polar_encoder(code3);

    % 修复：这里原来误写成 I_set1/S_set1
    frozen_bits3 = ones(N,1);
    frozen_bits3(I_set3) = 0;
    frozen_bits3(S_set3) = 0;

    %%%%%%%%%%%%%%%%%%%%%% 第四路 bit
    S_bits4 = sort(channels_ordered(1:S_size4),'ascend');
    I_bits4 = sort(channels_ordered(S_size4+1:S_size4+K4),'ascend');
    SandI_bits4 = sort(channels_ordered(1:S_size4+K4),'ascend');
    F_set4 = sort(channels_ordered(S_size4+1+K4:end),'ascend');

    S_set4 = S_bits4;
    I_set4 = I_bits4;
    SandI_set4 = SandI_bits4;

    llr4_src = ones(N,1);
    llr4_src(:) = log((1-p4)/p4);

    frozen_bits4 = ones(N,1);
    frozen_bits4(S_set4) = 0;
    shaped_bits4 = SC_decoder(llr4_src, S_size4, frozen_bits4, lambda_offset, llr_layer_vec, bit_layer_vec);

    code4 = zeros(N,1);
    origin_data4 = randsrc(K4,1,[0 1;0.5 0.5]);
    code4(I_set4) = origin_data4;
    code4(S_set4) = shaped_bits4;

    xxx4 = polar_encoder(code4);

    % 修复：这里原来误写成 I_set1/S_set1
    frozen_bits4 = ones(N,1);
    frozen_bits4(I_set4) = 0;
    frozen_bits4(S_set4) = 0;

    %%%%%%%%%%%%%%%%%%%%%% 并行转串行：4路拼成 4N bits
    xxx = parallel_to_serial_bits(xxx1, xxx2, xxx3, xxx4);

    %%%%%%%%%%%%%%%%%%%%%% 16QAM 调制
    txSym = qammod(xxx, M, 'gray', ...
                   'InputType','bit', ...
                   'UnitAveragePower', true);

    blenum_sc1 = 0; blenum_sc2 = 0; blenum_sc3 = 0; blenum_sc4 = 0;

    % 互信息累加（每个 SNR 点上，对 i_runs 平均）
    mi1_sum = 0; mi2_sum = 0; mi3_sum = 0; mi4_sum = 0;

    nRuns = 1000;

    for i_runs = 1:nRuns

        spow = sum(abs(txSym).^2) / N;
        sigma_noise = sqrt(spow)*sigma;

        rxSym = txSym + sigma_noise * (randn(N,1) + 1j*randn(N,1));

        LLR_qam = qamdemod(rxSym, M, 'gray', ...
                           'OutputType','llr', ...
                           'UnitAveragePower', true, ...
                           'NoiseVariance', 2*sigma^2);

        %%%%%%%%%%%%%%%%%% 串行转并行（按你当前拼接规则抽取）
        llr1 = LLR_qam(1:4:end);
        llr2 = LLR_qam(2:4:end);
        llr3 = LLR_qam(3:4:end);
        llr4 = LLR_qam(4:4:end);

        %%%%%%%%%%%%%%%%%% 互信息（用“LLR + 真值发送bit”）
        mi1_sum = mi1_sum + mutualinfo_llr(llr1, xxx1);
        mi2_sum = mi2_sum + mutualinfo_llr(llr2, xxx2);
        mi3_sum = mi3_sum + mutualinfo_llr(llr3, xxx3);
        mi4_sum = mi4_sum + mutualinfo_llr(llr4, xxx4);

        %%%%%%%%%%%%%%%%%%%%%%%%%%% 第一路 SC 解码
        SandI1 = SC_decoder(llr1, (K1+S_size1), frozen_bits1, lambda_offset, llr_layer_vec, bit_layer_vec);
        code_hat1 = zeros(N,1);
        code_hat1(SandI_set1) = SandI1;
        polar_info_sc1 = code_hat1(I_set1);

        if any(polar_info_sc1 ~= origin_data1), blenum_sc1 = blenum_sc1 + 1; end
        nfails1 = sum(polar_info_sc1 ~= origin_data1);
        BER1(i) = BER1(i) + nfails1;

        %%%%%%%%%%%%%%%%%%%%%%%%%%% 第二路 SC 解码
        SandI2 = SC_decoder(llr2, (K2+S_size2), frozen_bits2, lambda_offset, llr_layer_vec, bit_layer_vec);
        code_hat2 = zeros(N,1);
        code_hat2(SandI_set2) = SandI2;
        polar_info_sc2 = code_hat2(I_set2);

        if any(polar_info_sc2 ~= origin_data2), blenum_sc2 = blenum_sc2 + 1; end
        nfails2 = sum(polar_info_sc2 ~= origin_data2);
        BER2(i) = BER2(i) + nfails2;

        %%%%%%%%%%%%%%%%%%%%%%%%%%% 第三路 SC 解码
        SandI3 = SC_decoder(llr3, (K3+S_size3), frozen_bits3, lambda_offset, llr_layer_vec, bit_layer_vec);
        code_hat3 = zeros(N,1);
        code_hat3(SandI_set3) = SandI3;
        polar_info_sc3 = code_hat3(I_set3);

        if any(polar_info_sc3 ~= origin_data3), blenum_sc3 = blenum_sc3 + 1; end
        nfails3 = sum(polar_info_sc3 ~= origin_data3);
        BER3(i) = BER3(i) + nfails3;

        %%%%%%%%%%%%%%%%%%%%%%%%%%% 第四路 SC 解码
        SandI4 = SC_decoder(llr4, (K4+S_size4), frozen_bits4, lambda_offset, llr_layer_vec, bit_layer_vec);
        code_hat4 = zeros(N,1);
        code_hat4(SandI_set4) = SandI4;
        polar_info_sc4 = code_hat4(I_set4);

        if any(polar_info_sc4 ~= origin_data4), blenum_sc4 = blenum_sc4 + 1; end
        nfails4 = sum(polar_info_sc4 ~= origin_data4);
        BER4(i) = BER4(i) + nfails4;

    end % i_runs

    %%%%%%%%%%%%%% 平均功率
    energy(i) = spow;

    %%%%%%%%%%%%%% 互信息：对 nRuns 平均
    I1(i) = mi1_sum / nRuns;
    I2(i) = mi2_sum / nRuns;
    I3(i) = mi3_sum / nRuns;
    I4(i) = mi4_sum / nRuns;
    I_total(i) = I1(i) + I2(i) + I3(i) + I4(i);

    %%%%%%%%%%%%%% 计算每一路 BER/BLER（按你原来的方式）
    BER1(i) = BER1(i) / (K1*nRuns);
    BLER1(i) = blenum_sc1 / nRuns;

    BER2(i) = BER2(i) / (K2*nRuns);
    BLER2(i) = blenum_sc2 / nRuns;

    BER3(i) = BER3(i) / (K3*nRuns);
    BLER3(i) = blenum_sc3 / nRuns;

    BER4(i) = BER4(i) / (K4*nRuns);
    BLER4(i) = blenum_sc4 / nRuns;

    %%%%%%%%%%%%%% 对所有四种 bit 位置进行加权
    BER(i) = (K1*BER1(i) + K2*BER2(i) + K3*BER3(i) + K4*BER4(i)) / (K1+K2+K3+K4);
    BLER(i) = (K1*BLER1(i) + K2*BLER2(i) + K3*BLER3(i) + K4*BLER4(i)) / (K1+K2+K3+K4);

end % SNR loop

end % function get_16test


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 子函数：用 LLR + 真值 bit 估计互信息 I(B;L)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function I = mutualinfo_llr(L, x)
% MUTUALINFO_LLR  Estimate mutual information I(B;L) from LLRs and known bits
%
% Inputs:
%   L : real LLR array (vector/matrix)
%   x : corresponding bits (0/1), same number of elements as L
%
% Output:
%   I : estimated MI in bits
%
% Assumption:
%   L is consistent with bit definition (x=0 -> L tends to +, x=1 -> L tends to -),
%   and prior has been included if input is non-uniform.

    L = L(:);
    x = x(:);

    if numel(L) ~= numel(x)
        error('mutualinfo_llr: size mismatch: L and x must have same number of elements.');
    end
    if any(x~=0 & x~=1)
        error('mutualinfo_llr: x must contain only 0/1.');
    end

    s = 1 - 2*x;      % x=0 -> +1, x=1 -> -1
    z = -s .* L;      % z = -sL
    I = 1 - mean(log1p(exp(z))) / log(2);
end
