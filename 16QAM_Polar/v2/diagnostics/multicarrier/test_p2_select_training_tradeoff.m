function test_p2_select_training_tradeoff()
% Deterministic paired data, constraints, dominance, ties and rejection.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    purpose=repmat({'model_calibration'},6,1); control=repmat({'shaped'},6,1);
    seed=ones(6,1)*8401; snr_db=ones(6,1)*24; channel=[1;2;1;2;1;2];
    case_id={'a';'a';'b';'b';'c';'c'}; frames=10*ones(6,1);
    ber=[.05;.05;.06;.06;.2;.2]; goodput_cp=[.5;.5;.4;.4;.6;.6];
    rx_envelope_m2_l4=[1;1;2;2;3;3]; rx_envelope_m4_l4=[1;1;2;2;3;3];
    T=table(purpose,seed,channel,snr_db,case_id,control,frames,ber,goodput_cp,rx_envelope_m2_l4,rx_envelope_m4_l4);
    a=p2_select_training_tradeoff(T,.1,.3,1,1);
    assert(strcmp(a.selected_case,'b') && all(a.candidates.pareto(1:2)) && ~a.candidates.feasible(3));
    ties=T; ties.rx_envelope_m2_l4(3:4)=1; ties.rx_envelope_m4_l4(3:4)=1; ties.goodput_cp(3:4)=.5; ties.ber(3:4)=.05;
    tie=p2_select_training_tradeoff(ties,.1,.3,1,1); assert(strcmp(tie.selected_case,'a'));
    b=p2_select_training_tradeoff(T,.01,.3,1,1); assert(strcmp(b.status,'no_feasible') && isempty(b.selected_case));
    fails(@() p2_select_training_tradeoff(T(1:5,:),.1,.3,1,1),'tradeoff:Unpaired');
    bad=T; bad.purpose(:)={'test_seen'}; fails(@() p2_select_training_tradeoff(bad,.1,.3,1,1),'tradeoff:InvalidRole');
    bad=T; bad.rx_envelope_m4_l4(1)=NaN; fails(@() p2_select_training_tradeoff(bad,.1,.3,1,1),'tradeoff:InvalidMetrics');
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
