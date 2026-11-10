function summarize_fixed_h()
root=fileparts(fileparts(mfilename('fullpath')));out=fullfile(root,'results','20261110_154338_fixed_h');d=load(fullfile(out,'existing.mat'));x=d.rows;summary=[];
for h=1:3,for p=1:2,for label=[20 28]
 a=x(x(:,1)==h & x(:,3)==p & x(:,2)==label,:);v=zeros(10,6);
 for f=1:10
  b=a(a(:,4)==f,:);v(f,:)=[sum(b(:,7))/sum(b(:,8)) sum(b(:,9))/sum(b(:,8)) sum(b(:,14))/sum(b(:,8)) mean(~isnan(b(:,12))) sum(b(:,15))/max(1,sum(b(:,16))) sum(b(:,13)==1)];
 end
 summary=[summary;h p label mean(v) 2.262*std(v)/sqrt(10)]; %#ok<AGROW>
end;end;end
writematrix(summary,fullfile(out,'existing_summary.csv'));save(fullfile(out,'existing_summary.mat'),'summary');disp(summary(:,1:7));
f=figure('Visible','off');errorbar(1:12,summary(:,4),summary(:,10),'o-');hold on;errorbar(1:12,summary(:,5),summary(:,11),'s--');ylabel('I bit error rate');xlabel('H / p / reference-label cell');legend('Actual SC','Genie true prefix');saveas(f,fullfile(out,'existing_reliability.png'));close(f);
end
