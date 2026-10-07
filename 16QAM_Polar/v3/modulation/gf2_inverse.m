function Tinv = gf2_inverse(T)
%GF2_INVERSE Invert a binary square matrix over GF(2).
    validateattributes(T, {'numeric','logical'}, {'2d','nonempty'});
    [nr, nc] = size(T);
    if nr ~= nc, error('v3:GF2NotSquare', 'GF(2) relation matrix must be square.'); end
    if any(T(:) ~= 0 & T(:) ~= 1), error('v3:GF2NotBinary', 'GF(2) entries must be 0 or 1.'); end
    aug = [mod(double(T), 2), eye(nr)];
    for col = 1:nr
        pivot = find(aug(col:nr, col), 1, 'first');
        if isempty(pivot), error('v3:GF2Singular', 'GF(2) relation matrix is singular.'); end
        pivot = pivot + col - 1;
        if pivot ~= col, tmp = aug(col, :); aug(col, :) = aug(pivot, :); aug(pivot, :) = tmp; end
        for row = 1:nr
            if row ~= col && aug(row, col) == 1
                aug(row, :) = mod(aug(row, :) + aug(col, :), 2);
            end
        end
    end
    Tinv = aug(:, nr + 1:end);
end
