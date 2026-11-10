function report = p2_evaluate_predictions_checked(T)
%P2_EVALUATE_PREDICTIONS_CHECKED Reject invalid timers before exploratory gates.
% This numeric check does not establish provenance or independence.
    required={'purpose','channel','error_count','ber','ber_predicted','rate_cp', ...
        'goodput_cp','elapsed_seconds','frames','online_seconds'};
    assert(istable(T) && all(ismember(required,T.Properties.VariableNames)), ...
        'predictioncheck:MissingFields','Required evaluation columns are missing.');
    fields={'elapsed_seconds','online_seconds','frames'};
    for k=1:numel(fields)
        v=T.(fields{k});
        assert(isnumeric(v) && isreal(v) && iscolumn(v) && ...
            all(isfinite(v) & v>0), ...
            'predictioncheck:InvalidTiming','Times and frame counts must be finite and strictly positive.');
    end
    assert(all(T.frames==fix(T.frames)), ...
        'predictioncheck:InvalidTiming','Frame counts must be integers.');
    report=p2_evaluate_predictions(T);
    nonempty=report.cells>0;
    assert(all(isfinite(report.online_speedup(nonempty))), ...
        'predictioncheck:InvalidTiming','Normalized speed must be finite.');
    report.scope(:)={'Numeric exploratory gate only; source independence is not verified'};
end
