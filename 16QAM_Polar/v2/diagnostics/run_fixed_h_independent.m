function run_fixed_h_independent()
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;addpath(fullfile(root,'..','v3','polar'));
out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_fixed_h']);mkdir(out);diary(fullfile(out,'P_log.txt'));started=tic;
source=fullfile(root,'results','20261110_144834_A0_production');N=1024;G=false(N);
for i=0:N-1,for j=0:N-1,G(i+1,j+1)=bitand(uint16(i),uint16(j))==j;end;end
for k=1:N,u=zeros(N,1);u(k)=1;assert(isequal(polar_encoder(u),double(G(k,:))'));end
rng(11010742,'twister');for k=1:8,u=randi([0 1],N,1);assert(isequal(polar_encoder(u),mod(double(G)'*u,2)));end
maxdiff=0;streams=0;files=dir(fullfile(source,'frame_*.mat'));
for j=1:numel(files)
 d=load(fullfile(source,files(j).name));state=d.state;
 for g=1:3
  r=d.records{g};for b=1:4
   F=false(N,1);F(state.F{b})=true;[u,t]=reference(r.L(:,b),F,zeros(N,1));assert(isequal(u,r.decoded(:,b)));maxdiff=max(maxdiff,max(abs(t-r.ordinary_llr(:,b))./(1+abs(t))));
   [u,t]=reference(r.L(:,b),true(N,1),r.u(:,b));assert(isequal(u,r.u(:,b)));maxdiff=max(maxdiff,max(abs(t-r.genie_llr(:,b))./(1+abs(t))));streams=streams+1;
  end
 end
end
assert(maxdiff<=1e-10);elapsed=toc(started);save(fullfile(out,'P_result.mat'),'maxdiff','streams','elapsed','source');fprintf('P independent: %d streams maxdiff %.17g elapsed %.2fs\n',streams,maxdiff,elapsed);diary off;
end
function [u,t,beta]=reference(L,F,truth)
N=numel(L);if N==1,t=L;if F,u=truth;else,u=double(L<0);end;beta=u;return;end
m=N/2;a=L(1:m);b=L(m+1:end);[ul,tl,bl]=reference(sign(a).*sign(b).*min(abs(a),abs(b)),F(1:m),truth(1:m));[ur,tr,br]=reference((1-2*bl).*a+b,F(m+1:end),truth(m+1:end));u=[ul;ur];t=[tl;tr];beta=[mod(bl+br,2);br];
end
