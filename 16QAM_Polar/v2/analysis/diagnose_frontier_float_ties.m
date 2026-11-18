function diagnose_frontier_float_ties(out)
% Operate on native MAT doubles; CSV decimal formatting can collapse values.
pairs=nchoosek(1:125,2);rows=[];
for h=1:11
 for label=[16 20 24 28]
  file=fullfile(out,sprintf('prediction_h%02d_l%02d.mat',h,label));if ~isfile(file),continue,end
  z=load(file,'rows');assert(size(z.rows,1)==125);
  for method=1:2
   v=z.rows(:,3+method);difference=v(pairs(:,1))-v(pairs(:,2));tolerance=64*eps(max(abs(v)));
   rows=[rows;h label method tolerance sum(difference==0) sum(difference~=0 & abs(difference)<=tolerance)]; %#ok<AGROW>
  end
 end
end
writetable(array2table(rows,'VariableNames',{'H','label','method','floating_tolerance','exact_ties','additional_nearties'}),fullfile(out,'floating_point_ties.csv'));
disp(array2table(rows(rows(:,1)==9,:),'VariableNames',{'H','label','method','floating_tolerance','exact_ties','additional_nearties'}));
end
