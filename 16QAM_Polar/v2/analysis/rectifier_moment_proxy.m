function result = rectifier_moment_proxy(envelope, volts_per_unit, resistance_ohm, k2, k4, valid_power_w)
%RECTIFIER_MOMENT_PROXY Two/fourth-order rectifier-current proxy, not DC power.
% Peak-envelope convention: v_RF=real(Vu*envelope*exp(j*omega_c*t)).
% k2 and k4 are caller-supplied A/V^2 and A/V^4 proxy coefficients.
% Carrier averaging and the assumed matching/input impedance are external
% physical assumptions, not inferred from discrete samples.
    if ~(isnumeric(volts_per_unit) && isreal(volts_per_unit) && isscalar(volts_per_unit) && ...
            isfinite(volts_per_unit) && volts_per_unit>0 && ...
            isnumeric(resistance_ohm) && isreal(resistance_ohm) && isscalar(resistance_ohm) && ...
            isfinite(resistance_ohm) && resistance_ohm>0)
        error('rectproxy:InvalidScale','Voltage scale and resistance must be finite positive scalars.');
    end
    if ~(isnumeric(k2) && isreal(k2) && isscalar(k2) && isfinite(k2) && k2>=0 && ...
            isnumeric(k4) && isreal(k4) && isscalar(k4) && isfinite(k4) && k4>=0 && (k2+k4)>0)
        error('rectproxy:InvalidCoefficients','Coefficients must be finite nonnegative scalars and not both zero.');
    end
    if ~(isnumeric(valid_power_w) && isreal(valid_power_w) && numel(valid_power_w)==2 && ...
            all(isfinite(valid_power_w(:))) && valid_power_w(1)>=0 && valid_power_w(2)>=valid_power_w(1))
        error('rectproxy:InvalidRange','Power range must be finite nonnegative [minimum maximum].');
    end
    moments=rf_envelope_moments(envelope);
    v2=volts_per_unit^2*moments.mean_abs2/2;
    v4=3*volts_per_unit^4*moments.mean_abs4/8;
    power=v2/resistance_ohm;
    if ~all(isfinite([v2,v4,power]))
        error('rectproxy:Overflow','Voltage moments overflow double precision.');
    end
    result=struct('rf_input_power_w',power,'rf_voltage_second_v2',v2, ...
        'rf_voltage_fourth_v4',v4,'current_proxy_a',nan,'status','out_of_range', ...
        'is_dc_power',false,'sample_count',moments.sample_count);
    if power>=valid_power_w(1) && power<=valid_power_w(2)
        proxy=k2*v2+k4*v4;
        if ~isfinite(proxy), error('rectproxy:Overflow','Current proxy overflow.'); end
        result.current_proxy_a=proxy;
        result.status='within_supplied_range';
    end
end
