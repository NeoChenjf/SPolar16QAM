function run_p4_predictions(out)
% Frozen predictions use only A0 training assets, never independent test data.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;rows=[];a0=fullfile(root,'results','20261110_144834_A0_production');started=tic;
for hi=1:3
for label=[20 28]
for pi=1:2
for g=1:3
counts=zeros(16,1);
for k=1:10
ix=(hi-1)*40+(label==28)*20+(k-1)*2+pi;d=load(fullfile(a0,sprintf('frame_%03d.mat',ix)));x=zeros(1024,4);for b=1:4,x(:,b)=polar_encoder(d.records{g}.u(:,b));end;counts=counts+accumarray(bi2de(x,'left-msb')+1,1,[16 1]);
end
sub=mod(d.locations{g}-1,64)+1;us=unique(sub);[~,map]=ismember(sub,us);sigma=sqrt(64*d.N0/2)./abs(d.H(us));p=p1_predict_minsum(counts/sum(counts),sigma,map,d.state,8192,112100004,80);
for b=1:4,rows=[rows;hi label pi g b d.state.K(b) p.ber_per_stream(b) p.genie_per_stream(b) p.sc_se_per_stream(b) p.seconds];end %#ok<AGROW>
writematrix(rows,fullfile(out,'frozen_predictions.csv'));save(fullfile(out,'prediction_checkpoint.mat'),'rows','hi','label','pi','g');fprintf('frozen prediction H%d label%d p%d group%d\n',hi,label,pi,g);
end
end
end
end
seconds=toc(started);save(fullfile(out,'prediction_runtime.mat'),'seconds');
end
