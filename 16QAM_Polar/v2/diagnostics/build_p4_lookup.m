function build_p4_lookup(out)
% Build from frozen predictions + A0 assets only, never target test labels.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
P=readmatrix(fullfile(out,'frozen_predictions.csv'));assert(size(P,1)==144);bank=struct([]);timing=[];k=0;
for hi=1:3
for label=[20 28]
for pi=1:2
ix=(hi-1)*40+(label==28)*20+pi;d=load(fullfile(root,'results','20261110_144834_A0_production',sprintf('frame_%03d.mat',ix)));
for g=1:3
q=P(P(:,1)==hi & P(:,2)==label & P(:,3)==pi & P(:,4)==g,:);assert(size(q,1)==4 && isequal(q(:,5),(1:4)'));k=k+1;bank(k).H=d.H;bank(k).N0=d.N0;bank(k).locations=d.locations{g};bank(k).state_fingerprint=d.state.fingerprint;bank(k).p_vec=d.state.p_vec;bank(k).N=d.state.N;bank(k).K=d.state.K;bank(k).I=d.state.I;bank(k).S=d.state.S;bank(k).F=d.state.F;bank(k).kind=d.state.kind;bank(k).source_fingerprint=d.state.source_fingerprint;bank(k).ber_per_stream=q(:,7)';bank(k).genie_per_stream=q(:,8)';bank(k).sc_se_per_stream=q(:,9)';bank(k).key=[hi label pi g];
end
end
end
end
save(fullfile(out,'frozen_lookup.mat'),'bank');
for k=1:numel(bank)
e=bank(k);key=e.key;ix=(key(1)-1)*40+(key(2)==28)*20+key(3);d=load(fullfile(root,'results','20261110_144834_A0_production',sprintf('frame_%03d.mat',ix)),'state');t=tic;for rep=1:100;p=p4_lookup_minsum(e.H,e.N0,e.locations,d.state,bank);assert(p.valid && isequal(p.ber_per_stream,e.ber_per_stream));end;seconds=toc(t)/100;
bad=p4_lookup_minsum(e.H,e.N0*1.001,e.locations,d.state,bank);assert(~bad.valid && isnan(bad.ber));bad=p4_lookup_minsum(e.H*1.001,e.N0,e.locations,d.state,bank);assert(~bad.valid);loc=e.locations;loc(1)=loc(1)+1;bad=p4_lookup_minsum(e.H,e.N0,loc,d.state,bank);assert(~bad.valid);s=d.state;s.fingerprint=[s.fingerprint '_changed'];bad=p4_lookup_minsum(e.H,e.N0,e.locations,s,bank);assert(~bad.valid);s=d.state;s.I{1}(1)=mod(s.I{1}(1),s.N)+1;bad=p4_lookup_minsum(e.H,e.N0,e.locations,s,bank);assert(~bad.valid);s=d.state;s.kind='random_s';bad=p4_lookup_minsum(e.H,e.N0,e.locations,s,bank);assert(~bad.valid);timing=[timing;key seconds]; %#ok<AGROW>
end
writematrix(timing,fullfile(out,'lookup_timing.csv'));fprintf('LOOKUP 36 exact matches and H/N0/map/SIF rejection PASS\n');
end


