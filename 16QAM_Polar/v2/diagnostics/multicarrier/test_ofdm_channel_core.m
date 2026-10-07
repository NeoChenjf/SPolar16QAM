%% TEST_OFDM_CHANNEL_CORE Focused checks for the shared CP-OFDM channel core.

script_dir = fileparts(mfilename('fullpath'));
v2_root = fullfile(script_dir, '..', '..');
addpath(v2_root);
setup_paths();

rng(7, 'twister');
n_subcarriers = 64;
cp_len = 16;
n_symbols = 3;
tx_grid = (randn(n_subcarriers, n_symbols) + ...
    1j * randn(n_subcarriers, n_symbols)) / sqrt(2);

%% Unit impulse: exact noiseless recovery.
out_awgn = ofdm_channel_roundtrip(tx_grid, 1, 0, cp_len, struct());
err_awgn = max(abs(out_awgn.rx_grid_equalized(:) - tx_grid(:)));
assert(err_awgn < 1e-10, 'Unit-impulse OFDM recovery mismatch: %.3e', err_awgn);

%% Multipath with sufficient CP: exact noiseless recovery.
h = [1; 0.35-0.2j; -0.1+0.05j];
h = h / norm(h);
out_rayleigh = ofdm_channel_roundtrip(tx_grid, h, 0, cp_len, struct());
err_rayleigh = max(abs(out_rayleigh.rx_grid_equalized(:) - tx_grid(:)));
assert(err_rayleigh < 1e-9, 'Multipath OFDM recovery mismatch: %.3e', err_rayleigh);
assert(isfinite(out_rayleigh.rx_signal_power) && out_rayleigh.rx_signal_power > 0);

%% Deep spectral null: equalizer protection must keep outputs finite.
h_null = [1; -1] / sqrt(2);
out_null = ofdm_channel_roundtrip(tx_grid, h_null, 0, cp_len, ...
    struct('equalizer_floor', 1e-6));
assert(all(isfinite(out_null.rx_grid_equalized(:))), ...
    'Equalizer floor did not protect a spectral null.');

%% Explicit shared noise must be deterministic.
noise_len = numel(out_rayleigh.tx_serial) + numel(h) - 1;
noise_unit = randn(noise_len, 1) + 1j * randn(noise_len, 1);
opts = struct('noise_unit', noise_unit);
out_noise_a = ofdm_channel_roundtrip(tx_grid, h, 0.2, cp_len, opts);
out_noise_b = ofdm_channel_roundtrip(tx_grid, h, 0.2, cp_len, opts);
assert(isequal(out_noise_a.rx_grid_equalized, out_noise_b.rx_grid_equalized), ...
    'Explicit noise_unit did not produce deterministic output.');

%% Too-short CP must fail at the boundary.
did_fail = false;
try
    ofdm_channel_roundtrip(tx_grid, ones(18, 1), 0, cp_len, struct());
catch err
    did_fail = contains(err.message, 'cp_len');
end
assert(did_fail, 'Too-short CP did not raise the expected error.');

%% Vector-sigma LLR must preserve scalar behavior and support fading variance.
bits = de2bi((0:15).', 4, 'left-msb');
tx_symbols = qammod(reshape(bits.', [], 1), 16, 'gray', ...
    'InputType', 'bit', 'UnitAveragePower', true);
llr_scalar = llr_16qam_gray_LSE(tx_symbols, 0.2);
llr_vector = llr_16qam_gray_LSE(tx_symbols, 0.2 * ones(size(tx_symbols)));
assert(max(abs(llr_scalar - llr_vector)) < 1e-12, ...
    'Vector sigma changed scalar LLR behavior.');
llr_fading = llr_16qam_gray_LSE(tx_symbols, linspace(0.1, 0.3, 16).');
assert(all(isfinite(llr_fading)), 'Vector-sigma LLR returned NaN/Inf.');

fprintf('test_ofdm_channel_core: PASS\n');
