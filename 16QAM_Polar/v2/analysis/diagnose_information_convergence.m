function rows=diagnose_information_convergence(source,out,tasks)
%DIAGNOSE_INFORMATION_CONVERGENCE Bounded development sensitivity, no frames.
% tasks columns: channel index, label index, group index, probability index.
% Cross order {80,160}, B {8192,16384}, and three fixed seeds.
% Outputs are descriptive sensitivity, never confidence/error bounds.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
if nargin<3
 tasks=[5 2 1 4;5 2 1 5;5 2 2 4;5 2 2 5;5 2 3 4;5 2 3 5;8 4 3 1;8 4 3 5];
end
validateattributes(tasks,{'numeric'},{'2d','integer','positive','ncols',4});
if ischar(source)||isstring(source),z=load(source);else,z=source;end
assert(all(tasks(:,1)<=size(z.channels,2))&&all(tasks(:,2)<=numel(z.protocol.labels)));
assert(all(tasks(:,3)<=3)&&all(tasks(:,4)<=5));
if ~isfolder(out),mkdir(out);end
target=fullfile(out,'convergence_rows.csv');assert(~isfile(target),'Do not overwrite a diagnostic');
rows=zeros(0,12);orders=[80 160];particles=[8192 16384];seeds=z.protocol.model_seed+(0:2);
fid=fopen(target,'w');assert(fid>=0);guard=onCleanup(@()fclose(fid));
fprintf(fid,'H,label,group,p_index,order,B,seed,BER,group_goodput,particle_SE_BER,seconds,leaf_seconds\n');
for q=1:size(tasks,1)
 hi=tasks(q,1);li=tasks(q,2);g=tasks(q,3);j=tasks(q,4);
 H=fft(z.channels(:,hi),64);N0=3*1024/(64^2*49)*10^(-z.protocol.labels(li)/10);
 sub=mod(z.locations{hi,g}-1,64)+1;[un,~,map]=unique(sub);sigma=sqrt(64*N0/2)./abs(H(un));
 state=z.states{li,j};K=sum(state.K);
 for order=orders
  for B=particles
   for seed=seeds
    r=p1_predict_minsum(z.pmfs(:,j),sigma,map,state,B,seed,order);
    se=sqrt(sum((r.sc_se_per_stream.*state.K).^2))/K;
    row=[hi z.protocol.labels(li) g j order B seed r.ber K*(1-r.ber)/(4*49*80) se r.seconds r.leaf_seconds];
    rows(end+1,:)=row; %#ok<AGROW>
    fprintf(fid,[repmat('%.17g,',1,11) '%.17g\n'],row);
    save(fullfile(out,'convergence_checkpoint.mat'),'rows','tasks','orders','particles','seeds');
   end
  end
 end
 fprintf('CONVERGENCE task %d/%d H%d label%d group%d p_index%d complete\n',q,size(tasks,1),hi,z.protocol.labels(li),g,j);
end
save(fullfile(out,'convergence_complete.mat'),'rows','tasks','orders','particles','seeds');
end
