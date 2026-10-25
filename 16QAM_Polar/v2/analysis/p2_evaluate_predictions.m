function report = p2_evaluate_predictions(T)
%P2_EVALUATE_PREDICTIONS Predeclared use gates; no fitting/test feedback.
% At least 20 observed errors per cell; at least 10 eligible independent-channel
% cells per split are required. All valid cells count in Goodput MAE.
    assert(all(ismember(T.purpose,{'test_seen','test_unseen'})));
    assert(all(isfinite(T.ber_predicted)&T.ber_predicted>=0&T.ber_predicted<=1));
    splits={'test_seen','test_unseen'}; rows=cell(2,10);
    for i=1:2
        S=T(strcmp(T.purpose,splits{i}),:);
        eligible=S.error_count>=20 & S.ber>=1e-4 & S.ber<=.1;
        E=S(eligible,:); sufficient=height(E)>=10 && numel(unique(E.channel))>=10;
        med=nan; p90=nan;
        if ~isempty(E)
            factor=max(E.ber_predicted./E.ber,E.ber./max(E.ber_predicted,realmin));
            med=median(factor); p90=prctile(factor,90);
        end
        gp=nan; speed=nan;
        if ~isempty(S)
            gp=mean(abs(S.rate_cp.*(1-S.ber_predicted)-S.goodput_cp));
            % Same frame and group workload normalized to one-frame prediction.
            speed=sum(S.elapsed_seconds./S.frames)/sum(S.online_seconds);
        end
        pass=sufficient && med<=2 && p90<=5 && gp<=.02 && speed>=10;
        rows(i,:)={splits{i},height(S),height(E),sufficient,med,p90,gp,speed,pass, ...
            'Exploratory use gate; not a communication reliability guarantee'};
    end
    report=cell2table(rows,'VariableNames',{'split','cells','eligible_cells','sufficient', ...
        'median_factor','p90_factor','goodput_mae','online_speedup','use_gate_pass','scope'});
end
