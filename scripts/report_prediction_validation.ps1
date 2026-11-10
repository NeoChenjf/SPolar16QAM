param([Parameter(Mandatory=$true)][string]$RunDirectory)
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$runPath = (Resolve-Path -LiteralPath $RunDirectory).Path
if (!(Test-Path -LiteralPath (Join-Path $runPath 'completed.mat'))) { throw 'Validation is not terminal.' }
$reportPath = Join-Path $runPath ('analysis_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Path $reportPath | Out-Null
Copy-Item -LiteralPath (Join-Path $runPath 'validation.csv') -Destination $reportPath
& python -B (Join-Path $PSScriptRoot 'report_prediction_validation.py') $reportPath
if ($LASTEXITCODE -ne 0) { throw 'Numerical evaluation failed.' }
$v2 = (Join-Path $project '16QAM_Polar/v2').Replace("'", "''")
$r = $runPath.Replace("'", "''")
$o = $reportPath.Replace("'", "''")
$code = @"
cd('$v2');setup_paths;run_dir='$r';out='$o';
finished=load(fullfile(run_dir,'completed.mat'));T=readtable(fullfile(out,'validation.csv'));
assert(isequal(size(T,1),size(finished.T,1)));B=load(fullfile(run_dir,'frozen_predictor.mat'));G=[];maxdiff=0;inclusive_times=zeros(height(T),1);
for i=1:height(T)
 ct=find(strcmp(T.control{i},{'shaped','random_s','donor_s'}));sn=find([20 24 28]==T.reference_db(i));
 z=load(fullfile(run_dir,sprintf('raw_%d_%d_%d_%d.mat',T.split(i),T.channel(i),sn,ct)));a=z.artifact;
 assert(sum(a.errors(:))==T.errors(i) && sum(a.bits(:))==T.bits(i));
 assert(a.frames==T.frames(i));
 clock=tic;H=fft(a.h,64);[~,order]=sort(abs(H).^2,'descend');groups=ones(64,1)*3;groups(order(1:22))=1;groups(order(23:43))=2;locations=cell(1,3);
 for gg=1:3,ix=find(repmat(groups==gg,1,49));locations{gg}=ix(1:1024);end
 names={'seen','unseen'};key=sprintf('%d/%d/%s_%s',T.split(i),sn,names{T.split(i)},T.control{i});hit=find(strcmp({B.entries.key},key));assert(isscalar(hit));
 P=p2_predict_cheap(H,a.N0,64,B.entries(hit).states,locations,B.model);inclusive_times(i)=toc(clock);
 maxdiff=max(maxdiff,abs(P.ber-T.predicted(i)));
 rate=sum(a.bits(:))/a.frames/(4*80*49);assert(abs(rate-T.rate_cp(i))<1e-12);
 for g=1:3
  G(end+1,:)=[T.split(i),T.channel(i),T.reference_db(i),ct,g,sum(a.errors(g,:)),sum(a.bits(g,:)),P.per_group(g)];
 end
end
assert(maxdiff<1e-12);writematrix(G,fullfile(out,'group_counts_predictions.csv'));
inclusive=T;inclusive.original_online_seconds=T.online_seconds;inclusive.online_seconds=inclusive_times;writetable(inclusive,fullfile(out,'inclusive_timing_validation.csv'));
f=figure('Visible','off','Position',[100 100 1200 800]);
for si=1:2
 q=T(T.split==si,:);subplot(2,3,(si-1)*3+1);scatter(q.ber,q.predicted,12,q.reference_db,'filled');hold on;plot([0 .3],[0 .3],'k--');axis([0 .3 0 .3]);grid on;colorbar;xlabel('Observed BER');ylabel('Predicted BER');title(sprintf('%s: all cells',names{si}));
 subplot(2,3,(si-1)*3+2);e=q(q.errors>=20 & q.ber>=1e-4 & q.ber<=.1,:);loglog(e.ber,e.predicted,'.');hold on;loglog([1e-4 .1],[1e-4 .1],'k--');grid on;xlabel('Observed BER');ylabel('Predicted BER');title('Eligible waterfall cells');
 subplot(2,3,(si-1)*3+3);plot(q.reference_db,q.rate_cp.*(q.ber-q.predicted),'.');hold on;plot([19 29],[0 0],'k--');grid on;xlabel('Reference label (diagnostic)');ylabel('Goodput prediction error');title('All valid cells');
end
saveas(f,fullfile(out,'independent_prediction.png'));print(f,fullfile(out,'independent_prediction.pdf'),'-dpdf','-bestfit');close(f);
f=figure('Visible','off','Position',[100 100 1100 420]);
for si=1:2
 subplot(1,2,si);hold on;
 for g=1:3
  q=G(G(:,1)==si & G(:,5)==g,:);scatter(q(:,6)./q(:,7),q(:,8),9,'filled');
 end
 all_groups=G(G(:,1)==si,:);lim=min(1,max([.5;all_groups(:,6)./all_groups(:,7);all_groups(:,8)])*1.05);
 plot([0 lim],[0 lim],'k--');axis([0 lim 0 lim]);grid on;legend('Group 1','Group 2','Group 3','Equality','Location','best');xlabel('Observed group BER');ylabel('Predicted group BER');title(names{si});
end
saveas(f,fullfile(out,'independent_group_prediction.png'));print(f,fullfile(out,'independent_group_prediction.pdf'),'-dpdf','-bestfit');close(f);
f=figure('Visible','off','Position',[100 100 900 400]);
for si=1:2
 q=T(T.split==si,:);subplot(1,2,si);semilogy([1 2],[mean(q.simulation_seconds./q.frames),mean(inclusive_times(T.split==si))],'o-','LineWidth',1.5);xlim([.5 2.5]);set(gca,'XTick',[1 2],'XTickLabel',{'Simulation/frame','Full online'});ylabel('Seconds (log scale)');title(names{si});grid on;
end
saveas(f,fullfile(out,'independent_timing.png'));print(f,fullfile(out,'independent_timing.pdf'),'-dpdf','-bestfit');close(f);
fprintf('RAW_RECONSTRUCTION_MAX_DIFF %.12g\n',maxdiff);fprintf('TOTAL_CASE_FRAMES %d elapsed %.3f stopped %d\n',finished.completed_frames,finished.elapsed,finished.stop);fprintf('REPORT_DIRECTORY=%s\n',out);
"@
& 'D:/matlab/bin/matlab.exe' -batch $code
if ($LASTEXITCODE -ne 0) { throw 'MATLAB raw verification/report failed.' }
