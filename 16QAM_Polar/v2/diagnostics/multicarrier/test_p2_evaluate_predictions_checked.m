function test_p2_evaluate_predictions_checked()
% Numerical timing guard regression; synthetic channels are not provenance.
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    addpath(root); setup_paths;
    T=table(repmat({'test_seen'},10,1),(1:10)',ones(10,1)*100, ...
        ones(10,1)*.01,ones(10,1)*.01,ones(10,1)*.3,ones(10,1)*.297, ...
        ones(10,1),ones(10,1),ones(10,1)*.01, ...
        'VariableNames',{'purpose','channel','error_count','ber','ber_predicted','rate_cp', ...
        'goodput_cp','elapsed_seconds','frames','online_seconds'});
    r=p2_evaluate_predictions_checked(T); assert(r.use_gate_pass(1) && ~r.use_gate_pass(2));
    for bad=[0,-1,nan,inf]
        U=T; U.online_seconds(1)=bad; rejected=false;
        try, p2_evaluate_predictions_checked(U); catch e, rejected=strcmp(e.identifier,'predictioncheck:InvalidTiming'); end
        assert(rejected,'Invalid online timing was not rejected.');
    end
    U=T; U.elapsed_seconds(1)=0; rejected=false;
    try, p2_evaluate_predictions_checked(U); catch e, rejected=strcmp(e.identifier,'predictioncheck:InvalidTiming'); end
    assert(rejected);
    U=T; U.frames(1)=1.5; rejected=false;
    try, p2_evaluate_predictions_checked(U); catch e, rejected=strcmp(e.identifier,'predictioncheck:InvalidTiming'); end
    assert(rejected);
    U=T; U.channel(:)=1; r=p2_evaluate_predictions_checked(U); assert(~r.sufficient(1) && ~r.use_gate_pass(1));
end
