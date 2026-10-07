function reliability = bsc_bhattacharyya(q, N)
%BSC_BHATTACHARYYA Polar BSC reliability proxy; larger is more reliable.
    validateattributes(q, {'numeric'}, {'scalar','real','finite','>=',0,'<=',0.5});
    validateattributes(N, {'numeric'}, {'scalar','integer','>=',2});
    if abs(log2(N) - round(log2(N))) > eps
        error('v3:PolarLength', 'N must be a power of two.');
    end
    z = 2 * sqrt(q * (1 - q));
    values = z;
    for stage = 1:round(log2(N))
        old = values; values = zeros(1, 2 * numel(old));
        values(1:2:end) = min(1, 2 * old - old.^2); % W^- upper bound
        values(2:2:end) = old.^2;                    % W^+ exact
    end
    values = bitrevorder(values);
    reliability = -values(:); % smaller Bhattacharyya parameter is better
end
