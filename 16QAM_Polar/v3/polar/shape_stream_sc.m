function [u, x] = shape_stream_sc(payload, stream)
%SHAPE_STREAM_SC Insert payload/F first, then resolve only S with source SC.
    N = stream.S_size + stream.K + stream.F_size;
    payload = payload(:);
    if numel(payload) ~= stream.K || any(payload ~= 0 & payload ~= 1)
        error('v3:PayloadShape', 'payload must be a binary K-vector for this stream.');
    end
    known_mask = false(N, 1); known_bits = zeros(N, 1);
    known_mask(stream.I) = true; known_bits(stream.I) = payload;
    known_mask(stream.F) = true; % frozen value convention is zero.
    source_llr = ones(N, 1) * log((1 - stream.p) / stream.p);
    u = sc_decode_forced_full(source_llr, known_mask, known_bits);
    if any(u(stream.I) ~= payload) || any(u(stream.F) ~= 0)
        error('v3:SCForcedInvariant', 'SC precoder did not preserve I/F constraints.');
    end
    x = polar_encoder(u);
end
