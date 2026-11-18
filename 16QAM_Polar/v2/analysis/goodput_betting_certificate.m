function [lower,upper,detail]=goodput_betting_certificate(G,G0,K,K0,D,nmethods)
%GOODPUT_BETTING_CERTIFICATE Fixed-mixture bounded-mean confidence sequence.
% Independent paired frames of Z=G-.95G0, conditional on fixed H/noise.
% For fixed mu, each positive-direction factor is nonnegative and has
% conditional expectation <=1 under E[Z|past]<=mu; negative reverses it.
% At the true iid mean both wealth mixtures are nonnegative martingales.
% Ville + union bound over 124 candidates, methods and two tails gives
% simultaneous anytime coverage. Fractions are fixed before observations.
% Wealth is monotone in mu in the required direction, so inversion gives
% an interval; no look-count adjustment or fitted variance is used.
design={K,K0,D,nmethods};
if ~all(cellfun(@(x)isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x),design))|| ...
        K<0||K0<0||D<=0||K>D||K0>D||nmethods<1||nmethods~=fix(nmethods)
    error('betting:InvalidDesign','Valid finite scalar design parameters required.');
end
if ~(isnumeric(G)&&isnumeric(G0)&&isreal(G)&&isreal(G0)&& ...
        (isvector(G)||isempty(G))&&(isvector(G0)||isempty(G0))&& ...
        numel(G)==numel(G0)&&all(isfinite(G(:)))&&all(isfinite(G0(:))))
    error('betting:InvalidFrames','Finite paired real vectors required.');
end
if any(G(:)<0|G(:)>K/D)||any(G0(:)<0|G0(:)>K0/D)
    error('betting:FrameOutOfRange','Frame Goodput exceeds design bounds.');
end
a=-.95*K0/D;b=K/D;Z=G(:)-.95*G0(:);
fractions=[.1 .25 .5 .9];threshold=log(124*nmethods*2/.05);
detail=struct('fractions',fractions,'log_threshold',threshold,'n',numel(Z));
lower=a;upper=b;if isempty(Z)||a==b,return,end
% Interior evaluations avoid singular denominators at the theoretical ends.
l=a;r=b;
for k=1:64
    mu=l+(r-l)/2;if mu==a||mu==b,break,end
    if wealth(Z,mu,a,b,fractions,1)>=threshold,l=mu;else,r=mu;end
end
lower=l;
l=a;r=b;
for k=1:64
    mu=l+(r-l)/2;if mu==a||mu==b,break,end
    if wealth(Z,mu,a,b,fractions,-1)>=threshold,r=mu;else,l=mu;end
end
upper=r;
end
function v=wealth(Z,mu,a,b,f,side)
if side==1,x=(Z-mu)/(mu-a);else,x=(mu-Z)/(b-mu);end
s=sum(log1p(x*f),1);m=max(s);v=m+log(mean(exp(s-m)));
end
