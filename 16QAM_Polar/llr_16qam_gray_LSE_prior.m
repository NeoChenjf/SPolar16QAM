function LLR = llr_16qam_gray_LSE_prior(y, sigma, psym)
%LLR_16QAM_GRAY_LSE_PRIOR  Exact MAP (LSE) bit-wise LLR with SYMBOL priors
%
%   LLR = llr_16qam_gray_LSE_prior(y, sigma, psym)
%
%   This is the symbol-prior-aware version of llr_16qam_gray_LSE.
%   It computes bit LLRs under arbitrary non-uniform constellation priors
%   P(S = s_m) provided by psym.
%
%   INPUT:
%     y     : received complex symbols (vector)
%     sigma : noise std per real dimension (I/Q), i.e., nI,nQ~N(0,sigma^2)
%     psym  : constellation prior probabilities, length 16.
%             psym(m) corresponds to symbol index (m-1) passed to qammod.
%             Must be non-negative; will be normalized to sum to 1.
%
%   OUTPUT:
%     LLR   : column vector of bit LLRs, length = 4*length(y)
%             bit order per symbol follows MATLAB qammod/qamdemod bit order:
%             de2bi(int,4,'left-msb') (same as qammod InputType='bit')
%
%   IMPORTANT:
%     Mapping is CONSISTENT with:
%       qammod(bits,16,'gray','InputType','bit','UnitAveragePower',true)

    y = y(:);
    Ns = length(y);
    LLR = zeros(4*Ns, 1);

    if numel(psym) ~= 16
        error('psym must have length 16 for 16QAM.');
    end
    psym = psym(:);
    if any(psym < 0)
        error('psym must be non-negative.');
    end
    s = sum(psym);
    if s <= 0
        error('psym must have at least one positive entry.');
    end
    psym = psym / s;

    % --- Build MATLAB-consistent Gray 16QAM constellation and bit labels ---
    persistent const labels idx0 idx1
    if isempty(const)
        M = 16;
        const = qammod((0:M-1).', M, 'gray', 'UnitAveragePower', true);
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
    logps = log(max(psym, realmin));

    for k = 1:Ns
        d = abs(y(k) - const).^2 / denom;   % 16x1

        for b = 1:4
            % LLR = log( sum_{s in Sk0} P(s) exp(-d(s)) ) - log( sum_{s in Sk1} P(s) exp(-d(s)) )
            L0 = LSE_logw_neg(d(idx0{b}), logps(idx0{b}));
            L1 = LSE_logw_neg(d(idx1{b}), logps(idx1{b}));
            LLR(4*(k-1) + b) = L0 - L1;
        end
    end
end

% -------- numerically stable log(sum(exp(logw - a))) --------
function v = LSE_logw_neg(a, logw)
    % compute log( sum_i exp(logw_i - a_i) ) stably
    t = logw - a;
    tmax = max(t);
    v = tmax + log(sum(exp(t - tmax)));
end
