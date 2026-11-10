function verify_fixed_h_boundaries()
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;addpath(fullfile(root,'..','v3','polar'));rng(11010743,'twister');N=1024;maxdiff=0;
for kind=1:4
 L=randn(N,1);if kind==1,L(:)=0;elseif kind==2,L=L*1e-14;elseif kind==3,L=L.*logspace(-8,8,N)';end
 for mask=1:3
 F=false(N,1);if mask==2,F(1:2:end)=true;elseif mask==3,F(1:512)=true;end
 [u,t]=reference(L,F,zeros(N,1));p=SC_decoder(L,sum(~F),double(F),2.^(0:10),get_llr_layer(N),get_bit_layer(N));assert(isequal(u(~F),p));[v,s]=sc_decode_forced_full(L,F,zeros(N,1));assert(isequal(u,v));maxdiff=max(maxdiff,max(abs(t-s)./(1+abs(t))));
 end
end
truth=randi([0 1],N,1);[~,base]=sc_decode_forced_full(L,true(N,1),truth);for k=[1 2 511 512 513 1023 1024],alt=truth;alt(k)=1-alt(k);[~,q]=sc_decode_forced_full(L,true(N,1),alt);assert(isequal(base(1:k),q(1:k)));end
caught=false;try,sc_decode_forced_full(L,true(N-1,1),truth);catch,caught=true;end;assert(caught);assert(maxdiff<=1e-10);fprintf('Synthetic N1024 masks/LLR and representative noninterference passed maxdiff %.17g\n',maxdiff);
end
function [u,t,beta]=reference(L,F,truth)
N=numel(L);if N==1,t=L;if F,u=truth;else,u=double(L<0);end;beta=u;return;end
m=N/2;a=L(1:m);b=L(m+1:end);[ul,tl,bl]=reference(sign(a).*sign(b).*min(abs(a),abs(b)),F(1:m),truth(1:m));[ur,tr,br]=reference((1-2*bl).*a+b,F(m+1:end),truth(m+1:end));u=[ul;ur];t=[tl;tr];beta=[mod(bl+br,2);br];
end
