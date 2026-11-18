function analyze_p4_independent(out)
% Extract independent frame denominators; no fitting or model modification.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
fs=dir(fullfile(out,'summary_*.mat'));assert(numel(fs)==600);rows=[];
for j=1:numel(fs)
d=load(fullfile(out,fs(j).name));assert(d.frame<=50);for g=1:3
c=d.records{g}.counts;for b=1:4,rows=[rows;d.hi d.label d.pi g b d.frame c(b,6) c(b,2) c(b,1)];end %#ok<AGROW>
end
end
writematrix(rows,fullfile(out,'frame_streams.csv'));
% CPU benchmark only: repeated decoding of the SAME saved LLRs, no new frames.
traces=dir(fullfile(out,'trace_*.mat'));bench=[];
for j=1:numel(traces)
d=load(fullfile(out,traces(j).name));id=sscanf(traces(j).name,'trace_%d.mat');key=load(fullfile(out,sprintf('summary_%04d.mat',id)),'hi','label','pi');
old_index=(key.hi-1)*40+(key.label==28)*20+key.pi;old=load(fullfile(root,'results','20261110_144834_A0_production',sprintf('frame_%03d.mat',old_index)),'state');assert(isequal(old.state.fingerprint,d.state.fingerprint));
for g=1:3
t=tic;for rep=1:10
for b=1:4
F=ones(1024,1);F([d.state.I{b};d.state.S{b}])=0;u=SC_decoder(d.records{g}.L(:,b),sum(F==0),F,2.^(0:10),get_llr_layer(1024),get_bit_layer(1024));assert(isequal(u,d.records{g}.decoded(F==0,b)));
end
end
bench=[bench;key.hi key.label key.pi g toc(t)/10]; %#ok<AGROW>
end
end
writematrix(bench,fullfile(out,'ordinary_sc_benchmark.csv'));fprintf('P4 extracted %d frame-streams\n',size(rows,1));
end

