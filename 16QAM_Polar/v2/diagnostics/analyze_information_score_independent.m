function analyze_information_score_independent(out)
% Frame-paired descriptive assessment; does not tune or regenerate frames.
f=readmatrix(fullfile(out,'frames.csv'));p=readmatrix(fullfile(out,'predictions.csv'));
assert(size(f,1)==7200);assert(size(p,1)==96);rng(26111301,'twister');
cases=[];decisions=[];pairing=[];
for hi=1:8
 for label=[20 28]
  G=zeros(50,3);E=G;K=G;S=zeros(1,3);D=S;
  for c=1:3
   for fr=1:50
    z=f(f(:,1)==hi & f(:,2)==label & f(:,3)==fr & f(:,4)==c,:);assert(size(z,1)==3 && numel(unique(z(:,5)))==3);
    E(fr,c)=sum(sum(z(:,6:9)));K(fr,c)=sum(sum(z(:,10:13)));G(fr,c)=(K(fr,c)-E(fr,c))/(4*49*80);
   end
   q=p(p(:,1)==hi&p(:,2)==label&p(:,3)==c,:);S(c)=q(q(:,4)==80,5);D(c)=S(c)-q(q(:,4)==40,5);
   ix=randi(50,50,2000);b=mean(reshape(G(ix,c),50,2000),1);ci=prctile(b,[2.5 97.5]);
   cases=[cases;hi label c K(1,c) sum(E(:,c)) sum(K(:,c)) sum(E(:,c))/sum(K(:,c)) mean(G(:,c)) ci S(c) D(c)]; %#ok<AGROW>
  end
  assert(all(K(:,2)==K(:,3)));
  [~,selected]=max(S);[best,actual]=max(mean(G,1));loss=best-mean(G(:,selected));
  difference=G(:,2)-G(:,3);ix=randi(50,50,2000);ci=prctile(mean(difference(ix),1),[2.5 97.5]);
  q=p(p(:,1)==hi&p(:,2)==label&p(:,4)==40,:);[~,sel40]=max(q(:,5));
  decisions=[decisions;hi label selected actual loss best-mean(G(:,1)) S(2)-S(3) mean(difference) ci selected==sel40]; %#ok<AGROW>
  for a=1:2,for b=a+1:3
   difference=G(:,a)-G(:,b);ix=randi(50,50,2000);ci=prctile(mean(difference(ix),1),[2.5 97.5]);
   pairing=[pairing;hi label a b S(a)-S(b) mean(difference) ci]; %#ok<AGROW>
  end,end
 end
end
writetable(array2table(cases,'VariableNames',{'H','label','candidate','K','errors','bits','BER','goodput','low','high','score','order_delta'}),fullfile(out,'cases.csv'));
writetable(array2table(decisions,'VariableNames',{'H','label','selected','empirical_best','empirical_loss','baseline_loss','equal_score_delta','equal_goodput_delta','equal_low','equal_high','order_selection_stable'}),fullfile(out,'decisions.csv'));
writetable(array2table(pairing,'VariableNames',{'H','label','a','b','score_delta','goodput_delta','low','high'}),fullfile(out,'paired_comparisons.csv'));
figure('Visible','off');subplot(1,2,1);errorbar(decisions(:,7),decisions(:,8),decisions(:,8)-decisions(:,9),decisions(:,10)-decisions(:,8),'o');xline(0);yline(0);xlim([-.001 max(decisions(:,7))*1.1]);xlabel('Score difference, candidate 2 - 3');ylabel('Measured Goodput difference');grid on;
subplot(1,2,2);plot(decisions(:,5),'o-');hold on;plot(decisions(:,6),'x-');legend('Information score','Largest K');xlabel('Fixed-H / noise case');ylabel('Empirical Goodput selection loss');ylim([-.001 .001]);grid on;
print(gcf,fullfile(out,'validation.png'),'-dpng','-r180');print(gcf,fullfile(out,'validation.pdf'),'-dpdf','-bestfit');close(gcf);
disp(array2table(decisions));fprintf('frames=2400 bits=%g errors=%g\n',sum(f(:,10:13),'all'),sum(f(:,6:9),'all'));
end
