function diagnose_frontier_seed_sensitivity(out)
% Exploratory, post-hoc diagnostic of H5/20 candidates 99 and 120.
% Frozen test predictions are not replaced; no communication frames are generated.
z=load(fullfile(out,'frozen.mat'));p=z.protocol;hi=5;li=find(p.labels==20);cand=[99 120];indices=[4 5];seeds=p.model_seed+(1:5);H=fft(z.channels(:,hi),64);
N0=3*1024/(64^2*49)*10^(-20/10);rows=[];
fid=fopen(fullfile(out,'seed_diagnostic_plan.txt'),'w');fprintf(fid,'Post-hoc explanation of H5/20 candidates99 and120; seeds model_seed+1..5, all three groups and p=.4/.5; no test prediction replacement or model selection.\n');fclose(fid);
for sd=seeds
 ber=zeros(3,5);se=zeros(3,5);t=tic;
 for g=1:3
  sub=mod(z.locations{hi,g}-1,64)+1;[un,~,map]=unique(sub);sigma=sqrt(64*N0/2)./abs(H(un));
  for j=indices
   r=p1_predict_minsum(z.pmfs(:,j),sigma,map,z.states{li,j},p.particle_B,sd,p.order);ber(g,j)=r.ber;se(g,j)=sqrt(sum((r.sc_se_per_stream.*z.states{li,j}.K).^2))/sum(z.states{li,j}.K);
  end
 end
 score=zeros(1,2);
 for k=1:2
  choice=p.choices(cand(k),:);idx=sub2ind([3 5],1:3,choice);K=cellfun(@(x)sum(x.K),z.states(li,choice));score(k)=sum(K.*(1-ber(idx)))/(4*49*80);
 end
 rows=[rows;sd score score(1)-score(2) toc(t)]; %#ok<AGROW>
 writematrix(rows,fullfile(out,'seed_diagnostic.csv'));save(fullfile(out,sprintf('seed_diagnostic_%d.mat',sd)),'ber','se','score','sd');
 fprintf('SEED %d predicted99-minus120 %.9g\n',sd,score(1)-score(2));
end
end
