function model = p2_calibrate_model(T)
%P2_CALIBRATE_MODEL Two GLOBAL logit parameters; no strategy/SNR-specific fits.
    required={'purpose','ber_raw','error_count','info_bits'};
    assert(all(ismember(required,T.Properties.VariableNames)));
    assert(all(strcmp(T.purpose,'model_calibration')), ...
        'Only model_calibration rows may be fitted.');
    assert(all(T.info_bits>0 & T.error_count>=0 & T.error_count<=T.info_bits));
    assert(all(isfinite(T.ber_raw) & T.ber_raw>=0 & T.ber_raw<=1));
    eligible=T.error_count>=20 & T.error_count./T.info_bits>=1e-4 & ...
        T.error_count./T.info_bits<=.1 & T.ber_raw>0 & T.ber_raw<1;
    model.input_rows=height(T); T=T(eligible,:);
    model.fit_status='fitted';
    if height(T)<6 || numel(unique(T.ber_raw))<3
        model.parameters=[0,1]; model.training_rows=height(T); model.loss=nan;
        model.version='p2_global_logit_2param_v1'; model.fit_status='insufficient_data_uncalibrated_fallback';
        return;
    end
    x=log(T.ber_raw./(1-T.ber_raw));
    % Jeffreys-smoothed responses for fitting only. Raw counts remain the observations.
    y=(T.error_count+.5)./(T.info_bits+1); y=log(y./(1-y));
    objective=@(z) mean((z(1)+exp(z(2))*x-y).^2);
    fit=fminsearch(objective,[0,0],optimset('Display','off'));
    model.parameters=[fit(1),exp(fit(2))];
    model.training_rows=height(T); model.loss=objective(fit);
    model.version='p2_global_logit_2param_v1';
    if ismember('seed',T.Properties.VariableNames), model.training_seeds=unique(T.seed); end
end
