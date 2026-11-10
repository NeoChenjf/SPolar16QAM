function moments = rf_envelope_moments(envelope)
%RF_ENVELOPE_MOMENTS Discrete moments of a caller-specified complex envelope.
% The input is a finite, nonempty time vector; the caller defines sampling,
% interpolation, window, amplitude convention, and units. No DC inference.
    if ~(isnumeric(envelope) && isvector(envelope) && ~isempty(envelope) && ...
            all(isfinite(envelope(:))))
        error('rfmoments:InvalidEnvelope','Envelope must be a finite nonempty numeric vector.');
    end
    magnitude2 = abs(double(envelope(:))).^2;
    if any(~isfinite(magnitude2)) || any(~isfinite(magnitude2.^2))
        error('rfmoments:Overflow','Envelope moments overflow double precision.');
    end
    moments = struct('mean_abs2',mean(magnitude2), ...
        'mean_abs4',mean(magnitude2.^2),'sample_count',numel(envelope));
end
