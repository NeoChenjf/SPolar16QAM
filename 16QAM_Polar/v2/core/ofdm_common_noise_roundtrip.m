function result = ofdm_common_noise_roundtrip(grid, h, N0, cp_len, noise_unit)
%OFDM_COMMON_NOISE_ROUNDTRIP Apply fixed complex time-noise power N0.
% Supply the SAME h and unit-noise sample vector to each paired candidate.
% N0 is per complex time-domain sample; it is never derived from grid power.
    if ~(isnumeric(grid) && ismatrix(grid) && ~isempty(grid) && all(isfinite(grid(:))))
        error('commonnoise:InvalidGrid','Grid must be a finite nonempty numeric matrix.');
    end
    if ~(isnumeric(h) && isvector(h) && ~isempty(h) && all(isfinite(h(:))))
        error('commonnoise:InvalidChannel','Channel must be a finite nonempty numeric vector.');
    end
    if ~(isnumeric(N0) && isreal(N0) && isscalar(N0) && isfinite(N0) && N0>=0)
        error('commonnoise:InvalidN0','N0 must be a finite nonnegative real scalar.');
    end
    if ~(isnumeric(cp_len) && isreal(cp_len) && isscalar(cp_len) && isfinite(cp_len) && ...
            cp_len==fix(cp_len) && cp_len>=numel(h)-1 && cp_len<size(grid,1))
        error('commonnoise:InvalidCP','CP must cover the channel and be shorter than the FFT.');
    end
    expected=(size(grid,1)+cp_len)*size(grid,2)+numel(h)-1;
    if ~(isnumeric(noise_unit) && isvector(noise_unit) && numel(noise_unit)==expected && ...
            all(isfinite(noise_unit(:))))
        error('commonnoise:InvalidNoise','A finite paired unit-noise vector of exact length is required.');
    end
    sigma_freq=sqrt(size(grid,1)*N0/2);
    result=ofdm_channel_roundtrip(grid,h,sigma_freq,cp_len,struct('noise_unit',noise_unit));
end
