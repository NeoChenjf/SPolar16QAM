function analyze_p1_reliability(run_dir)
% One independent-marginal min-sum particle reference; diagnostic, not online.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths; started=tic;rng(112100001,'twister');
if strcmp(run_dir,'test');rng(112100002);for N=[8 1024];L=randn(N,3);F=false(N,1);F(1:3:end)=true;[u,~]=local_sc(L,F);for k=1:3;v=SC_decoder(L(:,k),sum(~F),double(F),2.^(0:log2(N)),get_llr_layer(N),get_bit_layer(N));assert(isequal(u(~F,k),v));end;end;for trial=1:40;N=8;F=false(N,1);F(1:3:end)=true;truth=randi([0 1],N,1);truth(F)=0;x=polar_encoder(truth);L=randn(N,1);[eh,~]=local_sc((1-2*x).*L,F);v=SC_decoder(L,sum(~F),double(F),2.^(0:log2(N)),get_llr_layer(N),get_bit_layer(N));assert(isequal(eh(~F),mod(v+truth(~F),2)));end;disp('VECTOR_SC_AND_ERROR_DOMAIN_40_PASS');return;end
files=dir(fullfile(run_dir,'summary_*.mat')); rows=[];bits=[]; B=8192;
for hi=1:3
for label=[20 28]
for pi=1:2
 z=cell(1,3); ge=z;sc=z;states=[];n=0;
 for j=1:numel(files)
 d=load(fullfile(run_dir,files(j).name));if d.hi~=hi || d.label~=label || d.pi~=pi,continue;end
 n=n+1;states=d.state;for g=1:3,z{g}(:,:,n)=d.records{g}.leaf_signed;ge{g}(:,:,n)=d.records{g}.genie_errors;sc{g}(:,:,n)=d.records{g}.sc_errors;end
 end
 if n==0,continue;end
 for g=1:3
 % PMF estimated from existing A0 codewords, independent of this batch noise.
 counts=zeros(16,1);a0=fullfile(root,'results','20261110_144834_A0_production');
 for kk=1:10
 jj=(hi-1)*40+(label==28)*20+(kk-1)*2+pi;old=load(fullfile(a0,sprintf('frame_%03d.mat',jj))); xx=zeros(1024,4);for bb=1:4,xx(:,bb)=polar_encoder(old.records{g}.u(:,bb));end;counts=counts+accumarray(bi2de(xx,'left-msb')+1,1,[16 1]);
 end
 sub=mod(old.locations{g}-1,64)+1;us=unique(sub);sigma=sqrt(64*old.N0/2)./abs(old.H(us));
 tq=tic;ref=p2_llr_reference(counts/sum(counts),sigma,1,80);[~,map]=ismember(sub,us);theory=p2_predict_ga(ref.ga_mean(map,:),states);quadrature_seconds=toc(tq);
 mu=mean(z{g},3);va=var(z{g},1,3);leaf=2*max(mu,0).^2./max(va,eps); t=tic;pred=p2_predict_ga(leaf,states);ga_seconds=toc(t);
 particle=zeros(1024,4,B);for i=1:1024,for b=1:4,v=squeeze(z{g}(i,b,:));particle(i,b,:)=v(randi(n,1,B));end;end
 t=tic;
 particle=local_density_particles(counts/sum(counts),sigma,map,B);leaf_density_seconds=toc(t);
 scmodel=zeros(1024,4);t=tic;for bb=1:4;F=true(1024,1);F([states.I{bb};states.S{bb}])=false;[uh,~]=local_sc(reshape(particle(:,bb,:),1024,B),F);scmodel(:,bb)=mean(uh,2);end;scmodel_seconds=toc(t);t=tic;
 for depth=1:10
 half=1024/2^depth;layer=reshape(particle,2*half,[],B);a=layer(1:half,:,:);c=layer(half+1:end,:,:);
 particle=reshape(cat(1,sign(a).*sign(c).*min(abs(a),abs(c)),a+c),1024,4,B);
 end
 density_seconds=toc(t);qms=mean(particle<0,3);
 for b=1:4
 I=states.I{b};emp=mean(ge{g}(I,b,:),3);qga=.5*erfc(sqrt(pred.reliability{b}(I)/4));q=qms(I,b);qt=.5*erfc(sqrt(theory.reliability{b}(I)/4)); f=squeeze(mean(ge{g}(I,b,:),1));normal=sqrt(log(40)/(2*n));
 rows=[rows;hi label pi g b n numel(I) sum(reshape(ge{g}(I,b,:),[],1)) mean(emp) max(0,mean(emp)-normal) min(1,mean(emp)+normal) mean(qga) mean(q) mean(reshape(sc{g}(I,b,:),[],1)) mean(abs(qga-emp)) mean(abs(q-emp)) corr(qga,emp,'Type','Spearman') corr(q,emp,'Type','Spearman') ga_seconds density_seconds mean(qt) mean(abs(qt-emp)) quadrature_seconds mean(reshape(particle(I,b,:)==0,[],1)) mean(scmodel(I,b)) scmodel_seconds leaf_density_seconds]; %#ok<AGROW>
 bits=[bits;repmat([hi label pi g b n],numel(I),1) I emp qga q qt]; %#ok<AGROW>
 end
 end
 fprintf('analyzed H%d label%d p%d frames%d\n',hi,label,pi,n);
end
end
end
T=array2table(rows,'VariableNames',{'H','label','p_index','group','stream','frames','I_count','errors','genie','low','high','ga','minsum','sc','ga_mae','minsum_mae','ga_rank','minsum_rank','ga_seconds','density_seconds','quadrature_ga','quadrature_mae','quadrature_seconds','particle_zero_mass','sc_model','scmodel_seconds','leaf_density_seconds'});writetable(T,fullfile(run_dir,'reliability.csv'));writematrix(bits,fullfile(run_dir,'bit_probabilities.csv'));seconds=toc(started);save(fullfile(run_dir,'reliability_analysis.mat'),'T','bits','seconds','B');
f=figure('Visible','off');loglog(T.genie,T.ga,'o',T.genie,T.minsum,'x');hold on;plot([1e-5 1],[1e-5 1],'k--');legend('Moment GA','Marginal min-sum','Identity','Location','best');xlabel('Genie BER');ylabel('Diagnostic prediction');grid on;print(f,fullfile(run_dir,'reliability.png'),'-dpng');print(f,fullfile(run_dir,'reliability.pdf'),'-dpdf');close(f);
end



function [u,beta]=local_sc(L,F)
N=size(L,1);if N==1,u=double(L<0);if F,u(:)=0;end;beta=u;return;end
h=N/2;a=L(1:h,:);b=L(h+1:end,:);
[ul,bl]=local_sc(sign(a).*sign(b).*min(abs(a),abs(b)),F(1:h));
[ur,br]=local_sc(b+(1-2*bl).*a,F(h+1:end));u=[ul;ur];beta=[mod(bl+br,2);br];
end


function particle=local_density_particles(pmf,sigma,map,B)
% Numerical Gaussian quadrature atoms, not generated communication symbols.
o=80;v=sqrt((1:o-1)/2);[V,D]=eig(diag(v,1)+diag(v,-1));[nodes,id]=sort(diag(D));w=V(1,id).^2;[a,b]=ndgrid(sqrt(2)*nodes,sqrt(2)*nodes);noise=a(:)+1i*b(:);ww=w(:)*w(:)';prob=reshape(ww(:)*pmf(:)',[],1);cdf=cumsum(prob);cdf=cdf/cdf(end);cdf(end)=1;assert(all(diff(cdf)>=0));
symbols=qammod((0:15)',16,'gray','UnitAveragePower',true);labels=de2bi((0:15)',4,'left-msb');bits=kron(labels,ones(o^2,1));particle=zeros(numel(map),4,B);
for k=1:numel(sigma)
Y=noise*sigma(k)+symbols.';d=abs(bsxfun(@minus,Y(:),symbols.')).^2/(2*sigma(k)^2);L=zeros(numel(Y),4);
for bb=1:4
v=-d(:,labels(:,bb)==0);m=max(v,[],2);l0=m+log(sum(exp(v-m),2));v=-d(:,labels(:,bb)==1);m=max(v,[],2);l1=m+log(sum(exp(v-m),2));L(:,bb)=(1-2*bits(:,bb)).*(l0-l1);
end
positions=find(map==k);for i=positions(:)';for bb=1:4;[~,ix]=histc(rand(1,B),[0;cdf]);particle(i,bb,:)=L(ix,bb);end;end
end
end




