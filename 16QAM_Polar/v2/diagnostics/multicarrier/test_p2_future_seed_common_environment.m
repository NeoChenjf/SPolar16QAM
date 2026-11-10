function test_p2_future_seed_common_environment()
% Short integration: new candidate keys drive shared physical h and n.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    previous=rng; cleanup=onCleanup(@() rng(previous)); %#ok<NASGU>
    N=64; cp=16; L=16; nsym=4; N0=.003; ch=1; snr=1; frame=1;
    channel_key=p2_future_seed('diagnostic_a',ch,0,0,0,'channel');
    noise_key=p2_future_seed('diagnostic_a',ch,snr,frame,0,'noise');
    rng(channel_key,'twister'); h=(randn(L,1)+1i*randn(L,1))/sqrt(2*L);
    rng(noise_key,'twister'); len=(N+cp)*nsym+L-1; n=randn(len,1)+1i*randn(len,1);
    rng(p2_future_seed('diagnostic_a',ch,snr,frame,1,'payload'),'twister');
    x=2*randi([0 1],N,nsym)-1; y=2*x;
    a=ofdm_common_noise_roundtrip(x,h,N0,cp,n);
    b=ofdm_common_noise_roundtrip(y,h,N0,cp,n);
    err_a=a.rx_noisy_serial-a.rx_signal_serial; err_b=b.rx_noisy_serial-b.rx_signal_serial;
    assert(max(abs(err_a-err_b))<1e-12 && max(abs(err_a-sqrt(N0/2)*n(1:numel(err_a))))<1e-12);
    rng(channel_key,'twister'); h2=(randn(L,1)+1i*randn(L,1))/sqrt(2*L);
    rng(noise_key,'twister'); n2=randn(len,1)+1i*randn(len,1);
    assert(isequal(h,h2) && isequal(n,n2));
    unseen_key=p2_future_seed('diagnostic_b',ch,0,0,0,'channel');
    rng(unseen_key,'twister'); h3=(randn(L,1)+1i*randn(L,1))/sqrt(2*L);
    assert(unseen_key~=channel_key && ~isequal(h,h3));
    fprintf('future-key common channel/noise and split smoke passed\n');
end

