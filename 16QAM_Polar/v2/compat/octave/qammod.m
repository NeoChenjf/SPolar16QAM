function y = qammod(x, M, varargin)
%QAMMOD  (Octave compat) MATLAB-口径一致的 16QAM Gray 调制
%
% 仅 16QAM + 'gray' 路径，复刻 MATLAB Communications Toolbox 的 qammod：
%   qammod(int, 16, 'gray', 'UnitAveragePower', tf)
%   qammod(bits, 16, 'gray', 'InputType','bit', 'UnitAveragePower', tf)
%
% 本文件只在 Octave 下被加入路径（见 setup_paths.m），MATLAB 下用原生 qammod。
% 目的：Octave communications package 的 qammod 签名与 MATLAB 不兼容
%       （不接受 'gray'/'UnitAveragePower'/'InputType' 等 NV 参数）。
%
% 口径与项目 modulation/llr_16qam_gray_LSE.m 注释一致：
%   - 比特序 left-msb（de2bi(idx,4,'left-msb')）
%   - I 路 = 高 2 bit，Q 路 = 低 2 bit
%   - 每路 2-bit 经 Gray->二进制 解码映到电平 {-3,-1,+1,+3}
%   - UnitAveragePower=true 时整体除以 sqrt(10)

    if M ~= 16
        error('qammod(compat): 仅支持 M=16');
    end

    % --- 解析参数 ---
    mapping = 'gray';
    input_type = 'integer';
    unit_avg = false;
    k = 1;
    % 第一个可选位置参数可能是 mapping 字符串
    if ~isempty(varargin) && ischar(varargin{1}) && ...
       any(strcmpi(varargin{1}, {'gray','bin'}))
        mapping = lower(varargin{1});
        k = 2;
    end
    while k <= numel(varargin)
        key = varargin{k};
        val = varargin{k+1};
        switch lower(key)
            case 'inputtype';      input_type = lower(val);
            case 'unitaveragepower'; unit_avg = logical(val);
            otherwise
                error('qammod(compat): 不支持的参数 %s', key);
        end
        k = k + 2;
    end
    if ~strcmpi(mapping, 'gray')
        error('qammod(compat): 仅支持 gray 映射');
    end

    % --- bit 输入 -> 整数 ---
    if strcmpi(input_type, 'bit')
        b = x(:);
        if mod(numel(b), 4) ~= 0
            error('qammod(compat): bit 输入长度必须是 4 的倍数');
        end
        nb = numel(b) / 4;
        bm = reshape(b, 4, nb).';        % nb x 4，每行 [b3 b2 b1 b0] (left-msb)
        ints = bm * [8;4;2;1];           % left-msb -> 整数
    else
        ints = x(:);
    end

    % --- 整数 -> 星座点 ---
    sym = qam16_gray_symbol(ints);       % 归一化前

    if unit_avg
        sym = sym / sqrt(10);            % 16QAM 平均功率=10
    end

    % 输出形状跟随输入（integer 输入保持原形状；bit 输入返回列向量）
    if strcmpi(input_type, 'bit')
        y = sym;
    else
        y = reshape(sym, size(x));
    end
end

function s = qam16_gray_symbol(ints)
% 整数 0..15 -> 复星座点（归一化前，I/Q ∈ {-3,-1,1,3}）
    ints = ints(:);
    b3 = bitget(ints, 4);   % MSB
    b2 = bitget(ints, 3);
    b1 = bitget(ints, 2);
    b0 = bitget(ints, 1);   % LSB
    I = gray2level(b3, b2); % 高 2 bit -> I
    Q = gray2level(b1, b0); % 低 2 bit -> Q
    s = I + 1j*Q;
end

function lev = gray2level(hi, lo)
% 2-bit Gray (hi=MSB,lo=LSB) -> 电平 {-3,-1,+1,+3}
% Gray 值 g=2*hi+lo (0..3) -> 二进制 0,1,3,2 -> 电平 -3,-1,+3,+1
    g = 2*hi + lo;               % 0..3
    map = [0;1;3;2];             % Gray->binary（2bit）：0->0,1->1,2->3,3->2
    bin = map(g+1);
    lev = 2*bin - 3;             % 0..3 -> -3,-1,1,3
end
