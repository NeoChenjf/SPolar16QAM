function test_p2_mechanism()
%TEST_P2_MECHANISM Behavioral tests for controls, likelihood, GA and leakage guards.
    previous_rng=rng; original_path=path;
    restore=onCleanup(@() local_restore(previous_rng,original_path)); %#ok<NASGU>
    here=fileparts(mfilename('fullpath')); root=fileparts(fileparts(here));
    addpath(root); setup_paths(); addpath(fullfile(root,'..','v3','polar'));
    N=16; rng(1901,'twister');
    source=build_source_entropy_partition(N,[.5,.3,.5,.3],.1,200,9001);
    uniform=build_source_entropy_partition(N,ones(1,4)*.5,.1,200,9001);
    shaped=p2_prepare_state(source,24,'shaped');
    same=p2_prepare_state(source,24,'same_k_i',shaped);
    native=p2_prepare_state(uniform,24,'native');
    assert(isequal(same.I,shaped.I) && isequal(same.K,shaped.K));
    assert(all(same.S_size==0) && all(same.p_vec==.5));
    assert(all(native.K==N/2) && all(native.S_size==0));
    auxiliary=randi([0,1],N,4); donor=randi([0,1],N,4); payload=randi([0,1],N,4);
    random_state=p2_prepare_state(source,24,'random_s');
    donor_state=p2_prepare_state(source,24,'donor_s');
    assert(isequal(random_state.I,shaped.I) && isequal(random_state.S,shaped.S) && isequal(random_state.F,shaped.F));
    for state={random_state,donor_state}
        block=p2_transmit_block(state{1},payload,auxiliary,donor);
        decoded=p2_decode_block(2.7*block.symbols,.001,2.7,block,true);
        assert(sum(decoded.errors)==0 && sum(decoded.info_bits)==sum(shaped.K));
        changed=p2_transmit_block(state{1},1-payload,auxiliary,donor);
        donor_reference=p2_transmit_block(shaped,donor);
        for b=1:4
            idx=state{1}.S{b}; assert(isequal(block.u(idx,b),changed.u(idx,b)));
            if strcmp(state{1}.kind,'random_s'), expected=auxiliary(idx,b);
            else, expected=donor_reference.u(idx,b); end
            assert(isequal(block.u(idx,b),expected));
        end
    end
    proof_random=p2_uniformity_contract(random_state,'I_union_S'); assert(proof_random.uniform_exact);
    [~,role,required]=p2_distribution_reference(donor_state,ones(16,1)/16);
    assert(~required && contains(role,'not_uniform_target'));
    % Exhaustive PMF proof distinguishes fixed-zero outputs from fair outputs.
    tiny=struct('N',4,'S_size',zeros(1,4),'I',{{1,1,1,1}});
    proof=p2_uniformity_contract(tiny); empirical=zeros(16,1);
    for message=0:15
        bits=de2bi(message,4,'left-msb'); x=zeros(4,4);
        for bit=1:4
            u=zeros(4,1); u(1)=bits(bit); x(:,bit)=polar_encoder(u);
        end
        empirical=empirical+accumarray(bi2de(x,'left-msb')+1,1,[16,1])/64;
    end
    assert(max(abs(empirical-proof.model_pmf))<1e-12 && proof.tv_from_uniform>.05);
    tiny.I={4,4,4,4}; fair=p2_uniformity_contract(tiny); assert(fair.uniform_exact);
    for state={shaped,same,native}
        base=randi([0,1],N,4); block=p2_transmit_block(state{1},base);
        d=p2_decode_block(2.7*block.symbols,.001,2.7,block,true);
        assert(sum(d.errors)==0 && sum(d.oracle_errors)==0,'Nonzero message loopback failed.');
        assert(isequal(block.u(state{1}.I{1},1),block.payload{1}));
    end
    % Independent exhaustive check: true-prefix decision LLR for N=4 against
    % direct max-log likelihood over ALL compatible future bits.
    llr=[.7;-1.2;.4;2.1]; truth=[1;0;1;0];
    [~,trace]=sc_decode_forced_full(llr,true(4,1),truth);
    all_u=de2bi((0:15)',4,'left-msb'); scores=zeros(16,1);
    for i=1:16
        x=polar_encoder(all_u(i,:)'); scores(i)=sum((1-2*x).*llr)/2;
    end
    for bit=1:4
        mask=all(all_u(:,1:bit-1)==truth(1:bit-1)',2);
        expected=max(scores(mask&all_u(:,bit)==0))-max(scores(mask&all_u(:,bit)==1));
        assert(abs(trace(bit)-expected)<1e-10,'Forced-prefix/max-log mismatch.');
    end
    % Nonidentical GA reduces to its own constant-channel recursion; index
    % changes must affect predictions, even when |I| stays the same.
    st=struct('N',4,'I',{{1,1,1,1}},'K',ones(1,4));
    a=p2_predict_ga(ones(4,4)*2,st); st.I={4,4,4,4};
    b=p2_predict_ga(ones(4,4)*2,st); assert(b.ber_raw<a.ber_raw);
    bad=false; try, p2_predict_ga(-ones(4,4),st); catch, bad=true; end; assert(bad);
    % Production LLR versus independent direct likelihood.
    symbols=qammod((0:15)',16,'gray','UnitAveragePower',true);
    labels=de2bi((0:15)',4,'left-msb'); y=1.8*symbols+.13+1i*.07; sigma=.4;
    production=reshape(llr_16qam_gray_LSE(y,sigma,1.8),4,[])';
    for k=1:16
        likelihood=exp(-abs(y(k)-1.8*symbols).^2/(2*sigma^2));
        for bit=1:4
            expected=log(sum(likelihood(labels(:,bit)==0))/sum(likelihood(labels(:,bit)==1)));
            assert(abs(production(k,bit)-expected)<1e-10);
        end
    end
    ref=p2_llr_reference(ones(16,1)/16,[.4;.8],1.8,8);
    assert(all(isfinite(ref.ga_mean(:))) && all(ref.raw_ber(2,:)>ref.raw_ber(1,:)));
    assert(max(abs(ref.mean_given_0(:,1)-ref.mean_given_1(:,1)))<1e-9);
    % Zero-SNR leaves must never create reliability from nothing.
    z=p2_predict_ga(zeros(4,4),st); assert(abs(z.ber_raw-.5)<1e-12);
    % Fail closed for test leakage and unauthorized formal execution, before writing.
    fake=table({'test_seen'},.01,2,100,'VariableNames',{'purpose','ber_raw','error_count','info_bits'});
    failed=false; try, p2_calibrate_model(fake); catch, failed=true; end; assert(failed);
    raw=logspace(-4,-.7,12)'; true_parameters=[.4,1.2];
    expected=1./(1+exp(-(.4+1.2*log(raw./(1-raw)))));
    training=table(repmat({'model_calibration'},12,1),raw,round(expected*1e8),ones(12,1)*1e8, ...
        'VariableNames',{'purpose','ber_raw','error_count','info_bits'});
    fitted=p2_calibrate_model(training);
    assert(max(abs(fitted.parameters-true_parameters))<.01,'Global calibration recovery failed.');
    evaluation=table([repmat({'test_seen'},10,1);repmat({'test_unseen'},10,1)], ...
        repmat((1:10)',2,1),ones(20,1)*100,ones(20,1)*.01,ones(20,1)*.01, ...
        ones(20,1)*.3,ones(20,1)*.297,ones(20,1),ones(20,1),ones(20,1)*.01, ...
        'VariableNames',{'purpose','channel','error_count','ber','ber_predicted','rate_cp', ...
        'goodput_cp','elapsed_seconds','frames','online_seconds'});
    report=p2_evaluate_predictions(evaluation); assert(all(report.use_gate_pass));
    evaluation.channel(:)=1; report=p2_evaluate_predictions(evaluation);
    assert(~any(report.use_gate_pass) && ~any(report.sufficient),'Repeated channel created false maturity.');
    cfg=p2_default_config(); cfg.mode='formal'; failed=false;
    try, run_p2_mechanism(cfg); catch exception
        failed=contains(exception.message,'budget approval');
    end; assert(failed,'Formal run must reject missing budget approval.');
    cfg=p2_default_config(); cfg.purpose='model_calibration'; cfg.seed=8401;
    cfg.strategy_p=cfg.heldout_p; cfg.strategy_names={'a','b','c'}; failed=false;
    try, run_p2_mechanism(cfg); catch exception
        failed=contains(exception.message,'leaked');
    end; assert(failed,'Heldout configuration must not leak into fitting.');
    ids=zeros(8,3); names=fieldnames(cfg.seed_roles);
    for i=1:8
        for j=1:3, ids(i,j)=p2_seed(names{i},cfg.seed_roles.(names{i})(1),1,1,j,0); end
    end
    assert(numel(unique(ids(:)))==numel(ids));
    validation_ids=arrayfun(@(s) p2_seed('power_validation',s,31,15,8191,7), ...
        cfg.seed_roles.power_validation);
    assert(numel(unique(validation_ids))==numel(validation_ids) && all(validation_ids<2^32));
    fprintf('PASS test_p2_mechanism: controls, nonzero loopback, max-log oracle, actual I, likelihood, isolation.\n');
end

function local_restore(previous_rng,original_path)
    rng(previous_rng); path(original_path);
end
