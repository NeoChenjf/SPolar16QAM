function run_information_frontier_main(out,phase)
% Unified 125-candidate experiment. Explicit user authorization 2026-11-12.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
addpath(fullfile(root,'..','v3','polar'));if ~isfolder(out),mkdir(out);end
diary(fullfile(out,[phase '.log']));cleanup=onCleanup(@()diary('off'));
if strcmp(phase,'prepare'),local_prepare(root,out);return,end
z=load(fullfile(out,'frozen.mat'));p=z.protocol;
assert(datetime('now')<datetime(p.final_deadline),'Wall budget expired');
if strcmp(phase,'predict'),local_predict(out,z);return,end
assert(strcmp(phase,'simulate'));
local_simulate(out,z);
end

function local_prepare(root,out)
base=fullfile(root,'results');grid=fullfile(base,'20261109_115203_p2_grid_study');
t=load(fullfile(grid,'five_level_templates.mat'),'templates');templates=t.templates;
probabilities=[.1 .2 .3 .4 .5];assert(numel(templates)==5);
paths={fullfile(base,'20261107_111152_p2_v2_strategy_batch_pilot_strategy_training_f0197d58','raw_c1_s1_combo_02_shaped.mat'),fullfile(base,'20261107_111152_p2_v2_strategy_batch_pilot_strategy_training_f0197d58','raw_c1_s1_combo_27_shaped.mat'),fullfile(grid,'20261109_115237_p2_v2_strategy_batch_pilot_strategy_training_4d7664df','raw_c1_s1_grid_002_shaped.mat'),fullfile(grid,'20261109_115237_p2_v2_strategy_batch_pilot_strategy_training_4d7664df','raw_c1_s1_grid_004_shaped.mat')};
pmfs=zeros(16,5);training_states=cell(1,5);sources=cell(1,5);
for file=1:numel(paths)
 a=load(paths{file},'artifact');a=a.artifact;
 for g=1:3
  j=find(abs(probabilities-a.states{g}.p_vec(2))<1e-10);assert(numel(j)==1);
  if isempty(training_states{j})
   training_states{j}=a.states{g};counts=sum(a.counts(:,g,:),3);pmfs(:,j)=counts/sum(counts);sources{j}=struct('file',paths{file},'group',g,'frames',size(a.counts,3));
  end
 end
 if file==2,reference_m2=mean(cellfun(@(r)r.rx_m2_l16,a.records));end
end
assert(all(sum(pmfs,1)>0));labels=[16 20 24 28];states=cell(4,5);
for li=1:4
 N0=3*1024/(64^2*49)*10^(-labels(li)/10);
 for j=1:5
  assert(abs(templates{j}.p_vec(2)-probabilities(j))<eps);
  states{li,j}=p2_prepare_state(templates{j},-10*log10(64*N0),'shaped');
  for field={'I','S','F'},assert(isequal(states{li,j}.(field{1}),training_states{j}.(field{1})),'PMF construction mismatch');end
 end
end
[a,b,c]=ndgrid(1:5);choices=[a(:) b(:) c(:)];rng(2611121501,'twister');channels=(randn(16,11)+1i*randn(16,11))/sqrt(32);
channels(:,9)=0;channels(1,9)=1;
channels(:,10)=0;channels(1,10)=1;channels(2,10)=.15;channels(:,10)=channels(:,10)/norm(channels(:,10));
channels(:,11)=0;channels(1,11)=1;channels(9,11)=-.98;channels(:,11)=channels(:,11)/norm(channels(:,11));
locations=cell(11,3);for hi=1:11
 H=fft(channels(:,hi),64);[~,order]=sortrows([-abs(H).^2 (1:64)'],[1 2]);group=3*ones(64,1);group(order(1:22))=1;group(order(23:43))=2;
 for g=1:3,ix=find(repmat(group==g,1,49));locations{hi,g}=ix(1:1024);end
end
protocol=struct('start','2026-11-12 15:09:49','communication_deadline','2026-11-13 00:39:49','final_deadline','2026-11-13 03:09:49','labels',labels,'probabilities',probabilities,'choices',choices,'frames',50,'random_H',8,'diagnostic_H',3,'frame_cap',275500,'formal_frames',275000,'disk_GiB',8,'particle_B',8192,'order',80,'model_seed',2611121502,'frame_seed_base',2711120000,'sources',{sources},'diode_Is',5e-6,'diode_n',1.05,'temperature_K',300,'resistance_ohm',50,'reference_dbm',[-30 -25 -20],'volts_per_unit_primary',sqrt(2*50*10^(-25/10)/1000/reference_m2),'reference_m2',reference_m2);
save(fullfile(out,'frozen.mat'),'protocol','pmfs','templates','states','channels','locations');
fid=fopen(fullfile(out,'protocol.json'),'w');fprintf(fid,'%s',jsonencode(protocol));fclose(fid);
fprintf('PREPARED 125 candidates, 5 matched training PMFs, 11H, labels16/20/24/28\n');
end

function local_predict(out,z)
p=z.protocol;predictions=[];timings=[];clock=tic;
for hi=1:11
 H=fft(z.channels(:,hi),64);
 for li=1:4
  file=fullfile(out,sprintf('prediction_h%02d_l%02d.mat',hi,p.labels(li)));
  if isfile(file),continue,end
  N0=3*1024/(64^2*49)*10^(-p.labels(li)/10);score=zeros(3,5);ber=score;model_se=score;costs=zeros(3,5,2);
  for g=1:3
   sub=mod(z.locations{hi,g}-1,64)+1;[un,~,map]=unique(sub);sigma=sqrt(64*N0/2)./abs(H(un));multiplicity=accumarray(map,1);
   for j=1:5
    assert(datetime('now')<datetime(p.communication_deadline),'Prediction budget');
    t=tic;for k=1:numel(un),score(g,j)=score(g,j)+multiplicity(k)*information_score_quadrature(z.pmfs(:,j),sigma(k),p.order);end;costs(g,j,1)=toc(t);
    t=tic;r=p1_predict_minsum(z.pmfs(:,j),sigma,map,z.states{li,j},p.particle_B,p.model_seed,p.order);costs(g,j,2)=toc(t);ber(g,j)=r.ber;model_se(g,j)=sqrt(sum((r.sc_se_per_stream.*z.states{li,j}.K).^2))/sum(z.states{li,j}.K);
   end
  end
  rows=zeros(125,7);for c=1:125
   K=cellfun(@(s)sum(s.K),z.states(li,p.choices(c,:)));ix=sub2ind([3 5],1:3,p.choices(c,:));
   rows(c,:)=[hi p.labels(li) c sum(score(ix))/(4*49*80) sum(K.*(1-ber(ix)))/(4*49*80) sum(K) sum(K.*ber(ix))/sum(K)];
  end
  save(file,'rows','score','ber','model_se','costs');predictions=[predictions;rows];timings=[timings;hi p.labels(li) sum(costs(:,:,1),'all') sum(costs(:,:,2),'all')]; %#ok<AGROW>
  writematrix(predictions,fullfile(out,'predictions.csv'));writematrix(timings,fullfile(out,'prediction_timings.csv'));fprintf('PREDICTED H%d label%d cumulative%.1fs\n',hi,p.labels(li),toc(clock));
 end
end
end

function local_simulate(out,z)
p=z.protocol;clock=tic;charged=0;actual=0;
if isfile(fullfile(out,'budget.mat')),b=load(fullfile(out,'budget.mat'));charged=b.charged;actual=b.actual;end
for hi=1:11
 h=z.channels(:,hi);H=fft(h,64);
 for li=1:4
  file=fullfile(out,sprintf('communication_h%02d_l%02d.mat',hi,p.labels(li)));if isfile(file),continue,end
  assert(isfile(fullfile(out,sprintf('prediction_h%02d_l%02d.mat',hi,p.labels(li)))));
  partial=fullfile(out,'partial.mat');first=1;errors=zeros(50,125,3,4);bits=errors;moments=zeros(50,125,4);elapsed=zeros(50,1);
  if isfile(partial),s=load(partial);assert(s.hi==hi&&s.li==li);errors=s.errors;bits=s.bits;moments=s.moments;elapsed=s.elapsed;first=s.fr+1;end
  N0=3*1024/(64^2*49)*10^(-p.labels(li)/10);
  for fr=first:50
   assert(charged+125<=p.frame_cap && datetime('now')<datetime(p.communication_deadline),'Communication budget');
   charged=charged+125;save(fullfile(out,'budget.mat'),'charged','actual');t=tic;
   rng(p.frame_seed_base+hi*10000+li*100+fr,'twister');payload=randi([0 1],1024,4,3);noise=randn(80*49+numel(h)-1,1)+1i*randn(80*49+numel(h)-1,1);
   blocks=cell(3,5);for g=1:3,for j=1:5,blocks{g,j}=p2_transmit_block(z.states{li,j},payload(:,:,g));end,end
   for c=1:125
    grid=zeros(64,49);for g=1:3,grid(z.locations{hi,g})=blocks{g,p.choices(c,g)}.symbols;end
    actual=actual+1;phys=ofdm_common_noise_roundtrip(grid,h,N0,16,noise);sg=repmat(phys.sigma_equalized,1,49);
    for g=1:3
     b=blocks{g,p.choices(c,g)};r=p2_decode_block(phys.rx_grid_equalized(z.locations{hi,g}),sg(z.locations{hi,g}),1,b,false);errors(fr,c,g,:)=r.errors;bits(fr,c,g,:)=r.info_bits;
    end
    rx=ofdm_oversampled_channel(grid,h,16,8);m=rf_envelope_moments(rx);
    rx4=ofdm_oversampled_channel(grid,h,16,4);m4=rf_envelope_moments(rx4);
    moments(fr,c,:)=[m.mean_abs2 m.mean_abs4 m4.mean_abs2 m4.mean_abs4];
    if fr==1&&c==1,assert(max(abs(rx(1:8:end)-phys.rx_signal_serial))<1e-10);end
   end
   elapsed(fr)=toc(t);save(partial,'errors','bits','moments','elapsed','hi','li','fr','-v7');save(fullfile(out,'budget.mat'),'charged','actual');
   if mod(fr,10)==0,fprintf('H%d label%d frame%d actual%d charged%d seconds%.1f\n',hi,p.labels(li),fr,actual,charged,toc(clock));end
  end
  save(file,'errors','bits','moments','elapsed','hi','li','-v7');delete(partial);
  s=dir(fullfile(out,'*.mat'));assert(sum([s.bytes])<p.disk_GiB*1024^3,'Disk budget');
 end
end
seconds=toc(clock);save(fullfile(out,'communication_complete.mat'),'charged','actual','seconds');
end
