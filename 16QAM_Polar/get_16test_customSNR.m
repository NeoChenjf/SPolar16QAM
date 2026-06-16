function [BER, BLER, spow] = get_16test_customSNR(p, SNR)
% GET_16TEST_CUSTOMSNR - 16QAM Gray shaped polar test with custom SNR vector
% Usage:
%   [BER, BLER, spow] = get_16test_customSNR(p, SNR)
% Inputs:
%   p   - shaping parameter for bit-2 and bit-4
%   SNR - vector of SNR values (dB)
% Outputs:
%   BER  - bit error rate per SNR
%   BLER - block error rate per SNR
%   spow - average symbol power per SNR

SNR = SNR(:).'; % ensure row vector

% shaping parameters
p1 = 0.5;
p2 = p;
p3 = 0.5;
p4 = p;

N = 1024;
M = 16;

lambda_offset = 2.^(0:log2(N));
llr_layer_vec = get_llr_layer(N);
bit_layer_vec = get_bit_layer(N);

BER = zeros(1, length(SNR));
BLER = zeros(1, length(SNR));
energy = zeros(1, length(SNR));

% bit-1
h_p1 = (-p1*log2(p1) + (-(1-p1)*log2(1-p1)));
S_size1 = ceil(N*(1-h_p1));
S_size_complementary1 = N-S_size1;
K1 = ceil(S_size_complementary1/2);
BER1 = zeros(1,length(SNR));
BLER1 = zeros(1,length(SNR));

% bit-2
h_p2 = (-p2*log2(p2) + (-(1-p2)*log2(1-p2)));
S_size2 = ceil(N*(1-h_p2));
S_size_complementary2 = N-S_size2;
K2 = ceil(S_size_complementary2/2);
BER2 = zeros(1,length(SNR));
BLER2 = zeros(1,length(SNR));

% bit-3
h_p3 = (-p3*log2(p3) + (-(1-p3)*log2(1-p3)));
S_size3 = ceil(N*(1-h_p3));
S_size_complementary3 = N-S_size3;
K3 = ceil(S_size_complementary3/2);
BER3 = zeros(1,length(SNR));
BLER3 = zeros(1,length(SNR));

% bit-4
h_p4 = (-p4*log2(p4) + (-(1-p4)*log2(1-p4)));
S_size4 = ceil(N*(1-h_p4));
S_size_complementary4 = N-S_size4;
K4 = ceil(S_size_complementary4/2);
BER4 = zeros(1,length(SNR));
BLER4 = zeros(1,length(SNR));

for i = 1:length(SNR)
    sigma = 10^(-SNR(i)/20);
    channels = GA(sigma,N);
    [~,channels_ordered] = sort(channels,'descend');

    % bit-1 sets
    S_bits1 = sort(channels_ordered(1:S_size1),'ascend');
    I_bits1 = sort(channels_ordered(S_size1+1:S_size1+K1),'ascend');
    SandI_bits1 = sort(channels_ordered(1:S_size1+K1),'ascend');
    F_set1 = sort(channels_ordered(S_size1+1+K1:end),'ascend');
    F_bits1 = ones(S_size_complementary1,1);
    F_bits1(I_bits1)=0;
    logic1 = mod(F_bits1+1,2);
    I_bits_logical1 = logical(logic1);
    u1 = zeros(S_size_complementary1,1);

    S_set1 = S_bits1;
    I_set1 = I_bits1;
    F_set1 = F_set1;
    SandI_set1 = SandI_bits1;

    c = zeros(N,1);
    llr1 = ones(N,1);
    lls1 = log((1-p1)/p1);
    llr1(llr1==1)=lls1;

    frozen_bits1 = ones(N,1);
    frozen_bits1(S_set1)=0;
    shaped_bits1 = SC_decoder(llr1, S_size1, frozen_bits1, lambda_offset, llr_layer_vec, bit_layer_vec);
    code1=zeros(N,1);
    origin_data1=randsrc(K1,1,[0 1;0.5 0.5]);
    code1(I_set1)=origin_data1;
    code1(S_set1)=shaped_bits1;
    xxx1=polar_encoder(code1);

    frozen_bits1=ones(N,1);
    frozen_bits1(I_set1)=0;
    frozen_bits1(S_set1)=0;

    % bit-2 sets
    S_bits2=sort(channels_ordered(1:S_size2),'ascend');
    I_bits2=sort(channels_ordered(S_size2+1:S_size2+K2),'ascend');
    SandI_bits2=sort(channels_ordered(1:S_size2+K2),'ascend');
    F_set2=sort(channels_ordered(S_size2+1+K2:end),'ascend');
    F_bits2=ones(S_size_complementary2,1);
    F_bits2(I_bits2)=0;
    logic2=mod(F_bits2+1,2);
    I_bits_logical2=logical(logic2);
    u2=zeros(S_size_complementary2,1);

    S_set2=S_bits2;
    I_set2=I_bits2;
    F_set2=F_set2;
    SandI_set2=SandI_bits2;

    c=zeros(N,1);
    llr2=ones(N,1);
    lls2=log((1-p2)/p2);
    llr2(llr2==1)=lls2;

    frozen_bits2=ones(N,1);
    frozen_bits2(S_set2)=0;
    shaped_bits2 = SC_decoder(llr2, S_size2, frozen_bits2, lambda_offset, llr_layer_vec, bit_layer_vec);
    code2=zeros(N,1);
    origin_data2=randsrc(K2,1,[0 1;0.5 0.5]);
    code2(I_set2)=origin_data2;
    code2(S_set2)=shaped_bits2;
    xxx2=polar_encoder(code2);

    frozen_bits2=ones(N,1);
    frozen_bits2(I_set2)=0;
    frozen_bits2(S_set2)=0;

    % bit-3 sets
    S_bits3=sort(channels_ordered(1:S_size3),'ascend');
    I_bits3=sort(channels_ordered(S_size3+1:S_size3+K3),'ascend');
    SandI_bits3=sort(channels_ordered(1:S_size3+K3),'ascend');
    F_set3=sort(channels_ordered(S_size3+1+K3:end),'ascend');
    F_bits3=ones(S_size_complementary3,1);
    F_bits3(I_bits3)=0;
    logic3=mod(F_bits3+1,2);
    I_bits_logical3=logical(logic3);
    u3=zeros(S_size_complementary3,1);

    S_set3=S_bits3;
    I_set3=I_bits3;
    F_set3=F_set3;
    SandI_set3=SandI_bits3;

    c=zeros(N,1);
    llr3=ones(N,1);
    lls3=log((1-p3)/p3);
    llr3(llr3==1)=lls3;

    frozen_bits3=ones(N,1);
    frozen_bits3(S_set3)=0;
    shaped_bits3 = SC_decoder(llr3, S_size3, frozen_bits3, lambda_offset, llr_layer_vec, bit_layer_vec);
    code3=zeros(N,1);
    origin_data3=randsrc(K3,1,[0 1;0.5 0.5]);
    code3(I_set3)=origin_data3;
    code3(S_set3)=shaped_bits3;
    xxx3=polar_encoder(code3);

    frozen_bits3=ones(N,1);
    frozen_bits3(I_set3)=0;
    frozen_bits3(S_set3)=0;

    % bit-4 sets
    S_bits4=sort(channels_ordered(1:S_size4),'ascend');
    I_bits4=sort(channels_ordered(S_size4+1:S_size4+K4),'ascend');
    SandI_bits4=sort(channels_ordered(1:S_size4+K4),'ascend');
    F_set4=sort(channels_ordered(S_size4+1+K4:end),'ascend');
    F_bits4=ones(S_size_complementary4,1);
    F_bits4(I_bits4)=0;
    logic4=mod(F_bits4+1,2);
    I_bits_logical4=logical(logic4);
    u4=zeros(S_size_complementary4,1);

    S_set4=S_bits4;
    I_set4=I_bits4;
    F_set4=F_set4;
    SandI_set4=SandI_bits4;

    c=zeros(N,1);
    llr4=ones(N,1);
    lls4=log((1-p4)/p4);
    llr4(llr4==1)=lls4;

    frozen_bits4=ones(N,1);
    frozen_bits4(S_set4)=0;
    shaped_bits4 = SC_decoder(llr4, S_size4, frozen_bits4, lambda_offset, llr_layer_vec, bit_layer_vec);
    code4=zeros(N,1);
    origin_data4=randsrc(K4,1,[0 1;0.5 0.5]);
    code4(I_set4)=origin_data4;
    code4(S_set4)=shaped_bits4;
    xxx4=polar_encoder(code4);

    frozen_bits4=ones(N,1);
    frozen_bits4(I_set4)=0;
    frozen_bits4(S_set4)=0;

    xxx = parallel_to_serial_bits(xxx1, xxx2, xxx3, xxx4);

    txSym = qammod(xxx, M, 'gray', ...
                   'InputType','bit', ...
                   'UnitAveragePower', true);

    blenum_sc1=0;
    blenum_sc2=0;
    blenum_sc3=0;
    blenum_sc4=0;

    for i_runs=1:1000
        spow = sum(abs(txSym).^2) / N;
        sigma_noise = sqrt(spow)*sigma;
        rxSym = txSym + sigma_noise * (randn(N, 1) + 1j * randn(N, 1));

        LLR_qam = qamdemod(rxSym, M, 'gray', ...
                   'OutputType','llr', ...
                   'UnitAveragePower', true, ...
                   'NoiseVariance', 2*sigma^2);

        llr1 = LLR_qam(1:4:end);
        llr2 = LLR_qam(2:4:end);
        llr3 = LLR_qam(3:4:end);
        llr4 = LLR_qam(4:4:end);

        SandI1=SC_decoder(llr1,(K1+S_size1),frozen_bits1,lambda_offset, llr_layer_vec, bit_layer_vec);
        code_hat1=zeros(N,1);
        code_hat1(SandI_set1)=SandI1;
        polar_info_sc1=code_hat1(I_set1);
        if any(polar_info_sc1~=origin_data1)
            blenum_sc1=blenum_sc1+1;
        end
        nfails1=sum(polar_info_sc1~=origin_data1);
        BER1(i)=BER1(i)+nfails1;

        SandI2 = SC_decoder(llr2, (K2 + S_size2), frozen_bits2, lambda_offset, llr_layer_vec, bit_layer_vec);
        code_hat2 = zeros(N, 1);
        code_hat2(SandI_set2) = SandI2;
        polar_info_sc2 = code_hat2(I_set2);
        if any(polar_info_sc2 ~= origin_data2)
            blenum_sc2 = blenum_sc2 + 1;
        end
        nfails2 = sum(polar_info_sc2 ~= origin_data2);
        BER2(i) = BER2(i) + nfails2;

        SandI3 = SC_decoder(llr3, (K3 + S_size3), frozen_bits3, lambda_offset, llr_layer_vec, bit_layer_vec);
        code_hat3 = zeros(N, 1);
        code_hat3(SandI_set3) = SandI3;
        polar_info_sc3 = code_hat3(I_set3);
        if any(polar_info_sc3 ~= origin_data3)
            blenum_sc3 = blenum_sc3 + 1;
        end
        nfails3 = sum(polar_info_sc3 ~= origin_data3);
        BER3(i) = BER3(i) + nfails3;

        SandI4 = SC_decoder(llr4, (K4 + S_size4), frozen_bits4, lambda_offset, llr_layer_vec, bit_layer_vec);
        code_hat4 = zeros(N, 1);
        code_hat4(SandI_set4) = SandI4;
        polar_info_sc4 = code_hat4(I_set4);
        if any(polar_info_sc4 ~= origin_data4)
            blenum_sc4 = blenum_sc4 + 1;
        end
        nfails4 = sum(polar_info_sc4 ~= origin_data4);
        BER4(i) = BER4(i) + nfails4;
    end

    energy(i)=spow;

    BER1(i)=BER1(i)/(K1*1000);
    BLER1(i)=BLER1(i)+blenum_sc1;
    BLER1(i)=BLER1(i)/1000;

    BER2(i) = BER2(i) / (K2 * 1000);
    BLER2(i) = BLER2(i) + blenum_sc2;
    BLER2(i) = BLER2(i) / 1000;

    BER3(i) = BER3(i) / (K3 * 1000);
    BLER3(i) = BLER3(i) + blenum_sc3;
    BLER3(i) = BLER3(i) / 1000;

    BER4(i) = BER4(i) / (K4 * 1000);
    BLER4(i) = BLER4(i) + blenum_sc4;
    BLER4(i) = BLER4(i) / 1000;

    BER(i) = (K1 * BER1(i) + K2 * BER2(i) + K3 * BER3(i) + K4 * BER4(i)) / (K1 + K2 + K3 + K4);
    BLER(i) = (K1 * BLER1(i) + K2 * BLER2(i) + K3 * BLER3(i) + K4 * BLER4(i)) / (K1 + K2 + K3 + K4);
end

spow = energy;
end
