$ErrorActionPreference = 'Stop'
$code = @'
cd('C:/Users/11956/Desktop/研究生毕设/16QAM_Polar/v2');setup_paths;
src=fullfile('results','20261109_114849_prediction_group_loss_development');out=fullfile('results',[datestr(now,'yyyymmdd_HHMMSS') '_prediction_candidate_frozen']);mkdir(out);
M=jsondecode(fileread(fullfile(src,'development_models.json')));model=M.cheap;D=readtable(fullfile(src,'group_predictions.csv'));T=readtable(fullfile(src,'total_predictions.csv'));
dirs={'20261107_104154_p2_v2_batch_pilot_test_seen_033e7056','20261107_105616_p2_v2_batch_pilot_test_unseen_92681c0c'};
entries=struct('key',{},'states',{},'construction_snr_db',{});R=[];maxerr=0;build_seconds=0;
for si=1:2
 A=readtable(fullfile('results',dirs{si},'repetitions.csv'));
 for i=1:height(A)
  sn=find([20 24 28]==A.snr_db(i));z=load(fullfile('results',dirs{si},sprintf('raw_c%d_s%d_%s.mat',A.channel(i),sn,A.case_id{i})),'artifact');a=z.artifact;
  key=sprintf('%d/%d/%s',si,sn,A.case_id{i});hit=find(strcmp({entries.key},key));
  if isempty(hit)
   clock=tic;states=cell(1,3);for g=1:3,states{g}=p2_prepare_state(a.states{g},a.construction_snr_db,a.states{g}.kind);end;build_seconds=build_seconds+toc(clock);
   for g=1:3,assert(isequal(states{g}.I,a.states{g}.I));end
   entries(end+1)=struct('key',key,'states',{states},'construction_snr_db',a.construction_snr_db);hit=numel(entries);
  end
  for g=1:3,assert(strcmp(entries(hit).states{g}.fingerprint,a.states{g}.fingerprint));end
  clock=tic;hit=find(strcmp({entries.key},key));P=p2_predict_cheap(a.H,a.noise_complex_time_power,64,entries(hit).states,a.layout.locations,model);seconds=toc(clock);
  idx=D.split==si+1 & D.channel==A.channel(i) & D.reference_db==A.snr_db(i) & strcmp(D.case_id,A.case_id{i});Q=sortrows(D(idx,:),'group');maxerr=max(maxerr,max(abs(P.per_group-Q.prediction_cheap)));
  R(end+1,:)=[si+1,A.channel(i),A.snr_db(i),seconds,A.elapsed_seconds(i)/A.frames(i)];
 end
 fprintf('FROZEN_SPLIT %d\n',si+1);
end
assert(maxerr<1e-12);
save(fullfile(out,'frozen_predictor.mat'),'model','entries','build_seconds','src');
clock=tic;B=load(fullfile(out,'frozen_predictor.mat'));load_seconds=toc(clock);
writematrix(R,fullfile(out,'cached_online_timing.csv'));save(fullfile(out,'timing.mat'),'R','maxerr','build_seconds','load_seconds');
copyfile(fullfile(src,'development_models.json'),fullfile(out,'development_models.json'));copyfile('analysis/p2_predict_cheap.m',fullfile(out,'p2_predict_cheap_source.m'));
f=figure('Visible','off','Position',[100 100 1200 700]);
for si=2:3
 q=T(T.split==si & strcmp(T.model,'cheap'),:);u=D(D.split==si,:);[~,ix]=unique(strcat(string(u.channel),'/',string(u.reference_db),'/',string(u.case_id)),'stable');u=u(ix,:);
 subplot(2,2,(si-2)*2+1);scatter(u.total_ber,u.old_prediction,12,'filled');hold on;plot([0 .2],[0 .2],'k--');axis([0 .2 0 .2]);grid on;title(sprintf('Original predictor / development %d',si));xlabel('Observed BER');ylabel('Predicted BER');
 subplot(2,2,(si-2)*2+2);scatter(q.observed,q.predicted,12,q.reference_db,'filled');hold on;plot([0 .2],[0 .2],'k--');axis([0 .2 0 .2]);grid on;title(sprintf('Frozen cheap predictor / development %d',si));xlabel('Observed BER');ylabel('Predicted BER');
end
saveas(f,fullfile(out,'ber_comparison.png'));print(f,fullfile(out,'ber_comparison.pdf'),'-dpdf','-bestfit');close(f);
f=figure('Visible','off','Position',[100 100 1100 420]);
for si=2:3
 subplot(1,2,si-1);q=T(T.split==si & strcmp(T.model,'cheap'),:);scatter(q.reference_db,q.rate.*(q.observed-q.predicted),12,'filled');grid on;xlabel('Reference label (diagnostic only)');ylabel('Goodput prediction error');title(sprintf('Frozen cheap / observed development %d',si));
end
saveas(f,fullfile(out,'goodput_errors.png'));print(f,fullfile(out,'goodput_errors.pdf'),'-dpdf','-bestfit');close(f);
for si=2:3
 q=R(R(:,1)==si,:);fprintf('FROZEN_SPEED split=%d cached=%.3f median_ms=%.4f\n',si,sum(q(:,5))/sum(q(:,4)),1000*median(q(:,4)));
end
fprintf('OFFLINE states=%d build_seconds=%.6f load_seconds=%.6f maxdiff=%.12g\n',numel(entries),build_seconds,load_seconds,maxerr);
fprintf('FROZEN_DIR=%s\n',out);
'@
& 'D:/matlab/bin/matlab.exe' -batch $code
exit $LASTEXITCODE
