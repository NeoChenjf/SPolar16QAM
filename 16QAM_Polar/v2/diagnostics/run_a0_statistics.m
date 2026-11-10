function run_a0_statistics()
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);setup_paths;
out=fullfile(root,'results',[datestr(now,'yyyymmdd_HHMMSS') '_A0_statistics']);mkdir(out);diary(fullfile(out,'run_log.txt'));
rng(11010072,'twister'); seed=11010072; count=0; rows=[];
labels=de2bi((0:15)',4,'left-msb'); c=qammod((0:15)',16,'gray','UnitAveragePower',true);
for snr=[8 12]
 n=100000; tx=randi([0 15],n,1); sigma=sqrt(10^(-snr/10)/2); y=c(tx+1)+sigma*(randn(n,1)+1i*randn(n,1));count=count+n;
 save(fullfile(out,sprintf('raw_%d.mat',snr)),'tx','y','sigma','seed','count');
 L=reshape(llr_16qam_gray_LSE(y,sigma),4,[])'; e=(L<0)~=labels(tx+1,:); v=mean(e,2); ser=any(e,2);
 % Independent integration of one-dimensional Gray decision regions.
 levels=[-3 -1 1 3]/sqrt(10); edge=[-inf -2 0 2 inf]/sqrt(10); bb=[0 0;0 1;1 1;1 0];pb=0;ps=0;
 for a=1:4
  for b=1:4
   prob=.5*erfc(-(edge(b+1)-levels(a))/(sigma*sqrt(2)))-.5*erfc(-(edge(b)-levels(a))/(sigma*sqrt(2)));
   pb=pb+prob*sum(bb(a,:)~=bb(b,:))/8;ps=ps+prob*(a~=b)/4;
  end
 end
 expected_ser=1-(1-ps)^2; z=sqrt(2)*erfcinv(.01/4); half=z*[std(v) std(double(ser))]/sqrt(n);
 rows=[rows;snr mean(v) pb half(1) mean(ser) expected_ser half(2)]; %#ok<AGROW>
 save(fullfile(out,'summary.mat'),'rows','seed','count');disp(rows(end,:));
end
writematrix(rows,fullfile(out,'summary.csv'));f=figure('Visible','off');errorbar(rows(:,1),rows(:,2),rows(:,4),'o-');hold on;plot(rows(:,1),rows(:,3),'x--');xlabel('Actual Es/N0 (dB)');ylabel('BER');legend('Independent symbols','Region integral');saveas(f,fullfile(out,'BER.png'));close(f);diary off;
end
