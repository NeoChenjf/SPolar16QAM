function run_information_certified_frontier(out,phase)
% Offline certification experiment, fresh authorization 2026-11-17.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;addpath(fullfile(root,'..','v3','polar'));
if ~isfolder(out),mkdir(out);end
diary(fullfile(out,[phase '.log']));cleanup=onCleanup(@()diary('off'));
if strcmp(phase,'prepare'),prepare(root,out);return,end
z=load(fullfile(out,'frozen.mat'));p=z.protocol;
assert(datetime('now')<datetime(p.final_deadline),'certified:Deadline','Final deadline');
if strcmp(phase,'smoke')
 t=tic;values=zeros(3,3);for c=[1 99 125],[g,m]=one_frame(z,1,1,c,400001,true,true);values(find([1 99 125]==c),:)=[g m];end
 seconds=toc(t);assert(all(isfinite(values),'all')&&all(values(:,1)>=0));
 actual=3;save(fullfile(out,'smoke.mat'),'values','seconds','actual');fprintf('SMOKE3 %.3fs\n',seconds);return
end
assert(strcmp(phase,'run'));run_batch(out,z);
end

function prepare(root,out)
old=load(fullfile(root,'results','20261112_150949_information_frontier_main','frozen.mat'));
pmfs=old.pmfs;states=old.states;templates=old.templates;
rng(2611172301,'twister');channels=(randn(16,5)+1i*randn(16,5))/sqrt(32);
channels(:,5)=0;channels(1,5)=1;channels(9,5)=-.98;channels(:,5)=channels(:,5)/norm(channels(:,5));
conditions=[repelem((1:4)',2) repmat([1;3],4,1);5 2];locations=cell(5,3);
for hi=1:5
 H=fft(channels(:,hi),64);[~,ix]=sortrows([-abs(H).^2 (1:64)'],[1 2]);g=3*ones(64,1);g(ix(1:22))=1;g(ix(23:43))=2;
 for j=1:3,k=find(repmat(g==j,1,49));locations{hi,j}=k(1:1024);end
end
protocol=rmfield(old.protocol,{'frames','random_H','diagnostic_H','formal_frames'});
protocol.random_H=4;protocol.diagnostic_H=1;protocol.start='2026-11-17 23:48:19';protocol.communication_deadline='2026-11-18 08:48:19';protocol.final_deadline='2026-11-18 11:48:19';
protocol.conditions=conditions;protocol.channel_seed=2611172301;protocol.model_seed=2611172302;protocol.frame_seed_base=2811170000;
protocol.looks=[5 20 80 320 1280];protocol.budgets=[60 180 600];protocol.methods={'simple','numerical_SC','direct_SC'};
protocol.energy_frames=8;protocol.evaluation_frames=100;protocol.frame_cap=650000;protocol.disk_GiB=4;
protocol.claim='Time-uniform betting bounds: 124 candidates x 3 methods x 2 tails, within fixed H/noise';
save(fullfile(out,'frozen.mat'),'protocol','pmfs','states','templates','channels','locations');
fid=fopen(fullfile(out,'protocol.json'),'w');fprintf(fid,'%s',jsonencode(protocol));fclose(fid);
fprintf('Prepared 4 new random H x labels16/24 plus fixed deep-fade label20. Cap650000 includes energy, certification, evaluation.\n');
end

function run_batch(out,z)
p=z.protocol;actual=0;if isfile(fullfile(out,'smoke.mat')),q=load(fullfile(out,'smoke.mat'));actual=q.actual;end
if isfile(fullfile(out,'ledger.mat')),q=load(fullfile(out,'ledger.mat'));actual=q.actual;end
for ci=1:size(p.conditions,1)
 hi=p.conditions(ci,1);li=p.conditions(ci,2);file=fullfile(out,sprintf('condition_%02d.mat',ci));if isfile(file),continue,end
 K=zeros(1,125);for c=1:125,K(c)=sum(cellfun(@(s)sum(s.K),z.states(li,p.choices(c,:))));end
 t=tic;energy_raw=zeros(p.energy_frames,125,2);
 for fr=1:p.energy_frames,for c=1:125
  guard(out,p,actual);actual=actual+1;[~,m]=one_frame(z,hi,li,c,100000+fr,false,true);energy_raw(fr,c,:)=m;
 end,end
 v=p.volts_per_unit_primary;vt=1.380649e-23*p.temperature_K/1.602176634e-19;
 k2=p.diode_Is/(2*(p.diode_n*vt)^2);k4=p.diode_Is/(24*(p.diode_n*vt)^4);
 energy=[v^2*mean(energy_raw(:,:,1),1)'/(2*p.resistance_ohm),k2*v^2*mean(energy_raw(:,:,1),1)'/2+3*k4*v^4*mean(energy_raw(:,:,2),1)'/8];catalog_seconds=toc(t);
 save(fullfile(out,sprintf('catalog_%02d.mat',ci)),'energy','energy_raw','catalog_seconds');methods=cell(1,3);
 for method=mod((0:2)+ci-1,3)+1
  timer=tic;score=nan(125,1);prediction=[];refinement=[];
  if method<3
   [score,prediction]=predict(z,hi,li,method,p.order,p.particle_B,p.model_seed);
   if method==2
    [~,ix]=sort(abs(score-.95*score(125)));used=false(3,5);for c=ix(1:5)',for g=1:3,used(g,p.choices(c,g))=true;end,end
    refined=prediction.values;H=fft(z.channels(:,hi),64);N0=3*1024/(64^2*49)*10^(-p.labels(li)/10);
    for g=1:3,for j=find(used(g,:))
     if toc(timer)+catalog_seconds>=p.budgets(end)*.5,break,end
     sub=mod(z.locations{hi,g}-1,64)+1;[un,~,map]=unique(sub);sigma=sqrt(64*N0/2)./abs(H(un));
     r=p1_predict_minsum(z.pmfs(:,j),sigma,map,z.states{li,j},p.particle_B,p.model_seed+1,160);
     refined(g,j)=r.ber;refinement=[refinement;g j prediction.values(g,j) r.ber r.seconds]; %#ok<AGROW>
    end,end
    q=assemble(z,li,refined);prediction.refined_goodput=q;score=(score+q)/2;
   end
  end
  forecast_seconds=toc(timer);G=cell(1,125);G0=[];state=zeros(1,125);state(125)=1;bounds=nan(125,2);bounds(125,:)=[0 inf];
  snapshots=cell(1,numel(p.budgets));next=1;history=[];n=zeros(1,125);rounds=0;
  % Direct-SC comparator screens all125. Predictors screen a fixed10
  % rank-tradeoff shortlist; no shortlisted point is certified by prediction.
  if method==3,pilot=1:124;
  else
   [~,ord]=sort(score,'descend');rank=zeros(125,1);rank(ord)=1:125;erank=zeros(125,1);
   for axis=1:2,[~,ord]=sort(energy(:,axis),'descend');r=zeros(125,1);r(ord)=1:125;erank=erank+r/2;end
   [~,ord]=sort(rank+erank);pilot=ord(ord~=125);pilot=pilot(1:10)';
  end
  while toc(timer)+catalog_seconds<p.budgets(end)
   elapsed=toc(timer)+catalog_seconds;
   while next<=numel(p.budgets)&&elapsed>=p.budgets(next),snapshots{next}=snapshot(state,bounds,n,energy,p.budgets(next));next=next+1;end
   if ~isempty(pilot),c=pilot(1);pilot(1)=[];
   else
    eligible=find(state==0 & n>0 & n<p.looks(end));if isempty(eligible),break,end
    if method==3
     estimate=nan(125,1);for j=eligible,estimate(j)=mean(G{j});end;priority=estimate-.95*mean(G0);
    elseif method==2,priority=score-.95*score(125);
    else,[~,ord]=sort(score,'descend');rank=zeros(125,1);rank(ord)=1:125;priority=-rank/125;
    end
    rank_energy=zeros(125,1);for axis=1:2,[~,ord]=sort(energy(:,axis),'descend');r=zeros(125,1);r(ord)=1:125;rank_energy=rank_energy+r/250;end
    if method==1,key=priority(eligible)-rank_energy(eligible);
    else,key=double(priority(eligible)>=0)-rank_energy(eligible)+.01*priority(eligible);end
    [~,pick]=max(key);c=eligible(pick);
   end
   target=p.looks(find(p.looks>n(c),1));
   for fr=n(c)+1:target
    if toc(timer)+catalog_seconds>=p.budgets(end),break,end
    if numel(G0)<fr,guard(out,p,actual);actual=actual+1;G0(fr)=one_frame(z,hi,li,125,method*10000+fr,true,false);end %#ok<AGROW>
    guard(out,p,actual);actual=actual+1;G{c}(fr)=one_frame(z,hi,li,c,method*10000+fr,true,false);
    elapsed=toc(timer)+catalog_seconds;
    while next<=numel(p.budgets)&&elapsed>=p.budgets(next),snapshots{next}=snapshot(state,bounds,n,energy,p.budgets(next));next=next+1;end
   end
   n(c)=numel(G{c});
   if any(n(c)==p.looks)
    [lo,up]=goodput_betting_certificate(G{c}(:),G0(1:n(c))',K(c),K(125),15680,3);
    elapsed=toc(timer)+catalog_seconds;
    while next<=numel(p.budgets)&&elapsed>=p.budgets(next),snapshots{next}=snapshot(state,bounds,n,energy,p.budgets(next));next=next+1;end
    bounds(c,:)=[lo up];if lo>=0,state(c)=1;elseif up<0,state(c)=-1;end
    history=[history;toc(timer)+catalog_seconds c n(c) lo up state(c)]; %#ok<AGROW>
    save(fullfile(out,'partial_method.mat'),'G','G0','state','bounds','n','history','snapshots','ci','method','actual','-v7');save(fullfile(out,'ledger.mat'),'actual');
   end
   rounds=rounds+1;if mod(rounds,20)==0,fprintf('C%d method%d %.1fs certified%d rejected%d frames%d\n',ci,method,toc(timer)+catalog_seconds,sum(state==1)-1,sum(state==-1),actual);end
  end
  while next<=numel(p.budgets),snapshots{next}=snapshot(state,bounds,n,energy,p.budgets(next));next=next+1;end
  methods{method}=struct('score',score,'prediction',prediction,'refinement',refinement,'forecast_seconds',forecast_seconds,'total_seconds',toc(timer)+catalog_seconds,'catalog_seconds',catalog_seconds,'snapshots',{snapshots},'history',history,'G',{G},'G0',G0,'n',n,'state',state,'bounds',bounds);
  save(fullfile(out,sprintf('method_c%02d_m%d.mat',ci,method)),'methods','ci','hi','li','actual','-v7');save(fullfile(out,'ledger.mat'),'actual');
  fprintf('DONE C%d method%d %.1fs actual%d\n',ci,method,methods{method}.total_seconds,actual);
 end
 eval_G=zeros(p.evaluation_frames,125);eval_M=zeros(p.evaluation_frames,125,2);
 for fr=1:p.evaluation_frames,for c=1:125
  guard(out,p,actual);actual=actual+1;[eval_G(fr,c),m]=one_frame(z,hi,li,c,200000+fr,true,true);eval_M(fr,c,:)=m;
 end
 if mod(fr,20)==0,save(fullfile(out,'ledger.mat'),'actual');fprintf('EVAL C%d frame%d actual%d\n',ci,fr,actual);end
 end
 save(file,'ci','hi','li','K','energy','energy_raw','methods','eval_G','eval_M','actual','-v7');save(fullfile(out,'ledger.mat'),'actual');fprintf('CONDITION %d COMPLETE actual%d\n',ci,actual);
end
save(fullfile(out,'completed.mat'),'actual');
end

function [score,detail]=predict(z,hi,li,method,order,B,seed)
H=fft(z.channels(:,hi),64);N0=3*1024/(64^2*49)*10^(-z.protocol.labels(li)/10);value=zeros(3,5);cost=value;
for g=1:3
 sub=mod(z.locations{hi,g}-1,64)+1;[un,~,map]=unique(sub);sigma=sqrt(64*N0/2)./abs(H(un));mult=accumarray(map,1);
 for j=1:5,t=tic;
  if method==1,for k=1:numel(un),value(g,j)=value(g,j)+mult(k)*information_score_quadrature(z.pmfs(:,j),sigma(k),order);end
  else,r=p1_predict_minsum(z.pmfs(:,j),sigma,map,z.states{li,j},B,seed,order);value(g,j)=r.ber;end
  cost(g,j)=toc(t);
 end
end
if method==1,score=zeros(125,1);for c=1:125,ix=sub2ind([3 5],1:3,z.protocol.choices(c,:));score(c)=sum(value(ix))/15680;end
else,score=assemble(z,li,value);end
detail=struct('values',value,'costs',cost);
end

function score=assemble(z,li,ber)
score=zeros(125,1);for c=1:125,js=z.protocol.choices(c,:);K=cellfun(@(s)sum(s.K),z.states(li,js));ix=sub2ind([3 5],1:3,js);score(c)=sum(K.*(1-ber(ix)))/15680;end
end

function s=snapshot(state,bounds,n,energy,budget)
cert=find(state==1);selected=zeros(1,2);for axis=1:2,[~,j]=max(energy(cert,axis));selected(axis)=cert(j);end
s=struct('budget',budget,'certified',cert,'selected',selected,'bounds',bounds,'n',n);
end

function [G,m]=one_frame(z,hi,li,c,fr,decode,moments)
persistent cached_seed cached_blocks
p=z.protocol;h=z.channels(:,hi);N0=3*1024/(64^2*49)*10^(-p.labels(li)/10);
seed=p.frame_seed_base+hi*1000000+li*300000+fr;
rng(seed,'twister');payload=randi([0 1],1024,4,3);noise=randn(80*49+15,1)+1i*randn(80*49+15,1);
if isempty(cached_seed)||cached_seed~=seed,cached_seed=seed;cached_blocks=cell(3,5);end
grid=zeros(64,49);blocks=cell(1,3);
for g=1:3
 j=p.choices(c,g);if isempty(cached_blocks{g,j}),cached_blocks{g,j}=p2_transmit_block(z.states{li,j},payload(:,:,g));end
 blocks{g}=cached_blocks{g,j};grid(z.locations{hi,g})=blocks{g}.symbols;
end
G=nan;m=[nan nan];
if decode
 phys=ofdm_common_noise_roundtrip(grid,h,N0,16,noise);sg=repmat(phys.sigma_equalized,1,49);errors=0;bits=0;
 for g=1:3,r=p2_decode_block(phys.rx_grid_equalized(z.locations{hi,g}),sg(z.locations{hi,g}),1,blocks{g},false);errors=errors+sum(r.errors);bits=bits+sum(r.info_bits);end
 G=(bits-errors)/15680;
end
if moments,rx=ofdm_oversampled_channel(grid,h,16,8);q=rf_envelope_moments(rx);m=[q.mean_abs2 q.mean_abs4];end
end

function guard(out,p,actual)
assert(actual<p.frame_cap,'certified:FrameBudget','Frame cap');assert(datetime('now')<datetime(p.communication_deadline),'certified:Deadline','Communication deadline');
if mod(actual,1000)==0,save(fullfile(out,'ledger.mat'),'actual');end
end
