function out = qamdemod(y, M, varargin)
%QAMDEMOD  (Octave compat) MATLAB-口径一致的 16QAM Gray 解调 / LLR
%
% 仅 16QAM + 'gray'。支持项目用到的两种输出：
%   qamdemod(y,16,'gray','OutputType','llr','UnitAveragePower',tf,'NoiseVariance',nv)
%   qamdemod(y,16,'gray','OutputType','integer'|'bit','UnitAveragePower',tf)
%
% 只在 Octave 下被加入路径（见 setup_paths.m）。MATLAB 下用原生 qamdemod。
%
% LLR 口径直接复用项目纯数学实现 modulation/llr_16qam_gray_LSE.m，
% 与 compat qammod 共用同一套星座，保证 qammod/qamdemod/LLR 三者自洽。
%
% NoiseVariance 约定（同 MATLAB）：复噪声方差 nv，每实维 sigma^2 = nv/2。

    if M ~= 16
        error('qamdemod(compat): 仅支持 M=16');
    end

    mapping = 'gray';
    output_type = 'integer';
    unit_avg = false;
    noise_var = 1;
    k = 1;
    if ~isempty(varargin) && ischar(varargin{1}) && ...
       any(strcmpi(varargin{1}, {'gray','bin'}))
        mapping = lower(varargin{1});
        k = 2;
    end
    while k <= numel(varargin)
        key = varargin{k}; val = varargin{k+1};
        switch lower(key)
            case 'outputtype';       output_type = lower(val);
            case 'unitaveragepower'; unit_avg = logical(val);
            case 'noisevariance';    noise_var = val;
            otherwise
                error('qamdemod(compat): 不支持的参数 %s', key);
        end
        k = k + 2;
    end
    if ~strcmpi(mapping, 'gray')
        error('qamdemod(compat): 仅支持 gray 映射');
    end

    y = y(:);

    if strcmpi(output_type, 'llr')
        % llr_16qam_gray_LSE 内部用 UnitAveragePower=true 的归一化星座，
        % 故归一化坐标下直接传 y，不做反归一化。
        % NoiseVariance nv 为复噪声方差 -> 每实维 sigma^2 = nv/2。
        if ~unit_avg
            % 非归一化输入：换算到归一化坐标，噪声同步缩小
            yv = y / sqrt(10);
            sigma = sqrt((noise_var/10) / 2);
        else
            yv = y;
            sigma = sqrt(noise_var / 2);
        end
        % 返回 log P(b=0)/P(b=1)，bit 序 left-msb，长度 4*Ns
        out = llr_16qam_gray_LSE(yv, sigma);
        return;
    end

    % 硬判决：最近星座点
    const = qammod((0:15).', 16, 'gray', 'UnitAveragePower', unit_avg);  % 16x1
    Ns = numel(y);
    ints = zeros(Ns, 1);
    for n = 1:Ns
        [~, idx] = min(abs(y(n) - const).^2);
        ints(n) = idx - 1;
    end

    switch output_type
        case 'integer'
            out = ints;
        case 'bit'
            bm = zeros(Ns, 4);
            for n = 1:Ns
                bm(n,:) = [bitget(ints(n),4), bitget(ints(n),3), ...
                           bitget(ints(n),2), bitget(ints(n),1)];
            end
            out = reshape(bm.', [], 1);   % left-msb 串行
        otherwise
            error('qamdemod(compat): 不支持的 OutputType %s', output_type);
    end
end
