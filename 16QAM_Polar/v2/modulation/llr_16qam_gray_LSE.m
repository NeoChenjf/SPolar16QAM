function LLR = llr_16qam_gray_LSE(y, sigma)
%LLR_16QAM_GRAY_LSE  Exact MAP (LSE) bit-wise LLR for MATLAB Gray 16QAM
%
%   LLR = llr_16qam_gray_LSE(y, sigma)
%
%   INPUT:
%     y     : received complex symbols (vector)
%     sigma : noise std per real dimension (I/Q), i.e.,
%             nI,nQ ~ N(0, sigma^2)
%
%   OUTPUT:
%     LLR   : column vector of bit LLRs, length = 4*length(y)
%             bit order per symbol follows MATLAB qammod/qamdemod bit order:
%             de2bi(int,4,'left-msb') (same as qammod InputType='bit')
%
%   IMPORTANT:
%     This implementation is CONSISTENT with:
%       qammod(bits,16,'gray','InputType','bit','UnitAveragePower',true)

    y = y(:);
    Ns = length(y);
    LLR = zeros(4*Ns, 1);

    % --- Build MATLAB-consistent Gray 16QAM constellation and bit labels ---
    persistent const labels idx0 idx1
    if isempty(const)
        M = 16;
        % constellation points consistent with MATLAB mapping
        const = qammod((0:M-1).', M, 'gray', 'UnitAveragePower', true);
        % bit labels consistent with qammod/qamdemod bit ordering (left-msb)
        labels = de2bi(0:M-1, 4, 'left-msb');  % size: 16 x 4

        idx0 = cell(1,4);
        idx1 = cell(1,4);
        for b = 1:4
            idx0{b} = find(labels(:,b) == 0);
            idx1{b} = find(labels(:,b) == 1);
        end
    end

    % Complex AWGN: nI,nQ~N(0,sigma^2) => p(y|s) ∝ exp(-|y-s|^2/(2*sigma^2))
    denom = 2*sigma^2;

    for k = 1:Ns
        % distance metrics to all 16 constellation points
        d = abs(y(k) - const).^2 / denom;   % 16x1

        % bit-wise LLR: log P(b=0|y)/P(b=1|y)
        for b = 1:4
            L0 = LSE_neg(d(idx0{b}));
            L1 = LSE_neg(d(idx1{b}));
            LLR(4*(k-1) + b) = L0 - L1;
        end
    end
end

% -------- numerically stable log(sum(exp(-a))) --------
function v = LSE_neg(a)
    amin = min(a);
    v = -amin + log(sum(exp(-(a - amin))));
end
