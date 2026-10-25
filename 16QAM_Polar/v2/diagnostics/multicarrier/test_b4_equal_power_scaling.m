%% TEST_B4_EQUAL_POWER_SCALING Power/LLR scaling contract checks.
script_dir=fileparts(mfilename('fullpath')); v2_root=fullfile(script_dir,'..','..'); addpath(v2_root); setup_paths();
rng(91,'twister'); n=64; cp=16; h=[1;0.2+0.1j;-0.08j]; h=h/norm(h);
tx=(randn(n,3)+1j*randn(n,3))/sqrt(2); sigma=0.17; alpha=0.73;
noiseLen=(n+cp)*size(tx,2)+numel(h)-1; noise=randn(noiseLen,1)+1j*randn(noiseLen,1); opts=struct('noise_unit',noise);
a=ofdm_channel_roundtrip(tx,h,sigma,cp,opts); b=ofdm_channel_roundtrip(alpha*tx,h,sigma,cp,opts);
assert(max(abs(b.rx_signal_serial-alpha*a.rx_signal_serial))<1e-11,'Signal path did not follow TX amplitude scaling.');
na=a.rx_noisy_serial-a.rx_signal_serial; nb=b.rx_noisy_serial-b.rx_signal_serial;
assert(max(abs(nb-na))<1e-12,'Fixed physical noise changed when TX scale changed.');
assert(abs(a.sigma_equalized(10)-b.sigma_equalized(10))<1e-14,'Noise variance must stay fixed across TX strategies.');
% The channel helper expects post-FFT sigma, so compensate its 1/sqrt(N) conversion
% to achieve the requested serialized time-domain complex noise power N0.
targetPower=1; snrDb=20; n0=targetPower/10^(snrDb/10);
sigmaFreq=sqrt(n*n0/2); txLong=zeros(n,500); noiseLong=randn((n+cp)*500+numel(h)-1,1)+1j*randn((n+cp)*500+numel(h)-1,1);
noiseResult=ofdm_channel_roundtrip(txLong,h,sigmaFreq,cp,struct('noise_unit',noiseLong));
observedNoise= noiseResult.rx_noisy_serial-noiseResult.rx_signal_serial;
assert(abs(mean(abs(observedNoise).^2)/n0-1)<0.02,'Time-domain complex noise power does not match the requested SNR definition.');
% Direct full-constellation likelihood reference and scale invariance when both observation and sigma are scaled.
y=0.21-0.37j; s=0.31; points=qammod((0:15).',16,'gray','UnitAveragePower',true); labels=de2bi(0:15,4,'left-msb');
llr=llr_16qam_gray_LSE(y,s); ref=zeros(4,1);
for bit=1:4
    d=abs(y-points).^2/(2*s^2); ref(bit)=lse(-d(labels(:,bit)==0))-lse(-d(labels(:,bit)==1));
end
assert(max(abs(llr-ref))<1e-10,'LLR disagrees with direct likelihood reference.');
scaled=llr_16qam_gray_LSE(alpha*y,alpha*s,alpha);
assert(max(abs(llr-scaled))<1e-10,'Joint scaling of observation and sigma changed the LLR.');
scaledFixedNoise=llr_16qam_gray_LSE(alpha*y,s,alpha); ds=abs(alpha*y-alpha*points).^2/(2*s^2); refScaled=zeros(4,1);
for bit=1:4, refScaled(bit)=lse(-ds(labels(:,bit)==0))-lse(-ds(labels(:,bit)==1)); end
assert(max(abs(scaledFixedNoise-refScaled))<1e-10,'Scaled constellation LLR disagrees with direct fixed-noise likelihood.');
fprintf('test_b4_equal_power_scaling: PASS\n');
function out=lse(x), m=max(x); out=m+log(sum(exp(x-m))); end
