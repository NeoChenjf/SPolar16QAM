function check_information_frontier_numerics(out)
% Fixed sensitivity diagnostics only; do not replace frozen predictions.
z=load(fullfile(out,'frozen.mat'));p=z.protocol;Hset=[1 8];Lset=[1 4];Gset=3;Pset=[1 5];rows=[];
for hi=Hset
 H=fft(z.channels(:,hi),64);
 for li=Lset
  f=fullfile(out,sprintf('prediction_h%02d_l%02d.mat',hi,p.labels(li)));assert(isfile(f));orig=load(f);
  N0=3*1024/(64^2*49)*10^(-p.labels(li)/10);
  for g=Gset
   sub=mod(z.locations{hi,g}-1,64)+1;[un,~,map]=unique(sub);sigma=sqrt(64*N0/2)./abs(H(un));
   for j=Pset
    t=tic;alternative=p1_predict_minsum(z.pmfs(:,j),sigma,map,z.states{li,j},p.particle_B,p.model_seed+1,p.order);seconds_seed=toc(t);
    t=tic;higher=p1_predict_minsum(z.pmfs(:,j),sigma,map,z.states{li,j},p.particle_B,p.model_seed,160);seconds_order=toc(t);
    rows=[rows;hi p.labels(li) g j orig.ber(g,j) alternative.ber higher.ber orig.model_se(g,j) seconds_seed seconds_order]; %#ok<AGROW>
    writematrix(rows,fullfile(out,'numerical_sensitivity.csv'));fprintf('NUMERIC H%d label%d g%d p%.1f done\n',hi,p.labels(li),g,p.probabilities(j));
   end
  end
 end
end
end
