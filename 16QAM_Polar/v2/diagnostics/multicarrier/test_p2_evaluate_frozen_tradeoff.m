function test_p2_evaluate_frozen_tradeoff()
% Verify test isolation, paired deltas, and missing/mismatched channels.
    root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root); setup_paths();
    purpose=repmat({'test_seen'},4,1); control=repmat({'shaped'},4,1);
    seed=ones(4,1)*8501; snr_db=ones(4,1)*24; channel=[1;2;1;2];
    case_id={'selected';'selected';'base';'base'}; frames=10*ones(4,1);
    ber=[.04;.06;.08;.10]; goodput_cp=[.5;.4;.45;.35];
    rx_envelope_m2_l4=[2;2;1;1]; rx_envelope_m4_l4=[3;3;2;2];
    noise_complex_time_power=ones(4,1)*.01;
    T=table(purpose,seed,channel,snr_db,case_id,control,frames,ber,goodput_cp, ...
        rx_envelope_m2_l4,rx_envelope_m4_l4,noise_complex_time_power);
    frozen=struct('status','selected','selected_case','selected','training_seed',8401, ...
        'reference_snr_db',24,'beta2',1,'beta4',2,'max_ber',.1,'min_goodput',.3);
    x=p2_evaluate_frozen_tradeoff(frozen,T,{'base'});
    assert(abs(x.delta_ber+.04)<1e-12 && abs(x.delta_goodput-.05)<1e-12 && ...
        abs(x.delta_proxy-3)<1e-12 && x.selected_channels_meeting_thresholds==2);
    fails(@() p2_evaluate_frozen_tradeoff(frozen,T(1:3,:),{'base'}),'tradeofftest:Unpaired');
    bad=T; bad.seed(:)=8401; fails(@() p2_evaluate_frozen_tradeoff(frozen,bad,{'base'}),'tradeofftest:InvalidRole');
    bad=T; bad.noise_complex_time_power(3)=.02;
    fails(@() p2_evaluate_frozen_tradeoff(frozen,bad,{'base'}),'tradeofftest:Unpaired');
end
function fails(f,id)
    caught=false; try, f(); catch e, caught=strcmp(e.identifier,id); end
    assert(caught,'Expected error %s',id);
end
