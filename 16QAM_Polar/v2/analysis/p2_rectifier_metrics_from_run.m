function output = p2_rectifier_metrics_from_run(run_dir,volts_per_unit,resistance_ohm,k2,k4,valid_power_w)
%P2_RECTIFIER_METRICS_FROM_RUN Apply explicit proxy assumptions to saved moments.
% Validity of range, physical scale and waveform window is the caller's responsibility.
    p2_verify_common_snapshot(run_dir); p2_audit_common_pairing(run_dir);
    T=readtable(fullfile(run_dir,'repetitions.csv')); p2_validate_common_raw_metrics(run_dir,T);
    n=height(T); power=nan(n,1); proxy=nan(n,1); status=cell(n,1);
    for i=1:n
        z=rectifier_proxy_from_moments(T.rx_envelope_m2_l4(i),T.rx_envelope_m4_l4(i), ...
            volts_per_unit,resistance_ohm,k2,k4,valid_power_w);
        power(i)=z.rf_input_power_w; proxy(i)=z.current_proxy_a; status{i}=z.status;
    end
    output=T(:,{'purpose','seed','channel','snr_db','case_id','frames'});
    output.rf_input_power_w=power; output.current_proxy_a=proxy; output.model_status=status;
end
