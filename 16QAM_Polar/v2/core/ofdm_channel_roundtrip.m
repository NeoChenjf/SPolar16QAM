function result = ofdm_channel_roundtrip(tx_grid, h, sigma_noise_freq, cp_len, options)
% OFDM_CHANNEL_ROUNDTRIP Apply CP-OFDM channel, noise, FFT, and ZF equalization.
%
% result = ofdm_channel_roundtrip(tx_grid, h, sigma_noise_freq, cp_len, options)
%
% tx_grid            : nSub x nOfdmSymbols frequency-domain grid.
% h                  : channel impulse response column/vector.
% sigma_noise_freq   : noise std per real dimension after FFT, before ZF.
% cp_len             : cyclic-prefix length in samples.
% options            : optional struct with fields:
%   equalizer_floor  : minimum |H_k| used by ZF (default 1e-8).
%   noise_unit       : optional unit complex noise vector with real/imag N(0,1).
%
% The serialized CP waveform is convolved continuously with h. Receiver FFT
% windows discard the CP, so cp_len must be at least length(h)-1.

    if nargin < 5 || isempty(options)
        options = struct();
    end
    validateattributes(tx_grid, {'numeric'}, {'2d', 'nonempty', 'finite'});
    validateattributes(h, {'numeric'}, {'vector', 'nonempty', 'finite'});
    validateattributes(sigma_noise_freq, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'});
    validateattributes(cp_len, {'numeric'}, ...
        {'scalar', 'integer', 'nonnegative'});

    [n_subcarriers, n_ofdm_symbols] = size(tx_grid);
    if cp_len >= n_subcarriers
        error('ofdm_channel_roundtrip: cp_len must be smaller than nSubcarriers.');
    end
    h = h(:);
    if cp_len < numel(h) - 1
        error('ofdm_channel_roundtrip: cp_len must be at least length(h)-1.');
    end

    equalizer_floor = 1e-8;
    if isfield(options, 'equalizer_floor')
        equalizer_floor = options.equalizer_floor;
    end
    validateattributes(equalizer_floor, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});

    tx_time_no_cp = ifft(tx_grid, n_subcarriers, 1);
    if cp_len > 0
        tx_time_cp = [tx_time_no_cp(end-cp_len+1:end, :); tx_time_no_cp];
    else
        tx_time_cp = tx_time_no_cp;
    end
    tx_serial = tx_time_cp(:);
    rx_signal_full = conv(tx_serial, h);

    sigma_noise_time = sigma_noise_freq / sqrt(n_subcarriers);
    if isfield(options, 'noise_unit') && ~isempty(options.noise_unit)
        noise_unit = options.noise_unit(:);
        if numel(noise_unit) ~= numel(rx_signal_full)
            error('ofdm_channel_roundtrip: noise_unit length mismatch.');
        end
        if any(~isfinite(noise_unit))
            error('ofdm_channel_roundtrip: noise_unit must be finite.');
        end
    else
        noise_unit = randn(size(rx_signal_full)) + 1j * randn(size(rx_signal_full));
    end
    rx_noisy_full = rx_signal_full + sigma_noise_time * noise_unit;

    block_len = n_subcarriers + cp_len;
    rx_time_no_cp = zeros(n_subcarriers, n_ofdm_symbols);
    for i_symbol = 1:n_ofdm_symbols
        block_start = (i_symbol - 1) * block_len;
        fft_start = block_start + cp_len + 1;
        fft_stop = fft_start + n_subcarriers - 1;
        rx_time_no_cp(:, i_symbol) = rx_noisy_full(fft_start:fft_stop);
    end

    rx_grid = fft(rx_time_no_cp, n_subcarriers, 1);
    H = reshape(fft(h, n_subcarriers), [], 1);
    H_safe = H;
    small = abs(H_safe) < equalizer_floor;
    if any(small)
        phase = exp(1j * angle(H_safe(small)));
        phase(abs(phase) == 0) = 1;
        H_safe(small) = equalizer_floor .* phase;
    end
    rx_grid_equalized = bsxfun(@rdivide, rx_grid, H_safe);

    observation_len = numel(tx_serial);
    rx_signal_window = rx_signal_full(1:observation_len);
    rx_noisy_window = rx_noisy_full(1:observation_len);

    result.tx_time_no_cp = tx_time_no_cp;
    result.tx_time_cp = tx_time_cp;
    result.tx_serial = tx_serial;
    result.rx_signal_serial = rx_signal_window;
    result.rx_noisy_serial = rx_noisy_window;
    result.rx_grid = rx_grid;
    result.rx_grid_equalized = rx_grid_equalized;
    result.H = H;
    result.H_safe = H_safe;
    result.sigma_noise_freq = sigma_noise_freq;
    result.sigma_equalized = sigma_noise_freq ./ abs(H_safe);
    result.tx_time_power = mean(abs(tx_serial).^2);
    result.rx_signal_power = mean(abs(rx_signal_window).^2);
    result.rx_noisy_power = mean(abs(rx_noisy_window).^2);
end
