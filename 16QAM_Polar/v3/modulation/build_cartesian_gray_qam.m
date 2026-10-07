function qam = build_cartesian_gray_qam(M)
%BUILD_CARTESIAN_GRAY_QAM Canonical rectangular Gray-QAM constellation.
% Labels are [I-axis MSB..LSB, Q-axis MSB..LSB], with levels ascending.
    validateattributes(M, {'numeric'}, {'scalar','real','finite','integer','positive'});
    m = log2(M);
    if abs(m - round(m)) > eps || ~ismember(M, [8 16 32 64])
        error('v3:UnsupportedM', 'v3 Unit 0 supports M in {8,16,32,64}.');
    end
    m = round(m); mI = ceil(m / 2); mQ = floor(m / 2);
    MI = 2^mI; MQ = 2^mQ;
    [aI, labelI] = local_gray_pam(MI);
    [aQ, labelQ] = local_gray_pam(MQ);
    rawI = repelem(aI, MQ, 1);
    rawQ = repmat(aQ, MI, 1);
    labels = [repelem(labelI, MQ, 1), repmat(labelQ, MI, 1)];
    raw_constellation = rawI + 1i * rawQ;
    uniform_scale = sqrt(mean(abs(raw_constellation).^2));
    qam = struct('M', M, 'm', m, 'MI', MI, 'MQ', MQ, 'mI', mI, 'mQ', mQ, ...
        'levelsI', aI, 'levelsQ', aQ, 'labelsI', labelI, 'labelsQ', labelQ, ...
        'rawI', rawI, 'rawQ', rawQ, 'raw_constellation', raw_constellation, ...
        'uniform_scale', uniform_scale, 'constellation', raw_constellation / uniform_scale, ...
        'labels', labels);
end

function [levels, labels] = local_gray_pam(L)
    k = round(log2(L));
    levels = (-(L - 1):2:(L - 1)).';
    labels = zeros(L, k);
    for n = 0:(L - 1)
        g = bitxor(uint16(n), bitshift(uint16(n), -1));
        for b = 1:k
            labels(n + 1, b) = bitget(g, k - b + 1);
        end
    end
end
