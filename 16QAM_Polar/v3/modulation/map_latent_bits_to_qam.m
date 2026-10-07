function [tx, label_bits, symbol_index] = map_latent_bits_to_qam(z_bits, qam, model)
%MAP_LATENT_BITS_TO_QAM Map N-by-m latent bits through b=Tz to QAM points.
% z_bits uses the canonical stream order [I latent bits, Q latent bits].
    if size(z_bits, 2) ~= qam.m
        error('v3:LatentBitShape', 'z_bits must have m=log2(M) columns.');
    end
    if any(z_bits(:) ~= 0 & z_bits(:) ~= 1)
        error('v3:LatentBits', 'z_bits must be binary.');
    end
    z_bits = mod(double(z_bits), 2);
    bI = mod(model.TI * z_bits(:, 1:qam.mI).', 2).';
    bQ = mod(model.TQ * z_bits(:, qam.mI+1:end).', 2).';
    label_bits = [bI bQ];
    [is_member, symbol_index] = ismember(label_bits, qam.labels, 'rows');
    if ~all(is_member)
        error('v3:LabelLookup', 'Transformed labels must map to canonical constellation rows.');
    end
    tx = qam.constellation(symbol_index);
end
