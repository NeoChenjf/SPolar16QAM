function test_ofdm_common_noise_roundtrip()
% Check common physical noise independently of candidate symbol power.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    N=16; cp=3; h=[1;.2i]; grid=ones(N,2); len=(N+cp)*2+numel(h)-1;
    n=(1:len)'/len+1i*(len:-1:1)'/len; N0=.08;
    a=ofdm_common_noise_roundtrip(grid,h,N0,cp,n);
    b=ofdm_common_noise_roundtrip(3*grid,h,N0,cp,n);
    expected=sqrt(N0/2)*n(1:numel(a.tx_serial));
    assert(max(abs(a.rx_noisy_serial-a.rx_signal_serial-expected))<1e-12);
    assert(max(abs((b.rx_noisy_serial-b.rx_signal_serial)-expected))<1e-12);
    assert(abs(a.sigma_noise_freq-sqrt(N*N0/2))<1e-12);
    assert(max(abs(a.sigma_equalized-sqrt(N*N0/2)./abs(a.H_safe)))<1e-12);
    z=ofdm_common_noise_roundtrip(grid,1,0,cp,zeros((N+cp)*2,1));
    assert(max(abs(z.rx_grid_equalized(:)-grid(:)))<1e-12);
    fails(@() ofdm_common_noise_roundtrip(grid,h,-1,cp,n),'commonnoise:InvalidN0');
    fails(@() ofdm_common_noise_roundtrip(grid,h,N0,cp,n(1:end-1)),'commonnoise:InvalidNoise');
    fails(@() ofdm_common_noise_roundtrip(grid,ones(5,1),N0,cp,n),'commonnoise:InvalidCP');
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
