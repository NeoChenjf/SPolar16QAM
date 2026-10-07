function test_unit0_bsc_ga_partition()
%TEST_UNIT0_BSC_GA_PARTITION S is BSC-based and symmetric under p <-> 1-p.
    root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
    for p = [0.6 0.75 0.9]
        a = build_stream_partition_bsc_ga(64, p, 1.0);
        b = build_stream_partition_bsc_ga(64, 1-p, 1.0);
        assert(isequal(a.S, b.S));
        assert(numel(unique([a.S; a.I; a.F])) == 64);
        assert(isempty(intersect(a.S, a.I)) && isempty(intersect(a.S, a.F)) && isempty(intersect(a.I, a.F)));
        fprintf('[Unit0] BSC+GA p=%.2f / %.2f partition PASS\n', p, 1-p);
    end
end
