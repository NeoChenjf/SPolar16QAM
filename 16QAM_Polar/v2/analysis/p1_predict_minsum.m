function prediction=p1_predict_minsum(pmf,sigma,map,state,B,seed,order)
%P1_PREDICT_MINSUM Frozen candidate: product signed-leaf density and SC states.
% Inputs contain no target received frame, truth, first error or measured loss.
% Numerical quadrature atoms are not transmitted communication symbols.
if nargin<7,order=80;end;validateattributes(order,{'numeric'},{'scalar','integer','>=',4});if nargin<5,B=8192;end;if nargin<6,seed=112100004;end
validateattributes(B,{'numeric'},{'scalar','integer','positive'});
assert(numel(pmf)==16 && all(pmf>=0) && abs(sum(pmf)-1)<1e-10);
assert(numel(map)==state.N && all(map>=1) && all(map<=numel(sigma)));
assert(all(isfinite(sigma)) && all(sigma>0));
saved_rng=rng;cleanup=onCleanup(@()rng(saved_rng));rng(seed,'twister');started=tic;
particle=local_density_particles(pmf,sigma,map,B,order);prediction.leaf_seconds=toc(started);prediction.ber_per_stream=zeros(1,4);prediction.genie_per_stream=zeros(1,4);
for b=1:4
F=true(state.N,1);F([state.I{b};state.S{b}])=false;L=reshape(particle(:,b,:),state.N,B);[u,~]=local_sc(L,F);prediction.ber_per_stream(b)=mean(reshape(u(state.I{b},:),[],1));prediction.sc_se_per_stream(b)=std(mean(u(state.I{b},:),1))/sqrt(B);
end
for depth=1:log2(state.N)
half=state.N/2^depth;layer=reshape(particle,2*half,[],B);a=layer(1:half,:,:);c=layer(half+1:end,:,:);particle=reshape(cat(1,sign(a).*sign(c).*min(abs(a),abs(c)),a+c),state.N,4,B);
end
for b=1:4,prediction.genie_per_stream(b)=mean(reshape(particle(state.I{b},b,:)<0,[],1));end
prediction.ber=sum(prediction.ber_per_stream.*state.K)/sum(state.K);prediction.genie=sum(prediction.genie_per_stream.*state.K)/sum(state.K);prediction.seconds=toc(started);prediction.B=B;prediction.seed=seed;prediction.order=order;prediction.status='development_candidate_not_independently_validated';
end
function [u,beta]=local_sc(L,F)
N=size(L,1);if N==1,u=double(L<0);if F,u(:)=0;end;beta=u;return;end
h=N/2;a=L(1:h,:);b=L(h+1:end,:);
[ul,bl]=local_sc(sign(a).*sign(b).*min(abs(a),abs(b)),F(1:h));
[ur,br]=local_sc(b+(1-2*bl).*a,F(h+1:end));u=[ul;ur];beta=[mod(bl+br,2);br];
end


function particle=local_density_particles(pmf,sigma,map,B,order)
% Numerical Gaussian quadrature atoms, not generated communication symbols.
o=order;v=sqrt((1:o-1)/2);[V,D]=eig(diag(v,1)+diag(v,-1));[nodes,id]=sort(diag(D));w=V(1,id).^2;[a,b]=ndgrid(sqrt(2)*nodes,sqrt(2)*nodes);noise=a(:)+1i*b(:);ww=w(:)*w(:)';prob=reshape(ww(:)*pmf(:)',[],1);cdf=cumsum(prob);cdf=cdf/cdf(end);cdf(end)=1;assert(all(diff(cdf)>=0));
symbols=qammod((0:15)',16,'gray','UnitAveragePower',true);labels=de2bi((0:15)',4,'left-msb');bits=kron(labels,ones(o^2,1));particle=zeros(numel(map),4,B);
for k=1:numel(sigma)
Y=noise*sigma(k)+symbols.';d=abs(bsxfun(@minus,Y(:),symbols.')).^2/(2*sigma(k)^2);L=zeros(numel(Y),4);
for bb=1:4
v=-d(:,labels(:,bb)==0);m=max(v,[],2);l0=m+log(sum(exp(v-m),2));v=-d(:,labels(:,bb)==1);m=max(v,[],2);l1=m+log(sum(exp(v-m),2));L(:,bb)=(1-2*bits(:,bb)).*(l0-l1);
end
positions=find(map==k);for i=positions(:)';for bb=1:4;[~,ix]=histc(rand(1,B),[0;cdf]);particle(i,bb,:)=L(ix,bb);end;end
end
end






