function analyze_fixed_h_batch()
root=fileparts(fileparts(mfilename('fullpath')));out=fullfile(root,'results','20261110_154811_fixed_h_E');files=dir(fullfile(out,'summary_*.mat'));assert(numel(files)==1200);rows=[];
for j=1:numel(files)
 d=load(fullfile(out,files(j).name));v=zeros(1,10);
 for g=1:3
  r=d.records{g};c=r.counts;assert(all(c(:)>=0));assert(all(c(:,1)<=c(:,2)));assert(all(c(:,3)<=c(:,4)));v=v+[sum(c(:,1)) sum(c(:,2)) sum(c(:,6)) sum(r.propagation(:,1)) sum(~isnan(r.first(:,1))) sum(r.first(:,2)==1) sum(c(:,3)) sum(c(:,4)) sum(r.propagation(:,2)) sum(r.propagation(:,3))];
 end
 rows=[rows;d.hi d.pi d.label d.frame v]; %#ok<AGROW>
end
writematrix(rows,fullfile(out,'frame_metrics.csv'));summary=[];
for h=1:3,for p=1:2,for label=[20 28]
 a=sortrows(rows(rows(:,1)==h & rows(:,2)==p & rows(:,3)==label,:),4);assert(size(a,1)==100 && isequal(a(:,4),(1:100)'));
 v=[a(:,5)./a(:,6) a(:,7)./a(:,6) (a(:,5)-a(:,7))./a(:,6) a(:,8)./a(:,6) a(:,9)/12 a(:,10)/12 a(:,11)./max(1,a(:,12)) a(:,13)./max(1,a(:,14))];
 summary=[summary;h p label mean(v) 1.984*std(v)/10 sum(a(:,5)) sum(a(:,6)) sum(a(:,7)) sum(a(:,8))]; %#ok<AGROW>
end;end;end
writematrix(summary,fullfile(out,'cell_summary.csv'));save(fullfile(out,'analysis.mat'),'rows','summary');disp(summary(:,1:7));
f=figure('Visible','off');subplot(1,2,1);errorbar(1:12,summary(:,4),summary(:,12),'o-');hold on;errorbar(1:12,summary(:,5),summary(:,13),'s--');legend('Actual SC','Genie');xlabel('H / p / reference cell');ylabel('Information BER');subplot(1,2,2);errorbar(1:12,summary(:,6),summary(:,14),'d-');xlabel('H / p / reference cell');ylabel('Paired actual minus genie');saveas(f,fullfile(out,'reliability.png'));close(f);
f=figure('Visible','off');plot(1:12,summary(:,7)./summary(:,4),'o-');ylim([0 1.02]);ylabel('Fraction of I errors after first free-bit error');xlabel('H / p / reference cell');saveas(f,fullfile(out,'after_first.png'));close(f);
end
