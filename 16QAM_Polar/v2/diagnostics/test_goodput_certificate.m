function test_goodput_certificate
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
% Independent hand calculation: sample Z=[.1 .2 .3], variance=.01.
[lo,hi,r]=goodput_certificate([.1;.2;.3],zeros(3,1),1,1,1,5,3);
t=log(2/(.05/(124*5*3*2)));
expected=sqrt(2*.01*t/3)+7*1.95*t/6;
assert(abs(r-expected)<1e-12&&lo==-.95&&hi==1);
[lo,hi,r]=goodput_certificate(.2,0,1,1,1,5,3);
assert(lo==-.95&&hi==1&&isinf(r));
G=.4*ones(10000,1);G0=.4*ones(10000,1);
[lo,hi,r]=goodput_certificate(G,G0,1,1,1,5,3);
assert(lo>0&&hi>=lo&&r>0); % Even zero variance retains bounded-tail penalty.
[lo2,hi2,r2]=goodput_certificate(G,G0,1,1,1,10,3);
assert(lo2<=lo&&hi2>=hi&&r2>=r);
[lo,hi]=goodput_certificate(.2*ones(10000,1),G0,1,1,1,5,3);
assert(lo<0&&hi<0);
local_error(@()goodput_certificate(NaN,0,1,1,1,5,3),'certificate:InvalidFrames');
local_error(@()goodput_certificate([0;1],0,1,1,1,5,3),'certificate:InvalidFrames');
local_error(@()goodput_certificate(1.1,0,1,1,1,5,3),'certificate:FrameOutOfRange');
local_error(@()goodput_certificate(0,0,1,1,0,5,3),'certificate:InvalidDesign');
fprintf('goodput_certificate tests passed\n');
end
function local_error(f,id)
caught=false;try,f();catch e,caught=strcmp(e.identifier,id);end
assert(caught,'Expected specific validation failure.');
end
