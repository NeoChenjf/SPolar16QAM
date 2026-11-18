function run_p1_saved_ga()
% Development comparison only: no generated communication or symbol samples.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_p1_saved_ga']);mkdir(out);diary(fullfile(out,'run_log.txt')); started=tic;
source=fullfile(root,'results','20261110_144834_A0_production');files=dir(fullfile(source,'frame_*.mat')); rows=[]; detail=[];
% Predeclared: empirical signed-leaf moment projection, no calibration;
% per H/label/p/group/stream frame means, normal frame CI, rank descriptive.
for j=1:numel(files)
 d=load(fullfile(source,files(j).name));s=d.state;
 for g=1:3
  r=d.records{g};
  % Encoder x is reconstructed without rerunning channel or receiver.
  x=zeros(1024,4);for b=1:4,x(:,b)=polar_encoder(r.u(:,b));end; Z=(1-2*x).*r.L;
  if j==1, disp(fieldnames(d));end
  hi=ceil(j/40); label=20+8*(mod(j-1,40)>=20);pi=1+mod(j-1,2);
  detail=[detail; repmat([hi label pi g j],1024,1) (1:1024)' Z]; %#ok<AGROW>
 end
end
save(fullfile(out,'leaf_samples.mat'),'detail','source','-v7');
for hi=1:3
for label=[20 28]
for pi=1:2
for g=1:3
 mask=detail(:,1)==hi & detail(:,2)==label & detail(:,3)==pi & detail(:,4)==g;
 a=detail(mask,:); ids=unique(a(:,5)); first=load(fullfile(source,files(ids(1)).name));s=first.state;
 z=zeros(1024,4,numel(ids));for k=1:numel(ids),z(:,:,k)=a(a(:,5)==ids(k),7:10);end
 mu=mean(z,3); va=var(z,1,3); leaf=2*max(mu,0).^2./max(va,eps); pred=p2_predict_ga(leaf,s);
 for b=1:4
 I=s.I{b}; q=.5*erfc(sqrt(pred.reliability{b}(I)/4)); ge=zeros(numel(ids),numel(I));sc=ge;
 for k=1:numel(ids)
 d=load(fullfile(source,files(ids(k)).name));r=d.records{g};ge(k,:)=(r.genie_llr(I,b)<0)~=r.u(I,b);sc(k,:)=r.decoded(I,b)~=r.u(I,b);
 end
 f=mean(ge,2); se=std(f)/sqrt(numel(f)); empirical=mean(ge,1)'; rho=corr(q,empirical,'Type','Spearman','Rows','complete');
 rows=[rows;hi label pi g b numel(ids) numel(I) sum(ge(:)) mean(f) max(0,mean(f)-1.96*se) min(1,mean(f)+1.96*se) mean(q) mean(sc(:)) mean(abs(q-empirical)) rho mean(reshape(va(:,b)./max(2*mu(:,b),eps),[],1))]; %#ok<AGROW>
 end
end
end
end
end
T=array2table(rows,'VariableNames',{'H','label','p_index','group','stream','frames','I_count','genie_errors','genie_ber','ci_low','ci_high','ga_ber','sc_ber','bit_mae','rank_rho','leaf_consistency'});writetable(T,fullfile(out,'comparison.csv'));save(fullfile(out,'analysis.mat'),'T','rows');
f=figure('Visible','off');loglog(T.genie_ber,T.ga_ber,'o');hold on;plot([1e-6 1],[1e-6 1],'k--');xlabel('Saved genie BER');ylabel('Empirical leaf GA BER');grid on;print(f,fullfile(out,'comparison.png'),'-dpng');print(f,fullfile(out,'comparison.pdf'),'-dpdf');close(f);
seconds=toc(started);save(fullfile(out,'runtime.mat'),'seconds');fprintf('RESULT %s seconds %.3f\n',out,seconds);diary off;
end

