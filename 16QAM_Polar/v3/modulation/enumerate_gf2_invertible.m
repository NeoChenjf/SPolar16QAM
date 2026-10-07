function candidates = enumerate_gf2_invertible(k)
%ENUMERATE_GF2_INVERTIBLE All GL(k,2) matrices for k<=3, mask order.
    validateattributes(k, {'numeric'}, {'scalar','integer','>=',1,'<=',3});
    candidates = {};
    for mask = 0:(2^(k*k) - 1)
        bits = bitget(uint16(mask), 1:(k*k));
        % bitget returns uint16; v3 GF(2) matrix algebra uses double.
        T = double(reshape(bits, k, k).');
        try
            gf2_inverse(T);
            candidates{end + 1, 1} = T; %#ok<AGROW>
        catch err
            if ~strcmp(err.identifier, 'v3:GF2Singular'), rethrow(err); end
        end
    end
end
