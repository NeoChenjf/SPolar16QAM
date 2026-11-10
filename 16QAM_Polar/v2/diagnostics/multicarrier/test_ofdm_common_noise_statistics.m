function test_ofdm_common_noise_statistics()
% Seeded numerical smoke of time, FFT and equalized Gaussian noise scales.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths;
    old=rng; cleanup=onCleanup(@() rng(old)); %#ok<NASGU>
    rng(440917,'twister'); N=64; cp=16; nsym=512; N0=.03; h=[1;.2i;-.1];
    n=randn((N+cp)*nsym+numel(h)-1,1)+1i*randn((N+cp)*nsym+numel(h)-1,1);
    out=ofdm_common_noise_roundtrip(zeros(N,nsym),h,N0,cp,n);
    timepower=mean(abs(out.rx_noisy_serial).^2);
    freqpower=mean(abs(out.rx_grid(:)).^2);
    normalized=bsxfun(@times,out.rx_grid_equalized,abs(out.H_safe));
    eqpower=mean(abs(normalized(:)).^2);
    % For 32768 FFT samples the 5%% tolerance is deliberately wider than sampling error;
    % this is a deterministic seeded smoke, not a formal statistical acceptance rule.
    assert(abs(timepower/N0-1)<.05,'Unexpected time-domain complex noise power.');
    assert(abs(freqpower/(N*N0)-1)<.05,'Unexpected FFT-domain complex noise power.');
    assert(abs(eqpower/(N*N0)-1)<.05,'Unexpected ZF-normalized complex noise power.');
    fprintf('noise ratios time=%.6f fft=%.6f zf_normalized=%.6f\n',timepower/N0,freqpower/(N*N0),eqpower/(N*N0));
end
