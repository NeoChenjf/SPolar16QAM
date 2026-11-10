function test_ofdm_oversampled_channel()
% Verify integer-delay tap convention against existing linear channel.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    N=16; cp=3; grid=reshape((1:N*3)+1i*(N*3:-1:1),N,3)/48;
    for h={[1], [1;.2+.3i;-.15]}
        base=ofdm_channel_roundtrip(grid,h{1},0,cp,struct());
        for L=[1,2,4]
            rx=ofdm_oversampled_channel(grid,h{1},cp,L);
            assert(numel(rx)==numel(base.rx_signal_serial)*L);
            assert(max(abs(rx(1:L:end)-base.rx_signal_serial))<1e-12);
        end
    end
    fails(@() ofdm_oversampled_channel(grid,[1;2;3;4;5],cp,2),'ofdmoversample:ChannelExceedsCP');
    fails(@() ofdm_oversampled_channel(grid,[1;NaN],cp,2),'ofdmoversample:InvalidChannel');
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
