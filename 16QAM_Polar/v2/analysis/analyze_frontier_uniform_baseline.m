function analyze_frontier_uniform_baseline(out)
% Post-hoc point-best vs uniform; preserves the candidate-selection caveat.
z=load(fullfile(out,'frozen.mat'));p=z.protocol;baseline=find(all(p.choices==5,2));assert(isscalar(baseline));rng(2611121507,'twister');rows=[];
for h=1:11
 for l=1:4
  file=fullfile(out,sprintf('communication_h%02d_l%02d.mat',h,p.labels(l)));if ~isfile(file),continue,end;a=load(file,'errors','bits');
  E=reshape(sum(sum(a.errors,4),3),50,125);K=reshape(sum(sum(a.bits,4),3),50,125);G=(K-E)/(4*49*80);[best,candidate]=max(mean(G,1));
  difference=G(:,candidate)-G(:,baseline);ix=randi(50,50,2000);interval=prctile(mean(difference(ix),1),[2.5 97.5]);
  rows=[rows;h p.labels(l) baseline candidate mean(G(:,baseline)) best best-mean(G(:,baseline)) interval]; %#ok<AGROW>
 end
end
writetable(array2table(rows,'VariableNames',{'H','label','uniform_candidate','sample_best_candidate','uniform_G','sample_best_G','point_gap','conditional_low','conditional_high'}),fullfile(out,'uniform_baseline_comparison.csv'));
end
