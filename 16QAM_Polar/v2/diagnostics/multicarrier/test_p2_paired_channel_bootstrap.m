function test_p2_paired_channel_bootstrap()
% Whole-channel paired deltas, RNG isolation, boundary and invalid inputs.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    initial=rng; a=p2_paired_channel_bootstrap([1,2,3],200,19); after=rng;
    assert(isequal(initial,after) && a.channels==3 && a.mean==2);
    b=p2_paired_channel_bootstrap([1,2,3],200,19);
    assert(isequaln(a,b) && a.lower95>=1 && a.upper95<=3 && a.lower95<=a.upper95);
    c=p2_paired_channel_bootstrap(7,200,19);
    assert(strcmp(c.status,'insufficient_channels') && isnan(c.lower95));
    fails(@() p2_paired_channel_bootstrap([1,NaN],200,19),'pairedci:InvalidDelta');
    fails(@() p2_paired_channel_bootstrap([1,2],99,19),'pairedci:InvalidBootstrap');
    fails(@() p2_paired_channel_bootstrap([1,2],200,-1),'pairedci:InvalidSeed');
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
