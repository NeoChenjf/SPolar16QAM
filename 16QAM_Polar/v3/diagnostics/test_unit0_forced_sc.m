function test_unit0_forced_sc()
%TEST_UNIT0_FORCED_SC Check message-conditioned S/I/F precoding invariants.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
    N = 32; p = 0.8; stream = build_stream_partition_ga(N, p, 1.0);
    assert(stream.K > 0 && stream.S_size > 0 && stream.F_size > 0);
    payload0 = zeros(stream.K, 1); payload1 = payload0; payload1(1) = 1;
    [u0, x0] = shape_stream_sc(payload0, stream);
    [u1, x1] = shape_stream_sc(payload1, stream);
    assert(all(u0(stream.I) == payload0) && all(u1(stream.I) == payload1));
    assert(all(u0(stream.F) == 0) && all(u1(stream.F) == 0));
    assert(any(u0 ~= u1) && any(x0 ~= x1));
    rx_known_mask = false(N, 1); rx_known_mask(stream.F) = true;
    assert(~any(rx_known_mask(stream.I)) && ~any(rx_known_mask(stream.S)));
    fprintf('[Unit0] forced SC I/F constraints and receiver F-only mask PASS\n');
end
