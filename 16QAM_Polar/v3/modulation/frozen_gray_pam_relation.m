function [T, metadata] = frozen_gray_pam_relation(k)
%FROZEN_GRAY_PAM_RELATION Versioned relations used by the v3 energy family.
    validateattributes(k, {'numeric'}, {'scalar','integer','positive'});
    switch k
        case 1
            T = 1;
            metadata = struct('version', 'pam2-identity-v1-20260903', ...
                'selection', 'unique GL(1,2) relation', ...
                'target_family', 'energy-lambda exact');
        case 2
            T = [1 1; 0 1];
            metadata = struct('version', 'pam4-energy-exact-v1-20260903', ...
                'selection', ['explicit relation: z2 separates inner/outer Gray levels; ' ...
                'z1 remains equiprobable for sign symmetry'], ...
                'target_family', 'energy-lambda exact');
        case 3
            [T, metadata] = frozen_gray_pam8_relation();
        otherwise
            error('v3:AxisOrder', 'Frozen relation supports axis order 1, 2 or 3.');
    end
    gf2_inverse(T);
end
