function run_fixed_h_batch()
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;addpath(fullfile(root,'..','v3','polar'));
out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_fixed_h_E']);mkdir(out);diary(fullfile(out,'run_log.txt'));
t=load(fullfile(root,'results','20261109_115203_p2_grid_study','20261109_225158_p2_v2_strategy_batch_pilot_strategy_test_a9c377f9','templates.mat'));all_templates=t.templates; templates=cell(1,2); for j=1:2, target=[.5 .3]; matches=find(cellfun(@(x) isequal(x.p_vec,[.5 target(j) .5 target(j)]),all_templates)); assert(numel(matches)==1,'A0:TemplateMatch'); templates{j}=all_templates{matches}; end;save(fullfile(out,'templates.mat'),'templates');
started=tic; frames=0;rows=[];rng(11010073,'twister'); old=load(fullfile(root,'results','20261110_144834_A0_production','channels.mat')); channels=old.channels;save(fullfile(out,'channels.mat'),'channels');
try
for hi=1:3
 h=channels(:,hi);H=fft(h,64);[~,order]=sort(abs(H).^2,'descend');groups=3*ones(64,1);groups(order(1:22))=1;groups(order(23:43))=2;locations=cell(1,3);
 for g=1:3,idx=find(repmat(groups==g,1,49));locations{g}=idx(1:1024);end
 for label=[20 28]
 N0=3*1024/(64^2*49)*10^(-label/10); states=cell(2,1);for p=1:2,states{p}=p2_prepare_state(templates{p},-10*log10(64*N0),'shaped');end
 for frame=1:100
 rng(111000000+hi*10000+label*100+frame,'twister');payload=randi([0 1],1024,4,3);noise=randn(80*49+15,1)+1i*randn(80*49+15,1);
 for pi=1:2
 assert(toc(started)<3000 && frames<1200 && datetime('now','TimeZone','UTC')<datetime(2026,11,10,8,47,25,'TimeZone','UTC')); grid=zeros(64,49);blocks=cell(1,3);for g=1:3,blocks{g}=p2_transmit_block(states{pi},payload(:,:,g));grid(locations{g})=blocks{g}.symbols;end
 frames=frames+1;save(fullfile(out,'budget.mat'),'frames');phys=ofdm_common_noise_roundtrip(grid,h,N0,16,noise);sg=repmat(phys.sigma_equalized,1,49);records=cell(1,3); nw=reshape(noise(1:80*49),80,49); direct=bsxfun(@times,grid,H)+sqrt(N0/2)*fft(nw(17:80,:),64,1); delta=max(abs(direct(:)-phys.rx_grid(:)))/(1+max(abs(direct(:)))); assert(delta<1e-10);
 for g=1:3
  block=blocks{g};state=states{pi};L=reshape(llr_16qam_gray_LSE(phys.rx_grid_equalized(locations{g}),sg(locations{g}),1),4,[])';r=struct('u',block.u,'L',L,'decoded',zeros(1024,4),'ordinary_llr',zeros(1024,4),'genie_llr',zeros(1024,4),'counts',zeros(4,7),'first',nan(4,2));
  for b=1:4
   assert(numel(unique([state.I{b};state.S{b};state.F{b}]))==1024); if frame==1 && hi==1, clean=(1-2*block.x(:,b))*100; ff=ones(1024,1); ff([state.I{b};state.S{b}])=0; got=SC_decoder(clean,sum(ff==0),ff,2.^(0:10),get_llr_layer(1024),get_bit_layer(1024)); assert(isequal(got,block.u(ff==0,b))); end; F=false(1024,1);F(state.F{b})=true;free=find(~F);p=SC_decoder(L(:,b),numel(free),double(F),2.^(0:10),get_llr_layer(1024),get_bit_layer(1024));
   [u,ll]=sc_decode_forced_full(L(:,b),F,zeros(1024,1));assert(isequal(u(free),p));[v,gl]=sc_decode_forced_full(L(:,b),true(1024,1),block.u(:,b));assert(isequal(v,block.u(:,b)));
   alt=block.u(:,b);alt(512)=1-alt(512);[~,al]=sc_decode_forced_full(L(:,b),true(1024,1),alt);assert(al(512)==gl(512));
   I=state.I{b};S=state.S{b};ei=sum(u(I)~=block.u(I,b));es=sum(u(S)~=block.u(S,b));r.counts(b,:)=[ei numel(I) es numel(S) ei>0 sum((gl(I)<0)~=block.u(I,b)) sum((gl(S)<0)~=block.u(S,b))];
   k=find(u(free)~=block.u(free,b),1);if ~isempty(k),r.first(b,:)=[free(k) ismember(free(k),S)];end; pos=inf;if ~isempty(k),pos=free(k);end; r.propagation(b,:)=[sum(u(I(I>pos))~=block.u(I(I>pos),b)) sum((ll(I(I<=pos))<0)~=block.u(I(I<=pos),b)) sum(I<=pos)];
   r.decoded(:,b)=u;r.ordinary_llr(:,b)=ll;r.genie_llr(:,b)=gl;
  end
  records{g}=r;rows=[rows;hi label frame pi g sum(r.counts(:,1)) sum(r.counts(:,2)) any(r.counts(:,1)>0) sum(r.counts(:,3))]; %#ok<AGROW>
 end
 if frame==1, save(fullfile(out,sprintf('trace_%04d.mat',frames)),'records','state','h','H','N0','locations','groups','noise','payload'); end; for gg=1:3,records{gg}=rmfield(records{gg},{'u','L','decoded','ordinary_llr','genie_llr'});end; save(fullfile(out,sprintf('summary_%04d.mat',frames)),'records','state','hi','label','pi','frame','N0');
 if frames==1, check=load(fullfile(out,'trace_0001.mat')); assert(isequal(check.state.p_vec,[.5 .5 .5 .5]) && numel(check.records)==3); fprintf('FIRST FRAME VERIFIED\n'); end; sizes=dir(fullfile(out,'*.mat')); assert(sum([sizes.bytes])<450*1024^2); writematrix(rows,fullfile(out,'frames.csv'));fprintf('completed %d/1200\n',frames);
 end
 end
 end
end
catch e
 failure=getReport(e,'extended','hyperlinks','off');save(fullfile(out,'failure.mat'),'failure','frames');disp(failure); diary off; rethrow(e);
end
diary off;
end
