function check_frontier_pmf_sensitivity(out)
% Post-hoc fixed-subset training-PMF bootstrap, no test-data fitting.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
z=load(fullfile(out,'frozen.mat'));p=z.protocol;Hset=[1 8];Lset=[1 4];indices=[1 5];replicates=10;pmfs=zeros(16,5,replicates);
rng(2611121506,'twister');
for j=indices
 source=p.sources{j};a=load(source.file,'artifact');counts=reshape(a.artifact.counts(:,source.group,:),16,[]);assert(size(counts,2)==40);
 for b=1:replicates
  ix=randi(40,40,1);x=sum(counts(:,ix),2);pmfs(:,j,b)=x/sum(x);
 end
end
save(fullfile(out,'pmf_bootstrap_inputs.mat'),'pmfs','Hset','Lset','indices','replicates');rows=[];
for hi=Hset
 H=fft(z.channels(:,hi),64);g=3;
 for li=Lset
  original=load(fullfile(out,sprintf('prediction_h%02d_l%02d.mat',hi,p.labels(li))),'ber');N0=3*1024/(64^2*49)*10^(-p.labels(li)/10);
  sub=mod(z.locations{hi,g}-1,64)+1;[un,~,map]=unique(sub);sigma=sqrt(64*N0/2)./abs(H(un));
  for j=indices
   for b=1:replicates
    t=tic;r=p1_predict_minsum(pmfs(:,j,b),sigma,map,z.states{li,j},p.particle_B,p.model_seed,p.order);
    rows=[rows;hi p.labels(li) g j b original.ber(g,j) r.ber .5*sum(abs(pmfs(:,j,b)-z.pmfs(:,j))) toc(t)]; %#ok<AGROW>
    writematrix(rows,fullfile(out,'pmf_sensitivity.csv'));
   end
   fprintf('PMF sensitivity H%d label%d p%.1f complete\n',hi,p.labels(li),p.probabilities(j));
  end
 end
end
end
