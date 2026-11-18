function [lower,upper,radius]=goodput_certificate(G,G0,K,K0,D,nlooks,nmethods)
%GOODPUT_CERTIFICATE Simultaneous bounded-frame empirical Bernstein interval.
% For Z=G-.95*G0. Union allocation covers 124 candidates, fixed looks,
% methods and both tails, within ONE fixed H/noise condition. Independent
% paired frames are required; arbitrary repeated peeking is not covered.
% Maurer & Pontil (2009), Theorem 4, arXiv:0907.3740.
if ~(isnumeric(G)&&isnumeric(G0)&&isreal(G)&&isreal(G0)&& ...
        isvector(G)&&isvector(G0)&&numel(G)==numel(G0)&& ...
        all(isfinite(G(:)))&&all(isfinite(G0(:))))
    error('certificate:InvalidFrames','Finite paired real frame vectors required.');
end
design={K,K0,D,nlooks,nmethods};
if ~all(cellfun(@(x)isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x),design))
    error('certificate:InvalidDesign','Finite real scalar design parameters required.');
end
if ~( ...
        K>=0&&K0>=0&&D>0&&K<=D&&K0<=D&& ...
        nlooks>=1&&nlooks==fix(nlooks)&&nmethods>=1&&nmethods==fix(nmethods))
    error('certificate:InvalidDesign','Valid scalar bit counts, denominator and multiplicities required.');
end
if any(G(:)<0|G(:)>K/D)||any(G0(:)<0|G0(:)>K0/D)
    error('certificate:FrameOutOfRange','Frame Goodput exceeds design bounds.');
end
a=-.95*K0/D;b=K/D;n=numel(G);
if n<2,lower=a;upper=b;radius=inf;return,end
Z=G(:)-.95*G0(:);delta=.05/(124*nlooks*nmethods*2);
t=log(2/delta);
radius=sqrt(2*var(Z,0)*t/n)+7*(b-a)*t/(3*(n-1));
lower=max(a,mean(Z)-radius);upper=min(b,mean(Z)+radius);
end
