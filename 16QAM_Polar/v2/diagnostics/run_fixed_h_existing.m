function run_fixed_h_existing()
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;addpath(fullfile(root,'..','v3','polar'));
out=fullfile(root,'results','20261110_154338_fixed_h');source=fullfile(root,'results','20261110_144834_A0_production');files=dir(fullfile(source,'frame_*.mat'));rows=[];diary(fullfile(out,'D_log_retry.txt'));
for j=1:numel(files)
 d=load(fullfile(source,files(j).name));s=d.state;hi=ceil(j/40);label=20+8*(mod(j-1,40)>=20);pi=1+mod(j-1,2);frame=ceil((mod(j-1,20)+1)/2);
 [~,order]=sort(GA(sqrt(64*d.N0/2),1024),'descend');
 grid=zeros(64,49);
 for g=1:3
  block=p2_transmit_block(s,d.payload(:,:,g));assert(isequal(block.u,d.records{g}.u));grid(d.locations{g})=block.symbols;
 end
 phys=ofdm_common_noise_roundtrip(grid,d.h,d.N0,16,d.noise);sigma=repmat(phys.sigma_equalized,1,49);
 for g=1:3
  r=d.records{g};block=p2_transmit_block(s,d.payload(:,:,g));dec=p2_decode_block(phys.rx_grid_equalized(d.locations{g}),sigma(d.locations{g}),1,block,true);assert(isequal(dec.errors,r.counts(:,1)'));assert(isequal(dec.channel_llr,r.L));
  for b=1:4
   I=s.I{b};S=s.S{b};remaining=order(~ismember(order,S));expected=sort(remaining(1:s.K(b))); assert(isequal(expected(:),I(:)));
   free=sort([I;S]);err=r.decoded(:,b)~=r.u(:,b);first=find(err(free),1);after=0;type=nan;position=nan;natural_n=0;natural_e=0;
   if ~isempty(first),position=free(first);type=ismember(position,S);after=sum(err(I(I>position)));end
   prefix=true;for k=free',if prefix && ismember(k,I),natural_n=natural_n+1;natural_e=natural_e+err(k);end;prefix=prefix && ~err(k);end
   rows=[rows;hi label pi frame g b sum(err(I)) numel(I) sum((r.genie_llr(I,b)<0)~=r.u(I,b)) sum(err(S)) numel(S) position type after natural_e natural_n]; %#ok<AGROW>
  end
 end
end
writematrix(rows,fullfile(out,'existing_streams.csv'));save(fullfile(out,'existing.mat'),'rows');fprintf('D complete: %d stream records, production wrapper and I selection exact\n',size(rows,1));diary off;
end
