function analyze_information_frontier_main(out)
% Full same-candidate comparison; existing frames only.
z=load(fullfile(out,'frozen.mat'));p=z.protocol;names={'H','label','candidate','K','errors','bits','BER','goodput','rf_W','proxy_A','proxy_m30_A','proxy_m20_A','simple_score','sc_goodput','simple_front_RF','sc_front_RF','actual_front_RF','simple_front_proxy','sc_front_proxy','actual_front_proxy','simple_front_m30','sc_front_m30','actual_front_m30','simple_front_m20','sc_front_m20','actual_front_m20','goodput_loss_vs_uniform','rf_gain_vs_uniform','proxy_gain_vs_uniform','error_frames','zero_errorframe_upper95','goodput_low','goodput_high'};
cases=[];metrics=[];choices=[];rankings=[];raw_predictions=[];pairs=nchoosek(1:125,2);rng(2611121503,'twister');
for hi=1:11
 for li=1:4
  file=fullfile(out,sprintf('communication_h%02d_l%02d.mat',hi,p.labels(li)));prediction=fullfile(out,sprintf('prediction_h%02d_l%02d.mat',hi,p.labels(li)));
  if ~isfile(file)||~isfile(prediction),continue,end
  a=load(file);b=load(prediction);assert(isequal(size(a.errors),[50 125 3 4]));assert(size(b.rows,1)==125);
  raw_predictions=[raw_predictions;b.rows]; %#ok<AGROW>
  E=reshape(sum(sum(a.errors,4),3),50,125);K=reshape(sum(sum(a.bits,4),3),50,125);G=(K-E)/(4*49*80);e=sum(E,1);k=sum(K,1);assert(all(K==K(1,:),'all'));
  v=p.volts_per_unit_primary;R=p.resistance_ohm;vt=1.380649e-23*p.temperature_K/1.602176634e-19;k2=p.diode_Is/(2*(p.diode_n*vt)^2);k4=p.diode_Is/(24*(p.diode_n*vt)^4);
  m2=reshape(a.moments(:,:,1),50,125);m4=reshape(a.moments(:,:,2),50,125);m44=reshape(a.moments(:,:,4),50,125);
  RF=mean(v^2*m2/(2*R),1);proxy=mean(k2*v^2*m2/2+k4*3*v^4*m4/8,1);v30=v*10^(-5/20);v20=v*10^(5/20);
  proxy30=mean(k2*v30^2*m2/2+k4*3*v30^4*m4/8,1);proxy20=mean(k2*v20^2*m2/2+k4*3*v20^4*m4/8,1);
  energies={RF,proxy,proxy30,proxy20};Gmean=mean(G,1);S=b.rows(:,4)';Q=b.rows(:,5)';
  baseline=find(all(p.choices==5,2));assert(numel(baseline)==1 && Gmean(baseline)>0 && RF(baseline)>0 && proxy(baseline)>0);
  bootstrap_indices=randi(50,50,2000);
  bootstrap_G=zeros(2000,125);for n=1:2000,bootstrap_G(n,:)=mean(G(bootstrap_indices(:,n),:),1);end
  weights=zeros(2000,50);for n=1:2000,weights(n,:)=accumarray(bootstrap_indices(:,n),1,[50 1])'/50;end
  bootstrap_energy={weights*(v^2*m2/(2*R)),weights*(k2*v^2*m2/2+k4*3*v^4*m4/8),weights*(k2*v30^2*m2/2+k4*3*v30^4*m4/8),weights*(k2*v20^2*m2/2+k4*3*v20^4*m4/8)};
  pair_direction=zeros(size(pairs,1),1);
  for first=1:250:size(pairs,1)
   rows=first:min(first+249,size(pairs,1));difference=bootstrap_G(:,pairs(rows,1))-bootstrap_G(:,pairs(rows,2));
   interval=prctile(difference,[2.5 97.5],1);pair_direction(rows)=double(interval(1,:)>0)-double(interval(2,:)<0);
  end
  for method=1:2
   if method==1,score=S;else,score=Q;end
   agree=0;disagree=0;ties=0;
   for x=1:124
    for y=x+1:125
     product=sign(score(x)-score(y))*sign(Gmean(x)-Gmean(y));
     agree=agree+(product>0);disagree=disagree+(product<0);ties=ties+(product==0);
    end
   end
   score=score(:);forecast_direction=sign(score(pairs(:,1))-score(pairs(:,2)));
   clear_agree=sum(forecast_direction.*pair_direction>0);clear_disagree=sum(forecast_direction.*pair_direction<0);
   unresolved=sum(pair_direction==0 & forecast_direction~=0);forecast_ties=sum(forecast_direction==0);
   assert(clear_agree+clear_disagree+unresolved+forecast_ties==7750);
   rankings=[rankings;hi p.labels(li) method agree disagree ties clear_agree clear_disagree unresolved forecast_ties]; %#ok<AGROW>
  end
  fronts=false(3,4,125);for axis=1:4
   energy=energies{axis};
   vals={S,Q,Gmean};
   for method=1:3
    for c=1:125,fronts(method,axis,c)=~any(energy>=energy(c)&vals{method}>=vals{method}(c)&(energy>energy(c)|vals{method}>vals{method}(c)));end
   end
  end
  bounds=prctile(bootstrap_G,[2.5 97.5],1);
  for c=1:125
   error_frames=sum(E(:,c)>0);upper=nan;if error_frames==0,upper=1-.05^(1/50);end
   cases=[cases;hi p.labels(li) c K(1,c) e(c) k(c) e(c)/k(c) Gmean(c) RF(c) proxy(c) proxy30(c) proxy20(c) S(c) Q(c) fronts(1,1,c) fronts(2,1,c) fronts(3,1,c) fronts(1,2,c) fronts(2,2,c) fronts(3,2,c) fronts(1,3,c) fronts(2,3,c) fronts(3,3,c) fronts(1,4,c) fronts(2,4,c) fronts(3,4,c) 1-Gmean(c)/Gmean(baseline) RF(c)/RF(baseline)-1 proxy(c)/proxy(baseline)-1 error_frames upper bounds(1,c) bounds(2,c)]; %#ok<AGROW>
  end
  for axis=1:4
   energy=energies{axis};
   targets=linspace(min(energy),max(energy),21);
   for threshold=1:numel(targets)
    eligible=find(energy>=targets(threshold));[best,j]=max(Gmean(eligible));oracle=eligible(j);[~,j]=max(S(eligible));simple=eligible(j);[~,j]=max(Q(eligible));sc=eligible(j);
    ds=G(:,oracle)-G(:,simple);dq=G(:,oracle)-G(:,sc);
    cis=prctile(mean(ds(bootstrap_indices),1),[2.5 97.5]);ciq=prctile(mean(dq(bootstrap_indices),1),[2.5 97.5]);
    eligible_boot=bootstrap_energy{axis}>=targets(threshold);valid=any(eligible_boot,2);empty_fraction=mean(~valid);
    boot_truth=bootstrap_G;boot_truth(~eligible_boot)=-inf;best_boot=max(boot_truth,[],2);
    simple_boot=repmat(S,2000,1);simple_boot(~eligible_boot)=-inf;[~,is]=max(simple_boot,[],2);
    sc_boot=repmat(Q,2000,1);sc_boot(~eligible_boot)=-inf;[~,iq]=max(sc_boot,[],2);
    row=(1:2000)';regret_simple=best_boot-bootstrap_G(sub2ind([2000 125],row,is));regret_sc=best_boot-bootstrap_G(sub2ind([2000 125],row,iq));
    if any(valid),ci_reselect_s=prctile(regret_simple(valid),[2.5 50 97.5]);ci_reselect_q=prctile(regret_sc(valid),[2.5 50 97.5]);else,ci_reselect_s=nan(1,3);ci_reselect_q=nan(1,3);end
    choices=[choices;hi p.labels(li) axis threshold targets(threshold) oracle simple sc best-Gmean(simple) best-Gmean(sc) cis ciq ci_reselect_s ci_reselect_q empty_fraction]; %#ok<AGROW>
   end
   realfront=squeeze(fronts(3,axis,:))';
   for method=1:2
    pred=squeeze(fronts(method,axis,:))';d=choices(choices(:,1)==hi&choices(:,2)==p.labels(li)&choices(:,3)==axis,:);
    metrics=[metrics;hi p.labels(li) axis method sum(realfront) sum(pred) sum(realfront&pred) mean(d(:,8+method)) max(d(:,8+method)) mean(abs(m4(:)-m44(:))./max(m4(:),realmin)) sum(a.elapsed)]; %#ok<AGROW>
   end
  end
  fprintf('ANALYZED H%d label%d\n',hi,p.labels(li));
 end
end
if isempty(cases),fprintf('No completed conditions\n');return,end
local_write(fullfile(out,'analysis_cases.csv'),names,cases);
local_write(fullfile(out,'analysis_frontiers.csv'),{'H','label','energy_axis','method','actual_front_n','pred_front_n','overlap_n','mean_regret','max_regret','L4_L8_m4_relative','communication_seconds'},metrics);
local_write(fullfile(out,'analysis_choices.csv'),{'H','label','energy_axis','threshold_index','threshold','oracle','simple','sc','simple_loss','sc_loss','simple_low','simple_high','sc_low','sc_high','simple_reselect_low','simple_reselect_median','simple_reselect_high','sc_reselect_low','sc_reselect_median','sc_reselect_high','bootstrap_no_feasible_fraction'},choices);
local_write(fullfile(out,'analysis_rankings.csv'),{'H','label','method','agree','disagree','ties','resolved_agree','resolved_disagree','unresolved','forecast_ties'},rankings);
local_write(fullfile(out,'predictions_full_precision.csv'),{'H','label','candidate','simple_score','sc_goodput','K','sc_BER'},raw_predictions);
fprintf('Completed conditions %d, rows %d. Bootstrap holds selected candidates and energy thresholds fixed.\n',size(cases,1)/125,size(cases,1));
end

function local_write(path,names,data)
% Seventeen digits preserve binary64 values for downstream near-tie checks.
fid=fopen(path,'w');assert(fid>=0);cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s',names{1});for i=2:numel(names),fprintf(fid,',%s',names{i});end;fprintf(fid,'\n');
format=[repmat('%.17g,',1,numel(names)-1) '%.17g\n'];fprintf(fid,format,data.');
end
