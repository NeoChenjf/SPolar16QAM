function audit_information_frontier_main(out)
% Audit saved artifacts; does not generate communication samples.
z=load(fullfile(out,'frozen.mat'));p=z.protocol;[x,y,w]=ndgrid(1:5);assert(isequal(sortrows(p.choices),sortrows([x(:),y(:),w(:)])));
bits_total=0;errors_total=0;zero_cases=0;long_frames=[];cases=0;max_moment_error=0;
for hi=1:11
 for li=1:4
  name=sprintf('communication_h%02d_l%02d.mat',hi,p.labels(li));file=fullfile(out,name);assert(isfile(file));a=load(file);
  name=sprintf('prediction_h%02d_l%02d.mat',hi,p.labels(li));file=fullfile(out,name);assert(isfile(file));b=load(file);
  assert(isequal(size(a.errors),[50 125 3 4])&&isequal(size(a.bits),[50 125 3 4])&&isequal(size(a.moments),[50 125 4]));
  assert(size(b.rows,1)==125&&all(isfinite(b.rows),'all')&&all(isfinite(a.errors),'all')&&all(isfinite(a.moments),'all'));
  assert(all(a.errors>=0,'all')&&all(a.errors<=a.bits,'all')&&all(a.errors==floor(a.errors),'all'));
  for c=1:125
   assert(b.rows(c,3)==c);
   for g=1:3
    want=z.states{li,p.choices(c,g)}.K;assert(all(reshape(a.bits(:,c,g,:),50,4)==repmat(want,50,1),'all'));
   end
   E=sum(reshape(a.errors(:,c,:,:),[],1));K=sum(reshape(a.bits(:,c,:,:),[],1));assert(K==50*b.rows(c,6));
   errors_total=errors_total+E;bits_total=bits_total+K;zero_cases=zero_cases+(E==0);cases=cases+1;
  end
  m2=a.moments(:,:,1);m4=a.moments(:,:,2);max_moment_error=max(max_moment_error,max(max(m2.^2-m4)));assert(all(m4+1e-12>=m2.^2,'all'));
  ix=find(a.elapsed>60);for k=ix(:)',long_frames=[long_frames;hi p.labels(li) k a.elapsed(k)];end %#ok<AGROW>
 end
end
assert(cases==5500);budget=load(fullfile(out,'budget.mat'));assert(budget.charged<=p.frame_cap && budget.actual<=budget.charged);
assert(budget.charged==275030 && budget.actual==275030);d=readmatrix(fullfile(out,'diode_replay.csv'));assert(isequal(size(d),[90 14]) && sum(d(:,13)==1)==18);
assert(max(d(d(:,13)==1,14))<1e-10);
assert(size(readmatrix(fullfile(out,'numerical_sensitivity.csv')),1)==8);assert(size(readmatrix(fullfile(out,'pmf_sensitivity.csv')),1)==80);assert(size(readmatrix(fullfile(out,'seed_diagnostic.csv')),1)==5);
output=struct('formal_frames',275000,'replayed_frames_charged',30,'charged',budget.charged,'actual',budget.actual,'communication_conditions',44,'candidate_cases',cases,'bits',bits_total,'errors',errors_total,'zero_error_candidate_cases',zero_cases,'max_m2_squared_minus_m4',max_moment_error,'long_frames',long_frames,'independent_SC_verified_frames',6,'max_relative_fourier_difference',max(d(d(:,13)==1,14)),'numeric_sensitivity_groups',8,'pmf_sensitivity_runs',80,'seed_diagnostic_replicates',5);
fid=fopen(fullfile(out,'completion_audit.json'),'w');fprintf(fid,'%s',jsonencode(output));fclose(fid);disp(output);
end
