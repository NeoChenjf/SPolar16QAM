function run_information_score_independent(out)
% Frozen finite-candidate information-score validation, 2400 case-frame cap.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
addpath(fullfile(root,'..','v3','polar'));mkdir(out);diary(fullfile(out,'run.log'));
started=tic; count=0; deadline=datetime(2026,11,11,23,53,0);
train=fullfile(root,'results','20261107_111152_p2_v2_strategy_batch_pilot_strategy_training_f0197d58');
old=load(fullfile(train,'raw_c1_s1_combo_02_shaped.mat'),'artifact');
uniform=load(fullfile(train,'raw_c1_s1_combo_27_shaped.mat'),'artifact');
assets={uniform.artifact,old.artifact,old.artifact}; groups=[1 1 2];
pmfs=zeros(16,3);templates=cell(1,3);training_states=cell(1,3);
for j=1:3
 a=assets{j};g=groups(j);training_states{j}=a.states{g};templates{j}=a.states{g};
 pmfs(:,j)=sum(a.counts(:,g,:),3);pmfs(:,j)=pmfs(:,j)/sum(pmfs(:,j));
end
choices=[1 1 1;2 3 3;3 3 2];labels=[20 28];
params=struct('choices',choices,'p',[.5 .3 .1],'labels',labels,'frames',50,'channel_seed',26111101,'frame_seed_base',26111200,'orders',[40 80],'pmf_source',train,'pmf_frames',40,'frame_cap',2400,'disk_cap_MiB',500,'communication_deadline',char(deadline));
save(fullfile(out,'frozen.mat'),'params','templates','training_states','pmfs');
fid=fopen(fullfile(out,'params.json'),'w');fprintf(fid,'%s',jsonencode(params));fclose(fid);
rng(params.channel_seed,'twister');channels=(randn(16,8)+1i*randn(16,8))/sqrt(32);
predictions=[];states=cell(2,3);locations_bank=cell(8,1);
for li=1:2
 N0=3*1024/(64^2*49)*10^(-labels(li)/10);
 for j=1:3
  states{li,j}=p2_prepare_state(templates{j},-10*log10(64*N0),'shaped');
  for f={'I','S','F'}
   assert(isequal(states{li,j}.(f{1}),training_states{j}.(f{1})),'Training PMF construction mismatch');
  end
 end
end
for hi=1:8
 H=fft(channels(:,hi),64);[~,ix]=sort(abs(H).^2,'descend');partition=3*ones(64,1);partition(ix(1:22))=1;partition(ix(23:43))=2;
 locations=cell(1,3);for g=1:3,ix=find(repmat(partition==g,1,49));locations{g}=ix(1:1024);end;locations_bank{hi}=locations;
 for li=1:2
  N0=3*1024/(64^2*49)*10^(-labels(li)/10);
  for order=[40 80]
   densities=zeros(3,3);clock=tic;
   for g=1:3
    sub=mod(locations{g}-1,64)+1;[un,~,ix]=unique(sub);multiplicity=accumarray(ix,1);
    for j=1:3
     for k=1:numel(un)
      sigma=sqrt(64*N0/2)/abs(H(un(k)));densities(g,j)=densities(g,j)+multiplicity(k)*local_score(pmfs(:,j),sigma,order);
     end
    end
   end
   for c=1:3
    score=sum(densities(sub2ind([3 3],1:3,choices(c,:))))/(4*49*80);
    K=sum(cellfun(@(s)sum(s.K),states(li,choices(c,:))));
    predictions=[predictions;hi labels(li) c order score K toc(clock)]; %#ok<AGROW>
   end
  end
 end
 fprintf('Predicted H%d time %.1f\n',hi,toc(started));
end
writematrix(predictions,fullfile(out,'predictions.csv'));save(fullfile(out,'frozen_predictions.mat'),'predictions','channels','states','locations_bank','pmfs','params');
rows=[];
for hi=1:8
 h=channels(:,hi);locations=locations_bank{hi};
 for li=1:2
  N0=3*1024/(64^2*49)*10^(-labels(li)/10);
  for fr=1:50
   rng(params.frame_seed_base+hi*10000+li*100+fr,'twister');payload=randi([0 1],1024,4,3);noise=randn(80*49+15,1)+1i*randn(80*49+15,1);
   for c=1:3
    assert(count<2400 && datetime('now')<deadline,'Communication budget reached');
    blocks=cell(1,3);grid=zeros(64,49);
    for g=1:3,blocks{g}=p2_transmit_block(states{li,choices(c,g)},payload(:,:,g));grid(locations{g})=blocks{g}.symbols;end
    count=count+1;save(fullfile(out,'budget.mat'),'count');
    phys=ofdm_common_noise_roundtrip(grid,h,N0,16,noise);sigmas=repmat(phys.sigma_equalized,1,49);
    for g=1:3
     decoded=p2_decode_block(phys.rx_grid_equalized(locations{g}),sigmas(locations{g}),1,blocks{g},false);
     rows=[rows;hi labels(li) fr c g decoded.errors decoded.info_bits]; %#ok<AGROW>
    end
   end
  end
  writematrix(rows,fullfile(out,'frames.csv'));seconds=toc(started);save(fullfile(out,'progress.mat'),'count','seconds');fprintf('H%d label%d frames%d seconds%.1f\n',hi,labels(li),count,seconds);
 end
end
seconds=toc(started);save(fullfile(out,'completed.mat'),'count','seconds');diary off;
end

function value=local_score(p,sigma,order)
persistent cached_order noise weights C bits
if isempty(C),C=qammod((0:15)',16,'gray','UnitAveragePower',true);bits=de2bi((0:15)',4,'left-msb');end
if isempty(cached_order)||cached_order~=order
 v=sqrt((1:order-1)/2);[V,D]=eig(diag(v,1)+diag(v,-1));[nodes,ix]=sort(diag(D));w=V(1,ix).^2;[a,b]=ndgrid(sqrt(2)*nodes,sqrt(2)*nodes);noise=a(:)+1i*b(:);weights=reshape(w(:)*w(:)',[],1);cached_order=order;
end
value=0;
for x=1:16
 if p(x)==0,continue,end
 y=C(x)+sigma*noise;d=-abs(y-C.').^2/(2*sigma^2);q=zeros(size(d));
 for k=1:4
  for b=0:1
   mask=bits(:,k)==b;z=d(:,mask);m=max(z,[],2);ls=m+log(sum(exp(z-m),2));q(:,mask)=q(:,mask)+ls;
  end
 end
 m=max(q,[],2);ld=m+log(exp(q-m)*p);value=value+p(x)*sum(weights.*(q(:,x)-ld))/log(2);
end
end
