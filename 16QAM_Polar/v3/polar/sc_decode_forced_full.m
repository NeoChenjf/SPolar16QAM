function [u_hat, decision_llr] = sc_decode_forced_full(llr, known_mask, known_bits, prior_llr)
%SC_DECODE_FORCED_FULL SC decoder with arbitrary known u positions.
% Used by v3 shaping: I/F are forced at the precoder, F only at receiver.

    llr = llr(:); known_mask = logical(known_mask(:)); known_bits = known_bits(:);
    N = numel(llr);
    if N < 2 || abs(log2(N) - round(log2(N))) > eps
        error('v3:PolarLength', 'N must be a power of two.');
    end
    if numel(known_mask) ~= N || numel(known_bits) ~= N
        error('v3:ForcedShape', 'known_mask and known_bits must have length N.');
    end
    if any(known_bits ~= 0 & known_bits ~= 1)
        error('v3:ForcedBits', 'known_bits must be binary.');
    end
    if nargin < 4 || isempty(prior_llr), prior_llr = zeros(N, 1); end
    prior_llr = prior_llr(:);
    if numel(prior_llr) ~= N, error('v3:PriorShape', 'prior_llr must have length N.'); end

    n = round(log2(N));
    lambda_offset = 2.^(0:n);
    llr_layer_vec = get_llr_layer(N);
    bit_layer_vec = get_bit_layer(N);
    P = zeros(N - 1, 1); C = zeros(N - 1, 2); u_hat = zeros(N, 1); decision_llr = zeros(N, 1);
    for phi = 0:(N - 1)
        switch phi
            case 0
                index_1 = lambda_offset(n);
                for beta = 0:(index_1 - 1)
                    P(beta + index_1) = sign(llr(beta + 1)) * sign(llr(beta + 1 + index_1)) * ...
                        min(abs(llr(beta + 1)), abs(llr(beta + 1 + index_1)));
                end
                for i_layer = (n - 2):-1:0
                    index_1 = lambda_offset(i_layer + 1); index_2 = lambda_offset(i_layer + 2);
                    for beta = index_1:(index_2 - 1)
                        P(beta) = sign(P(beta + index_1)) * sign(P(beta + index_2)) * ...
                            min(abs(P(beta + index_1)), abs(P(beta + index_2)));
                    end
                end
            case N / 2
                index_1 = lambda_offset(n);
                for beta = 0:(index_1 - 1)
                    P(beta + index_1) = (1 - 2 * C(beta + index_1, 1)) * llr(beta + 1) + llr(beta + 1 + index_1);
                end
                for i_layer = (n - 2):-1:0
                    index_1 = lambda_offset(i_layer + 1); index_2 = lambda_offset(i_layer + 2);
                    for beta = index_1:(index_2 - 1)
                        P(beta) = sign(P(beta + index_1)) * sign(P(beta + index_2)) * ...
                            min(abs(P(beta + index_1)), abs(P(beta + index_2)));
                    end
                end
            otherwise
                llr_layer = llr_layer_vec(phi + 1);
                index_1 = lambda_offset(llr_layer + 1); index_2 = lambda_offset(llr_layer + 2);
                for beta = index_1:(index_2 - 1)
                    P(beta) = (1 - 2 * C(beta, 1)) * P(beta + index_1) + P(beta + index_2);
                end
                for i_layer = (llr_layer - 1):-1:0
                    index_1 = lambda_offset(i_layer + 1); index_2 = lambda_offset(i_layer + 2);
                    for beta = index_1:(index_2 - 1)
                        P(beta) = sign(P(beta + index_1)) * sign(P(beta + index_2)) * ...
                            min(abs(P(beta + index_1)), abs(P(beta + index_2)));
                    end
                end
        end
        phi_mod_2 = mod(phi, 2);
        decision_llr(phi + 1) = P(1) + prior_llr(phi + 1);
        if known_mask(phi + 1)
            decision = known_bits(phi + 1);
        else
            decision = decision_llr(phi + 1) < 0;
        end
        u_hat(phi + 1) = decision;
        C(1, 1 + phi_mod_2) = decision;
        if phi_mod_2 == 1 && phi ~= N - 1
            bit_layer = bit_layer_vec(phi + 1);
            for i_layer = 0:(bit_layer - 1)
                index_1 = lambda_offset(i_layer + 1); index_2 = lambda_offset(i_layer + 2);
                for beta = index_1:(index_2 - 1)
                    C(beta + index_1, 2) = mod(C(beta, 1) + C(beta, 2), 2);
                    C(beta + index_2, 2) = C(beta, 2);
                end
            end
            index_1 = lambda_offset(bit_layer + 1); index_2 = lambda_offset(bit_layer + 2);
            for beta = index_1:(index_2 - 1)
                C(beta + index_1, 1) = mod(C(beta, 1) + C(beta, 2), 2);
                C(beta + index_2, 1) = C(beta, 2);
            end
        end
    end
end
