function test_goodput_betting_certificate
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
[lo,hi]=goodput_betting_certificate([],[],1,1,1,3);
assert(lo==-.95&&hi==1);
n=100;G=.4*ones(n,1);G0=zeros(n,1);
[lo,hi,d]=goodput_betting_certificate(G,G0,1,1,1,3);
% Independent constant-observation closed form at returned roots.
f=[.1 .25 .5 .9];a=-.95;b=1;
lp=n*log1p(f*(.4-lo)/(lo-a));m=max(lp);
assert(abs(m+log(mean(exp(lp-m)))-d.log_threshold)<1e-9);
lm=n*log1p(f*(hi-.4)/(b-hi));m=max(lm);
assert(abs(m+log(mean(exp(lm-m)))-d.log_threshold)<1e-9);
[l2,u2]=goodput_betting_certificate(repmat(G,2,1),repmat(G0,2,1),1,1,1,3);
assert(l2>=lo&&u2<=hi&&l2>0);
[l2,u2]=goodput_betting_certificate(G,G0,1,1,1,6);
assert(l2<=lo&&u2>=hi);
% Reflect Z while swapping design bounds (K'= .95K0, K0'=K/.95).
[lr,ur]=goodput_betting_certificate(.95*G0/2,G/(.95*2),.95,1/.95,2,3);
[ll,uu]=goodput_betting_certificate(G/2,G0/2,1,1,2,3);
assert(abs(lr+uu)<1e-12&&abs(ur+ll)<1e-12);
check(@()goodput_betting_certificate(NaN,0,1,1,1,3),'betting:InvalidFrames');
check(@()goodput_betting_certificate(2,0,1,1,1,3),'betting:FrameOutOfRange');
check(@()goodput_betting_certificate(0,0,1,1,0,3),'betting:InvalidDesign');
fprintf('goodput_betting_certificate tests passed\n');
end
function check(f,id)
caught=false;try,f();catch e,caught=strcmp(e.identifier,id);end
assert(caught,'Expected specific validation failure.');
end
