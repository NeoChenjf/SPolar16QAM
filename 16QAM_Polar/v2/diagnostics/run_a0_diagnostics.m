function run_a0_diagnostics()
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setup_paths;
addpath(fullfile(fileparts(root),'v3','polar'));
out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_A0']); mkdir(out); diary(fullfile(out,'run_log.txt'));
rng(11010071,'twister'); report=struct; report.seed=11010071; report.frames=0; report.symbols=0;
save(fullfile(out,'checkpoint.mat'),'report');
try
G=1; for j=1:3, G=kron(G,[1 0;1 1]); end
for j=0:255, u=double(bitget(uint16(j),1:8))'; assert(isequal(polar_encoder(u),mod(G'*u,2))); end
report.T1_small=true;
labels=de2bi((0:15)',4,'left-msb'); c=qammod((0:15)',16,'gray','UnitAveragePower',true);
bits=parallel_to_serial_bits(labels(:,1),labels(:,2),labels(:,3),labels(:,4)); assert(isequal(qammod(bits,16,'gray','InputType','bit','UnitAveragePower',true),c));
report.mapping=true;
maxdiff=0;
for N=[8 16]
 for j=1:64
  L=randn(N,1)*10; if j==1,L(:)=0; elseif j==2,L(1:2:end)=1e-14; end
  for mask=1:3
   F=false(N,1); if mask==2,F(1:2:end)=true; elseif mask==3,F(1:floor(N/2))=true; end
   [u,t]=rec(L,F,zeros(N,1));
   p=SC_decoder(L,sum(~F),double(F),2.^(0:log2(N)),get_llr_layer(N),get_bit_layer(N)); assert(isequal(p,u(~F)));
   [v,s]=sc_decode_forced_full(L,F,zeros(N,1)); assert(isequal(u,v)); maxdiff=max(maxdiff,max(abs(t-s)./(1+abs(t))));
   truth=randi([0 1],N,1); [v,s]=sc_decode_forced_full(L,true(N,1),truth); assert(isequal(v,truth));
   k=ceil(N/2); alt=truth; alt(k)=1-alt(k); [~,s2]=sc_decode_forced_full(L,true(N,1),alt); assert(s(k)==s2(k));
  end
 end
end
assert(maxdiff<=1e-10); report.T3_maxdiff=maxdiff; report.T4_small=true;
y=[c; .13+.27i; -2+.7i]; sig=linspace(.1,1,numel(y))'; md=0;
for a=[1 .7]
 actual=reshape(llr_16qam_gray_LSE(y,sig,a),4,[])'; expected=zeros(size(actual));
 for k=1:numel(y)
  w=-abs(y(k)-a*c).^2/(2*sig(k)^2); w=w-max(w); w=exp(w);
  for b=1:4,expected(k,b)=log(sum(w(labels(:,b)==0)))-log(sum(w(labels(:,b)==1)));end
 end
 md=max(md,max(abs(actual(:)-expected(:))./(1+abs(expected(:)))));
end
assert(md<=1e-10); report.T2_llr=md;
test_ofdm_common_noise_roundtrip; report.T2_existing=true;
save(fullfile(out,'checkpoint.mat'),'report');
catch e
 report.failure=getReport(e,'extended','hyperlinks','off'); save(fullfile(out,'checkpoint.mat'),'report'); fprintf('%s\n',report.failure);
end
disp(report); diary off;
end
function [u,t,beta]=rec(L,F,truth)
N=numel(L);
if N==1
 t=L; if F,u=truth; else,u=double(L<0);end; beta=u; return
end
m=N/2; a=L(1:m); b=L(m+1:end);
[ul,tl,bl]=rec(sign(a).*sign(b).*min(abs(a),abs(b)),F(1:m),truth(1:m));
[ur,tr,br]=rec((1-2*bl).*a+b,F(m+1:end),truth(m+1:end));
u=[ul;ur];t=[tl;tr];beta=[mod(bl+br,2);br];
end
