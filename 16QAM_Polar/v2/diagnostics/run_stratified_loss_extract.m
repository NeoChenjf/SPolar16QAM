function run_stratified_loss_extract()
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
source=fullfile(root,'results','20261110_154811_fixed_h_E');out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_stratified_loss']);mkdir(out);rows=[];
for j=1:1200
 d=load(fullfile(source,sprintf('summary_%04d.mat',j)));
 for g=1:3
  r=d.records{g};for b=1:4
   pos=r.first(b,1);typ=r.first(b,2);n_after=0;bin=0;if ~isnan(pos),n_after=sum(d.state.I{b}>pos);bin=ceil(pos/256);end
   assert(r.counts(b,1)==r.propagation(b,1)+double(~isnan(pos) && typ==0));
   rows=[rows;d.hi d.pi d.label d.frame g b pos typ bin r.counts(b,1) r.counts(b,2) r.propagation(b,1) n_after]; %#ok<AGROW>
  end
 end
end
writematrix(rows,fullfile(out,'streams.csv'));save(fullfile(out,'streams.mat'),'rows','source');fprintf('Extracted %d streams to %s\n',size(rows,1),out);
end
