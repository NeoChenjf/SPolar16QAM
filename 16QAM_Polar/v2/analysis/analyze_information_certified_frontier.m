function analyze_information_certified_frontier(out)
% Analyze independent evaluation only; intervals are descriptive fixed-policy.
z=load(fullfile(out,'frozen.mat'));p=z.protocol;cases=[];choices=[];rankings=[];frontiers=[];
saved=rng;clean=onCleanup(@()rng(saved));rng(2611180401,'twister');
for ci=1:size(p.conditions,1)
 file=fullfile(out,sprintf('condition_%02d.mat',ci));if ~isfile(file),continue,end
 a=load(file);G=a.eval_G;assert(size(G,2)==125&&size(G,1)==p.evaluation_frames);
 assert(isequal(size(a.eval_M),[size(G,1) 125 2])&&all(isfinite(G),'all'));
 K=a.K(:)';gm=mean(G,1);assert(gm(125)>0);nframe=size(G,1);diagnostic=a.hi>4;
 v=p.volts_per_unit_primary;vt=1.380649e-23*p.temperature_K/1.602176634e-19;
 k2=p.diode_Is/(2*(p.diode_n*vt)^2);k4=p.diode_Is/(24*(p.diode_n*vt)^4);
 rf=v^2*a.eval_M(:,:,1)/(2*p.resistance_ohm);proxy=k2*v^2*a.eval_M(:,:,1)/2+3*k4*v^4*a.eval_M(:,:,2)/8;
 en=[mean(rf,1)' mean(proxy,1)'];loss=1-gm/gm(125);errs=round(K-G*15680);assert(all(errs>=0,'all'));
 weights=zeros(2000,nframe);for b=1:2000,weights(b,:)=accumarray(randi(nframe,nframe,1),1,[nframe 1])'/nframe;end
 bootG=weights*G;bootloss=1-bootG./bootG(:,125);interval=prctile(bootloss,[2.5 97.5],1);
 bootRF=weights*rf;bootProxy=weights*proxy;
 rfInterval=prctile(bootRF./bootRF(:,125)-1,[2.5 97.5],1);
 proxyInterval=prctile(bootProxy./bootProxy(:,125)-1,[2.5 97.5],1);
 S=a.methods{1}.score(:);Q=a.methods{2}.score(:);rawQ=zeros(125,1);
 rawber=a.methods{2}.prediction.values;
 for c=1:125
  js=p.choices(c,:);ks=cellfun(@(s)sum(s.K),z.states(a.li,js));ix=sub2ind([3 5],1:3,js);
  rawQ(c)=sum(ks.*(1-rawber(ix)))/15680;
 end
 for c=1:125
  cases(end+1,:)=[ci a.hi p.labels(a.li) diagnostic c K(c) nframe sum(errs(:,c)) sum(errs(:,c))/(K(c)*nframe) gm(c) en(c,:) loss(c) S(c) Q(c) rawQ(c)]; %#ok<AGROW>
 end
 for m=[1 2 4]
  if m==4,score=rawQ';else,score=a.methods{m}.score(:)';end;reverse=0;ties=0;
  for c=1:124,dg=gm(c)-gm(c+1:125);ds=score(c)-score(c+1:125);reverse=reverse+sum(dg.*ds<0);ties=ties+sum(dg==0|ds==0);end
  rankings(end+1,:)=[ci a.hi p.labels(a.li) diagnostic m reverse 7750 reverse/7750 ties]; %#ok<AGROW>
 end
 for m=1:3
  method=a.methods{m};
  for b=1:numel(method.snapshots)
   s=method.snapshots{b};if isempty(s),continue,end
   for axis=1:2
    allfront=pointfront(gm(:),en(:,axis));poolmask=false(125,1);poolmask(s.certified)=true;
    poolfront=false(125,1);poolfront(s.certified)=pointfront(gm(s.certified)',en(s.certified,axis));
    for candidate=1:125
     frontiers(end+1,:)=[ci a.hi p.labels(a.li) diagnostic m s.budget axis candidate poolmask(candidate) allfront(candidate) poolfront(candidate)]; %#ok<AGROW>
    end
    c=s.selected(axis);pool=s.certified;lo=s.bounds(c,1);if c==125,lo=nan;end
    choices(end+1,:)=[ci a.hi p.labels(a.li) diagnostic m s.budget axis c gm(c) loss(c) interval(:,c)' en(c,1)/en(125,1)-1 en(c,2)/en(125,2)-1 numel(pool)-1 sum(loss(pool)>.05) s.n(c) lo method.forecast_seconds c==125 rfInterval(:,c)' proxyInterval(:,c)']; %#ok<AGROW>
   end
  end
 end
end
assert(isempty(cases)||size(cases,2)==16);assert(isempty(choices)||size(choices,2)==24);
assert(isempty(rankings)||size(rankings,2)==9);assert(isempty(frontiers)||size(frontiers,2)==11);
writecsv(fullfile(out,'certified_cases.csv'),{'condition','H','label','diagnostic','candidate','K','frames','errors','BER','G','RF_W','proxy_A','loss_vs_uniform','simple_score','SC_score','raw_SC_goodput'},cases);
writecsv(fullfile(out,'certified_choices.csv'),{'condition','H','label','diagnostic','method','budget_s','axis','candidate','G','loss','loss_CI_low','loss_CI_high','RF_gain','proxy_gain','certified_nonbaseline','pool_point_loss_over5_count','candidate_frames','certificate_lower_Z','forecast_seconds','baseline_fallback','RF_gain_CI_low','RF_gain_CI_high','proxy_gain_CI_low','proxy_gain_CI_high'},choices);
writecsv(fullfile(out,'certified_rankings.csv'),{'condition','H','label','diagnostic','method','point_reversals','pair_denominator','reversal_fraction','point_ties'},rankings);
writecsv(fullfile(out,'certified_frontier_members.csv'),{'condition','H','label','diagnostic','method','budget_s','axis','candidate','certified_pool','all125_eval_point_front','pool_eval_point_front'},frontiers);
save(fullfile(out,'certified_analysis.mat'),'cases','choices','rankings','frontiers');
if isempty(choices),fprintf('No completed conditions; no scientific summary generated.\n');return,end
fig=figure('Visible','off','Color','w','Position',[100 100 1100 700]);names={'Simple-guided','SC-guided','Direct SC'};colors=lines(3);styles={'-o','--s',':^'};markers={'o','s','^'};
for axis=1:2
 subplot(2,2,axis);hold on;
 for m=1:3
  keep=choices(:,4)==0&choices(:,5)==m&choices(:,7)==axis;d=choices(keep,:);budgets=unique(d(:,6));means=nan(size(budgets));
  for b=1:numel(budgets),means(b)=mean(d(d(:,6)==budgets(b),12+axis));end
  plot(budgets,100*means,styles{m},'Color',colors(m,:),'DisplayName',names{m});
 end
 xlabel('Total decision budget (s)');ylabel('Mean evaluated energy gain (%)');title(sprintf('Axis %d: %s',axis,axisname(axis)));legend('Location','best');grid on;
 subplot(2,2,axis+2);hold on;
 for m=1:3
  keep=choices(:,4)==0&choices(:,5)==m&choices(:,7)==axis;d=choices(keep,:);
  scatter(d(:,6)+3*(m-2),100*d(:,10),25,colors(m,:),markers{m},'filled','DisplayName',names{m});
 end
 yline(5,'k--','5% constraint');xlabel('Decision budget (s), method jitter');ylabel('Evaluated Goodput loss (%)');title('Independent evaluation; point estimates');grid on;
end
print(fig,fullfile(out,'certified_cost_gain_loss.png'),'-dpng','-r160');print(fig,fullfile(out,'certified_cost_gain_loss.pdf'),'-dpdf','-bestfit');close(fig);
% Show all candidates and the final certified sets for first completed random H.
first=choices(find(choices(:,4)==0,1),1);if isempty(first),return,end
a=load(fullfile(out,sprintf('condition_%02d.mat',first)));d=cases(cases(:,1)==first,:);
fig=figure('Visible','off','Color','w','Position',[100 100 1100 430]);
for axis=1:2
 subplot(1,2,axis);hold on;scatter(d(:,10),d(:,10+axis),14,[.65 .65 .65],'filled','DisplayName','All125 evaluated');
 for m=1:3,s=a.methods{m}.snapshots{end};ix=s.certified;scatter(d(ix,10),d(ix,10+axis),40,colors(m,:),markers{m},'DisplayName',names{m});end
 xlabel('Independent evaluated Goodput');ylabel(axisname(axis));title('Certified membership; not a true-front guarantee');legend('Location','best');grid on;
end
print(fig,fullfile(out,'certified_membership_example.png'),'-dpng','-r160');print(fig,fullfile(out,'certified_membership_example.pdf'),'-dpdf','-bestfit');close(fig);
fprintf('Analyzed %d completed conditions, %d selected-policy rows.\n',numel(unique(cases(:,1))),size(choices,1));
end
function s=axisname(axis)
if axis==1,s='RF input power (W)';else,s='Nonlinear proxy (A)';end
end
function member=pointfront(g,e)
g=g(:);e=e(:);member=true(numel(g),1);
for c=1:numel(g),member(c)=~any(g>=g(c)&e>=e(c)&(g>g(c)|e>e(c)));end
end
function writecsv(file,names,rows)
fid=fopen(file,'w');assert(fid>=0);guard=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',strjoin(names,','));
if ~isempty(rows),fprintf(fid,[repmat('%.17g,',1,size(rows,2)-1) '%.17g\n'],rows');end
end
