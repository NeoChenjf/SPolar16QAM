function plot_information_frontier_main(out)
% Plot complete random-H cases separately from diagnostic conditions.
f=readtable(fullfile(out,'analysis_frontiers.csv'));c=readtable(fullfile(out,'analysis_cases.csv'));r=readtable(fullfile(out,'analysis_rankings.csv'));
f=f(f.H<=8,:);c=c(c.H<=8,:);r=r(r.H<=8,:);assert(~isempty(f));
a=f(f.energy_axis==1&f.method==1,:);[~,i]=max(a.mean_regret);H=a.H(i);label=a.label(i);x=c(c.H==H&c.label==label,:);
fig=figure('Visible','off','Position',[100 100 1400 550]);subplot(1,2,1);scatter(x.goodput,x.rf_W*1e6,12,[.65 .65 .65],'filled');hold on;
scatter(x.goodput(x.actual_front_RF~=0),x.rf_W(x.actual_front_RF~=0)*1e6,45,'k','o');
scatter(x.goodput(x.simple_front_RF~=0),x.rf_W(x.simple_front_RF~=0)*1e6,30,'b','x');
scatter(x.goodput(x.sc_front_RF~=0),x.rf_W(x.sc_front_RF~=0)*1e6,36,'r','+');
legend('Candidates','Actual frontier','Simple score frontier','SC prediction frontier','Location','best');xlabel('Measured Goodput');ylabel('Shared RF model input power (µW)');title(sprintf('Largest simple mean regret, H%d label%d',H,label));grid on;
subplot(1,2,2);j=r(r.method==1,:);k=r(r.method==2,:);assert(isequal(j(:,{'H','label'}),k(:,{'H','label'})));plot(j.disagree/7750,'bo-');hold on;plot(k.disagree/7750,'r+-');xlabel('Random-H / noise case');ylabel('Fraction of point ranking reversals');legend('Simple score','SC prediction','Location','best');grid on;
print(fig,fullfile(out,'frontier_and_ranking.png'),'-dpng','-r180');print(fig,fullfile(out,'frontier_and_ranking.pdf'),'-dpdf','-bestfit');close(fig);
fig=figure('Visible','off','Position',[100 100 1600 500]);
energy_names={'proxy_m30_A','proxy_A','proxy_m20_A'};
simple_names={'simple_front_m30','simple_front_proxy','simple_front_m20'};
sc_names={'sc_front_m30','sc_front_proxy','sc_front_m20'};
actual_names={'actual_front_m30','actual_front_proxy','actual_front_m20'};
levels=[-30 -25 -20];baseline=find(x.candidate==125);assert(numel(baseline)==1);
for k=1:3
 subplot(1,3,k);energy=x.(energy_names{k});gain=100*(energy/energy(baseline)-1);loss=100*x.goodput_loss_vs_uniform;
 scatter(loss,gain,10,[.65 .65 .65],'filled');hold on;
 mask=x.(actual_names{k})~=0;scatter(loss(mask),gain(mask),35,'k','o');
 mask=x.(simple_names{k})~=0;scatter(loss(mask),gain(mask),25,'b','x');
 mask=x.(sc_names{k})~=0;scatter(loss(mask),gain(mask),30,'r','+');
 xlabel('Measured Goodput loss vs uniform (%)');ylabel('Shared diode proxy gain vs uniform (%)');title(sprintf('Reference %d dBm',levels(k)));grid on;
end
legend('Candidates','Actual frontier','Simple score frontier','SC prediction frontier','Location','best');
sgtitle(sprintf('Conditional waveform proxy, H%d label%d; no circuit calibration',H,label));
print(fig,fullfile(out,'diode_proxy_sensitivity.png'),'-dpng','-r180');print(fig,fullfile(out,'diode_proxy_sensitivity.pdf'),'-dpdf','-bestfit');close(fig);
end
